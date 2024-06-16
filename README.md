## Mini language Implementation 

CSC-431


## BUILD INSTRUCTIONS

### Setup

In Order to build the project zig version 0.11 must be installed.

There is a nix shell setup for the project that will get you into a shell with [`just`](https://github.com/casey/just) (an alternative to `make`), clang (llvm) v7.0.1, and the correct version of zig. 
    - If you have `nix` and `just` installed you can run `just nix` to get into a shell with the correct versions of everything installed
    - If you do not have `just` installed you can copy line 139 from the file named `Justfile` in the root of the project which will enter the nix shell

If you do not wish to use nix the project can still be built with zig v0.11.


### Building

To build the compiler you must run `zig build` in the root directory of the project. The binary will be placed in `./zig-out/bin/minipp`


### Arguments

#### Modes

The arguments to the compiler are as follows

`-stack` | `-phi`
: These arguments set the mode for llvm generation. If both are provided the one that appears last will be used. If neither of these flags is passed 

`-opt`
: Meaningless unless the phi llvm IR gen mode is active. Enables optimizations on the IR

#### Optimization Flags

The following flags are meaningless unless the `-phi` and `-opt` flags are passed as well.

`-opt-use-sccp`
: By default comparison propogation will be used instead of sparse conditional constant propogation as constant propogation is an extension on top of sccp. Pass this flag if you wish to use sccp instead of comp-prop

`-opt-no-sccp-like`
: Disables both sccp and comp-prop passes

`-opt-no-dce`
: Disables the dead code elimintion pass

`-opt-no-ebe`
: Disables the empty block elimination pass

### Input/Output

`-i` | `-input`
: **REQUIRED** The input `-mini` file

`-o` | `-out`
: The file to output the `.ll` LLVM IR output to. If no output file is passed will default to stdout

`-dot`
: File to output a `.dot` file to containing the graphviz dot for the mini files CFG

### Test Suite

If you have just installed you can run `just run-suite [BUILD ARGS...]` to run the entire test suite or `just run-suite-test [TEST NAME] [BUILD ARGS...]` to run just one test. Both commands will place the `.ll` file as well as the compiled binary in the same directory as the original test in `./test-suite/tests/milestone2/benchmarks`

If just is not installed there is a script at `./run-suite.sh` that will do the same as the `just run-suite` test above. Note the script should be ran from the root directory. This script will place the resulting .ll file and binary in `./tests/milestone2/benchmarks/[test name]` rather than the `test-suite` directory like the just script.
