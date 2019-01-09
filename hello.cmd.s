
        .include "apple2.inc"

CROUT   := $FD8E
COUT    := $FDED

        .org    $4000

        jsr     CROUT
        ldx     #0
:       lda     str,x
        beq     done
        ora     #$80
        jsr     COUT
        inx
        jmp     :-

done:   jsr     CROUT
        clc
        rts

str:    .byte   "Hello, world!", 0