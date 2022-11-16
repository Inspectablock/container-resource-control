#!/bin/bash

# wait a bit so that the container can start
sleep 30

while :
do
	cpus=$(cat cpus)
	echo "Running stress-ng with $cpus CPUS ..."
	stress-ng --cpu $cpus --timeout 60s --metrics-brief
	sleep 30
done