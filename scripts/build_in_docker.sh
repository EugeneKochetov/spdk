#!/bin/bash
# --user $UID \
# centos75-spdk -> centos75-mofed46
#IMGID=centos75-mofed46
#IMGID=centos75-mofed46-upstream_libs
#IMGID=centos75-spdk
IMGID=centos75-spdk-upstream_libs
docker run  \
    --name build-spdk01 \
    -e "VER=19.04.1" -e "BUILD_NUMBER=${BUILD_NUMBER:-1}" \
    -v ~/rpmbuild:/rpmbuild \
    -v `pwd`:/scratch         \
    --rm -i         \
    -t harbor.mellanox.com/swx-storage/`uname -m`/$IMGID \
    /scratch/scripts/build_rpm.sh
