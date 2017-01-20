#!/bin/sh

getvols() { 
    local _file="/proc/self/mountinfo"

    _localetc=$(grep $_etc $_file | grep -v '/volumes/' | cut -f 4 -d" ")
    _locallog=$(grep $_log $_file | grep -v '/volumes/' | cut -f 4 -d" ")
    _localdata=$(grep $_root $_file | grep -v '/volumes/' | cut -f 4 -d" ")

    if [[ "$_localetc" ]] && [[ "$_locallog" ]] && [[ "$_localdata" ]]; then
        echo "-v $_localetc:$_etc -v $_locallog:$_log -v $_localdata:$_root"
    fi
}

_vols=$(getvols)
_ports="-p 80:80"

is_empty() { if [[ ! -d "$1" ]] || [[ ! "$(ls -A $1)" ]]; then echo "yes"; fi }

if [ ! "${_vols}" ]; then 
    echo "ERROR: you need run Docker with the -v parameter, try:"
    echo "    \$ docker run --rm -v /tmp:/data aquaron/anf help"
    exit 1
fi

_run="docker run -t --rm ${_vols} ${_ports} aquaron/anf"

HELP=`cat <<EOT
Usage: docker run -t --rm -v <local-dir>:/data ${_ports} aquaron/anf <command>

 <local-dir> - directory on the host system to map to container

 <command>   init    - initialize directories if they're empty
             daemon  - run in non-detached mode
             test    - test nginx configuration
             start   - start nginx server
             stop    - quick nginx shutdown
             quit    - graceful nginx shutdown
             reload  - reload nginx configuration file
             reopen  - reopens nginx log files

`

if [[ $# -lt 1 ]] || [[ ! "${_vols}" ]]; then echo "$HELP"; exit 1; fi

hint() {
    local hint="| $* |"
    local stripped="${hint//${bold}}"
    stripped="${stripped//${normal}}"
    local edge=$(echo "$stripped" | sed -e 's/./-/g' -e 's/^./+/' -e 's/.$/+/')
    echo "$edge"
    echo "$hint"
    echo "$edge"
}

_cmd=$1
_host=$2
_datadir=/data

_start="docker run ${_vols} ${_ports} -d aquaron/anf"

write_systemd_file() {
    local _name="$1"
    local _map="$2"
    local _port="$3"

    local _service_file="${_etc}/docker-${_name}.service"
    local _script="${_etc}/install-systemd.sh"

    apk --no-cache add bash

    cat ${_datadir}/templ/systemd.service \
        | write_template.sh name \""${_name}"\" map \""${_map}"\" port \""${_port}"\" \
        > ${_service_file}

    echo "Created ${_service_file}"

    cat ${_datadir}/templ/install.sh \
        | write_template.sh name \""${_name}"\" \
        > ${_script}

    chmod 755 ${_script}

    echo "Created ${_script}"

    apk del bash
}

run_init() {
    if [ "$(is_empty ${_etc})" ]; then
        cp -R ${_datadir}/etc/. ${_etc}/

        if [ "$(is_empty ${_root}/html)" ]; then
            cp -R ${_datadir}/html ${_root}/html
        fi

        if [ "$(is_empty ${_root}/cgi)" ]; then
            cp -R ${_datadir}/cgi ${_root}/cgi
        fi

        write_systemd_file "anf" "${_vols}" "${_ports}" 
    fi
}

assert_ok() {
    if [ "$?" = 1 ]; then
        hint "Abort"
        exit 1
    fi
}

start_fcgi() { /usr/bin/fcgi-run start; }
stop_fcgi() { /usr/bin/fcgi-run stop; }

case "${_cmd}" in
    init)
        hint "initializing"
        run_init
        ;;

    start) 
        hint "starting nginx server"
        start_fcgi
        nginx
        ;;

    daemon)
        run_init
        start_fcgi
        nginx -g 'daemon off;'
        ;;

    reload|reopen) 
        hint "${_cmd} nginx server"
        nginx -s ${_cmd}
        ;;

    stop|quit) 
        hint "${_cmd} nginx server"
        stop_fcgi
        nginx -s ${_cmd}
        ;;

    kill)
        killall nginx
        ;;

    test)
        hint "test nginx.conf"
        nginx -t
        ;;
     
    clean)
        hint "cleanning"
        rm -r ${_etc}/* ${_root}/html ${_root}/cgi ${_log}/*.log
        ;;

    *) echo "ERROR: Command '${_cmd}' not recognized"
        ;;
esac

