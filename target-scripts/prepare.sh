#!/bin/bash

BASEDIR="."
if [ ! -d images ] && [ -d ../outputs ]; then
  BASEDIR="../outputs"  # for tests
fi

BASEDIR=$(cd $BASEDIR; pwd)

cd $BASEDIR

# Install docker-ce
if ! command -v docker >/dev/null; then
  if [ -e /etc/redhat-release ]; then
    cd $BASEDIR/rpms

    # Install local yum repo
    cat <<EOF | sudo tee /etc/yum.repos.d/local-repo.repo
[local-repo]
name=Local repo
baseurl=file://$(pwd)
enabled=0
gpgcheck=0
EOF

    # ad hoc...
    sudo yum localinstall -y --disablerepo="*" --enablerepo=local-repo container-selinux-* libslirp-* slirp4netns-* fuse-overlayfs-*

    # Install docker-ce
    sudo yum install -y --disablerepo="*" --enablerepo=local-repo docker-ce
  else
    cd $BASEDIR/debs/pkgs
    sudo dpkg -i docker-ce*.deb containerd*.deb || exit 1
  fi
fi

# Load images
cd $BASEDIR/images
sudo docker load -i ./images/docker.io-library-registry-*.tar
sudo docker load -i ./images/docker.io-library-nginx-*.tar
