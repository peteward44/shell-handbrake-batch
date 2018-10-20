#!/bin/bash

LOG_FILE=~/convert.log
OUT_DIR=.
OUT_EXTENSION=mp4

if [ ! -d /var/run/handbrake_batch ]; then
	sudo mkdir -p /var/run/handbrake_batch
	sudo chmod 777 /var/run/handbrake_batch
fi

#(
#flock -x -w 2 222

show_help()
{
	echo "Handbrake CLI batch tool"
	echo "usage: handbrake-batch -o=/home/user/out -e=mp4 inputfile1.avi inputfile2.avi"
}

declare -a INPUT_FILES
INPUT_FILES_LENGTH=0
SCREEN_NAME="default"

for i in "$@"
do
case $i in
	-h|--help)
		show_help
		exit 0
	;;
	-o=*|--out=*)
		OUT_DIR="${i#*=}"
		shift
	;;
	-e=*|--ext=*)
		OUT_EXTENSION="${i#*=}"
		shift
	;;
	-a=*|--args=*)
		HANDBRAKE_ARGS="${i#*=}"
		shift
	;;
	-n=*|--name=*)
		SCREEN_NAME="${i#*=}"
		shift
	;;
	-l=*|--log=*)
		LOG_FILE="${i#*=}"
		shift
	;;
	*)
		INPUT_FILES[INPUT_FILES_LENGTH]="${i#*=}"
		((INPUT_FILES_LENGTH++))
	;;
esac
done

rm -f "$LOG_FILE" 

add_handbrake()
{
	INPUT=$1
	EXTENSION=${INPUT##*.}
	OUTPUT=$OUT_DIR/`basename "$INPUT" "$EXTENSION"`$OUT_EXTENSION
	if [ ! -f "$OUTPUT" ]; then
		echo Creating $OUTPUT
		/usr/bin/tmux new-session -d -s "$SCREEN_NAME" /usr/bin/HandBrakeCLI --optimize --preset "iPod" -a 1 --mixdown stereo --ab 128 -q 30 -i "$INPUT" -o "$OUTPUT" >> "$LOG_FILE" 2>&1
		#/usr/bin/screen -D -t "$SCREEN_NAME" -X "/usr/bin/HandBrakeCLI --optimize --preset \"Android\" -a 1 --mixdown stereo --ab 128 -q 30 -i \"$INPUT\" -o \"$OUTPUT\" >> \"$LOG_FILE\" 2>&1"
		#nohup /usr/bin/HandBrakeCLI --optimize --preset "Android" -a 1 --mixdown stereo --ab 128 -q 30 -i "$INPUT" -o "$OUTPUT" >> "$LOG_FILE" 2>&1
	fi
}

for I in "$INPUT_FILES"
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

#) 222>/var/run/handbrake_batch/lock

