
        .include "apple2.inc"

CROUT   := $FD8E
COUT    := $FDED
INBUF   := $200

        .org    $4000

        jsr     CROUT

        ldx     #cmd_length-1

        ;; Skip spaces
:       inx
        lda     INBUF,x
        cmp     #' ' | $80
        beq     :-
        dex

        ;; Echo string
:       inx
        lda     INBUF,x
        jsr     COUT
        cmp     #$D | $80
        bne     :-

        clc
        rts


cmd_length = .strlen("echo")