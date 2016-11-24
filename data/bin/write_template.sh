#!/bin/bash

declare -A vars=()

while [[ $# -gt 1 ]]; do
    val="$2"
    val="${val%\"}"
    vars[$1]="${val#\"}"
    shift
    shift
done

OLD_IFS="$IFS"
IFS=
while read -r line ; do
    while [[ "$line" =~ (\$\{([a-zA-Z][a-zA-Z_0-9]*)\}) ]] ; do
        LHS=${BASH_REMATCH[1]}
        VAR=${BASH_REMATCH[2]}
        line=${line//$LHS/${vars[$VAR]}}
    done
    echo "$line"
done
IFS="$OLD_IFS"
