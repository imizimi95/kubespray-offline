#!/bin/bash

source config.sh

mkdir -p ./cache

if [ ! -e outputs/files/${KUBESPRAY_TARBALL} ]; then
    echo "===> Download ${KUBESPRAY_TARBALL}"
    mkdir -p outputs/files/
    curl -SL https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v${KUBESPRAY_VERSION}.tar.gz >outputs/files/${KUBESPRAY_TARBALL} || exit 1

    if [ ${KUBESPRAY_DIR} = "./cache/kubespray" ] && [ -d ${KUBESPRAY_DIR} ]; then
        /bin/rm -rf ${KUBESPRAY_DIR}
    fi
fi

if [ ! -d ${KUBESPRAY_DIR} ]; then
    echo "===> Extract ${KUBESPRAY_TARBALL}"
    tar xzf outputs/files/${KUBESPRAY_TARBALL}

    mv kubespray-${KUBESPRAY_VERSION} ${KUBESPRAY_DIR}
fi
