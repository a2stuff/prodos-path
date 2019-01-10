
        .include "apple2.inc"

CROUT   := $FD8E
COUT    := $FDED
INBUF   := $200

        .org    $4000

        jsr     CROUT
        ldx     #0

        ;; Skip any leading spaces
        jsr     skip_spaces

        ;; Invoked with "-" ?
        lda     INBUF,x
        cmp     #'-'|$80
        bne     :+
        inx
:
        ;; Skip any more leading spaces
        jsr     skip_spaces

        ;; Skip command name (i.e. "echo")
        txa
        clc
        adc     #cmd_length
        tax

        ;; Skip leading spaces before string to echo
        jsr     skip_spaces

        ;; Echo string
:       lda     INBUF,x
        jsr     COUT
        cmp     #$D | $80
        beq     exit
        inx
        jmp     :-

exit:   rts

.proc skip_spaces
        lda     INBUF,x
        cmp     #' '|$80
        beq     :+
        rts
:       inx
        jmp     skip_spaces
.endproc

cmd_length = .strlen("echo")