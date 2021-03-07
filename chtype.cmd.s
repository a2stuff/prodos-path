;;; ============================================================
;;;
;;; CHTYPE - File type changing command for ProDOS-8
;;;
;;; Usage: CHTYPE filename[,Ttype][,Aaux][,S#][,D#]
;;;
;;;  * filename can be relative or absolute path
;;;  * specify T$nn to set file type
;;;  * specify A$nnnn to set aux type info
;;;  * type can be BIN, SYS, TXT (etc) or $nn
;;;  * with neither T nor A option, prints current values
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

        ;; Set accepted parameter flags (Name, Type, Address)

        lda     #PBitsFlags::T | PBitsFlags::FN1 ; Filename and Type
        sta     PBITS

        lda     #PBitsFlags::AD | PBitsFlags::SD ; Address, Slot & Drive handling
        sta     PBITS+1

        clc                     ; Success (so far)
        rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

execute:
        ;; Verify required arguments

        lda     FBITS
        and     #PBitsFlags::FN1 ; Filename?
        bne     :+
        lda     #$10            ; SYNTAX ERROR
        sec
rts1:   rts
:

;;; --------------------------------------------------

        ;; Get the existing file info
        lda     #$A
        sta     SSGINFO
        lda     #GET_FILE_INFO
        jsr     GOSYSTEM
        bcs     rts1

;;; --------------------------------------------------

        ;; Apply options
        ldy     #0              ; count number of options

        ;; Apply optional Type argument as new file type
        lda     FBITS
        and     #PBitsFlags::T  ; Type set?
        beq     :+
        iny
        lda     VTYPE
        sta     FIFILID
:

        ;; Apply optional Address argument as new aux type
        lda     FBITS+1
        and     #PBitsFlags::AD ; Address set?
        beq     :+
        iny
        lda     VADDR
        sta     FIAUXID
        lda     VADDR+1
        sta     FIAUXID+1
:

        ;; If no options were used, show current details instead.
        cpy     #0
        beq     show

        ;; Apply current date/time
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

;;; --------------------------------------------------

show:
        lda     #'T'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT
        lda     #'$'|$80
        jsr     COUT
        lda     FIFILID
        jsr     PRBYTE
        jsr     CROUT

        lda     #'A'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT
        lda     #'$'|$80
        jsr     COUT
        lda     FIAUXID+1
        jsr     PRBYTE
        lda     FIAUXID
        jsr     PRBYTE
        jsr     CROUT

        clc
        rts
