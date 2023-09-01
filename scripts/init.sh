#!/bin/bash

# 需要 root 权限执行此脚本
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root"
    exit 1
fi

DIR="$(dirname "$(readlink -f "$0")")"

SYS_TYPE=$(uname -s)

case $SYS_TYPE in
    "Darwin")
        source $DIR/init_mac.sh
        ;;
    "Linux")
        source $DIR/init_linux.sh
        ;;
    *)
        echo "Unknown SYS type: $SYS_TYPE"
        ;;
esac
