;;; ============================================================
;;; Memory locations

INBUF   := $200

;;; ============================================================
;;; Monitor ROM routines

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

TOKEN_NAME_TABLE := $D0D0
