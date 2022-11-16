#!/bin/bash

if [ -z $CPUS ]
then 
    echo "CPUS must be set";
    exit 1
fi

echo $CPUS >> cpus
exec "$@"