#!/bin/bash

PID="$1"
REMOTE="$2"
IMAGES="images-$PID"

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 PID USER@HOST"
fi

mkdir -p "$IMAGES"
echo "!! Dumping images for process $PID..."
# --leave-stopped
criu dump --tree "$PID" --images-dir "$IMAGES" --tcp-established --ghost-limit 18000000 || exit $?
echo "!! Copying images to $REMOTE..."
scp -r "$IMAGES" "$REMOTE:~/$IMAGES" || exit $?
echo "!! Restoring on $REMOTE..."
# --restore-detached
ssh "$REMOTE" criu restore --images-dir "~/$IMAGES" || exit $?
echo "!! Successfully migrated to $REMOTE; killing original process."
kill -9 $PID
echo "!! Cleaning up..."
ssh "$REMOTE" rm -rf '~/'"$IMAGES"
#rm -rf "$IMAGES"
