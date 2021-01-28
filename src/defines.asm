;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Predefined memory/ROM locations
;
; Mostly added as needed
; Tried to use standard names if known
;-----------------------------------------------------------------------------

; Grab ca65 defines to start with and then add missing ones
.include "apple2.inc"

; Memory map
HGRPAGE1        := $2000
HGRPAGE2        := $4000

; Soft switches
SPEAKER         := $C030
TEXTMODE 		:= $C01A	; Bit 7 is 1 if text mode

; ROM routines
GR 				:= $F390	; Low-res mixed graphics mode
TEXT            := $F399    ; Text-mode
HGR             := $F3E2    ; Turn on hi-res mode, page 1 mixed mode, clear    
HGR2            := $F3D8    ; Turn on hi-res mode, page 2, clear
PRBYTE 			:= $FDDA	; Print A as a 2-digit hex
PRINTXY			:= $F940	; Print X(low) Y(high) as 4-digit hex
VTAB 			:= $FC22	; Move the cursor to line CV
HOME            := $FC58    ; Clear text screen
CR 				:= $FC62 	; Output carriage return
RDKEY           := $FD0C    ; Read 1 char
COUT            := $FDED    ; Output a character
MON             := $FF65    ; Enter monitor (BRK)
MONZ            := $FF69    ; Enter monitor
WAIT 			:= $FCA8	; Wait 0.5*(26 + 27*A + 5*A*A) microseconds

; Keyboard
KEY_LEFT		= $88
KEY_DOWN		= $8A
KEY_UP			= $8B
KEY_RIGHT		= $95
KEY_ESC 		= $9B
KEY_SPACE       = $A0