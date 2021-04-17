;;; ============================================================
;;;
;;; CD - Change Directory (like PREFIX, plus .. support)
;;;
;;; Usage: CD path
;;;
;;;  * path can be absolute, e.g. CD /VOL/DIR
;;;  * path can be relative, e.g. CD SUBDIR/SUBDIR
;;;  * segments can be .. to go up a dir, e.g. CD ../DIR
;;;  * segments can be . to mean same dir, e.g. CD ./SUBDIR
;;;  * with no path, echoes current PREFIX
;;;
;;; ============================================================

        .include "apple2.inc"
        .include "more_apple2.inc"
        .include "prodos.inc"

;;; ============================================================

        .org $4000

        ;; Follow the BI external command protocol. Although
        ;; the parser is not used, this allows returning
        ;; BI error codes.

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
        lda     #0
        sta     PBITS
        lda     #0
        sta     PBITS+1

        clc                     ; Success (so far)
rts1:   rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

        PFXBUF := $280
        tmp := $06

execute:
        ;; Skip command and leading spaces
        ldx     XLEN
        inx
        jsr     SkipSpaces

        ;; Absolute?
        lda     INBUF,x
        cmp     #'/'|$80
        beq     abs

        ;; No, will need current prefix
        stx     tmp
        jsr     GetPrefix
        bcs     rts1
        ldx     tmp

        ;; Empty?
        lda     INBUF,x
        cmp     #$8D            ; CR
        bne     common          ; no, start processing

        ;; Echo the current prefix
        jsr     CROUT
        ldx     #0
:       inx
        lda     PFXBUF,x
        ora     #$80
        jsr     COUT
        cpx     PFXBUF
        bne     :-
        jsr     CROUT
        jsr     CROUT
        clc
        rts

;;; --------------------------------------------------
;;; Absolute path

abs:    lda     #1              ; init prefix to just '/'
        sta     PFXBUF
        lda     #'/'
        sta     PFXBUF+1
        inx                     ; consume leading '/'
        ;; fall through

;;; --------------------------------------------------
;;; Process the relative path
;;;
;;; PFXBUF has the prefix; Y holds the length
;;; X holds position in INBUF

common: ldy     PFXBUF

        ;; Loop over segments
loop:   jsr     GetC
        cmp     #$D             ; EOL?
        beq     done

        cmp     #'.'            ; Maybe "." or ".." ?
        beq     dot

put:    jsr     PutC
        jsr     GetC

        cmp     #$D             ; EOL?
        beq     done
        cmp     #'/'            ; end of segment?
        bne     put
        jsr     PutC
        bne     loop            ; always

dot:    jsr     GetC
        cmp     #'.'            ; ".." ?
        bne     :+
        jsr     Pop             ; yes, pop the last segment
        jsr     GetC
:       cmp     #$D             ; EOL?
        beq     done            ; groovy
        cmp     #'/'            ; "./" or "../"?
        beq     loop            ; also groovy

        lda     #BI_ERR_SYNTAX_ERROR
        sec
        rts

;;; --------------------------------------------------
;;; Try setting the new PREFIX

done:   sty     PFXBUF
        MLI_CALL SET_PREFIX, get_set_prefix_params
        bcc     :+
        jsr     BADCALL         ; Convert MLI error to BI error
:       rts


;;; ============================================================
;;; Pop a segment
.proc Pop
        cpy     #1
        beq     done
:       dey
        lda     PFXBUF,y
        cmp     #'/'
        bne     :-

done:   rts
.endproc

;;; ============================================================
;;; Get next character from INBUF at X.
.proc GetC
        lda     INBUF,x
        inx
        and     #$7F
        rts
.endproc

;;; ============================================================
;;; Append to PFXBUF at Y. Returns non-zero.
.proc PutC
        iny
        sta     PFXBUF,y
        rts
.endproc

;;; ============================================================
;;; Skip over spaces in INBUF, advancing X; returns first non-space.
.proc SkipSpaces
repeat: lda     INBUF,x
        cmp     #' '|$80
        beq     :+
        rts
:       inx
        jmp     repeat
.endproc

;;; ============================================================
;;; Leave PREFIX at PFXBUF; infers it the same way as BI if empty.
;;; Returns with Carry set on failure.
.proc GetPrefix
        ;; Try fetching prefix
        MLI_CALL GET_PREFIX, get_set_prefix_params
        lda     PFXBUF
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

:       lda     PFXBUF+1
        and     #$0F            ; mask off name_len
        tax
        inx                     ; leading and trailing '/'
        inx
        stx     PFXBUF
        lda     #'/'
        sta     PFXBUF+1        ; leading '/'
        sta     PFXBUF,x        ; trailing '/'

done:   clc
        rts

on_line_params:
        .byte   2
unit:   .byte   0
        .addr   PFXBUF+1        ; leave room to insert leading '/'
.endproc

get_set_prefix_params:
        .byte   1
        .addr   PFXBUF
