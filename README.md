# path - CMD executable path command for ProDOS

Build with [ca65](https://cc65.github.io/doc/ca65.html)

Installation:
* Copy target to ProDOS disk
* From BASIC.SYSTEM prompt, run: `-PATH` from STARTUP (or by hand)

Usage:
```
PATH            - view current search path
PATH prefix     - set search path
```

Once set, binary files of type `CMD` in the specified directory can be invoked by name.
* CMD file is loaded at $4000 and invoked; should return (`rts`) on completion
* The command line will be present at $200 (`GETLN` input buffer).

Example:
```
] -/hd/path              - install it
] PATH /hd/cmds          - set PATH
] PATH                   - verify path
/hd/cmds
] BELL                   - will invoke /hd/cmds/BELL if present
] HELLO                  - will invoke /hd/cmds/HELLO if present
```

Notes:
* Allocates a 3 page buffer to store the code and path
* Can be invoked as lower case (e.g. `path ...`)
* Applesoft BASIC commands are unaffected (but can't be CMD names)
