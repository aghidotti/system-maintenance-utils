#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
ROOTDEV="/dev/system/root"
SUBVOL="@"


function broadcast.info {
	echo $1 >&1
}

function broadcast.error {
	echo $1 >&2
}

function check_superuser {
	if [ $EUID -ne 0 ]; then
		broadcast.error "Error: $0 must be executed as root"
		exit 1
	fi
}

function check_retval {
	if [ $1 -ne 0 ]; then
		broadcast.error "Command exited with status $1: exiting"
		exit $1
	fi
}

###############################################################################

check_superuser


if [ -z "$(command -v btrfs)" ]; then 
	broadcast.error "Error: btrfs command missing: install btrfs-tools"
	exit 1
fi

if [ $# -gt 0 ] && [ -n "$1" ]; then
	SUBVOL="$1"
fi

broadcast.info "Creating temporary directory $tmpmnt"
tmpmnt=$(mktemp -d)
check_retval $?

broadcast.info "Mounting top-level subvolume"
mount $ROOTDEV $tmpmnt/
check_retval $?

broadcast.info "Creating snapshot of subvolume $SUBVOL"
btrfs sub snap -r $tmpmnt/$SUBVOL $tmpmnt/@$SUBVOL-$TIMESTAMP
check_retval $?

broadcast.info "Unmounting top-level subvolume"
umount $tmpmnt/
check_retval $?

broadcast.info "Removing temporary directory $tmpmnt"
rmdir $tmpmnt
check_retval $?

