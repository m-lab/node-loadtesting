#!/bin/bash
#
# Runs a stress test against an NDT server. To do this, the script launches
# several NDT clients simultaneously to run NDT tests against the specified NDT
# server.
#
# To run:
#
#   ./stress_test.sh SERVER COUNT
#
# SERVER - Address of NDT server to stress test
# COUNT - Number of stress test iterations to run. Each stress test iteration
#   runs 7 simultaneous tests in each of 3 NDT clients, so each stress test
#   iteration results in 21 NDT tests.
#
# For example:
#
#   ./stress_test.sh ndt.iupui.mlab3.iad0t.measurement-lab.org 1000
#
# This will run 1,000 stress test iterations (21,000 NDT tests) against the
# target NDT server.

DATE=`date +%Y%m%d-%T`
SERVER=$1
PORT=3001
SSL_PORT=3010
COUNT=$2
STOP=
OUTDIR=stress_test_results
NUMBER_REGEX='^[0-9]+$'

if [ -z $SERVER ]; then
  echo "error: no NDT server specified" >&2
  echo "usage: $0 SERVER COUNT"
  exit 1
elif ! [[ $COUNT =~ $NUMBER_REGEX ]]; then
  echo "error: count is not a number: [$COUNT]" >&2
  echo "usage: $0 SERVER COUNT"
  exit 1
fi

if [ -e $OUTDIR ]; then
  echo "$OUTDIR already exists. Renaming to $OUTDIR.$DATE. You're welcome!"
  mv $OUTDIR $OUTDIR.$DATE
fi

function stopall {
  STOP=true
}

function run_cmd_tests {
  trap stopall SIGINT SIGTERM
  local kind=$1; shift
  local cmd=$@
  local ts=
  local tmpfile=
  local ts_start=
  local ts_end=
  mkdir -p $OUTDIR/$kind

  X=0
  while [ $X -lt $COUNT ]; do
     X=$[$X + 1]
     ts=$(date --utc +%Y%m%dT%H:%M:%S.%N)
     tmpfile=${OUTDIR}/${kind}/${kind}.${ts}
     ts_start=$(date +%s)
     $cmd >> ${tmpfile} 2>&1
     echo Exited with code $? >> ${tmpfile}
     ts_end=$(date +%s)
     echo Ran for N seconds: $(( $ts_end - $ts_start )) >> ${tmpfile}
     if [ $(( $X % 20 )) -eq 0 ]; then
       echo $kind
     fi
     if [ -n "$STOP" ]; then
       break
     fi
     sleep $(( $RANDOM % 5 ))
  done
}

function run_ws_tests {
  run_cmd_tests ws nodejs ./ndt_client.js --server=${SERVER} --port=${PORT} --protocol=ws --debug
}

function run_wss_tests {
  run_cmd_tests wss nodejs ./ndt_client.js --server=${SERVER} --port=${SSL_PORT} --protocol=wss --acceptinvalidcerts --debug
}

function run_raw_tests {
  run_cmd_tests raw web100clt --disablemid --disablesfw -n ${SERVER} -p ${PORT} -ddddd
}

#while /bin/true; do
  run_ws_tests &
  run_ws_tests &
  run_ws_tests &
  run_ws_tests &
  run_ws_tests &
  run_ws_tests &
  run_ws_tests &
  run_wss_tests &
  run_wss_tests &
  run_wss_tests &
  run_wss_tests &
  run_wss_tests &
  run_wss_tests &
  run_wss_tests &
  run_raw_tests &
  run_raw_tests &
  run_raw_tests &
  run_raw_tests &
  run_raw_tests &
  run_raw_tests &
  run_raw_tests &
  wait
#done
