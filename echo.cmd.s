
        .include "apple2.inc"
        .include "more_apple2.inc"

        .org    $4000

        jsr     CROUT
        ldx     #0

        ;; Skip any leading spaces
        jsr     SkipSpaces

        ;; Invoked with "-" ?
        lda     INBUF,x
        cmp     #'-'|$80
        bne     :+
        inx
:
        ;; Skip any more leading spaces
        jsr     SkipSpaces

        ;; Skip command name (i.e. "echo")
        txa
        clc
        adc     #cmd_length
        tax

        ;; Skip leading spaces before string to echo
        jsr     SkipSpaces

        ;; Echo string
:       lda     INBUF,x
        jsr     COUT
        cmp     #$D | $80
        beq     exit
        inx
        jmp     :-

exit:   clc
        rts

.proc SkipSpaces
repeat: lda     INBUF,x
        cmp     #' '|$80
        beq     :+
        rts
:       inx
        jmp     repeat
.endproc

cmd_length = .strlen("echo")