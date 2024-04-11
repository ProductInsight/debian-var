#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_dev_target>"
    exit 1
fi

rsync -av $1/* user_rootfs/opt/vapr


