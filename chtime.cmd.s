;;; ============================================================
;;;
;;; CHTIME - File modification time changing command for ProDOS-8
;;;
;;; Usage: CHTIME filename[,Adate][,Btime][,S#][,D#]
;;;
;;;  * filename can be relative or absolute path
;;;  * specify A$nnnn to set file date
;;;  * specify B$nnnn to set file time
;;;  * with neither A nor B option, prints current values
;;;
;;; ============================================================

        .include "apple2.inc"
        .include "more_apple2.inc"
        .include "prodos.inc"

;;; ============================================================

        .org $4000

        ;; NOTE: Assumes XLEN is set by PATH

        ;; Point BI's parser at the command execution routine.
        lda     #<execute
        sta     XTRNADDR
        page_num2 := *+1         ; address needing updating
        lda     #>execute
        sta     XTRNADDR+1

        ;; Mark command as external (zero).
        lda     #0
        sta     XCNUM

        ;; Set accepted parameter flags

        ;; Filename
        lda     #PBitsFlags::FN1
        sta     PBITS

        ;; Address (A=Date word), Byte (B=Time word), Slot & Drive handling
        lda     #PBitsFlags::AD | PBitsFlags::B | PBitsFlags::SD
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

;;; --------------------------------------------------

        ;; Apply options
        ldy     #0              ; count number of options

        ;; Apply optional Address argument as new date
        lda     FBITS+1
        and     #PBitsFlags::AD ; Address set?
        beq     :+
        iny
        lda     VADDR
        sta     FIMDATE
        lda     VADDR+1
        sta     FIMDATE+1
:

        ;; Apply optional Byte argument as new time
        lda     FBITS+1
        and     #PBitsFlags::B  ; Type set?
        beq     :+
        iny
        lda     VBYTE
        sta     FIMDATE+2
        lda     VBYTE+1
        sta     FIMDATE+3
:

        ;; If no options were used, show current details instead.
        cpy     #0
        beq     show

        ;; Set new file info
        lda     #$7
        sta     SSGINFO

        lda     #SET_FILE_INFO
        jmp     GOSYSTEM

;;; --------------------------------------------------

show:
        lda     #'A'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT
        lda     #'$'|$80
        jsr     COUT
        lda     FIMDATE+1
        jsr     PRBYTE
        lda     FIMDATE
        jsr     PRBYTE
        jsr     CROUT

        lda     #'B'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT
        lda     #'$'|$80
        jsr     COUT
        lda     FIMDATE+3
        jsr     PRBYTE
        lda     FIMDATE+2
        jsr     PRBYTE
        jsr     CROUT

        clc
        rts
