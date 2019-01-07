;;; ============================================================
;;;
;;; PATH
;;;
;;; Build with: ca65 - https://cc65.github.io/doc/ca65.html
;;;
;;; ============================================================

        .org $2000

        .include "prodos.inc"

;;; ============================================================

INBUF           := $200         ; GETLN input buffer

;;; ============================================================
;;; Monitor ROM routines

CROUT   := $FD8E
COUT    := $FDED

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
        ldx     relocation_table
:       ldy     relocation_table+1,x
        sta     handler,y
        dex
        bpl     :-

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
        bne     not_path
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

        ;; Set accepted parameter flags (Name, Slot/Drive)

        lda     #PBitsFlags::FN1 ; Filename
        sta     PBITS

        lda     #PBitsFlags::SD ; Slot & Drive handling
        sta     PBITS+1

        clc                     ; Success (so far)
        rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

not_path:


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
        bne     set_path

;;; --------------------------------------------------
        ;; Show current path

        ldx     #0
        page_num3 := *+2
:       cpx     path_buffer
        beq     done
        page_num4 := *+2
        lda     path_buffer+1,x
        ora     #$80
        jsr     COUT
        inx
        bpl     :-

        jsr     CROUT
done:   clc
        rts

;;; --------------------------------------------------
        ;; Set path
set_path:
        ptr := $06
        lda     VPATH1
        sta     ptr
        ldx     VPATH1+1
        sta     ptr+1

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        page_num5 := *+2
        sta     path_buffer,y
        dey
        bpl     :-
        clc
        rts

;;; ============================================================
;;; Data

command_string:
        .byte   "PATH"        ; Command string
        command_length  =  *-command_string

path_buffer:
        .res    65, 0

.endproc
        .assert .sizeof(handler) <= $100, error, "Must fit on one page"
        next_command := handler::next_command

relocation_table:
        .byte   5
        .byte   <handler::page_num1
        .byte   <handler::page_num2
        .byte   <handler::page_num3
        .byte   <handler::page_num4
        .byte   <handler::page_num5
