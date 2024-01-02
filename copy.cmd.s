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
        lda     #>execute
        sta     XTRNADDR+1

        ;; Mark command as external (zero).
        lda     #0
        sta     XCNUM

        ;; Set accepted parameter flags

        lda     #PBitsFlags::FN1 | PBitsFlags::FN2 ; Filenames
        sta     PBITS
        lda     #0              ; See below for why PBitsFlags::SD is not used
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
        ;; Fix relative paths. If PREFIX is not emptu, this is not needed.
        ;; If PREFIX is empty, then relative paths will fail. Specifying
        ;; PBitsFlags::SD is the usual fix for BI commands that take paths
        ;; but while it will make FN1 absolute if needed it applies the
        ;; same change to FN2 (nothing or prepending) without inspecting
        ;; FN2. So REL,/ABS becomes /PFX/REL,/PFX//ABS (oops!) and
        ;; /ABS,REL remains /ABS,REL (still relative!).

        jsr     GetPrefix
        bcs     rts1

        lda     VPATH1
        ldx     VPATH1+1
        jsr     FixPath
        lda     VPATH2
        ldx     VPATH2+1
        jsr     FixPath

        ;; Get FN1 info
        lda     #$A
        sta     SSGINFO
        lda     #GET_FILE_INFO
        jsr     GOSYSTEM
        bcs     rts1

        ;; Reject directory file
        lda     FIFILID
        cmp     #FT_DIR
        bne     :+
        lda     #BI_ERR_FILE_TYPE_MISMATCH
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
        lda     HIMEM+1         ; Use BI's general purpose buffer (page aligned)
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

        lda     #BI_ERR_DUPLICATE_FILE_NAME
err:    pha
        jsr     CloseFiles
        pla
        sec
        rts

:       cmp     #BI_ERR_PATH_NOT_FOUND
        beq     :+
        cmp     #BI_ERR_VOLUME_DIR_NOT_FOUND
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
        cmp     #BI_ERR_END_OF_DATA
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


finish: jsr     CloseFiles

        ;; Apply FN1 info to FN2 to preserve modification date
        ldx     #$D - 3
:       lda     FN1INFO+3,x
        sta     SSGINFO+3,x
        dex
        bpl     :-
        lda     #$7
        sta     SSGINFO
        lda     #SET_FILE_INFO
        jsr     GOSYSTEM

        clc
        rts

.proc CloseFiles
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

;;; Leave PREFIX at INBUF; infers it the same way as BI if empty.
;;; Returns with Carry set on failure.
.proc GetPrefix
        ;; Try fetching prefix
        MLI_CALL GET_PREFIX, get_prefix_params
        lda     INBUF
        bne     done

        ;; Use BI's current slot and drive to construct unit number
        lda     DEFSLT          ; xxxxxSSS
        asl                     ; xxxxSSS0
        asl                     ; xxxSSS00
        asl                     ; xxSSS000
        asl                     ; xSSS0000
        asl                     ; SSS00000
        ldx     DEFDRV
        cpx     #2              ; C=0 if 1, C=1 if 2
        ror                     ; DSSS0000
        sta     unit

        ;; Get volume name and convert to path
        MLI_CALL ON_LINE, on_line_params
        bcc     :+
        jsr     BADCALL         ; sets Carry
        rts

:       lda     INBUF+1
        and     #$0F            ; mask off name_len
        tax
        inx                     ; leading and trailing '/'
        inx
        stx     INBUF
        lda     #'/'
        sta     INBUF+1         ; leading '/'
        sta     INBUF,x         ; trailing '/'

done:   clc
        rts

get_prefix_params:
        .byte   1
        .addr   INBUF

on_line_params:
        .byte   2
unit:   .byte   0
        .addr   INBUF+1         ; leave room to insert leading '/'
.endproc

;;; Fix path passed in A,X if it's relative. Uses prefix in INBUF
.proc FixPath
        ptr := $06
        ptr2 := $08

        sta     ptr
        stx     ptr+1

        ;; Already relative?
        ldy     #1
        lda     (ptr),y
        cmp     #'/'
        beq     done

        ;; Compute new length
        ldy     #0
        lda     (ptr),y
        tay                     ; Y = current length
        clc
        adc     INBUF           ; add prefix length
        pha                     ; stash for later

        ;; Shift path up to make room
        lda     INBUF
        clc
        adc     ptr
        sta     ptr2
        lda     #0
        adc     ptr+1
        sta     ptr2+1
:       lda     (ptr),y
        sta     (ptr2),y
        dey
        bpl     :-

        ;; Insert prefix
        lda     INBUF
        tax
        tay
:       lda     INBUF,x
        sta     (ptr),y
        dex
        dey
        bne     :-

        ;; Assign final length
        pla
        ldy     #0
        sta     (ptr),y

done:   rts
.endproc

.proc SkipSpaces
repeat: lda     INBUF,x
        cmp     #' '|$80
        beq     :+
        rts
:       inx
        jmp     repeat
.endproc

cmd_length = .strlen("echo")

        .assert * <= FN2BUF, error, "Too long"
