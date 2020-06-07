#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

PACKDIR=$(mktemp -d)
IMGFILE="out/prodos-path.po"
VOLNAME="path"

rm -f "$IMGFILE"
cadius CREATEVOLUME "$IMGFILE" "$VOLNAME" 140KB --no-case-bits --quiet

add_file () {
    cp "$1" "$PACKDIR/$2"
    cadius ADDFILE "$IMGFILE" "/$VOLNAME" "$PACKDIR/$2" --no-case-bits --quiet
}

add_file "out/path.BIN" "path#062000"
add_file "out/bell.CMD" "bell#F04000"
add_file "out/echo.CMD" "echo#F04000"
add_file "out/hello.CMD" "hello#F04000"
add_file "out/vols.CMD" "vols#F04000"

rm -r "$PACKDIR"

cadius CATALOG "$IMGFILE"
