#!/bin/bash

IMAGES_DIR=outputs/images
if [ ! -d $IMAGES_DIR ]; then
    mkdir -p $IMAGES_DIR
fi

get_image() {
    image=$1

    tarname="$(echo ${image} | sed s@"/"@"_"@g | sed s/":"/"-"/g)".tar
    zipname="$(echo ${image} | sed s@"/"@"_"@g | sed s/":"/"-"/g)".tar.gz

    if [ ! -e $IMAGES_DIR/$zipname ]; then
        echo "==> Pull $image"
        #$sudo $docker pull $image || exit 1
        if [[ "$container_runtime" == "docker" ]]; then
            # Use skopeo to pull image, because latest docker can't pull some old images
            echo $sudo ./bin/skopeo copy docker://$image docker-daemon:$image
            $sudo ./bin/skopeo copy docker://$image docker-daemon:$image || exit 1
        else
            $sudo $docker pull $image
        fi

        echo "==> Save $image"
        $sudo $docker save -o $IMAGES_DIR/$tarname $image || exit 1
        $sudo chown $(whoami) $IMAGES_DIR/$tarname
        chmod 0644 $IMAGES_DIR/$tarname
        gzip -v $IMAGES_DIR/$tarname
    else
        echo "==> Skip $image"
    fi
}

#
# Expand container image repo.
# ex)
#   registry:2       => docker.io/library/registry:2
#   rook/ceph:v1.3.2 => docker.io/rook/ceph:v1.3.2
#
expand_image_repo() {
    local repo="$1"

    if [[ "$repo" =~ ^[a-zA-Z0-9]+: ]]; then  # does not contain slash
        repo="docker.io/library/$repo"
    elif [[ "$repo" =~ ^[a-zA-Z0-9]+\/ ]]; then  # does not contain fqdn (period)
            repo="docker.io/$repo"
    fi
    echo "$repo"
}
