#!/bin/bash

CLIENT_LOGS="./stress_test_results"
ANALYSIS_FILE="stress_test_analysis.txt"
WS_PROTOS="ws wss"
C_CLIENT="raw"

cat /dev/null > $CLIENT_LOGS/$ANALYSIS_FILE

for ws_proto in $WS_PROTOS; do
    pushd $CLIENT_LOGS/$ws_proto > /dev/null

    TOTAL_TESTS=$(ls | wc -l)
    FAILED_TESTS=$(grep -l -L 'TESTS FINISHED SUCCESSFULLY' *)
    TOTAL_FAILURES=$(echo $FAILED_TESTS | wc -w)
    ZERO_SECS=$(grep 'Ran for N seconds' * | awk '{if ($5 == 0) print}' | wc -l)
    DIED_C2S_PREPARE=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'C2S type 3' | wc -l)
    DIED_C2S_START=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'C2S type 4' | wc -l)
    DIED_S2C_PREPARE=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'CALLED S2C with 3' | wc -l)
    DIED_S2C_START=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'CALLED S2C with 4' | wc -l)
    DIED_S2C_MSG=$(grep -B 5 'Ran for N seconds' $FAILED_TESTS | grep 'CALLED S2C with 5' | wc -l)
    CONN_REFUSED=$(grep 'ECONNREFUSED' * | wc -l)
    PERCENT_FAILED=$(echo "scale=4;$TOTAL_FAILURES/$TOTAL_TESTS*100" | bc)

    cat <<EOF >> ../$ANALYSIS_FILE
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
    Percent failed tests: $PERCENT_FAILED%

EOF
    popd > /dev/null
done

pushd $CLIENT_LOGS/$C_CLIENT > /dev/null
    TOTAL_TESTS=$(ls | wc -l)
    FAILED_TESTS=$(grep -l -L 'Exited with code 0' *)
    TOTAL_FAILURES=$(echo $FAILED_TESTS | wc -w)
    ZERO_SECS=$(grep 'Ran for N seconds' $FAILED_TESTS | awk '{if ($5 == 0) print}' | wc -l)
    DIED_C2S=$(grep '^running 10\.0s outbound test.*Exited with code 137$' $FAILED_TESTS | wc -l)
    DIED_S2C=$(grep '^running 10\.0s inbound test.*Exited with code 137$' $FAILED_TESTS | wc -l)
    DIED_CLIENT_SOCK=$(grep -B 1 'Exited with code 137' $FAILED_TESTS | grep 'network\.c:355 \] Client socket created' | wc -l)
    PROTO_ERRORS=$(grep -l 'Protocol error' $FAILED_TESTS | wc -l)
    CONN_REFUSED=$(grep 'Connection refused' $FAILED_TESTS | wc -l)
    PERCENT_FAILED=$(echo "scale=4;$TOTAL_FAILURES/$TOTAL_TESTS*100" | bc)
    cat <<EOF >> ../$ANALYSIS_FILE
Protocol: $C_CLIENT
    Total failed tests: $TOTAL_FAILURES
    Failed immediately (ran for 0 seconds): $ZERO_SECS
    Died at C2S: $DIED_C2S
    Died at S2C: $DIED_S2C
    Died at client socket created (network.c:355): $DIED_CLIENT_SOCK
    Protocol error: $PROTO_ERRORS
    Connection refused: $CONN_REFUSED
    Total tests run: $TOTAL_TESTS
    Percent failed tests: $PERCENT_FAILED%

EOF
popd > /dev/null
