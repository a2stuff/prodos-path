# chtype - change file type command for ProDOS

Build with [ca65](https://cc65.github.io/doc/ca65.html)

Installation:
* Copy target to ProDOS disk
* From BASIC.SYSTEM prompt, run: `-CHTYPE` from STARTUP (or by hand)

Usage:
```
CHTYPE pathname[,Ttype][,Aauxtype][,S#][,D#]
```

Examples:
* `CHTYPE` - show current type/auxtype
* `CHTYPE pic,T$08` - set just type
* `CHTYPE file,A$0640` - set just auxtype
* `CHTYPE now_basic,TBAS,A$801` - set both type and auxtype
* `CHTYPE /root/was_bin,TSYS` - works with absolute paths
* `CHTYPE as_text,TTXT,S6,D1` - can use slot/drive arguments too

Notes:
* Allocates a 1 page buffer to store the code
* Relative or absolute paths can be used
* Can be invoked as lower case (e.g. `chtype ...`)

Resources:
* [File Types Table](http://www.easy68k.com/paulrsm/6502/PDOS8TRM.HTM#B-1T) - [ProDOS 8 Technical Reference Manual](http://www.easy68k.com/paulrsm/6502/PDOS8TRM.HTM)
* [File Types](https://www.kreativekorp.com/miscpages/a2info/filetypes.shtml) - [Jon Relay's Apple II Info Archives](https://www.kreativekorp.com/miscpages/a2info/)
* [ProDOS File Types 2.0](https://macgui.com/kb/article/116) - [Mac GUI](https://macgui.com)
