;;; ============================================================
;;; Memory locations

INBUF   := $200

;;; ============================================================
;;; Zero Page

LINUM   := $1B

;;; ============================================================
;;; I/O Locations

SPKR    := $C030

;;; ============================================================
;;; Monitor ROM routines

PRTAX   := $F941
WAIT    := $FCA8
CROUT   := $FD8E
PRBYTE  := $FDDA
COUT    := $FDED

MOVE    := $FE2C                ; call with Y=0
MOVE_SRC   := $3C
MOVE_END   := $3E
MOVE_DST   := $42

BELL    := $FF3A

;;; ============================================================
;;; Applesoft ROM locations

TOKTABL := $D0D0
LINPRT  := $ED24
