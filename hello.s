
        .include "apple2.inc"

CROUT   := $FD8E
COUT    := $FDED

        .org    $4000

        ldx     #0
:       lda     str, x
        beq     done
        jsr     COUT
        jmp     :-

done:   jsr     CROUT
        rts

str:    .byte   "Hello, world!", 0