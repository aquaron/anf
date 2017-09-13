#!/bin/bash

CMD="$1"
DATADIR="/data"
BIN_PATH=$(dirname $0)
. ${BIN_PATH}/include.sh

VOLUMES="$(guess_volumes)"

if [ ! "${VOLUMES}" ]; then
    echo "ERROR: you need run Docker with the '-v' parameter, try:"
    echo "    \$ docker run --rm -v /tmp:/data ${_image} help"
    exit 1
fi

if [[ $# -lt 1 ]] || [[ ! "${VOLUMES}" ]]; then 
    echo "$HELP"
    exit 1
fi

case "${CMD}" in
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
        hint "${CMD} nginx server"
        nginx -s ${CMD}
        ;;

    stop|quit)
        hint "${CMD} nginx server"
        stop_fcgi
        nginx -s ${CMD}
        ;;

    kill)
        killall nginx
        ;;

    test)
        hint "test nginx.conf"
        nginx -t
        ;;

    cron)
        hint "running cron $2"
        run_cron "$2"
        assert_ok
        ;;

    clean)
        hint "cleanning"
        rm -r ${_etc}/* ${_root}/html ${_root}/cgi ${_log}/*.log
        ;;

    *) echo "ERROR: Command '${CMD}' not recognized"
        ;;
esac
