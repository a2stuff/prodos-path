
        .include "apple2.inc"

BELL := $FF3A

        .org    $4000

        jsr     BELL
        rts
