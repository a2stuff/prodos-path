
        .include "apple2.inc"

BELL := $FBE4

        .org    $4000

        jsr     BELL
        rts
