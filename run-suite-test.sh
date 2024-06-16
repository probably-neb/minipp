#!/usr/bin/env bash

set -euxo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_SUITE=${TEST_SUITE_PATH:-"./tests/milestone2/benchmarks"}

name="${1}"
shift
BUILD_ARGS="$@"

echo -e "Running Test Suite Test: ${YELLOW}${name}${NC}"
echo -e "${BLUE}Building Test Suite Test...${NC} ${BUILD_ARGS}"

minipp="./zig-out/bin/minipp"
zig build

build-suite-test() {
    name_no_arr="${name#array_}"
    dir="${TEST_SUITE}/${name}"
    rm -f "${TEST_SUITE}/output"
    rm -f "${TEST_SUITE}/output.longer"
    ${minipp} -i "$dir/${name_no_arr}.mini" -o "$dir/${name}.ll" ${BUILD_ARGS}
    clang "$dir/${name}.ll" -o "$dir/${name}"
}

rm -rf ./dot_svg/
rm -rf ./dot_generated/
mkdir dot_generated
mkdir dot_svg

echo -e "Running Test Suite Test: ${YELLOW}${name}${NC}"
echo -e "${BLUE}Building Test Suite Test...${NC}"
build-suite-test ${name} ${BUILD_ARGS}
echo -e "${GREEN}BUILD SUCCESS${NC}"

dir="${TEST_SUITE}/${name}"
bin="$dir/${name}"


echo "Checking Normal Input..."
$bin < "$dir/input" > "$dir/output"
diff "$dir/output" "$dir/output.expected"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}SUCCESS${NC}"
else
  echo -e "${RED}FAIL${NC}"
fi

echo "Checking Longer Input..."
longer="$dir/input.longer"
if [ -f "$longer" ]; then
    $bin < "$longer" > "$dir/output.longer"
    diff "$dir/output.longer" "$dir/output.longer.expected"
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}SUCCESS${NC}"
    else
      echo -e "${RED}FAIL${NC}"
    fi
else
  echo "Longer Input Not Found"
  echo -e "${GREEN}SUCCESS${NC}"
fi

# Comment out the following if you wish to preserve the genrated dot files
rm -rf ./dot_svg/
rm -rf ./dot_generated/
