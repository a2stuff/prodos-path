;;; ============================================================
;;;
;;; TOUCH - Apply current ProDOS date/time stamp to file
;;;
;;; Usage: TOUCH filename[,S#][,D#]
;;;
;;;  * filename can be relative or absolute path
;;;
;;; ============================================================

        .include "apple2.inc"
        .include "more_apple2.inc"
        .include "prodos.inc"

;;; ============================================================

        .org $4000

        ;; Point BI's parser at the command execution routine.
        lda     #<execute
        sta     XTRNADDR
        lda     #>execute
        sta     XTRNADDR+1

        ;; Mark command as external (zero).
        lda     #0
        sta     XCNUM

        ;; Set accepted parameter flags

        ;; Filename
        lda     #PBitsFlags::FN1
        sta     PBITS

        ;; Slot & Drive handling
        lda     #PBitsFlags::SD
        sta     PBITS+1

        clc                     ; Success (so far)
rts1:   rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

execute:
        ;; Get the existing file info
        lda     #$A
        sta     SSGINFO
        lda     #GET_FILE_INFO
        jsr     GOSYSTEM
        bcs     rts1

        ;; Apply time/date stamp
        ldx     #3
:       lda     DATE,x
        sta     FIMDATE,x
        dex
        bpl     :-

        ;; Set new file info
        lda     #$7
        sta     SSGINFO
        lda     #SET_FILE_INFO
        jmp     GOSYSTEM
