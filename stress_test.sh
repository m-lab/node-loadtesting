#!/bin/bash
SERVER=$1
PORT=3001
SSL_PORT=3010
COUNT=$2
STOP=
OUTDIR=stress_test_results
NUMBER_REGEX='^[0-9]+$'

if [ -z $SERVER ]; then
  echo "error: no NDT server specified" >&2
  echo "usage: $0 server count"
  exit 1
elif ! [[ $COUNT =~ $NUMBER_REGEX ]]; then
  echo "error: count is not a number: [$COUNT]" >&2
  echo "usage: $0 server count"
  exit 1
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
     tmpfile=stress_test_results/${kind}/${kind}.${ts}
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
  run_cmd_tests ws node ./ndt_client.js --server=${SERVER} --port=${PORT} --protocol=ws --debug
}

function run_wss_tests {
  run_cmd_tests wss node ./ndt_client.js --server=${SERVER} --port=${SSL_PORT} --protocol=wss --acceptinvalidcerts --debug
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
