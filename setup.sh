#!/bin/bash

set -e

# Ensure the script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo"
    exit 1
fi

apt update && apt upgrade -y

install_vm_ware_tools() {
    read -p "Do you want to install VMWawre tools? (y/n): " install_vmware_tools_choice
    if [[ $install_vmware_tools_choice == "y" ]]; then
        apt install -y open-vm-tools open-vm-tools-desktop
    fi
}

install_general_tools() {
    apt install -y git curl scdoc cmake pkg-config libfreetype6-dev \
    libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev apt-transport-https \
    ca-certificates software-properties-common tree jq btop flameshot rlwrap \
    ncat nmap gnome-tweaks neofetch sshfs rclone socat figlet lolcat dtrx \
    wl-clipboard progress

    snap install procs --classic
    snap install go --classic
    snap install code --classic
    snap install bw # bitwarden cli
}

install_cli_tools() {
    apt install -y lsd micro xclip ncdu duf fzf ripgrep bat neovim
    mkdir -p ~/.local/bin
    ln -s /usr/bin/batcat ~/.local/bin/bat # Required for ubuntu
}

clone_and_configure_dotfiles() {
    git clone https://github.com/loran-code/dotfiles.git /opt/dotfiles
    chown -R ${USER}:${USER} /opt/dotfiles
    mkdir $HOME/.config/alacritty $HOME/.config/atuin $HOME/.config/lazydocker $HOME/.config/zellij
    cp /opt/dotfiles/alacritty/* $HOME/.config/alacritty
    cp /opt/dotfiles/atuin/* $HOME/.config/atuin
    cp /opt/dotfiles/lazydocker/* $HOME/.config/lazydocker
    cp /opt/dotfiles/zellij/* $HOME/.config/zellij
    cp /opt/dotfiles/scripts/* /usr/local/bin/
    cp /opt/dotfiles/aliases $HOME/aliases
    cp /opt/dotfiles/.bashrc $HOME/.bashrc
}

configure_bash() {
    mkdir -p ~/.local/bin
    ln -s /usr/bin/fdfind ~/.local/bin/fd
}

configure_nerd_fonts() {
    mkdir -p $HOME/.local/share/fonts
    cp /opt/dotfiles/fonts/* $HOME/.local/share/fonts
    fc-cache -f -v
}

install_starship() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_atuin() {
    bash <(curl https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh)
    atuin import auto
}

install_docker() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update
    apt install -y docker-ce
    usermod -aG docker $USER
    newgrp docker
    systemctl enable docker
}

install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source "$HOME/.cargo/env"
    rustup override set stable
    rustup update stable
}

build_alacritty() {
    git clone https://github.com/alacritty/alacritty.git /opt/alacritty
    cd /opt/alacritty
    cargo build --release

    tic -xe alacritty,alacritty-direct extra/alacritty.info
    infocmp alacritty

    # Set Alacritty desktop icon and manual
    cp target/release/alacritty /usr/local/bin
    cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    desktop-file-install extra/linux/Alacritty.desktop
    update-desktop-database

    mkdir -p /usr/local/share/man/man1 /usr/local/share/man/man5
    scdoc < extra/man/alacritty.1.scd | gzip -c | tee /usr/local/share/man/man1/alacritty.1.gz > /dev/null
    scdoc < extra/man/alacritty-msg.1.scd | gzip -c | tee /usr/local/share/man/man1/alacritty-msg.1.gz > /dev/null
    scdoc < extra/man/alacritty.5.scd | gzip -c | tee /usr/local/share/man/man5/alacritty.5.gz > /dev/null
    scdoc < extra/man/alacritty-bindings.5.scd | gzip -c | tee /usr/local/share/man/man5/alacritty-bindings.5.gz > /dev/null
}

install_cargo_packages() {
    cargo install ripgrep # Faster Grep
    cargo install zellij --locked # Terminal Multiplexer
    cargo install zoxide --locked # zoxide is a smarter cd command, inspired by z and autojump.
    cargo install yazi-fm yazi-cli --locked  # CLI File Manager
}

install_containers() {
    docker pull lazyteam/lazydocker # Terminal UI container management
    docker pull hashicorp/terraform # Infrastructure as code
    docker pull hashicorp/vault # Secret Management
    docker pull ansible/ansible # Configuration Management
    docker pull portainer/portainer-ce # Container Management
    docker pull ngrok/ngrok # Connect localhost to the internet for testing 
    docker pull containrrr/watchtower # Automating Docker container base image updates. 
}

install_insomnia() {
    # Add to sources
    curl -1sLf \
    'https://packages.konghq.com/public/insomnia/setup.deb.sh' \
    | -E distro=ubuntu codename=focal bash

    # Refresh repository sources and install Insomnia
    apt-get update
    apt-get install insomnia
}

install_devtools() {
    read -p "Do you want to install development tools (e.g., VS Code, Insomnia)? (y/n): " install_devtools_choice
    if [[ $install_devtools_choice == "y" ]]; then
        install_insomnia
        # Devcontainers?
        # testcontainers
        # lazygit
        # jetbrains toolbox
    fi
}

install_python_tools() {
    read -p "Do you want to install Python tools (pyenv, Poetry)? (y/n): " install_python_tools_choice
    if [[ $install_python_tools_choice == "y" ]]; then
        install_pyenv
        install_poetry
    fi
}

install_pyenv() {
    apt install -y make build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
            libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git

    curl https://pyenv.run | bash

    # echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    # echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    # echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> ~/.bashrc
    # echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc

    source ~/.bashrc

    pyenv update
    pyenv install 3.12.3
    pyenv global 3.12.3
}

install_poetry() {
    curl -sSL https://install.python-poetry.org | python -
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
}

configure_ssh() {
    ssh-keygen -t rsa -b 4096 -C "Dev Ubuntu Desktop Virtual Environment Laptop Key"
}

configure_cron_job() {
    # Add a cron job to update and upgrade the system on reboot
    (crontab -l 2>/dev/null; echo "@reboot sudo apt update && sudo apt upgrade -y") | crontab -
}

configure_cron_job() {
    # Add a cron job to update and upgrade the system on reboot
    echo "@reboot apt update && apt upgrade -y" | tee -a /etc/crontab
}


configure_security() {
    # Install security tools
    apt install -y ufw fail2ban clamav rkhunter lynis

    # Configure UFW (Uncomplicated Firewall)
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow OpenSSH
    ufw enable

    # Configure Fail2Ban
    systemctl enable fail2ban
    systemctl start fail2ban

    # Configure ClamAV
    systemctl stop clamav-freshclam
    freshclam
    systemctl start clamav-freshclam
    systemctl enable clamav-freshclam
    echo "0 2 * * * clamscan -r / --bell -i" | tee -a /etc/crontab
    
    # Run RKHunter
    rkhunter --update
    rkhunter --propupd
    rkhunter --check --sk

    # Schedule RKHunter daily scans
    echo "0 3 * * * root /usr/bin/rkhunter --check --sk" | tee -a /etc/crontab

    # Run Lynis for an initial security audit
    lynis audit system

    # Disable unnecessary services
    # systemctl disable avahi-daemon
    # systemctl disable cups
    # systemctl disable bluetooth
    # systemctl disable isc-dhcp-server
    # systemctl disable isc-dhcp-server6
    # systemctl disable slapd
    # systemctl disable nfs-server
    # systemctl disable rpcbind
    # systemctl disable bind9
    # systemctl disable vsftpd
    # systemctl disable apache2
    # systemctl disable dovecot
    # systemctl disable smbd
    # systemctl disable xinetd
    # systemctl disable rsync

    # SSH Hardening (if SSH is enabled)
    if [ -f /etc/ssh/sshd_config ]; then
        sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        systemctl restart sshd
    fi
}

cleanup() {

}

# Main function to run installations and configurations
main() {
    install_vm_ware_tools
    install_general_tools
    install_cli_tools
    clone_and_configure_dotfiles
    configure_bash
    configure_nerd_fonts
    install_starship
    install_atuin
    install_docker
    install_rust
    build_alacritty
    install_cargo_packages
    install_containers

    install_devtools
    install_python_tools
    configure_ssh
    configure_cron_job
    configure_security
    cleanup
}

main

# pomodoro
# llm
# install_statusbar