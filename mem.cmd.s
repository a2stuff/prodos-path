;;; ============================================================
;;;
;;; MEM - Print memory stats
;;;
;;; Usage: MEM
;;;
;;; Inspiration from A2osX
;;;
;;; ============================================================

        .include "apple2.inc"
        .include "more_apple2.inc"

;;; ============================================================

        .org $4000

        jsr     CROUT
        jsr     CROUT

.macro  SHOW suffix
        lda     #<.ident(.concat("str_", .string(suffix)))
        ldx     #>.ident(.concat("str_", .string(suffix)))
        ldy     #.ident(.concat("addr_", .string(suffix)))
        jsr     Print
.endmacro

        SHOW    pgm_start
        SHOW    lomem
        SHOW    array_start
        SHOW    array_end
        SHOW    string_start
        SHOW    himem

        clc
        rts

addr_pgm_start          := $67
str_pgm_start:          .byte   "Program start: $", 0
addr_lomem              := $69
str_lomem:              .byte   "LOMEM:         $", 0
addr_array_start        := $6B
str_array_start:        .byte   "Array start:   $", 0
addr_array_end          := $6D
str_array_end:          .byte   "Array end:     $", 0
addr_string_start       := $6F
str_string_start:       .byte   "String start:  $", 0
addr_himem              := $73
str_himem:              .byte   "HIMEM:         $", 0

.proc Print
        sta     msg_addr
        stx     msg_addr+1
        iny                     ; MSB first
        sty     zp_addr

        ldx     #0
        msg_addr := *+1
loop:   lda     $1234,x         ; self-modified
        beq     :+
        ora     #$80
        jsr     COUT
        inx
        bne     loop            ; always
:
        jsr     getb
        jsr     PRBYTE
        jsr     getb
        jsr     PRBYTE
        jmp     CROUT

        zp_addr := *+1
getb:   lda     $12             ; self-modified
        dec     zp_addr
        rts
.endproc
