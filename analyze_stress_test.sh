#!/bin/bash

if [ -n "$1" ];then
    CLIENT_LOGS="$1"
else
    CLIENT_LOGS="stress_test_results-ipv4"
fi
ANALYSIS_FILE="stress_test_analysis.txt"
WS_PROTOS="ws wss"
C_CLIENT="raw"

cat /dev/null > $CLIENT_LOGS/$ANALYSIS_FILE

for ws_proto in $WS_PROTOS; do
    pushd $CLIENT_LOGS/$ws_proto > /dev/null

    TOTAL_TESTS=$(ls | wc -l)
    TESTS_KILLED_COUNT=$(grep -l 'Exited with code 137' * | wc -l)
    TESTS_NOT_KILLED=$(grep -L 'Exited with code 137' *)
    TESTS_NOT_KILLED_COUNT=$(grep -L 'Exited with code 137' * | wc -l)
    TESTS_GOT_SRV_QUEUE=$(grep -l 'SRV_QUEUE' * | wc -l)
    AVERAGE_C2S=$(grep 'Measured upload rate' * | awk '{count++; sum += $5;} END {print (sum/count)/1000}')
    AVERAGE_S2C=$(grep 'Measured download rate' * | awk '{count++; sum += $5;} END {print (sum/count)/1000}')
    FAILED_TESTS=$(grep -L 'TESTS FINISHED SUCCESSFULLY' $TESTS_NOT_KILLED)
    TOTAL_FAILURES=$(echo $FAILED_TESTS | wc -w)
    if [ "$TOTAL_FAILURES" -gt 0 ]; then
        ZERO_SECS=$(grep 'Ran for N seconds' * | awk '{if ($5 == 0) print}' | wc -l)
        DIED_C2S_PREPARE=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'C2S type 3' | wc -l)
        DIED_C2S_START=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'C2S type 4' | wc -l)
        DIED_S2C_PREPARE=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'CALLED S2C with 3' | wc -l)
        DIED_S2C_START=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'CALLED S2C with 4' | wc -l)
        DIED_S2C_MSG=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'CALLED S2C with 5' | wc -l)
        CONN_REFUSED=$(grep 'ECONNREFUSED' * | wc -l)
        PERCENT_FAILED=$(echo "scale=4;$TOTAL_FAILURES/$TESTS_NOT_KILLED_COUNT*100" | bc)
    else
        ZERO_SECS=0
        DIED_C2S_PREPARE=0
        DIED_C2S_START=0
        DIED_S2C_PREPARE=0
        DIED_S2C_START=0
        DIED_S2C_MSG=0
        CONN_REFUSED=0
        PERCENT_FAILED=0
    fi

    tee -a ../$ANALYSIS_FILE <<EOF 
Protocol: $ws_proto
    Total failed tests: $TOTAL_FAILURES
      Failed immediately (ran for 0 seconds): $ZERO_SECS
      Died at C2S TEST_PREPARE: $DIED_C2S_PREPARE
      Died at C2S TEST_START: $DIED_C2S_START
      Died at S2C TEST_PREPARE: $DIED_S2C_PREPARE
      Died at S2C TEST_START: $DIED_S2C_START
      Died at S2C TEST_MSG: $DIED_S2C_MSG
      Connection refused: $CONN_REFUSED
    Total tests run: $TOTAL_TESTS
      Tests killed: $TESTS_KILLED_COUNT
      Tests not killed: $TESTS_NOT_KILLED_COUNT
      Test that got SRV_QUEUE: $TESTS_GOT_SRV_QUEUE
      Average C2S throughput: $AVERAGE_C2S Mbps
      Average S2C throughput: $AVERAGE_S2C Mbps
    Percent failed tests: $PERCENT_FAILED%  ($TOTAL_FAILURES out of $TESTS_NOT_KILLED_COUNT)

EOF
    popd > /dev/null
done

pushd $CLIENT_LOGS/$C_CLIENT > /dev/null
    TOTAL_TESTS=$(ls | wc -l)
    TESTS_KILLED_COUNT=$(grep -l 'Exited with code 137' * | wc -l)
    TESTS_NOT_KILLED=$(grep -L 'Exited with code 137' *)
    TESTS_NOT_KILLED_COUNT=$(grep -L 'Exited with code 137' * | wc -l)
    TESTS_GOT_SRV_QUEUE=$(grep -l 'Another client is currently begin served' * | wc -l)
    FAILED_TESTS=$(grep -L 'Exited with code 0' $TESTS_NOT_KILLED)
    TOTAL_FAILURES=$(echo $FAILED_TESTS | wc -w)
    AVERAGE_C2S=$(for log in *; do awk '/[0-9]+\.[0-9]+ Mb\/s/{i++; if (i==1) print $1 }' $log; done | awk '{count++; sum += $1} END {print sum/count}')
    AVERAGE_S2C=$(for log in *; do awk '/[0-9]+\.[0-9]+ Mb\/s/{i++; if (i==2) print $1 }' $log; done | awk '{count++; sum += $1} END {print sum/count}')
    if [ "$TOTAL_FAILURES" -gt 0 ]; then
        ZERO_SECS=$(grep 'Ran for N seconds' $FAILED_TESTS | awk '{if ($5 == 0) print}' | wc -l)
        DIED_C2S=$(grep '^running 10\.0s outbound test.*Exited with code 137$' $FAILED_TESTS | wc -l)
        DIED_S2C=$(grep '^running 10\.0s inbound test.*Exited with code 137$' $FAILED_TESTS | wc -l)
        DIED_CLIENT_SOCK=$(grep -B 1 'Exited with code 137' $FAILED_TESTS | grep 'network\.c:355 \] Client socket created' | wc -l)
        PROTO_ERRORS=$(grep -l 'Protocol error' $FAILED_TESTS | wc -l)
        CONN_REFUSED=$(grep 'Connection refused' $FAILED_TESTS | wc -l)
        PERCENT_FAILED=$(echo "scale=4;$TOTAL_FAILURES/$TESTS_NOT_KILLED_COUNT*100" | bc)
    else
        ZERO_SECS=0
        DIED_C2S=0
        DIED_S2C=0
        DIED_CLIENT_SOCK=0
        PROTO_ERRORS=0
        CONN_REFUSED=0
        PERCENT_FAILED=0
    fi

    tee -a ../$ANALYSIS_FILE <<EOF
Protocol: $C_CLIENT
    Total failed tests: $TOTAL_FAILURES
      Failed immediately (ran for 0 seconds): $ZERO_SECS
      Died at C2S: $DIED_C2S
      Died at S2C: $DIED_S2C
      Died at client socket created (network.c:355): $DIED_CLIENT_SOCK
      Protocol error: $PROTO_ERRORS
      Connection refused: $CONN_REFUSED
    Total tests run: $TOTAL_TESTS
      Tests killed: $TESTS_KILLED_COUNT
      Tests not killed: $TESTS_NOT_KILLED_COUNT
      Test that got SRV_QUEUE: $TESTS_GOT_SRV_QUEUE
      Average C2S throughput: $AVERAGE_C2S Mbps
      Average S2C throughput: $AVERAGE_S2C Mbps
    Percent failed tests: $PERCENT_FAILED%  ($TOTAL_FAILURES out of $TESTS_NOT_KILLED_COUNT)

EOF
popd > /dev/null
