;;; ============================================================
;;;
;;; PATH
;;;
;;; Build with: ca65 - https://cc65.github.io/doc/ca65.html
;;;
;;; ============================================================

        .org $2000

        .include "apple2.inc"
        .include "prodos.inc"

;;; ============================================================
;;;
;;; Installed command memory structure:
;;; * 2 pages - code, path buffer
;;; * 4 pages - I/O buffer

;;; TODO:
;;;  * Dynamically allocate I/O buffer
;;;  * Support multi-segment path (e.g. /hd/bin:/hd/extras/bin
;;;  * Fail install if on an Integer BASIC machine
;;;  * Skip leading spaces

;;; ============================================================

cmd_load_addr := $4000
max_cmd_size   = $2000

;;; ============================================================
;;; Monitor ROM routines/locations

INBUF           := $200         ; GETLN input buffer

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

.proc installer
        ptr := $06

        ;; Save previous external command address
        lda     EXTRNCMD+1
        sta     next_command
        lda     EXTRNCMD+2
        sta     next_command+1

        ;; Request a 6-page buffer - 2 pages for handler,
        ;; 4 pages for I/O buffer.
        lda     #6
        jsr     GETBUFR
        bcc     :+
        lda     #$C             ; NO BUFFERS AVAILABLE
        rts
:       sta     new_page        ; A = MSB of new page

        ;; Compute move delta in pages
        sec
        sbc     #>handler
        sta     page_delta

        ;; Relocatable routine is aligned to page boundary so only MSB changes
        ldx     #0
:       txa
        asl
        tay
        lda     relocation_table+1,y
        sta     ptr
        lda     relocation_table+2,y
        sta     ptr+1

        lda     (ptr)
        clc
        adc     page_delta
        sta     (ptr)
        inx
        cpx     relocation_table
        bne     :-

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
.endproc

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
        jsr     to_upper_ascii

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

        lda     #PBitsFlags::FNOPT | PBitsFlags::FN1 ; Filename (optional)
        sta     PBITS

        lda     #PBitsFlags::SD ; Slot & Drive handling
        sta     PBITS+1

        clc                     ; Success (so far)
        rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

check_if_token:
        ;; Is a PATH set?
        page_num18 := *+2         ; address needing updating
        lda     path_buffer
        beq     not_ours

        ;; Ensure it's alpha
        lda     INBUF
        page_num7 := *+2         ; address needing updating
        jsr     to_upper_ascii

        cmp     #'A'
        bcc     not_ours
        cmp     #'Z'+1
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
        jsr     to_upper_ascii

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
        beq     maybe_invoke

not_ours:
        sec                     ; Signal failure...
        next_command := *+1
        jmp     $ffff           ; Execute next command in chain


.proc get_file_info_params
param_count:    .byte   $A
pathname:       .addr   command_path_buffer
access:         .byte   0
file_type:      .byte   0
aux_type:       .word   0
storage_type:   .byte   0
blocks_used:    .word   0
mod_date:       .word   0
mod_time:       .word   0
create_date:    .word   0
create_time:    .word   0
.endproc
        page_num9 := get_file_info_params::pathname+1

.proc open_params
param_count:    .byte   3
pathname:       .addr   command_path_buffer
io_buffer:      .addr   handler + $200
ref_num:        .byte   0
.endproc
        page_num10 := open_params::pathname+1
        page_num11 := open_params::io_buffer+1

.proc read_params
param_count:    .byte   4
ref_num:        .byte   0
data_buffer:    .addr   cmd_load_addr
request_count:  .word   max_cmd_size
trans_count:    .word   0
.endproc

.proc close_params
param_count:    .byte   1
ref_num:        .byte   0
.endproc

maybe_invoke:
        ;; Compose path
        ldx     #0
        page_num12 := *+2         ; address needing updating
:       lda     path_buffer+1,x
        page_num13 := *+2         ; address needing updating
        sta     command_path_buffer+1,x
        inx
        page_num14 := *+2         ; address needing updating
        cpx     path_buffer
        bne     :-

        lda     #'/'
        page_num15 := *+2         ; address needing updating
        sta     command_path_buffer+1,x
        inx

        ldy     #0
:       lda     INBUF,y
        and     #$7F
        cmp     #'.'
        beq     ok
        cmp     #'0'
        bcc     notok
        cmp     #'9'+1
        bcc     ok
        cmp     #'A'
        bcc     notok
        cmp     #'Z'+1
        bcc     ok
        cmp     #'a'
        bcc     notok
        cmp     #'z'+1
        bcs     notok

        page_num16 := *+2         ; address needing updating
ok:     sta     command_path_buffer+1,x
        inx
        iny
        bne     :-

        page_num17 := *+2         ; address needing updating
notok:  stx     command_path_buffer

        jsr     MLI
        .byte   GET_FILE_INFO
        page_num19 := *+1
        .addr   get_file_info_params
        beq     :+
        sec                     ; no such file - signal it's not us
        rts

        page_num23 := *+2
:       lda     get_file_info_params::file_type
        cmp     #$F0            ; CMD
        beq     :+
        sec                     ; wrong type - ignore it
        rts

        ;; Tell BASIC.SYSTEM it was handled.
:       lda     #0
        sta     XCNUM
        sta     PBITS
        sta     PBITS+1
        lda     #$FF            ; TODO: Signal how much of input was consumed (all?)
        sta     XLEN
        lda     #<XRETURN
        sta     XTRNADDR
        lda     #>XRETURN
        sta     XTRNADDR+1

        ;; Now try to open/read/close and invoke it
        jsr     MLI
        .byte   OPEN
        page_num20 := *+1
        .addr   open_params
        beq     :+
        lda     #8              ; I/O ERROR - TODO: is this used???
        sec
        rts

        page_num24 := *+2
:       lda     open_params::ref_num
        page_num25 := *+2
        sta     read_params::ref_num
        page_num26 := *+2
        sta     close_params::ref_num
        jsr     MLI
        .byte   READ
        page_num21 := *+1
        .addr   read_params
        beq     :+
        lda     #8              ; I/O ERROR - TODO: is this used???
        sec
        rts

:       jsr     MLI
        .byte   CLOSE
        page_num22 := *+1
        .addr   close_params

        ;; Invoke command
        jsr     cmd_load_addr

        clc                     ; Success
        rts                     ; Return to BASIC.SYSTEM


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
        lda     VPATH1+1
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

.proc to_upper_ascii
        and     #$7F
        cmp     #'a'
        bcc     skip
        and     #CASE_MASK
skip:   rts
.endproc

;;; ============================================================
;;; Data

command_string:
        .byte "PATH"
        command_length  =  *-command_string

path_buffer:
        .res    65, 0

command_path_buffer:
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
        .byte   (table_end - *) / 2
        .addr   handler::page_num1
        .addr   handler::page_num2
        .addr   handler::page_num3
        .addr   handler::page_num4
        .addr   handler::page_num5
        .addr   handler::page_num6
        .addr   handler::page_num7
        .addr   handler::page_num8
        .addr   handler::page_num9
        .addr   handler::page_num10
        .addr   handler::page_num11
        .addr   handler::page_num12
        .addr   handler::page_num13
        .addr   handler::page_num14
        .addr   handler::page_num15
        .addr   handler::page_num16
        .addr   handler::page_num17
        .addr   handler::page_num18
        .addr   handler::page_num19
        .addr   handler::page_num20
        .addr   handler::page_num21
        .addr   handler::page_num22
        .addr   handler::page_num23
        .addr   handler::page_num24
        .addr   handler::page_num25
        .addr   handler::page_num26
        table_end := *