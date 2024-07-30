#!/bin/bash

set -e
#set -x

readonly ABSOLUTE_FILENAME=`readlink -e "$0"`
readonly ABSOLUTE_DIRECTORY=`dirname ${ABSOLUTE_FILENAME}`

MEDIA=${ABSOLUTE_DIRECTORY}
SPL_IMAGE=SPL.nand
UBOOT_IMAGE=u-boot.img.nand
KERNEL_IMAGE=uImage
KERNEL_DTB=""
ROOTFS_DEV="emmc"




install_bootloader()
{
	echo
	echo "Installing bootloader to flash"

	if [ ! -f $MEDIA/$UBOOT_IMAGE ] ; then
		echo "ERROR: \"$MEDIA/$UBOOT_IMAGE\" does not exist"
		exit 1
	fi

	if [ ! -f $MEDIA/$SPL_IMAGE ] ; then
		echo "ERROR: \"$MEDIA/$SPL_IMAGE\" does not exist"
		exit 1
	fi

	flash_erase /dev/mtd0 0 0 2> /dev/null



    cd /tmp
	kobs-ng init -x $MEDIA/$SPL_IMAGE --search_exponent=1 -v > /dev/null
    cd -
	flash_erase /dev/mtd1 0 0 2> /dev/null
	nandwrite -p /dev/mtd1 $MEDIA/$UBOOT_IMAGE 
}

install_kernel()
{
	if [ ! -f $MEDIA/$KERNEL_IMAGE ] ; then
		echo "ERROR: \"$MEDIA/$KERNEL_IMAGE\" does not exist"
		exit 1
	fi
	echo
	echo "Installing kernel"
	flash_erase /dev/mtd2 0 0 2> /dev/null
	nandwrite -p /dev/mtd2 $MEDIA/$KERNEL_IMAGE > /dev/null
	nandwrite -p /dev/mtd1 -s 0x1e0000 $MEDIA/$KERNEL_DTB > /dev/null
}


install_rootfs()
{
    block=mmcblk0
	rootfspart=1

    node=/dev/${block}
    part=p
    mountdir_prefix=/run/media/${block}${part}
    imagesdir=${MEDIA}

    umount ${node}${part}*  2> /dev/null || true


    echo
	echo "Deleting current partitions"
	for ((i=0; i<=10; i++))
	do
		if [ -e ${node}${part}${i} ] ; then
			dd if=/dev/zero of=${node}${part}${i} bs=1024 count=1024 2> /dev/null || true
		fi
	done
	sync

	((echo d; echo 1; echo d; echo 2; echo d; echo 3; echo d; echo w) | fdisk $node &> /dev/null) || true
	sync

	dd if=/dev/zero of=$node bs=1M count=4
	sync


    echo
	echo "Creating new partitions"

	(echo n; echo p; echo $rootfspart; echo; echo; echo p; echo w) | fdisk $node > /dev/null
	
	fdisk -l $node
	sync; sleep 1

    echo
	echo "Formatting rootfs partition"
	mkfs.ext4 ${node}${part}${rootfspart} -L rootfs
	sync

    echo
	echo "Installing rootfs"
	mkdir -p ${mountdir_prefix}${rootfspart}
	mount ${node}${part}${rootfspart} ${mountdir_prefix}${rootfspart}
	printf "Extracting files"
    
	cat ${MEDIA}/rootfs.tar.gz* | tar --warning=no-timestamp -xzp -C ${mountdir_prefix}${rootfspart}
    

    cp ${MEDIA}/uEnv.txt ${mountdir_prefix}${rootfspart}

	echo
	echo
	sync
	umount ${node}${part}${rootfspart}


    echo
    echo Done.
}

usage()
{
	echo
	echo "This script installs Debian on VAR-SOM-MX6"
	echo
	echo " Usage: $0 OPTIONS"
	echo
	echo " OPTIONS:"
	echo " -b <mx6cb|scb|dart>	carrier Board model (MX6CustomBoard/SOLOCustomBoard/DART-MX6) - mandartory parameter."
	echo " -t <cap|res>		Touchscreen model (capacitive/resistive) - mandatory in case of MX6CustomBoard; ignored otherwise."
#	echo " -r <nand|emmc>		Rootfs device (NAND/eMMC) - mandatory in case of MX6CustomBoard/SOLOCustomBoard; ignored in case of DART-MX6."
	echo
}

finish()
{
	echo
	echo "PASS"
	exit 0
}


echo "*** VAPR INSTALL SCRIPT ***"


BOARD="scb"



STR="eMMC"


printf "Installing rootfs to: "
echo $STR


CPUS=`cat /proc/cpuinfo | grep -c processor`

if [ $CPUS = 1 ] || [ $CPUS = 2 ] ; then
	if [ `dmesg | grep -c SOM-SOLO` = 1 ] ; then
		if [ "$BOARD" = "scb" ] ; then
			KERNEL_DTB=imx6dl-var-som-solo-vsc.dtb
		else
			KERNEL_DTB=imx6dl-var-som-solo-$TOUCHSCREEN.dtb
		fi
	else
		if [ $CPUS = 1 ] || [ `dmesg | grep -c i.MX6DL` = 1 ] ; then
			# iMX6 Solo/DualLite
			if [ $BOARD = "scb" ] ; then
				KERNEL_DTB=imx6dl-var-som-vsc.dtb
			else
				KERNEL_DTB=imx6dl-var-som-$TOUCHSCREEN.dtb
			fi
		else
			# iMX6 Dual
			CPUS=4
		fi
	fi
fi

#iMX6 Dual/Quad
if [ $CPUS = 4 ] ; then
	if [ `cat /sys/devices/soc0/soc_id` = "i.MX6QP" ] ; then
		QUADTYPE="imx6qp"
	else
		QUADTYPE="imx6q"
	fi
	if [ $BOARD = "scb" ] ; then
		KERNEL_DTB=$QUADTYPE-var-som-vsc.dtb
	else
		KERNEL_DTB=$QUADTYPE-var-som-$TOUCHSCREEN.dtb
	fi
fi

printf "Installing Device Tree file: "
echo $KERNEL_DTB

install_bootloader
install_kernel
install_rootfs

finish
