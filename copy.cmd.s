;;; ============================================================
;;;
;;; COPY - Copy changing command for ProDOS-8
;;;
;;; Usage: COPY pathname1,pathname2
;;;
;;; Inspiration from COPY.ALL by Sandy Mossberg, Nibble 6/1987
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

        ;; NOTE: With PREFIX set, relative paths are fine.
        ;; If PREFIX is not set, then:
        ;; * Without PBitsFlags::SD:
        ;;    * COPY REL,REL - fails - BAD
        ;;    * COPY REL,/ABS - fails - BAD
        ;;    * COPY /ABS,/ABS - works
        ;;    * COPY /ABS,REL - fails - BAD
        ;; * With PBitsFlags::SD:
        ;;    * COPY REL,REL - works (FN1 & FN2 made absolute)
        ;;    * COPY REL,/ABS - fails; FN1 becomes /PFX/REL, FN2 becomes /PFX//ABS - BAD
        ;;    * COPY /ABS,/ABS - works (FN1 & FN2 left alone)
        ;;    * COPY /ABS,REL - fails; FN2 remains relative - BAD

        ;; Set accepted parameter flags

        lda     #PBitsFlags::FN1 | PBitsFlags::FN2 ; Filenames
        sta     PBITS
        lda     #PBitsFlags::SD ; Slot/Drive (and PREFIX)
        sta     PBITS+1

        clc                     ; Success (so far)
        rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

        FN1REF := $D6
        FN2REF := $D7

        FN1INFO := $2EE
        FN2BUF  := $4200
        DATABUF := $4600
        DATALEN = $6000 - DATABUF

execute:
        ;; Get FN1 info
        lda     #$A
        sta     SSGINFO
        lda     #GET_FILE_INFO
        jsr     GOSYSTEM
        bcs     rts1

        ;; Reject directory file
        lda     FIFILID
        cmp     #$F             ; DIR
        bne     :+
        lda     #$D             ; FILE TYPE MISMATCH
        sec
rts1:   rts
:

        ;; Save FN1 info
        ldx     #$11
:       lda     SSGINFO,x
        sta     FN1INFO,x
        dex
        bpl     :-

        ;; Open FN1
        lda     HIMEM           ; Use BI's general purpose buffer
        sta     OSYSBUF
        lda     HIMEM+1
        sta     OSYSBUF+1
        lda     #OPEN
        jsr     GOSYSTEM
        bcs     rts1
        lda     OREFNUM
        sta     FN1REF

        ;; Copy FN2 to FN1
        ptr1 := $06
        ptr2 := $08
        lda     VPATH1
        sta     ptr1
        lda     VPATH1+1
        sta     ptr1+1
        lda     VPATH2
        sta     ptr2
        lda     VPATH2+1
        sta     ptr2+1
        ldy     #0
        lda     (ptr2),y
        tay
:       lda     (ptr2),y
        sta     (ptr1),y
        dey
        bpl     :-

        ;; Get FN2 info
        lda     #GET_FILE_INFO
        jsr     GOSYSTEM
        bcs     :+

        lda     #$13            ; DUPLICATE FILE NAME
err:    pha
        jsr     close
        pla
        sec
        rts

:       cmp     #6              ; BI Errors 6 and 7 cover
        beq     :+              ; vol dir, pathname, or filename
        cmp     #7              ; not found.
        bne     err             ; Otherwise - fail.
:

        ;; Create FN2
        lda     #$C3            ; Free access
        sta     CRACESS
        ldx     #3
:       lda     FN1INFO+4,x     ; storage type, file type,
        sta     CRFKIND-3,x     ; aux type, create date/time
        lda     FN1INFO+$E,x
        sta     CRFKIND+1,x
        dex
        bpl     :-
        lda     #CREATE
        jsr     GOSYSTEM
        bcs     err

        ;; Open FN2
        lda     #<FN2BUF
        sta     OSYSBUF
        lda     #>FN2BUF
        sta     OSYSBUF+1
        lda     #OPEN
        jsr     GOSYSTEM
        bcs     err
        lda     OREFNUM
        sta     FN2REF

        ;; Read
read:   lda     FN1REF
        sta     RWREFNUM
        lda     #<DATABUF
        sta     RWDATA
        lda     #>DATABUF
        sta     RWDATA+1
        lda     #<DATALEN
        sta     RWCOUNT
        lda     #>DATALEN
        sta     RWCOUNT+1
        lda     #READ
        jsr     GOSYSTEM
        bcc     :+
        cmp     #5              ; END OF DATA
        beq     finish
:

        ;; Write
        lda     FN2REF
        sta     RWREFNUM
        lda     #<DATABUF
        sta     RWDATA
        lda     #>DATABUF
        sta     RWDATA+1
        lda     RWTRANS
        sta     RWCOUNT
        lda     RWTRANS+1
        sta     RWCOUNT+1
        lda     #WRITE
        jsr     GOSYSTEM
        bcc     read
        jmp     err


finish: jsr     close
        clc
        rts

.proc close
        lda     FN1REF
        sta     CFREFNUM
        lda     #CLOSE
        jsr     GOSYSTEM
        lda     FN2REF
        sta     CFREFNUM
        lda     #CLOSE
        jsr     GOSYSTEM
        rts
.endproc

        .assert * <= FN2BUF, error, "Too long"
