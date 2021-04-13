;;; ============================================================
;;; ProDOS MLI / Global Page

MLI             := $BF00
DATE            := $BF90

CREATE          = $C0
SET_FILE_INFO   = $C3
GET_FILE_INFO   = $C4
ON_LINE         = $C5
OPEN            = $C8
READ            = $CA
WRITE           = $CB
CLOSE           = $CC

.macro MLI_CALL cmd, params
        jsr     MLI
        .byte   cmd
        .addr   params
.endmacro

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
VBYTE           := $BE5A        ; Byte parameter
VSLOT           := $BE61        ; Slot parameter
VTYPE           := $BE6A        ; Type parameter
VPATH1          := $BE6C        ; Pathname 1 buffer
VPATH2          := $BE6E        ; Pathname 2 buffer (RENAME)

GOSYSTEM        := $BE70        ; Use instead of MLI


XRETURN         := $BE9E        ; Handy RTS

SCREATE         := $BEA0        ; CREATE Parameter block
CRACESS         := $BEA3        ; $C1 if directory create
CRFILID         := $BEA4
CRAUXID         := $BEA5
CRFKIND         := $BEA7
SSGPREFX        := $BEAC
SDSTROY         := $BEAC
SRECNAME        := $BEAF

SSGINFO         := $BEB4        ; GET_FILE_INFO Parameter block
FIACESS         := $BEB7        ; Access used by lock/unlock
FIFILID         := $BEB8        ; FILE ID is type specifier
FIAUXID         := $BEB9        ; Aux_id is used for load addr and record length
FIFKIND         := $BEBB        ; Identifies trees vs. directories
FIBLOKS         := $BEBC        ; Used by CAT commands for root
FIMDATE         := $BEBE

SONLINE         := $BEC6
SSETMKR         := $BEC6
SGETMRK         := $BEC6
SSETEOF         := $BEC6
SGETEOF         := $BEC6
SSETBUF         := $BEC6
SGETBUF         := $BEC6
SBUFREF         := $BEC7
SREFNUM         := $BEC7
SUNITNUM        := $BEC7
SDATPTR         := $BEC8
SMARK           := $BEC8
SEOF            := $BEC8
SBUFADR         := $BEC8
SOPEN           := $BECB        ; OPEN
OSYSBUF         := $BECE
OREFNUM         := $BED0

SREAD           := $BED5        ; READ
SWRITE          := $BED5        ; WRITE
RWREFNUM        := $BED6
RWDATA          := $BED7
RWCOUNT         := $BED9
RWTRANS         := $BEDB

SCLOSE          := $BEDD        ; CLOSE
SFLUSH          := $BEDD        ; FLUSH
CFREFNUM        := $BEDE
CCCSPARE        := $BEDF

GETBUFR         := $BEF5
FREEBUFR        := $BEF8
RSHIMEM         := $BEFB
