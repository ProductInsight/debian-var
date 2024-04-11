#!/bin/bash

pushd user_rootfs

# Copy our user tree over the rootfs tree
rsync -a -v --relative ./ ../rootfs/

popd

# Regenerate the rootfs tarball
./make_var_som_mx6_debian.sh -c rtar

