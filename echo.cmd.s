
        .include "apple2.inc"
        .include "more_apple2.inc"
        .include "prodos.inc"

        .org    $4000

        jsr     CROUT
        ldx     #0

        ;; Skip command and any leading spaces
        ldx     XLEN
        inx
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