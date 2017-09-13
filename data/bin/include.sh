#!/bin/bash

HELP=`cat <<EOT
Usage: docker run -t --rm -v <local-dir>:/data <local-port>:80 ${_image} <command>

 <local-dir> - directory on the host system to map to container

 <command>   init    - initialize directories if they're empty
             daemon  - run in non-detached mode
             test    - test nginx configuration
             start   - start nginx server
             stop    - quick nginx shutdown
             quit    - graceful nginx shutdown
             reload  - reload nginx configuration file
             reopen  - reopens nginx log files

EOT
`

function is_empty() { if [[ ! -d "$1" ]] || [[ ! "$(ls -A $1)" ]]; then echo "yes"; fi }

function hint() {
    local hint="| $* |"
    local stripped="${hint//${bold}}"
    stripped="${stripped//${normal}}"
    local edge=$(echo "$stripped" | sed -e 's/./-/g' -e 's/^./+/' -e 's/.$/+/')
    echo "$edge"
    echo "$hint"
    echo "$edge"
}

function assert_ok() { [[ "$?" = 1 ]] && hint "Abort" && exit 1; }
function start_fcgi() { /usr/bin/fcgi-run start; }
function stop_fcgi() { /usr/bin/fcgi-run stop; }

function run_cron() {
    _file="${_root}/cron/$1"
    if [ ! -s "${_file}" ]; then
        echo "${_file} not found"
        exit 1
    fi

    ${_file}
}

function get_os() { echo "$(grep ^ID= /etc/os-release | sed 's/^ID=//')"; }

function apt_get() {
    local _os="$(get_os)"
    for pkg in "$@"; do
        case "$_os" in
            alpine) [[ ! "$(apk -q version $pkg)" ]] && apk -q --no-cache add $pkg && DIRTY[$pkg]=1 ;;
            *) [[ ! "$(dpkg-query -s $pkg 2>&1 | grep "install ok")" ]] && \
                apt-get update && \
                apt-get install -y $pkg && \
                DIRTY[$pkg]=1
                ;;
        esac
    done
}

function apt_remove() {
    local _os="$(get_os)"
    for pkg in "$@"; do
        if [ "${DIRTY[$pkg]}" ]; then
            case "$(get_os)" in
                alpine) apk --purge -q del $1 ;;
                *) apt-get purge -yq $1 ;;
            esac
        fi
    done
}

function get_container_id() {
    echo "$(cat /proc/1/cgroup | grep 'docker/' | tail -1 | sed 's/^.*\///' | cut -c 1-12)"
}

function get_container_json() {
    echo "$(curl -s --unix-socket /var/run/docker.sock http://localhost/containers/$(get_container_id)/json)"
}

function get_container_data() {
    local _json="$(get_container_json)"

    PORT=$(echo $_json | jq '.HostConfig.PortBindings."80/tcp"[0].HostPort' -M -r)
    IMAGE="$(echo $_json | jq '.Config.Image' -M -r)"
    VOLUMES=""
    local _maps=( $(echo $_json | jq '.HostConfig.Binds' -M -r | tr '[],"' ' ') )
    for i in "${!_maps[@]}"; do
        [[ "${_maps[$i]}" =~ ^/var/run/docker.sock ]] || \
        VOLUMES="${VOLUMES} -v ${_maps[$i]}"
    done
}

function check_container_info() {
    if [ ! -S "/var/run/docker.sock" ]; then
        echo "ERRROR: Run container with '-v /var/run/docker.sock:/var/run/docker.sock' to initialize!"
        return 1
    fi

    declare -A -g DIRTY=()
    local _id="$(get_container_id)"

    apt_get curl jq

    get_container_data

    apt_remove curl jq
}

function guess_volumes() {
    declare -a _files=("$_etc" "$_log" "$_root")
    local _file="/proc/self/mountinfo"
    local _map=""

    for i in "${!_files[@]}"; do
        local _localpath=$(grep ${_files[$i]} ${_file} | grep -v '/volumes/' | cut -f 4,9 -d" " | perl -e 's{^(\S+)\s+(\S+)$}{$2$1}' -p)
        [[ "${_localpath}" ]] && _map="${_map} -v ${_localpath}:${_files[$i]}"
    done
    echo $_map
}

function write_systemd_file() {
    local _service_file="${_etc}/docker-${HOSTNAME}.service"
    local _script="${_etc}/install-systemd.sh"

    local _content=$(vars_substitute "${DATADIR}/templ/systemd.service" \
        name \""${HOSTNAME}"\" map \""${VOLUMES}"\" port \""${PORT}"\" image \""${IMAGE:-$_image}"\")

    if [ "${_content}" ]; then
        echo "${_content}" > ${_service_file}
    fi

    echo "Created ${_service_file}"

    cp ${DATADIR}/templ/install.sh ${_script}
    chmod 755 ${_script}
    echo "Created ${_script}"
}

function run_init() {
    if [ ! "$(is_empty ${_etc})" ]; then
        return 1
    fi

    cp -R ${DATADIR}/etc/. ${_etc}/

    if [ "$(is_empty ${_root}/html)" ]; then
        cp -R ${DATADIR}/html ${_root}/html
    fi

    if [ "$(is_empty ${_root}/cgi)" ]; then
        cp -R ${DATADIR}/cgi ${_root}/cgi
    fi

    if [ "$(is_empty ${_root}/cron)" ]; then
        mkdir ${_root}/cron
    fi

    check_container_info
    write_systemd_file
}

function vars_substitute() {
    local _file="$1"
    [[ ! -f "$_file" ]] && error_echo "$_file not found"
    shift

    declare -A vars=()

    while [[ $# -gt 1 ]]; do
        val="$2"
        val="${val%\"}"
        vars[$1]="${val#\"}"
        shift
        shift
    done

    local _line
    local _regex='(\$\{([a-zA-Z][a-zA-Z_0-9]*)\})'

    local _old_ifs="$IFS"; IFS=
    while read -r _line; do
        while [[ "$_line" =~ $_regex ]]; do
            local _lhs="${BASH_REMATCH[1]}"
            local _name="${BASH_REMATCH[2]}"
            _line="${_line//$_lhs/\$$_name}"
            if [ ! "${vars[$_name]}" ]; then
                vars[$_name]=""
            fi
        done
    done < "$_file"

    local _service_file=""
    while read -r _line; do
        while [[ "$_line" =~ $_regex ]]; do
            local _LHS="${BASH_REMATCH[1]}"
            local _VAR="${BASH_REMATCH[2]}"
            if [ "${vars[$_VAR]}" ]; then
                _line="${_line//$_LHS/${vars[$_VAR]}}"
            else
                _line="${_line//$_LHS/\$\-$_VAR\-}"
            fi
        done
        _service_file="${_service_file}${_line}\n"
    done < "$_file"

    IFS="$_old_ifs"

    local _content=""
    local _regex='(\$-([a-zA-Z][a-zA-Z_0-9]*)-)'
    while read -r _line; do
        while [[ "$_line" =~ $_regex ]]; do
            local _LHS="${BASH_REMATCH[1]}"
            local _VAR="${BASH_REMATCH[2]}"
            _line="${_line//$_LHS/\$\{$_VAR\}}"
        done
        _content="${_content}${_line}\n"
    done < <(echo $_service_file)

    echo -e "$_content"
}

