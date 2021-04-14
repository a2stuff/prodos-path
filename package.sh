#!/usr/bin/env bash

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
for file in bell echo hello online chtype chtime copy date type; do
    add_file "out/${file}.CMD" "${file}#F04000"
done

rm -r "$PACKDIR"

cadius CATALOG "$IMGFILE"
