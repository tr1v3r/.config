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
    echo "executing: $1"
    eval $1 || abort "执行失败: $1"
}

install_all=false
install_zsh=false
install_rust=false
install_go=false
install_python_tool=false

# 遍历所有参数
for arg in "$@"; do
    case $arg in
        --with-all)
            install_all=true
            ;;
        --with-zsh)
            install_zsh=true
            ;;
        --with-rust)
            install_rust=true
            ;;
        --with-go)
            install_go=true
            ;;
        --with-python-tools)
            install_python_tool=true
            ;;
        --help)
            echo "usage: incoming"
            ;;
        *)
            echo "未知参数: $arg"
            ;;
    esac
done

# 备份原有的 sources.list 文件
execute "[ -f /etc/apt/sources.list ] && cp /etc/apt/sources.list /etc/apt/sources.list.bak || touch /etc/apt/sources.list"

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

# echo "# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释" >>/etc/apt/sources.list
echo "# The source code image is commented by default to improve the speed of apt update. You can uncomment it yourself if necessary." >>/etc/apt/sources.list
for source in "${sources[@]}"; do
    echo $source >>/etc/apt/sources.list || abort "replace apt source fail"
done

# 更新 APT 包数据库和系统
echo "Updating apt sources..."
execute "apt update && apt upgrade -y && apt full-upgrade -y"

packages=(
    "curl" "wget" "dnsutils" "git" "gcc" "cmake" "sudo"
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
apt install "${packages[@]}" -y || abort "Failed to install apt packages"

if [ "$install_all" = true ] && [ "$install_zsh" = true ] && [ ! -d ~/.oh-my-zsh ]; then
    apt install zsh -y || abort "Failed to install zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && chsh -s /bin/zsh || abort "Failed to init oh-my-zsh"
fi

# 创建本地.config目录
echo "Downloading neovim config..."
mkdir ~/.config
git clone https://github.com/tr1v3r/nvim.git ~/.config/nvim

if [ "$install_all" = true ] && [ "$install_go" = true ]; then
    echo "Installing Golang..."
    # version=("1.16.15" "1.17.13" "1.18.10" "1.19.12" "1.20.7" "1.21.0") until 2023.07.24
    function InstallGO() {
        origin=$(pwd)
        cd /tmp
        for v in "${version[@]}"; do
            if [ -d "/usr/local/go$v" ]; then
                continue
            fi
            tar_file="go$v.$(uname | tr '[:upper:]' '[:lower:]')-$(uname -m | sed 's/aarch/arm/g').tar.gz"

            echo "deploying go$v" && wget https://go.dev/dl/$tar_file && tar xzf $tar_file && mv go /usr/local/go$v && rm $tar_file
        done
        cd $origin
    }
    version=("1.19.12" "1.20.7" "1.21.0")
    InstallGO || abort "Failed to install golang"
    export PATH="/usr/local/go/bin:$PATH"

    rm -rf /usr/local/go && ln -s "/usr/local/go1.21.0" /usr/local/go || abort "Failed to link go1.21.0 to /usr/local/go"

    echo "Installing Golang tools..."
    go_tools=("github.com/jesseduffield/lazygit@latest" "github.com/rhysd/vim-startuptime@latest")
    for tool in "${go_tools[@]}"; do
        go install "$tool" || abort "Failed to install $tool"
    done
fi

if [ "$install_all" = true ] && [ "$install_rust" = true ]; then
    # Install Rust
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh || abort "Failed to install Rust"
    source ~/.cargo/env || abort "Failed to source cargo env"

    # Install Rust tools
    echo "Installing Rust tools..."
    cargo install ripgrep zoxide || abort "Failed to install ripgrep"
fi

if [ "$install_all" = true ] && [ "$install_python_tool" = true ]; then
    # Install Python tools
    echo "Installing Python tools..."
    pip3 install ranger-fm || abort "Failed to install ranger-fm"
fi

echo "Debian init done."
