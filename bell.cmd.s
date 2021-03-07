
        .include "apple2.inc"
        .include "more_apple2.inc"

        .org    $4000

        jsr     BELL

        clc
        rts
