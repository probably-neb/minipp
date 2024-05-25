minipp := "./zig-out/bin/minipp"
TEST_SUITE := "./test-suite/tests/milestone2/benchmarks"

test path="_" filter="":
    zig {{ if path == "_" {"build test"} else { "test --main-pkg-path " + join(justfile_directory(), "src") + " " + join(justfile_directory(), "src", replace(parent_directory(path), "src", ""), file_stem(path)) + ".zig" + " --test-filter '" + filter + "'"} }}

watch path="_" filter="":
    watchexec -e zig -- just test {{path}} {{filter}}

build:
    zig build

make path exe="a.out": build
    {{minipp}} -i {{path}} -o ./out.ll
    clang ./out.ll -o ./{{exe}}

ensure-test-suite:
    git submodule update --init --recursive

run-suite *BUILD_ARGS: ensure-test-suite
    #!/usr/bin/env bash
    set -uo pipefail

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NC='\033[0m'
    
    for test in $(ls {{TEST_SUITE}}); do
        just run-suite-test $test {{BUILD_ARGS}} > /dev/null 2>&1
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}SUCCESS${NC} - ${test}"
        else
          echo -e "${RED}FAIL   ${NC} - ${test}"
        fi
    done

run-suite-test name *BUILD_ARGS: ensure-test-suite
    #!/usr/bin/env bash
    set -euo pipefail

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    echo -e "Running Test Suite Test: ${YELLOW}{{name}}${NC}"
    echo -e "${BLUE}Building Test Suite Test...${NC}"
    just build-suite-test {{name}} {{BUILD_ARGS}}
    echo -e "${GREEN}BUILD SUCCESS${NC}"

    dir="{{TEST_SUITE}}/{{name}}"
    bin="$dir/{{name}}"


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

build-suite-test name *BUILD_ARGS: build
    #!/usr/bin/env bash
    set -euxo pipefail
    name="{{name}}"
    name="${name#array_}"
    dir="{{TEST_SUITE}}/{{name}}"
    {{minipp}} -i "$dir/${name}.mini" -o "$dir/{{name}}.ll" {{BUILD_ARGS}}
    clang "$dir/{{name}}.ll" -o "$dir/{{name}}"

nix:
    sudo nix develop --extra-experimental-features nix-command --extra-experimental-features flakes


par-run-suite *BUILD_ARGS: ensure-test-suite
    #!/usr/bin/env bash
    set -uo pipefail

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    NC='\033[0m'

    run_test() {
        test=$1
        if just run-suite-test "$test" {{BUILD_ARGS}} > /dev/null 2>&1; then
            echo -e "${GREEN}SUCCESS${NC} - ${test}"
        else
            echo -e "${RED}FAIL   ${NC} - ${test}"
        fi
    }

    export -f run_test
    export RED GREEN NC

    ls {{TEST_SUITE}} | parallel run_test
