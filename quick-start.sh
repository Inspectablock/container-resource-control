#!/bin/bash
MAX_CPU_CHARES=1024
MIN_CPU_CHARES=128
MAX_LOAD_THRESHOLD=85
MIN_LOAD_THRESHOLD=80
DURATION=300
OUT_FILE=./results/out.csv
NO_LIMITING=0
usage="$(basename "$0") [-h] [-n Don't impose CPU limiting] [-d Duration in seconds] [-o Output file]"
options=':hnd:o:'
while getopts $options option; do
  case "$option" in
    h) echo "$usage"; exit;;
    n) NO_LIMITING=1;;
    d) DURATION=$OPTARG;;
    o) OUT_FILE=$OPTARG;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
  esac
done


function shutdown(){
    echo "Shutting down..."
    docker-compose down
    exit 0
}

trap shutdown SIGINT

# Number of processing units
PU=$(nproc)

# Spin up the stack
docker-compose up --force-recreate --build -d

# Allow some time for all services to be up and running
sleep 10


echo "load_perc,portal_shares,seconds,portal_cpu_usage,stress_cpu_uasge,job_exec_time" > $OUT_FILE

SECONDS=0
while [ $SECONDS -lt $DURATION ]; 
do
    LOAD=$(cut -d" " -f1-1 /proc/loadavg)
    LOAD=${LOAD%.*}
    LOAD=$(($LOAD * 100))
    P=$(($LOAD / $PU))


    PORTAL_CPU_USAGE=$(curl -X POST -s localhost:9090/api/v1/query \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "query=sum by (name) (rate(container_cpu_usage_seconds_total{name='portal'}[30s]))" | jq -r .data.result[0].value[1])
    if [ -z "$PORTAL_CPU_USAGE" ]; then
        continue
    fi
    STRESS_CONTAINER_CPU_USAGE=$(curl -X POST -s localhost:9090/api/v1/query \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "query=sum by (name) (rate(container_cpu_usage_seconds_total{name='stress-container'}[30s]))" | jq -r .data.result[0].value[1])        
    PORTAL_CPU_SHARES=$(curl -X POST -s localhost:9090/api/v1/query \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "query=container_spec_cpu_shares{name='portal'}" | jq -r .data.result[0].value[1])

    JOB_EXEC_TIME=$(docker exec portal cat /app/time.txt 2>/dev/null)

    echo "SECONDS $SECONDS 
LOAD $LOAD 
LOAD % $P 
PORTAL SHARES $PORTAL_CPU_SHARES 
PORTAL_CPU_USAGE $PORTAL_CPU_USAGE 
STRESS_CONTAINER_CPU_USAGE $STRESS_CONTAINER_CPU_USAGE

"

    if (( P >= $MAX_LOAD_THRESHOLD && $PORTAL_CPU_SHARES == $MAX_CPU_CHARES  )); then
        echo "Above or equal to max threshold"
        if ((NO_LIMITING == 0)); then
            echo "Decreasing Portal CPU shares"
            docker update --cpu-shares="$MIN_CPU_CHARES" portal 2>/dev/null
        fi
    elif (( P < $MIN_LOAD_THRESHOLD && $PORTAL_CPU_SHARES == $MIN_CPU_CHARES  )); then
        echo "Below min threshold"
        if ((NO_LIMITING == 0)); then
            echo "Increasing Portal CPU shares"
            docker update --cpu-shares="$MAX_CPU_CHARES" portal 2>/dev/null
        fi
    fi

    if [ $PORTAL_CPU_USAGE == 'null' ]; then
        PORTAL_CPU_USAGE=0
    fi
    if [ $STRESS_CONTAINER_CPU_USAGE == 'null' ]; then
        STRESS_CONTAINER_CPU_USAGE=0
    fi
    

    echo "$P,$PORTAL_CPU_SHARES,$SECONDS,$PORTAL_CPU_USAGE,$STRESS_CONTAINER_CPU_USAGE,$JOB_EXEC_TIME" >> $OUT_FILE

	sleep 2
done

shutdown