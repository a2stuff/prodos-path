# CMD executable PATH for ProDOS's BASIC.SYSTEM

Build with [ca65](https://cc65.github.io/doc/ca65.html)

Installation:
* Copy target to ProDOS disk
* From BASIC.SYSTEM prompt, run: `-PATH` from STARTUP (or by hand)

Usage:
```
PATH prefix     - set search path(s) - colon delimited
PATH            - view current search path(s)
cmdname         - load and execute named CMD, if in PATH
```

Once set, binary files of type `CMD` in the specified directories can be invoked by name.
* CMD file is loaded at $4000 and invoked; should return (`rts`) on completion.
* The command line will be present at $200 (`GETLN` input buffer).
* Supports multi-segment, colon-separated paths, e.g. `/hd/cmds:/hd2/more.cmds`

Example:
```
] -/hd/path              - install it
] PATH /hd/cmds:/h2/bin  - set PATH
] PATH                   - verify path
/hd/cmds
] BELL                   - will invoke /hd/cmds/BELL if present
] HELLO                  - will invoke /hd/cmds/HELLO if present
```

Notes:
* Allocates a permanent buffer to store the code and path (2 pages)
* Can be invoked as lower case (e.g. `path ...`)
* Applesoft BASIC commands are unaffected (but can't be CMD names)
* Search order when a command is typed:
   * ProDOS BASIC.SYSTEM intrinsics (`CAT`, `PREFIX`, etc)
   * AppleSoft keywords (`LIST`, `PRINT`, etc)
   * CMD files in paths, in listed order
