#!/bin/bash

# 检测当前 Linux 发行版
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo "Unable to detect your Linux distribution"
    exit 1
fi

if [[ $OS == Debian* ]]; then
    source $DIR/init_debian.sh
fi
