;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Macros
;-----------------------------------------------------------------------------


.macro  StringInv s
        .repeat .strlen(s), I
        .byte   .strat(s, I) & $3f
        .endrep
.endmacro

.macro  StringHi s
        .repeat .strlen(s), I
        .byte   .strat(s, I) | $80
        .endrep
.endmacro

.macro  StringHiBG s,bg
        .repeat .strlen(s), I
        .if(.strat(s,I) = bg)
        .byte 0
        .else
        .byte   .strat(s, I) | $80
        .endif
        .endrep
.endmacro

