
        .include "apple2.inc"

BELL := $FBE4

        .org    $4000

        ldy     #0
        jsr     BELL
        rts
