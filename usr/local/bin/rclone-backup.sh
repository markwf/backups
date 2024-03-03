#!/bin/bash

set -e
#set -x

PARM="--check-first --delete-after --delete-excluded --links --one-file-system --update --use-server-modtime --log-level INFO --bwlimit 1M:off"

EXCLUDE="--exclude-if-present .rclone-ignore --exclude-from /home/mark/.config/rclone/exclude"

# Sync a folder to the cloud using rclone $1=source, $2=target
sync () {
    echo "sync $1 $2"

    echo rclone sync $OPT $PARM $EXCLUDE "$1" "$2"

    echo
}

backup () {
    echo "backup $1 to backups:${1##*/}"

    # %%/ = remove trailing slash if any, :+/ = add trailing slash unless empty, ##*/ = remove prefix path if any
    rclone sync $OPT $PARM $EXCLUDE --backup-dir backups:archive "$1" "backups:${2%%/}${2:+/}${1##*/}"

    echo
}


echo -e "rclone common parms: $PARM $OPT $EXCLUDE"

# Backups - target buckets must have versioning turned on or these are not reliable backups
sync "/storage/Vault/mypasswords.kdbx" "cloud:"
backup "/storage/Ainslie"
backup "/storage/Ainslie Ideas"
backup "/storage/Beverley"
backup "/storage/bin"
backup "/storage/Birchmans"
backup "/storage/BMS"
backup "/storage/Books"
backup "/storage/drivers"
backup "/storage/Mark"
backup "/storage/mfd"
backup "/storage/Music"
backup "/storage/photos"
backup "/storage/Pictures"
backup "/storage/Projects"
backup "/storage/Reilly"
backup "/storage/Shared"
backup "/storage/System"
backup "/storage/Vault"
backup "/storage/videos"
backup /etc         hpserver
backup /home        hpserver
backup /root        hpserver
backup /usr/local   hpserver


