#!/bin/bash

c=0
while :
do
	c=$((c+1))
	i=0
	SECONDS=0
	while [ $i -lt $JOBS ]
	do
		i=$((i+1))
		echo "Starting ffmpeg process $i"
		ffmpeg -y -i ./video/bannerg004.mp4 -c:v vp9 -c:a libvorbis -nostdin ./video/output$i.mkv 2> /dev/null &
	done
	wait
	echo "Finished transcoding"
	echo "$c:$SECONDS" > time.txt
	sleep 0
done