#!/bin/bash
#
# run.sh creates a continuous stream of client download tests from the named
# target.

START=${1:?Please provide number of clients to run}
STOP=${2:?Please provide max clients}
STEP=${3:?Please provide step size}
TARGET=${4:-ndt-iupui-mlab3v4-lga0t.mlab-sandbox.measurement-lab.org}
PERIOD=${5:-360}

function runUntil() {
    local desired=$1
    local endtime=$2
    local remain=0
    local curr=0
    local now=0
    while true ; do
        now=$( date +%s )
        if [[ `jobs | grep -v Done | wc -l ` -lt $desired ]] ; then
            # Start more jobs if less than $desired jobs are currently running.
            curr=$(( $endtime - $now ))
            if [[ $remain -ne $curr ]] ; then
                remain=$curr
                echo "Seconds remaining ..." $remain
            fi
            # TODO: use the ndt5-go-client or ndt7-go-client.
            ./libndt-client -download -port 3001 ${TARGET} &> /dev/null < /dev/null &
        else
            sleep .1
            if [[ $now -gt $endtime ]]; then
                return
            fi
    fi
    done
}

CURRENT=$START
while true ; do
    echo `date --utc --iso-8601=seconds` "Starting $CURRENT ... "

    # Run $CURRENT tests until the end time.
    runUntil $CURRENT $(( `date +%s` + $PERIOD ))

    echo "INCREMENT..."
    # wait clears the completed background tests.
    wait
    CURRENT=$(( $CURRENT + $STEP ))
    if [[ $CURRENT -gt $STOP ]]; then
      echo "RESET..."
      CURRENT=$START
    fi
done
