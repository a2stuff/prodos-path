# CMD executable PATH for ProDOS's BASIC.SYSTEM

[![Build Status](https://travis-ci.org/a2stuff/prodos-path.svg?branch=master)](https://travis-ci.org/a2stuff/prodos-path)

💾 Disk images can be found on the [Releases](https://github.com/a2stuff/prodos-path/releases) page 💾

Build with [ca65](https://cc65.github.io/doc/ca65.html)

## Instructions For Users

Installation:
* Copy files from the floppy disk image to your Apple's hard disk, in a subdirectory e.g. `/HD/CMD`
* From BASIC.SYSTEM prompt, run: `PATH`, e.g. `-/HD/CMD/PATH`, either from `STARTUP` or manually

After installation, the usage is:
```
PATH prefix     - set search path(s) - colon delimited
PATH            - view current search path(s)
cmdname         - load and execute named CMD, if in PATH
```

* Once set, binary files of type `CMD` in the specified directories can be invoked by name.
* Supports multi-segment, colon-separated paths, e.g. `/hd/cmds:/hd2/more.cmds`

Example:
```
] -/hd/cmd/path          - install it
] PATH /hd/cmd:/h2/bin  - set PATH
] PATH                   - verify path
/hd/cmd:/h2/bin
] BELL                   - will invoke /hd/cmd/BELL if present
] HELLO                  - will invoke /hd/cmd/HELLO if present
] ONLINE                 - will invoke /hd/cmd/ONLINE if present
```

Notes:
* `PATH` can be invoked as lower case (e.g. `path /hd/cmd`)
* Commands can be invoked as lower case (e.g. `hello`)

Sample commands included:
* `HELLO` - shows a short message, for testing purposes
* `ECHO` - echoes back anything following the command
* `CD` - like `PREFIX` but accepts `..`, e.g. `cd ../dir`
* `ONLINE` - lists online volumes (volume name, slot and drive)
* `COPY` - copy a single file, e.g. `copy /path/to/file,dstfile`
* `TYPE` - show file contents (TXT, BAS, or BIN/other), e.g. `type filename`
* `DATE` - prints the current ProDOS date and time
* `CHTYPE` - change the type/auxtype of a file, e.g. `chtype file,T$F1,A$1234`
    * `T` (type) and `A` (auxtype) are optional. If neither is specified, current types are shown.
    * `S` and `D` arguments can be used to specify slot and drive.
* `CHTIME` - change the modification date/time of a file, e.g. `chtime file,A$1234,B$5678`
    * `A` (date) and `B` (time) are optional. If neither is specified, current values are shown.
    * `S` and `D` arguments can be used to specify slot and drive.
* `BELL` - emits the standard Apple II beep
* `BUZZ` - emits the ProDOS "nice little tone"

## Instructions For Developers

Behavior of `PATH`:

* Search order when a command is typed:
   * ProDOS BASIC.SYSTEM intrinsics (`CAT`, `PREFIX`, etc)
   * BASIC keywords (`LIST`, `PRINT`, etc)
   * CMD files in paths, in listed order
* Allocates a permanent buffer to store the code and path (2 pages)
* Applesoft BASIC commands are unaffected (but can't be CMD names)
   * Commands with BASIC keywords as _prefixes_ are allowed as long as the command continues with an alphabetic character. For example, `ONLINE` is allowed despite conflicting with the valid BASIC statement `ONLINE GOTO10` which is short for `ON LINE GOTO 10`.

Protocol for `CMD` files:

* CMD file is loaded at $4000 and invoked; should return (`rts`) on completion.
* $4000-$5FFF is assumed reserved for the CMD file and any buffers it needs.
* The command line will be present at $200 (`GETLN` input buffer).
* Commands can use the BI parser for arguments. See `chtype.cmd.s` for an example.
