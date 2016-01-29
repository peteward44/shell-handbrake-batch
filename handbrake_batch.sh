#!/bin/bash

LOG_FILE=/mnt/hd1/convert.log
OUT_DIR=/mnt/hd1/phone_sync/pete_note4/sync
OUT_EXTENSION=mp4
HANDBRAKE_ARGS="--optimize --preset \"Android Tablet\""
SCREEN_NAME=video_encode

if [ ! -d /var/run/handbrake_batch ]; then
	sudo mkdir -p /var/run/handbrake_batch
	sudo chmod 777 /var/run/handbrake_batch
fi

(
flock -x -w 2 222

FULL_STRING=""
rm -f "$LOG_FILE" 

add_handbrake()
{
	INPUT=$1
	EXTENSION=${INPUT##*.}
	OUTPUT=$OUT_DIR/`basename "$INPUT" "$EXTENSION"`$OUT_EXTENSION
	echo Creating $OUTPUT
	if [ ! -f "$OUTPUT" ]; then
		FULL_STRING="$FULL_STRING HandBrakeCLI -i \"$INPUT\" -o \"$OUTPUT\" $HANDBRAKE_ARGS >> \"$LOG_FILE\" 2>&1"
		FULL_STRING="$FULL_STRING &&"
	fi
}

for I in "$@"
do
  if [ -d "$I" ]; then
	SAVEIFS=$IFS
	IFS=$'\n'
	for FILE in `find "$I" -type f -print`
	do
		add_handbrake "$FILE"
	done
	IFS=$SAVEIFS
  else
	add_handbrake "$I"
  fi
done
FULL_STRING="$FULL_STRING echo \"\""

screen -S "$SCREEN_NAME" -d -m $FULL_STRING

) 222>/var/run/handbrake_batch/lock

