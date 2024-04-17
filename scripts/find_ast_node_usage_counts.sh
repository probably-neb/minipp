#!/usr/bin/env bash

files=$(cat src/ast.zig | rg '\s*\w+: struct' | cut -d: -f1 | cut -b 9-)

# thank you perplex-ippity
while IFS=$'\n' read -r line; do
    matches=$(rg -c "$line" src/parser.zig)
    echo "$line: $matches"
done <<< "$files"
