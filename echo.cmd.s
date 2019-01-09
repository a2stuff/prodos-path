
        .include "apple2.inc"

CROUT   := $FD8E
COUT    := $FDED
INBUF   := $200

        .org    $4000

        jsr     CROUT

        ldx     #cmd_length
:       lda     INBUF,x
        inx
        jsr     COUT
        cmp     #$8D
        bne     :-

        rts


cmd_length = .strlen("echo")