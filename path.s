;;; ============================================================
;;;
;;; PATH
;;;
;;; Build with: ca65 - https://cc65.github.io/doc/ca65.html
;;;
;;; ============================================================

        .org $2000

        .include "apple2.inc"
        .include "apple2.mac"
        .include "prodos.inc"

;;; ============================================================

INBUF           := $200         ; GETLN input buffer

;;; ============================================================
;;; Monitor ROM routines

CROUT   := $FD8E
COUT    := $FDED

MOVE    := $FE2C                ; call with Y=0
MOVE_SRC   := $3C
MOVE_END   := $3E
MOVE_DST   := $42


TOKEN_NAME_TABLE := $D0D0

CASE_MASK = $DF

;;; ============================================================
;;; Install the new command

        ;; TODO: Fail if Applesoft is not in ROM

        ;; Save previous external command address
        lda     EXTRNCMD+1
        sta     next_command
        lda     EXTRNCMD+2
        sta     next_command+1

        ;; Request a 2-page buffer
        lda     #2
        jsr     GETBUFR
        bcc     :+
        lda     #$C             ; NO BUFFERS AVAILABLE
        rts
:       sta     new_page        ; A = MSB of new page

        ;; Compute move delta in pages
        lda     #>handler
        sec
        sbc     new_page
        sta     page_delta

        ;; Relocatable routine is aligned to page boundary so only MSB changes
        ldx     relocation_table
:       ldy     relocation_table+1,x
        lda     handler,y
        clc
        adc     page_delta
        sta     handler,y
        dex
        bpl     :-

        ;; Relocate
        lda     #<handler
        sta     MOVE_SRC
        lda     #>handler
        sta     MOVE_SRC+1

        lda     #<handler_end
        sta     MOVE_END
        lda     #>handler_end
        sta     MOVE_END+1

        lda     #0
        sta     MOVE_DST
        lda     new_page
        sta     MOVE_DST+1
        ldy     #0
        jsr     MOVE

        ;; Install new address in external command address
        lda     new_page
        sta     EXTRNCMD+2
        lda     #0
        sta     EXTRNCMD+1

        ;; Complete
        rts

;;; ============================================================
;;; Command Handler
;;; ============================================================

        ;; Align handler to page boundary for easier
        ;; relocation
        .res    $2100 - *, 0

.proc handler
        ptr      := $06

        ;; Check for this command, character by character.
        ldx     #0
        ;;  TODO: skip leading spaces

nxtchr: lda     INBUF,x
        page_num6 := *+2         ; address needing updating
        jsr     to_upper

        page_num1 := *+2         ; address needing updating
        cmp     command_string,x
        bne     check_if_token
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

check_if_token:
        ;; Ensure it's alpha
        lda     INBUF
        page_num7 := *+2         ; address needing updating
        jsr     to_upper

        cmp     #'A'|$80
        bcc     not_ours
        cmp     #('Z'+1)|$80
        bcs     not_ours

        ;; Check if it's a BASIC token. Based on the AppleSoft BASIC source.

        ;; Point ptr at TOKEN_NAME_TABLE less one page (will advance below)
        lda     #<(TOKEN_NAME_TABLE-$100)
        sta     ptr
        lda     #>(TOKEN_NAME_TABLE-$100)
        sta     ptr+1

        ;; These start at "-1" and are immediately incremented
        ldx     #$FF            ; X = position in input line
        ldy     #$FF            ; (ptr),y offset TOKEN_NAME_TABLE

        ;; Match loop
mloop:  iny                     ; Advance through token table
        bne     :+
        inc     ptr+1
:       inx

        ;; Check for match
next_char:
        lda     INBUF,x         ; Next character
        page_num8 := *+2        ; address needing updating
        jsr     to_upper

        ;; NOTE: Does not skip over spaces, unlike BASIC tokenizer

        sec                     ; Compare by subtraction..
        sbc     (ptr),Y
        beq     mloop
        cmp     #$80          ; If only difference was the high bit
        beq     not_ours      ; then it's end-of-token -- and a match!

        ;; Otherwise, advance to next token
next_token:
        ldx     #0              ; Start next match at start of input line
        ;; TODO: skip leading spaces

@loop:  lda     (ptr),y         ; Scan table looking for a high bit set
        iny
        bne     :+
        inc     ptr+1
:       asl
        bcc     @loop           ; High bit clear, keep looking
        lda     (ptr),y         ; End of table?
        bne     next_char       ; Nope, check for a match

        ;; Not a keyword, so invoke

not_a_token:
        ;; TODO: Implement me!

not_ours:
        sec                     ; Signal failure...
        next_command := *+1
        jmp     $ffff           ; Execute next command in chain


;;; ============================================================
;;; ============================================================

execute:
        ;; Verify required arguments

        lda     FBITS
        and     #PBitsFlags::FN1 ; Filename?
        bne     set_path

;;; --------------------------------------------------
        ;; Show current path

        ldx     #0
        page_num3 := *+2         ; address needing updating
:       cpx     path_buffer
        beq     done
        page_num4 := *+2         ; address needing updating
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
        lda     VPATH1
        sta     ptr
        ldx     VPATH1+1
        sta     ptr+1

        ldy     #0
        lda     (ptr),y
        tay
:       lda     (ptr),y
        page_num5 := *+2         ; address needing updating
        sta     path_buffer,y
        dey
        bpl     :-
        clc
        rts

;;; ============================================================
;;; Helpers

.proc to_upper
        cmp     #'a'|$80
        bcc     skip
        and     #CASE_MASK
skip:   rts
.endproc

;;; ============================================================
;;; Data

command_string:
        scrcode "PATH"
        command_length  =  *-command_string

path_buffer:
        .res    65, 0

.endproc
        .assert .sizeof(handler) <= $200, error, "Must fit on two pages"
        handler_end := *-1
        next_command := handler::next_command

new_page:
        .byte   0
page_delta:
        .byte   0

relocation_table:
        .byte   5
        .byte   <handler::page_num1
        .byte   <handler::page_num2
        .byte   <handler::page_num3
        .byte   <handler::page_num4
        .byte   <handler::page_num5
        .byte   <handler::page_num6
        .byte   <handler::page_num7
        .byte   <handler::page_num8
