;;; ============================================================
;;;
;;; DATE - Print the current date/time
;;;
;;; Usage: DATE
;;;
;;; NOTE: Only supports 2 digit years
;;;
;;; ============================================================

        .include "apple2.inc"
        .include "more_apple2.inc"
        .include "prodos.inc"

;;; ============================================================

        .org $4000

start:
        jsr     CROUT

;;;           49041 ($BF91)     49040 ($BF90)
;;;           7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
;;;          +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;;; DATE:    |    year     |  month  |   day   |
;;;          +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;;;
;;;            49043 ($BF93)     49042 ($BF92)
;;;           7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0
;;;          +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
;;; TIME:    |0 0 0|   hour  | |0 0|  minute   |
;;;          +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+

        MLI_CALL GET_TIME, 0
        lda     DATELO
        ora     DATEHI
        beq     not_set

        ;; Date

        lda     DATELO+1        ; month
        ror     a
        pha
        lda     DATELO
        pha
        rol     a
        rol     a
        rol     a
        rol     a
        and     #%00001111
        jsr     cout_number

        lda     #'/'|$80        ; /
        jsr     COUT

        pla                     ; day
        and     #%00011111
        jsr     cout_number

        lda     #'/'|$80        ; /
        jsr     COUT

        pla                     ; year
        jsr     cout_number

        lda     #' '|$80        ;
        jsr     COUT
        jsr     COUT

        ;; Time

        lda     TIMELO+1        ; hour
        and     #%00011111
        jsr     cout_number

        lda     #':'|$80        ; ':'
        jsr     COUT

        lda     TIMELO          ; minute
        and     #%00111111
        jsr     cout_number

finish: jsr     CROUT

        clc
        rts

not_set:
        ldx     #0
:       lda     msg,x
        beq     finish
        ora     #$80
        jsr     COUT
        inx
        bne     :-              ; always

msg:    .byte   "<NO DATE>", 0


;;; ============================================================
;;; Print a 2-digit number, with leading zeros

.proc cout_number
        ;; Reduce to 2 digits
:       cmp     #100
        bcc     :+
        sec
        sbc     #100
        bne     :-

        ;; Leading zero?
:       ldx     #0
        cmp     #10             ; >= 10?
        bcc     tens

        ;; Divide by 10, dividend(+'0') in X remainder in A
:       sbc     #10
        inx
        cmp     #10
        bcs     :-

tens:   pha
        txa
        ora     #'0'|$80        ; convert to digit
        jsr     COUT

units:  pla
        ora     #'0'|$80        ; convert to digit
        jsr     COUT
        rts
.endproc
