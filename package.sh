#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

PACKDIR="out/package"
FINFO="$PACKDIR/_FileInformation.txt"
IMGFILE="out/prodos-path.po"
VOLNAME="path"

mkdir -p "$PACKDIR"
echo "" > "$FINFO"

# Copy renamed files (with type/auxtype info) into package directory.

cp "out/path.BIN" "$PACKDIR/path#062000"
cp "out/bell.CMD" "$PACKDIR/bell#F04000"
cp "out/echo.CMD" "$PACKDIR/echo#F04000"
cp "out/hello.CMD" "$PACKDIR/hello#F04000"

# Create a new disk image.

rm -f "$IMGFILE"

cadius CREATEVOLUME "$IMGFILE" "$VOLNAME" 140KB --no-case-bits --quiet
cadius ADDFILE "$IMGFILE" "/$VOLNAME" "$PACKDIR/path#062000" --no-case-bits --quiet
cadius ADDFILE "$IMGFILE" "/$VOLNAME" "$PACKDIR/bell#F04000" --no-case-bits --quiet
cadius ADDFILE "$IMGFILE" "/$VOLNAME" "$PACKDIR/echo#F04000" --no-case-bits --quiet
cadius ADDFILE "$IMGFILE" "/$VOLNAME" "$PACKDIR/hello#F04000" --no-case-bits --quiet

rm -r "$PACKDIR"

cadius CATALOG "$IMGFILE"
