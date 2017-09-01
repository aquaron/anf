#!/bin/sh

if [ "$(whoami)" != "root" ]; then echo "Usage: sudo $0"; exit 1; fi

_cwd=$(dirname $0)
_cwd=$(cd "$_cwd"; pwd)

if [ "$1" ]; then
    _service="$1"
else
    _files=$(ls -1 ${_cwd}/*.service | wc -l)
    case $_files in
        0) 
            echo "No files found"
            exit 1
            ;;
        1) 
            _service=$(ls -1 *.service)
            echo "Found: $_service"
            ;;
        *) 
            _choices=$(ls -1 *.service | awk '{printf "  %d) %s\n", NR, $0}')
            echo "$_choices"
            read -p "Which service to install? " num
            num="^\s*$num)"
            _service=$(echo "$_choices" | grep -e $num | sed 's/^[^)]*) //')
            ;;
    esac
fi

_orig_file="${_cwd}/${_service}"
_file="/lib/systemd/system/${_service}"
cp ${_orig_file} ${_file}

if [ ! -f "${_file}" ]; then
    echo "${_file}: does not exist"
    exit 1
fi

if [ "$(systemctl is-enabled ${_service} 2>&1)" = "enabled" ]; then
    read -p "Service enabled. Disable ${_service}? " yn
    case $yn in
        [Yy]* ) systemctl disable ${_file} ;;
        *) exit 1 ;;
    esac
fi

while true; do
    read -p "Install systemd startup file? " yn
    case $yn in
        [Yy]* ) 
            systemctl enable ${_file}
            systemctl daemon-reload
            echo "Test service run:\n\$ systemctl start ${_service}\n"

            exit 0
            ;;
        * ) exit 1
            ;;
    esac
done
