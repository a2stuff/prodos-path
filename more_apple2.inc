;;; ============================================================
;;; Memory locations

INBUF   := $200

;;; ============================================================
;;; Zero Page

LINUM   := $1B

;;; ============================================================
;;; Monitor ROM routines


PRTAX   := $F941
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
