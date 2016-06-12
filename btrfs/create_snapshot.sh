#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
ROOTDEV="/dev/system/root"
SUBVOL="@"


broadcast_info() {
	echo $1 >&1
}

broadcast_error() {
	echo $1 >&2
}

check_superuser() {
	if [ $EUID -ne 0 ]; then
		broadcast_error "Error: $0 must be executed as root"
		exit 1
	fi
}

check_retval() {
	if [ $1 -ne 0 ]; then
		broadcast_error "Command exited with status $1: exiting"
		exit $1
	fi
}

###############################################################################

check_superuser


if [ -z "$(command -v btrfs)" ]; then 
	broadcast_error "Error: btrfs command missing: install btrfs-tools"
	exit 1
fi

if [ $# -gt 0 ] && [ -n "$1" ]; then
	SUBVOL="$1"
fi

broadcast_info "Creating temporary directory $tmpmnt"
tmpmnt=$(mktemp -d)
check_retval $?

broadcast_info "Mounting top-level subvolume"
mount $ROOTDEV $tmpmnt/
check_retval $?

broadcast_info "Creating snapshot of subvolume $SUBVOL"
btrfs sub snap -r $tmpmnt/$SUBVOL $tmpmnt/@$SUBVOL-$TIMESTAMP
check_retval $?

broadcast_info "Unmounting top-level subvolume"
umount $tmpmnt/
check_retval $?

broadcast_info "Removing temporary directory $tmpmnt"
rmdir $tmpmnt
check_retval $?

