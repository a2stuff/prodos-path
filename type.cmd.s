;;; ============================================================
;;;
;;; TYPE - Dump contents of files to the screen
;;;
;;; Usage: TYPE pathname[,S#][,D#]
;;;
;;; Inspiration from OmniType by William H. Tudor, Nibble 2/1989
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

        lda     #PBitsFlags::FN1 ; Filenames
        sta     PBITS
        lda     #PBitsFlags::SD ; Slot & Drive handling
        sta     PBITS+1

        clc                     ; Success (so far)
        rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

        DATABUF := INBUF

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
        ;; Open the file
        lda     HIMEM           ; Use BI's buffer above HIMEM
        sta     OSYSBUF
        lda     HIMEM+1
        sta     OSYSBUF+1
        lda     #OPEN
        jsr     GOSYSTEM
        bcs     rts1

        ;; Prepare the read arguments
        lda     OREFNUM
        sta     RWREFNUM
        sta     CFREFNUM

        lda     #<DATABUF       ; Stash read data here
        sta     RWDATA
        lda     #>DATABUF
        sta     RWDATA+1

        lda     #<1             ; Read one byte at a time
        sta     RWCOUNT
        lda     #>1
        sta     RWCOUNT+1

        lda     #0              ; For BASIC
        sta     LINUM
        sta     LINUM+1

        lda     FIFILID         ; File type
        cmp     #$04            ; TXT
        beq     text
        cmp     #$FC            ; BAS
        bne     :+
        jmp     basic
:

         ;;  fall through

;;; ============================================================
;;; Generic (Binary) file

.proc binary
        jsr     ReadByte
        bcc     :+
        jmp     Exit
:       pha

        ;; Line prefix
        jsr     CROUT
        lda     #'$'|$80
        jsr     COUT
        ldx     LINUM
        lda     LINUM+1
        jsr     PRTAX
        lda     #'-'|$80
        jsr     COUT

        pla
        ldx     #8              ; 8 bytes at a time
        bne     byte            ; always

        ;; Line of bytes in hex
bloop:  jsr     ReadByte
        bcc     byte
        lda     #' '            ; at EOF, space it out
        sta     INBUF,x
        ldy     #3
        bne     spaces          ; always

byte:   sta     INBUF,x         ; stash bytes
        jsr     PRBYTE
        ldy     #1

spaces: jsr     PrintYSpaces
        dex
        bne     bloop

        ;; Character display
        lda     #'|'|$80
        jsr     COUT
        ldx     #8              ; 8 bytes at a time
cloop:  lda     INBUF,x
        ora     #$80
        cmp     #' '|$80        ; control character?
        bcs     :+
        lda     #'.'|$80        ; yes, replace with period
:       jsr     COUT
        dex
        bne     cloop

        ;; Increment offset
        lda     #8
        clc
        adc     LINUM
        sta     LINUM
        bcc     :+
        inc     LINUM+1
:
        jmp     binary
.endproc

;;; ============================================================
;;; Text file

.proc text
        jsr     ReadByte
        bcs     Exit

        ora     #$80
        cmp     #$8D            ; CR?
        beq     :+
        cmp     #' '|$80        ; other control character?
        bcc     text            ; yes, ignore

:       jsr     COUT
        jmp     text
.endproc

;;; ============================================================
;;; BASIC file

.proc basic
        jsr     CROUT
        jsr     ReadByte        ; first two bytes are pointer to next line
        jsr     ReadByte
        bcs     Exit            ; EOF
        beq     Exit            ; null high byte = end of program

        ;; Line number
        jsr     ReadByte        ; line number hi
        bcs     Exit
        tax
        jsr     ReadByte        ; line number lo
        bcs     Exit
        jsr     LINPRT          ; print line number
        jsr     PrintSpace

        ;; Line contents: EOL, token, or character?
lloop:  jsr     ReadByte
        beq     basic           ; EOL
        bmi     token           ; token

cout:   ora     #$80
        jsr     COUT
        jmp     lloop

        ptr := $06

        ;; Token
token:  and     #$7F
        tax                     ; command index

        jsr     PrintSpace      ; space before token

        lda     #<TOKTABL
        sta     ptr
        lda     #>TOKTABL
        sta     ptr+1

        ;; Search through token table; last char
        ;; of each token has high bit set.
        ldy     #0
        cpx     #0
        beq     tloop2
tloop1: lda     (ptr),y
        bpl     :+
        dex                     ; last char, is next it?
        beq     found
:       inc     ptr             ; nope, advance to next
        bne     :+
        inc     ptr+1
:       bne     tloop1          ; always

found:  iny                     ; past last char of prev token
tloop2: lda     (ptr),y
        bmi     :+
        ora     #$80
        jsr     COUT
        iny
        bne     tloop2          ; always

:       jsr     COUT
        lda     #' '            ; space after token
        bne     cout            ; always

.endproc

;;; ============================================================

PrintSpace:
        ldy     #1
        ;; fall through

.proc PrintYSpaces
        lda     #' '|$80
:       jsr     COUT
        dey
        bne     :-
        rts
.endproc

;;; ============================================================

.proc Exit
        jsr     Close
        jsr     CROUT
        clc
        rts
.endproc

.proc ExitWithError
        pha
        jsr     Close
        pla
        sec
        rts
.endproc

.proc Close
        lda     #CLOSE
        jsr     GOSYSTEM
        rts
.endproc

;;; ============================================================
;;; Read a single byte; returns C=1 on EOF
;;; On error, exits.
.proc ReadByte
        lda     #READ
        jsr     GOSYSTEM
        bcs     :+
        lda     DATABUF
        rts

:       cmp     #5              ; END OF DATA?
        beq     :+              ; exit with C=1 for EOF

        tax                     ; stash error
        pla                     ; pop return from stack
        pla
        txa                     ; unstash error
        pha                     ; re-stash error
        jsr     Close
        pla                     ; unstash error

:       sec                     ; either w/ error or on EOF
        rts
.endproc

;;; ============================================================
