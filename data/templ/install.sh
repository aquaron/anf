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
    read -p "Install systemd ${_service}? " yn
    case $yn in
        [Yy]* ) 
            systemctl enable ${_file}
            systemctl daemon-reload
            exit 0
            ;;
        * ) exit 1
            ;;
    esac
done
