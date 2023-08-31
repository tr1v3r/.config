#!/bin/bash

# 需要 root 权限执行此脚本
if [[ $EUID -ne 0 ]]; then
    echo "请以 root 用户身份运行此脚本"
    exit 1
fi

# 备份原有的 sources.list 文件
cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 注释掉原有的所有行
sed -i 's/^/# /' /etc/apt/sources.list

# 添加新的源
echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释" >>/etc/apt/sources.list
echo "deb https://mirrors.nju.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" >>/etc/apt/sources.list
echo "# deb-src https://mirrors.nju.edu.cn/debian/ bookworm main contrib non-free non-free-firmware" >>/etc/apt/sources.list

echo "deb https://mirrors.nju.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware" >>/etc/apt/sources.list
echo "# deb-src https://mirrors.nju.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware" >>/etc/apt/sources.list

echo "deb https://mirrors.nju.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware" >>/etc/apt/sources.list
echo "# deb-src https://mirrors.nju.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware" >>/etc/apt/sources.list

echo "deb https://mirrors.nju.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware" >>/etc/apt/sources.list
echo "# # deb-src https://mirrors.nju.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware" >>/etc/apt/sources.list

echo "# deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >>/etc/apt/sources.list
echo "# deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >>/etc/apt/sources.list

# 更新 APT 包数据库
apt update

echo "完成"
