
        .include "apple2.inc"
        .include "more_apple2.inc"
        .include "prodos.inc"

        .org    $4000

;;; ============================================================

        ptr := $06

        jsr     CROUT

        MLI_CALL ON_LINE, params
        bcs     exit

        lda     #<buf
        sta     ptr
        lda     #>buf
        sta     ptr+1

loop:   ldy     #0
        lda     (ptr),y
        beq     exit            ; Done!

        ;; Crack drive/slot/name_len
        and     #%00001111
        beq     next            ; Error; TODO: if next byte is $57 show Duplicate Volume
        sta     len
        lda     (ptr),y
        and     #%11110000
        sta     ds

        ;; Print name
        lda     #'/'|$80        ; Leading slash
        jsr     COUT
:       iny
        lda     (ptr),y         ; Name characters
        ora     #$80
        jsr     COUT
        cpy     len
        bne     :-

        ;; Space
        lda     #20
        sta     CH              ; TODO: COUT spaces, instead of HTAB?

        ;; Slot
        lda     #'S'|$80
        jsr     COUT
        lda     ds
        and     #%01110000
        lsr
        lsr
        lsr
        lsr
        ora     #'0'|$80
        jsr     COUT

        ;; Drive
        lda     #','|$80
        jsr     COUT
        lda     #'D'|$80
        jsr     COUT
        lda     #'1'|$80
        bit     ds
        bpl     :+
        lda     #'2'|$80
:       jsr     COUT
        jsr     CROUT

next:   dec     count
        beq     exit

        clc
        lda     ptr
        adc     #16
        sta     ptr
        lda     ptr+1
        adc     #0
        sta     ptr+1
        jmp     loop

exit:   clc
        rts

;;; ============================================================

.proc params
param_count:    .byte   2
unit_num:       .byte   0
data_buffer:    .addr   buf
.endproc

count:  .byte   16
buf:    .res    256
len:    .byte   0               ; name length
ds:     .byte   0               ; drive / slot
