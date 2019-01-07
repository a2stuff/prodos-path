;;; ============================================================
;;; ProDOS MLI / Global Page

MLI             := $BF00

GET_FILE_INFO   = $C4
OPEN            = $C8
READ            = $CA
CLOSE           = $CC

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

VPATH1          := $BE6C        ; Pathname buffer

GOSYSTEM        := $BE70        ; Use instead of MLI

XRETURN         := $BE9E        ; Handy RTS

SSGINFO         := $BEB4        ; Get Info Parameter block
FIFILID         := $BEB8        ; (set size $A)

GETBUFR         := $BEF5
