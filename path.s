;;; ============================================================
;;;
;;; CHTYPE - File type changing command for ProDOS-8
;;;
;;; Install:
;;;          -CHTYPE         (from BASIC.SYSTEM prompt)
;;; Usage:
;;;          CHTYPE filename[,Ttype][,Aaux][,S#][,D#]
;;;
;;;  * filename can be relative or absolute path
;;;  * specify T$nn to set file type
;;;  * specify A$nnnn to set aux type info
;;;  * type can be BIN, SYS, TXT (etc) or $nn
;;;  * with neither T nor A option, prints current values
;;;
;;; Build with: ca65 - https://cc65.github.io/doc/ca65.html
;;;
;;; ============================================================

        .org $2000

;;; ============================================================

INBUF           := $200         ; GETLN input buffer

;;; ============================================================
;;; Monitor ROM routines

CROUT   := $FD8E
PRBYTE  := $FDDA
COUT    := $FDED

;;; ============================================================
;;; ProDOS MLI / Global Page

SET_FILE_INFO   = $C3
GET_FILE_INFO   = $C4

DATE            := $BF90

;;; ============================================================
;;; BASIC.SYSTEM Global Page

EXTRNCMD        := $BE06        ; External command jmp vector
ERROUT          := $BE09        ; Error routine jmp vector
XTRNADDR        := $BE50        ; Ext cmd implementation addr

XLEN            := $BE52        ; Length of command string minus 1
XCNUM           := $BE53        ; Command number (ext cmd = 0).

PBITS           := $BE54        ; Command parameter bits
FBITS           := $BE56        ; Found parameter bits

.enum PBitsFlags
        ;; PBITS
        PFIX    = $80           ; Prefix needs fetching
        SLOT    = $40           ; No parameters to be processed
        RRUN    = $20           ; Command only valid during program
        FNOPT   = $10           ; Filename is optional
        CRFLG   = $08           ; CREATE allowed
        T       = $04           ; File type
        FN2     = $02           ; Filename '2' for RENAME
        FN1     = $01           ; Filename expected

        ;; PBITS+1
        AD      = $80           ; Address
        B       = $40           ; Byte
        E       = $20           ; End address
        L       = $10           ; Length
        LINE    = $08           ; '@' line number
        SD      = $04           ; Slot and drive numbers
        F       = $02           ; Field
        R       = $01           ; Record

        ;; Setting SD in PBITS+1 enables desired automatic behavior: if
        ;; a relative path is given, an appropriate prefix is computed,
        ;; using S# and D# options if supplied. Without this, absolute
        ;; paths must be used if no prefix is set.
.endenum

VADDR           := $BE58        ; Address parameter
VSLOT           := $BE61        ; Slot parameter
VTYPE           := $BE6A        ; Type parameter
VPATH1          := $BE6C        ; Pathname buffer

GOSYSTEM        := $BE70        ; Use instead of MLI

SSGINFO         := $BEB4        ; Get/Set Info Parameter block
FIFILID         := $BEB8        ; (set size to set=7 or get=$A)
FIAUXID         := $BEB9
FIMDATE         := $BEBE
GETBUFR         := $BEF5
;;; ============================================================

        ;; Save previous external command address
        lda     EXTRNCMD+1
        sta     next_command
        lda     EXTRNCMD+2
        sta     next_command+1

        ;; Request a 1-page buffer
        lda     #1
        jsr     GETBUFR
        bcc     :+
        lda     #$C             ; NO BUFFERS AVAILABLE
        rts
:
        ;; A = MSB of new page - update absolute addresses
        ;; (aligned to page boundary so only MSB changes)
        sta     page_num1
        sta     page_num2
        sta     page_num3

        ;; Install new address in external command address
        sta     EXTRNCMD+2
        lda     #0
        sta     EXTRNCMD+1

        ;; Relocate
        ldx     #0
:       lda     handler,x
        page_num3 := *+2
        sta     $2100,x         ; self-modified
        inx
        bne     :-

        ;; Complete
        rts

;;; ============================================================
;;; Command Handler
;;; ============================================================

        ;; Align handler to page boundary for easier
        ;; relocation
        .res    $2100 - *, 0

.proc handler

        ;; Check for this command, character by character.
        ldx     #0
nxtchr: lda     INBUF,x

        and     #$7F            ; Convert to ASCII
        cmp     #'a'            ; Convert to upper-case
        bcc     :+
        cmp     #'z'+1
        bcs     :+
        and     #$DF

        page_num1 := *+2         ; address needing updating
:       cmp     command_string,x
        bne     not_ours
        inx
        cpx     #command_length
        bne     nxtchr

        ;; A match - indicate end of command string for BI's parser.
        lda     #command_length-1
        sta     XLEN

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

not_ours:
        sec                     ; Signal failure...
        next_command := *+1
        jmp     $ffff           ; Execute next command in chain

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
        lda     VTYPE
        jsr     PRBYTE
        jsr     CROUT

        lda     #'A'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT
        lda     #'$'|$80
        jsr     COUT
        lda     VADDR+1
        jsr     PRBYTE
        lda     VADDR
        jsr     PRBYTE
        jsr     CROUT

        clc
        rts

;;; ============================================================
;;; Data

command_string:
        .byte   "CHTYPE"        ; Command string
        command_length  =  *-command_string

.endproc
        .assert .sizeof(handler) <= $100, error, "Must fit on one page"
        page_num1 := handler::page_num1
        page_num2 := handler::page_num2
        next_command := handler::next_command
