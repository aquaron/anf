#!/bin/sh

_service="docker-${name}.service"
_cwd=$(dirname $0)
_cwd=$(cd "$_cwd"; pwd)
_file="${_cwd}/${_service}"

if [ ! "${_file}" ]; then
    echo "${_file} does not exist"
    exit 1
fi

if [ ! "$(whoami)" = "root" ]; then
    echo "Usage: sudo $0"
    exit 1
fi

while true; do
    read -p "Install systemd startup file? " yn
    case $yn in
        [Yy]* ) 
            ln -s ${_file} /etc/systemd/system
            systemctl daemon-reload
            echo "Test service run:\n\$ systemctl start ${_service}\n"
            echo "Enable service at startup:\n\$ systemctl enable ${_service}"

            exit 0
            ;;
        * ) exit 1
            ;;
    esac
done
