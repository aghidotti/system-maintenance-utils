#!/bin/bash
QGROUPS=$(btrfs qgroup show / | tail -n +3 | cut -d/ -f2-)
NAMES=$(btrfs sub list / | cut -d" " -f2-)


#echo "$QGROUPS"
#echo "$NAMES"
join --nocheck-order -1 1 -2 1 <(echo "$QGROUPS") <(echo "$NAMES") | column -t -x | sort -r -h -b -k3,3
