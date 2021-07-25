#!/bin/bash

. /etc/os-release

# Install required packages
if [ -e /etc/redhat-release ]; then
    sudo yum check-update
    if [ ! -e /etc/yum.repos.d/docker-ce.repo ]; then
        echo "==> Install docker-ce repo"
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    fi

    sudo rpm -e podman-docker docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

    echo "==> Install docker-ce related packages"
    sudo yum install -y python3 python3-pip rsync docker-ce docker-ce-cli
    sudo yum install -y gcc python3-devel libffi-devel # pypi-mirror
    sudo yum install -y createrepo
    sudo systemctl enable --now docker


    if [ "$VERSION_ID" != "7" ]; then
        # RHEL/CentOS 8
        if ! command -v repo2module >/dev/null; then
            echo "==> Install modulemd-tools"
            sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
            sudo dnf copr enable -y frostyx/modulemd-tools-epel
            sudo dnf install -y modulemd-tools
        fi
    fi
else
    sources=/etc/apt/sources.list.d/download_docker_com_linux_ubuntu.list  # Same as kubespray
    if [ ! -e $sources ]; then
        echo "==> Install docker-ce repo"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee $sources
    fi
    sudo apt update
    sudo dpkg -r docker docker-engine docker.io containerd runc
    
    echo "==> Install docker-ce related packages"
    sudo apt install -y python3 python3-pip python3-venv rsync docker-ce docker-ce-cli
    sudo apt install -y gcc python3-dev libffi-dev # pypi-mirror
fi

# Set up docker proxy
if [ -n "$http_proxy" ] && [ ! -e /etc/systemd/system/docker.service.d/http-proxy.conf ]; then
    [ ! -d /etc/systemd/system/docker.service.d ] && sudo mkdir /etc/systemd/system/docker.service.d
    cat <<EOF | sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$http_proxy" "HTTPS_PROXY=$https_proxy"
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
fi

# Create python3 venv
if [ ! -e ~/.venv/default ]; then
    python3 -m venv ~/.venv/default
fi

. ~/.venv/default/bin/activate
pip install -r requirements.txt
