;;; ============================================================
;;; Bell
;;;
;;; From ProDOS 8 Technical Reference Manual 5.4:
;;; "The standard Apple II "Air-raid" bell has been replaced with a
;;; gentler tone. Use it to give users some aural feedback that
;;; they are using a ProDOS program."

        .include "apple2.inc"
        .include "more_apple2.inc"

        .org    $4000

        length := $06

;;; Generate a nice little tone
;;; Exits with Z-flag set (BEQ) for branching
;;; Destroys the contents of the accumulator
        lda     #32             ;duration of tone
        sta     length
bell1:  lda     #2              ;short delay...click
        jsr     WAIT
        sta     SPKR
        lda     #32             ;long delay...click
        jsr     WAIT
        sta     SPKR
        dec     length
        bne     bell1           ;repeat length times

        clc
        rts
