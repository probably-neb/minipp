#!/usr/bin/env bash
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'


BUILD_ARGS="$@"

TEST_SUITE=${TEST_SUITE_PATH:-"./tests/milestone2/benchmarks"}

for test in $(ls ${TEST_SUITE}); do
    ./run-suite-test.sh $test ${BUILD_ARGS} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}SUCCESS${NC} - ${test}"
    else
      echo -e "${RED}FAIL   ${NC} - ${test}"
    fi
done
