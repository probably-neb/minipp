test path="_" filter="":
    zig {{ if path == "_" {"build test"} else { "test --main-pkg-path " + join(justfile_directory(), "src") + " " + join(justfile_directory(), "src", replace(parent_directory(path), "src", ""), file_stem(path)) + ".zig" + " --test-filter '" + filter + "'"} }}

watch path="_" filter="":
    watchexec -e zig -- just test {{path}} {{filter}}

build:
    zig build

make path exe="a.out": build
    ./zig-out/bin/minipp -i {{path}} -o ./out.ll
    clang ./out.ll -o ./{{exe}}
