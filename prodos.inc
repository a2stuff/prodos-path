;;; ============================================================
;;; ProDOS MLI / Global Page

MLI             := $BF00
DEVNUM          := $BF30
DATE            := $BF90
DATELO          := $BF90
DATEHI          := $BF91
TIME            := $BF92
TIMELO          := $BF92
TIMEHI          := $BF93

GET_TIME        = $82
CREATE          = $C0
SET_FILE_INFO   = $C3
GET_FILE_INFO   = $C4
ON_LINE         = $C5
SET_PREFIX      = $C6
GET_PREFIX      = $C7
OPEN            = $C8
READ            = $CA
WRITE           = $CB
CLOSE           = $CC

.macro MLI_CALL cmd, params
        jsr     MLI
        .byte   cmd
        .addr   params
.endmacro

FT_TXT  = $04
FT_DIR  = $0F
FT_CMD  = $F0
FT_BAS  = $FC

ACCESS_D  = %10000000           ; Access: Destroy-Enable
ACCESS_RN = %01000000           ; Access: Rename-Enable
ACCESS_B  = %00100000           ; Access: Backup
ACCESS_I  = %00000100           ; Access: Invisible
ACCESS_W  = %00000010           ; Access: Write-Enable
ACCESS_R  = %00000001           ; Access: Read-Enable

;;; ============================================================
;;; BASIC.SYSTEM Global Page

EXTRNCMD        := $BE06        ; External command jmp vector
ERROUT          := $BE09        ; Error routine jmp vector

DEFSLT          := $BE3C        ; Default slot, set by 'S' parm
DEFDRV          := $BE3D        ; Default drive, set by 'D' parm

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

BADCALL         := $BE8B        ; convert MLI errors into BI equivalents

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

;;; Error Codes

BI_ERR_RANGE_ERROR              = 2
BI_ERR_NO_DEVICE_CONNECTED      = 3
BI_ERR_WRITE_PROTECTED          = 4
BI_ERR_END_OF_DATA              = 5
BI_ERR_PATH_NOT_FOUND           = 6
BI_ERR_VOLUME_DIR_NOT_FOUND     = 7 ; Also shows as PATH NOT FOUND
BI_ERR_IO_ERROR                 = 8
BI_ERR_DISK_FULL                = 9
BI_ERR_FILE_LOCKED              = 10
BI_ERR_INVALID_PARAMETER        = 11
BI_ERR_NO_BUFFERS_AVAILABLE     = 12
BI_ERR_FILE_TYPE_MISMATCH       = 13
BI_ERR_PROGRAM_TOO_LARGE        = 14
BI_ERR_NOT_DIRECT_COMMAND       = 15
BI_ERR_SYNTAX_ERROR             = 16
BI_ERR_DIRECTORY_FULL           = 17
BI_ERR_FILE_NOT_OPEN            = 18
BI_ERR_DUPLICATE_FILE_NAME      = 19
BI_ERR_FILE_BUSY                = 20
BI_ERR_FILES_STILL_OPEN         = 21
BI_ERR_DIRECT_COMMAND           = 22
