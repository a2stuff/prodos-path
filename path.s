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
;;; * 3 pages - code, path buffers

;;; TODO:
;;;  * Support multi-segment path (e.g. /hd/bin:/hd/extras/bin)

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

        ;; Request a buffer for handler.
        lda     #handler_pages
        jsr     GETBUFR
        bcc     :+
        lda     #$C             ; NO BUFFERS AVAILABLE
        rts
:       sta     new_page        ; A = MSB of new page

        ;; Reserve buffer permanently.
        ;; ProDOS Technical Note #9: Buffer Management Using BASIC.SYSTEM
        lda     RSHIMEM
        sec
        sbc     #handler_pages
        sta     RSHIMEM

        ;; Compute move delta in pages
        lda     new_page
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
        page_num9 := *+2         ; address needing updating
        jsr     skip_leading_spaces

        page_num6 := *+2         ; address needing updating
nxtchr: jsr     to_upper_ascii

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

        ;; Set accepted parameter flags (optional name)
        lda     #PBitsFlags::FNOPT | PBitsFlags::FN1
        sta     PBITS
        lda     #0
        sta     PBITS+1

        clc                     ; Success (so far)
        rts                     ; Return to BASIC.SYSTEM

;;; ============================================================

check_if_token:
        ;; Is a PATH set?
        page_num17 := *+2       ; address needing updating
        lda     path_buffer
        beq     not_ours

        page_num10 := *+2       ; address needing updating
        jsr     skip_leading_spaces
        page_num7 := *+2        ; address needing updating
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

        ;; These are immediately incremented
        dex
        ldy     #$FF            ; (ptr),y offset TOKEN_NAME_TABLE

        ;; Match loop
mloop:  iny                     ; Advance through token table
        bne     :+
        inc     ptr+1
:       inx

        ;; Check for match
next_char:
        page_num8 := *+2        ; address needing updating
        jsr     to_upper_ascii  ; Next character

        ;; NOTE: Does not skip over spaces, unlike BASIC tokenizer

        sec                     ; Compare by subtraction..
        sbc     (ptr),Y
        beq     mloop
        cmp     #$80          ; If only difference was the high bit
        beq     not_ours      ; then it's end-of-token -- and a match!

        ;; Otherwise, advance to next token
next_token:
        page_num12 := *+2       ; address needing updating
        jsr     skip_leading_spaces
sloop:  lda     (ptr),y         ; Scan table looking for a high bit set
        iny
        bne     :+
        inc     ptr+1
:       asl
        bcc     sloop           ; High bit clear, keep looking
        lda     (ptr),y         ; End of table?
        bne     next_char       ; Nope, check for a match
        beq     maybe_invoke

not_ours:
        sec                     ; Signal failure...
        next_command := *+1
        jmp     $ffff           ; Execute next command in chain


;;; ============================================================

maybe_invoke:
        lda     VPATH1
        sta     ptr
        lda     VPATH1+1
        sta     ptr+1

        ;; Compose path
        ldx     #0
        ldy     #1
        page_num11 := *+2         ; address needing updating
:       lda     path_buffer+1,x
        inx
        sta     (ptr),y
        iny
        page_num14 := *+2         ; address needing updating
        cpx     path_buffer
        bne     :-

        lda     #'/'
        sta     (ptr),y
        iny

        page_num15 := *+2         ; address needing updating
        jsr     skip_leading_spaces
        page_num16 := *+2         ; address needing updating
:       jsr     to_upper_ascii
        cmp     #'.'
        beq     ok
        cmp     #'0'
        bcc     notok
        cmp     #'9'+1
        bcc     ok
        cmp     #'A'
        bcc     notok
        cmp     #'Z'+1
        bcs     notok

ok:     sta     (ptr),y
        iny
        inx
        cpx     #65             ; Maximum path length+1
        bcc     :-
        bcs     fail_gfi

notok:  dey
        tya
        ldy     #0
        sta     (ptr),y

        ;; Check to see if path exists.
        lda     #$A             ; param length
        sta     SSGINFO
        MLI_CALL GET_FILE_INFO, SSGINFO
        beq     :+

fail_gfi:
        sec                     ; no such file - signal it's not us
        rts

        ;; Check to see if type is CMD.
:       lda     FIFILID
        cmp     #$F0            ; CMD
        bne     fail_gfi        ; wrong type - ignore it

        ;; Tell BASIC.SYSTEM it was handled.
        lda     #0
        sta     XCNUM
        sta     PBITS
        sta     PBITS+1
        lda     #$FF            ; TODO: Signal how much of input was consumed (all?)
        sta     XLEN
        lda     #<XRETURN
        sta     XTRNADDR
        lda     #>XRETURN
        sta     XTRNADDR+1

        ;; Reserve buffer for I/O
        lda     #4
        jsr     GETBUFR
        bcc     :+
        lda     #$C             ; NO BUFFERS AVAILABLE
        rts
:       sta     OSYSBUF+1

        ;; Now try to open/read/close and invoke it
        MLI_CALL OPEN, SOPEN
        bne     fail_load

        lda     OREFNUM
        sta     RWREFNUM
        sta     CFREFNUM

        lda     #<cmd_load_addr
        sta     RWDATA
        lda     #>cmd_load_addr
        sta     RWDATA+1
        lda     #<max_cmd_size
        sta     RWCOUNT
        lda     #>max_cmd_size
        sta     RWCOUNT+1


        MLI_CALL READ, SREAD
        bne     fail_load

        ;; CLOSE call trashes lower bytes of INBUF, so stash it.
        ldx     #$7F
:       lda     INBUF,x
        sta     INBUF+$80,x
        dex
        bpl     :-

        MLI_CALL CLOSE, SCLOSE
        jsr     FREEBUFR

        ;; Restore it.
        ldx     #$7F
:       lda     INBUF+$80,x
        sta     INBUF,x
        dex
        bpl     :-

        ;; Invoke command
        jsr     cmd_load_addr

        clc                     ; success
        rts                     ; Return to BASIC.SYSTEM

fail_load:
        jsr     FREEBUFR
        lda     #8              ; I/O ERROR - TODO: is this used???
        sec
        rts

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

;;; Returns INBUF,x with high bit stripped and up-cased
;;; (also converts {|}~DEL to [\]^_ but that's okay)

.proc to_upper_ascii
        lda     INBUF,x
        and     #$7F
        cmp     #'a'
        bcc     skip
        and     #CASE_MASK
skip:   rts
.endproc

;;; Returns with X pointing at first non-space in INBUF,
;;; and that character loaded in A.

.proc skip_leading_spaces
        ldx     #$FF
:       inx
        lda     INBUF,x
        cmp     #' '|$80
        beq     :-
        rts
.endproc

;;; ============================================================
;;; Data

command_string:
        .byte "PATH"
        command_length  =  *-command_string

path_buffer:
        .res    65, 0

.endproc
        handler_end := *-1
        handler_pages = (.sizeof(handler) + $FF) / $100
        next_command := handler::next_command

;;; ============================================================
;;; Installation Data

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
        .addr   handler::page_num14
        .addr   handler::page_num15
        .addr   handler::page_num16
        .addr   handler::page_num17
        table_end := *
