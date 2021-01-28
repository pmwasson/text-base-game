;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Entry for text game contest
;
; Use text-base sprite and page flipping
;
;
; Screen Layout:
;
;  00  ########################################
;  01  #                                      # 
;  02  ########################################
;  03  [------][------][------][------][------]
;  04  [      ][      ][      ][      ][      ]
;  05  [      ][      ][      ][      ][      ]
;  06  [      ][      ][      ][      ][      ]
;  07  [      ][      ][      ][      ][      ]
;  08  [------][------][------][------][------]
;  09  [------][------][------][------][------]
;  10  [      ][      ][      ][      ][      ]
;  11  [      ][      ][      ][      ][      ]
;  12  [      ][      ][      ][      ][      ]
;  13  [      ][      ][      ][      ][      ]
;  14  [------][------][------][------][------]
;  15  [------][------][------][------][------]
;  16  [      ][      ][      ][      ][      ]
;  17  [      ][      ][      ][      ][      ]
;  18  [      ][      ][      ][      ][      ]
;  19  [      ][      ][      ][      ][      ]
;  20  [------][------][------][------][------]
;  21  ########################################
;  22  #                                      # 
;  23  ########################################
;
;  8x6 tiles with top/bottom boarders


;------------------------------------------------
; Constants
;------------------------------------------------

.include "defines.asm"

TILE_HEIGHT = 	6
TILE_WIDTH  = 	8

;------------------------------------------------
; Zero page usage
;------------------------------------------------

tilePtr0    :=  $60     ; Tile pointer
tilePtr1    :=  $61
screenPtr0  :=  $52     ; Screen pointer
screenPtr1  :=  $53


.segment "CODE"
.org    $2000


.proc main

	; clear screen
	jsr     HOME

	; Turn on alternate characters
	sta 	ALTCHARSETON

	; set-up screen
	jsr		fill_screen
	jsr		draw_boarders

	; test tile

	lda 	#3
	sta 	tileY
	lda 	#0
	sta 	tileX

	lda 	#1
	jsr 	draw_tile

	lda 	#8
	sta 	tileX
	lda 	#1
	jsr 	draw_tile

	lda 	#16
	sta 	tileX
	lda 	#1
	jsr 	draw_tile

	lda 	#24
	sta 	tileX
	lda 	#1
	jsr 	draw_tile

	lda 	#32
	sta 	tileX
	lda 	#1
	jsr 	draw_tile


	lda 	#9
	sta 	tileY
	lda 	#0
	sta 	tileX

	lda 	#1
	jsr 	draw_tile

	lda 	#8
	sta 	tileX
	lda 	#1
	jsr 	draw_tile

	lda 	#16
	sta 	tileX
	lda 	#1
	jsr 	draw_tile

	lda 	#24
	sta 	tileX
	lda 	#1
	jsr 	draw_tile

	lda 	#32
	sta 	tileX
	lda 	#1
	jsr 	draw_tile


    ; exit
    jmp		MONZ

.endproc

;-----------------------------------------------------------------------------
; fill_screen
;-----------------------------------------------------------------------------

.proc fill_screen
	ldx		#0
loop:
	lda 	#$a0
	sta		$400,x
	sta		$480,x
	sta		$500,x
	sta		$580,x
	sta		$600,x
	sta		$680,x
	sta		$700,x
	sta		$780,x
	inx	
	cpx		#40*3
	bne		loop
	rts
.endproc

;-----------------------------------------------------------------------------
; draw_boarders
;-----------------------------------------------------------------------------
.proc draw_boarders
	ldx		#0
loop:
	lda 	#$20
	sta		$0400,x 			; row 0
	sta		$0500,x 			; row 2
	sta		$06D0,x 			; row 21
	sta		$07D0,x 			; row 23
	inx
	cpx		#40
	bne 	loop
	rts
.endproc


;-----------------------------------------------------------------------------
; draw_tile
;-----------------------------------------------------------------------------
; Tiles are 48 bytes, but pad to 64 so no page crossings

.proc draw_tile
    ; calculate tile pointer
    sta     temp            ; Save a copy of A

    ror
    ror
    ror                     ; Multiply by 64
    and 	#$c0
    clc
    adc     #<tileSheet
    sta     tilePtr0

    lda     #0
    adc     #>tileSheet
    sta     tilePtr1
    lda     temp 
    lsr
    lsr                     ; Divide by 4

    clc
    adc     tilePtr1
    sta     tilePtr1

    ; copy tileY
    lda 	tileY
    sta		temp

    ; 8 rows
    ldx 	#TILE_HEIGHT

loopy:
    ; calculate screen pointer
    ldy     temp 			; copy of tileY
    lda     tileX
    clc
    adc     lineOffset,y    ; + lineOffset
    sta     screenPtr0    
    lda     linePage,y
    sta     screenPtr1

	; set 8 bytes
    ldy     #TILE_WIDTH-1
loopx:
    lda     (tilePtr0),y
    beq 	skip
    sta     (screenPtr0),y
skip:
    dey
    bpl 	loopx

    ; assumes aligned such that there are no page crossing
    lda 	tilePtr0
    adc 	#TILE_WIDTH
    sta 	tilePtr0

    inc 	temp 		; next line

    dex
    bne 	loopy

    rts    

; locals
temp:		.byte   0

.endproc


; Libraries
;-----------------------------------------------------------------------------

; add utilies
.include "inline_print.asm"


; Globals
;-----------------------------------------------------------------------------

tileX:		.byte 	0
tileY:		.byte 	0

; Data
;-----------------------------------------------------------------------------

lineOffset:
    .byte   <$0400
    .byte   <$0480
    .byte   <$0500
    .byte   <$0580
    .byte   <$0600
    .byte   <$0680
    .byte   <$0700
    .byte   <$0780
    .byte   <$0428
    .byte   <$04A8
    .byte   <$0528
    .byte   <$05A8
    .byte   <$0628
    .byte   <$06A8
    .byte   <$0728
    .byte   <$07A8
    .byte   <$0450
    .byte   <$04D0
    .byte   <$0550
    .byte   <$05D0
    .byte   <$0650
    .byte   <$06D0
    .byte   <$0750
    .byte   <$07D0

linePage:
    .byte   >$0400
    .byte   >$0480
    .byte   >$0500
    .byte   >$0580
    .byte   >$0600
    .byte   >$0680
    .byte   >$0700
    .byte   >$0780
    .byte   >$0428
    .byte   >$04A8
    .byte   >$0528
    .byte   >$05A8
    .byte   >$0628
    .byte   >$06A8
    .byte   >$0728
    .byte   >$07A8
    .byte   >$0450
    .byte   >$04D0
    .byte   >$0550
    .byte   >$05D0
    .byte   >$0650
    .byte   >$06D0
    .byte   >$0750
    .byte   >$07D0



tileSheet:

; checker board
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; grass
	.byte 	$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7
	.byte 	$b8,$b9,$b2,$b3,$b4,$b5,$b6,$b7
	.byte 	$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7
	.byte 	$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7
	.byte 	$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7
	.byte 	$b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding