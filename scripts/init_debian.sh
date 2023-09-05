#!/bin/bash

# check if user is root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root"
    exit 1
fi

# 出错时退出脚本的函数
abort() {
    echo "abort: $1"
    exit 1
}

# 执行操作并检查状态
execute() {
    echo "execute: $1"
    eval $1 || abort "执行失败: $1"
}

# 备份原有的 sources.list 文件
execute "cp /etc/apt/sources.list /etc/apt/sources.list.bak"

# 注释掉原有的所有行
execute "sed -i 's/^/# /' /etc/apt/sources.list"

# 添加新的源
sources=(
    "deb https://mirrors.nju.edu.cn/debian/ bookworm main contrib non-free non-free-firmware"
    "# deb-src https://mirrors.nju.edu.cn/debian/ bookworm main contrib non-free non-free-firmware"
    "deb https://mirrors.nju.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware"
    "# deb-src https://mirrors.nju.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware"
    "deb https://mirrors.nju.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware"
    "# deb-src https://mirrors.nju.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware"
    "deb https://mirrors.nju.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware"
    "# deb-src https://mirrors.nju.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware"
)

echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释" >>/etc/apt/sources.list
for source in "${sources[@]}"; do
    echo $source >>/etc/apt/sources.list || abort "replace apt source fail"
done

# 更新 APT 包数据库和系统
execute "apt update && apt upgrade -y && apt full-upgrade -y"

packages=(
    "curl" "wget" "dnsutils" "zsh" "git" "gcc" "cmake"
    # net-tools -- ifconfig
    # iputils-ping -- ping
    "net-tools" "iputils-ping"
    "nftables"
    "neovim"
    "python3" "python3-pip" "python3-neovim"
    "highlight" "atool"
    "apt-transport-https" "ca-certificates"
    "openssl" "gpg"
)
apt install "${packages[@]}" -y || abort "Failed to install some apt packages"

echo "Debian init done."
