#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
TOPVOLDEV=""
SUBVOL=""
TAG=""


broadcast_debug() {
	echo "${TAG:+$TAG: }DEBUG => $1" >&1
}

broadcast_info() {
	echo "${TAG:+$TAG: }$1" >&1
}

broadcast_error() {
	echo "${TAG:+$TAG: }$1" >&2
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

print_usage() {
	echo \
"Usage: $(basename $0) -v <topvoldev> -s <subvol> [-t <tag>] [-b] [-d]
where:
	-v <topvoldev>: specify device containing top-level btrfs volume (e.g. /dev/system/root, /dev/sda1, ...)
	-s <subvol>: specify the child subvolume of which the snapshot will be taken (e.g. @home, .root, ...)
	-t <tag>: tag prefix for each output message
	-b: batch mode (useful for scripting)
	-d debug mode
	-h shows this message";
}

confirm() {
	if [ $1 == "true" ]; then
		echo 1;
		return;
	fi
	
	read -r -p "Are you sure to continue? [y/N]" RESPONSE
	case $RESPONSE in
		[yY][eE][sS]|[yY]) 
			echo 1
			;;
		*)
			echo 0
			;;
	esac
}

###############################################################################

v_flag=false;
s_flag=false;
BATCH_MODE=false;
DEBUG_MODE=false;

while getopts "bdv:s:t:h" OPT; do
	case $OPT in
		b	) BATCH_MODE=true;;
		d	) echo "Running in \"debug mode\""; DEBUG_MODE=true;;
		r	) v_flag=true; TOPVOLDEV="$OPTARG";;
		s	) s_flag=true; SUBVOL="$OPTARG";;
		t	) TAG="$OPTARG";;
		h	) print_usage;;
		\?	) echo "Unknown option: -$OPT" >&2; print_usage; exit 1;;
		:	) echo "Missing option argument for -$OPT" >&2; print_usage; exit 1;;
		*	) echo "Unimplemented option: -$OPT" >&2; print_usage; exit 1;;
	esac
done

if [ "$v_flag" == "false" ]; then
	broadcast_error "Error: -v <topdev> argument is mandatory"
	print_usage
	exit 1
fi

if [ "$s_flag" == "false" ]; then
	broadcast_error "Error: -s <subvol> argument is mandatory"
	print_usage
	exit 1
fi

#if [ -z $TAG ]; then
#	TAG="SNAP-$SUBVOL"
#fi

if [ "$DEBUG_MODE" == "true" ]; then
	broadcast_debug "ok = $ok"
	broadcast_debug "v_flag = $v_flag"
	broadcast_debug "s_flag = $s_flag"
	broadcast_debug "DEBUG_MODE = $DEBUG_MODE"
	broadcast_debug "TOPVOLDEV = $TOPVOLDEV"
	broadcast_debug "SUBVOL = $SUBVOL"
	broadcast_debug "TAG = $TAG"
	broadcast_debug "TIMESTAMP = $TIMESTAMP"
fi

check_superuser

if [ -z "$(command -v btrfs)" ]; then 
	broadcast_error "Error: btrfs command missing: install btrfs-tools"
	exit 1
fi

###############################################################################

broadcast_info "Creating temporary directory"
ok=$(confirm $BATCH_MODE)
if [ $ok -ne 1 ]; then exit 0; fi

TMPMNT=$(mktemp -d)
check_retval $?
[[ "$DEBUG_MODE" == "true" ]] && broadcast_debug "TMPMNT = $TMPMNT";



broadcast_info "Mounting top-level subvolume"
ok=$(confirm $BATCH_MODE);
if [ $ok -ne 1 ]; then
	broadcast_info "Removing temporary directory $TMPMNT"
	rmdir $TMPMNT
	check_retval $?
	exit 0;
fi

mount $TOPVOLDEV $TMPMNT/
check_retval $?



broadcast_info "Creating read-only snapshot of subvolume $SUBVOL into $TMPMNT/"
ok=$(confirm $BATCH_MODE);
if [ $ok -ne 1 ]; then
	broadcast_info "Unmounting top-level subvolume"
	umount $TMPMNT/
	broadcast_info "Removing temporary directory $TMPMNT"
	rmdir $TMPMNT
	check_retval $?
	exit 0; 
fi

btrfs sub snap -r $TMPMNT/$SUBVOL $TMPMNT/@$SUBVOL-$TIMESTAMP
check_retval $?



broadcast_info "Unmounting top-level subvolume"
umount $TMPMNT/
check_retval $?



broadcast_info "Removing temporary directory $TMPMNT"
rmdir $TMPMNT
check_retval $?

