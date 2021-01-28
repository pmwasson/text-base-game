;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Entry for text game contest
;
; Use text-base sprites
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
;  11  [      ][      ][  :)  ][      ][      ]
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

TILE_HEIGHT 	= 6
TILE_WIDTH  	= 8
SCREEN_WIDTH 	= 5
SCREEN_HEIGHT 	= 4
SCREEN_OFFSET   = 0
MAP_WIDTH 		= 16
MAP_HEIGHT 		= 16
CACHE_UP 		= 2+5
CACHE_LEFT 		= 6+5
CACHE_RIGHT 	= 8+5
CACHE_DOWN 		= 12+5

;------------------------------------------------
; Zero page usage
;------------------------------------------------

tilePtr0    :=  $50     ; Tile pointer
tilePtr1    :=  $51
screenPtr0  :=  $52     ; Screen pointer
screenPtr1  :=  $53
mapPtr0     :=  $54 	; Map pointer
mapPtr1     :=  $55

.segment "CODE"
.org    $2000


.proc main
	; clear screen
	jsr     HOME

	; Allow other characters
	sta 	ALTCHARSETON

	; set-up screen
	jsr		fill_screen
	jsr		draw_boarders

	; set starting position
	lda 	#(MAP_WIDTH-SCREEN_WIDTH)/2
	sta 	mapX
	lda 	#MAP_HEIGHT-SCREEN_HEIGHT
	sta 	mapY


gameLoop:
	jsr		draw_map

waitForKey:
	lda		KBD
	bpl		waitForKey
	sta		KBDSTRB

    ;------------------
    ; W = Up
    ;------------------
    cmp     #$80 | 'W'
    bne     :+
    ldx 	#CACHE_UP
    lda 	mapCache,x
    bne		waitForKey
    dec 	mapY
    jmp     gameLoop
:

    ;------------------
    ; S = Down
    ;------------------
    cmp     #$80 | 'S'
    bne     :+
    ldx 	#CACHE_DOWN
    lda 	mapCache,x
    bne		waitForKey
    inc 	mapY
    jmp     gameLoop
:

    ;------------------
    ; A = Left
    ;------------------
    cmp     #$80 | 'A'
    bne     :+
    ldx 	#CACHE_LEFT
    lda 	mapCache,x
    bne		waitForKey
    dec 	mapX
    jmp     gameLoop
:

    ;------------------
    ; D = Right
    ;------------------
    cmp     #$80 | 'D'
    bne     :+
    ldx 	#CACHE_RIGHT
    lda 	mapCache,x
    bne		waitForKey
    inc 	mapX
    jmp     gameLoop
:

    ;------------------
    ; ESC = Quit
    ;------------------
    cmp     #$9B
    bne     :+
    jmp		MONZ
:

	jmp		waitForKey

.endproc



;-----------------------------------------------------------------------------
; draw_map
;-----------------------------------------------------------------------------

.proc draw_map

	lda 	#SCREEN_OFFSET
	sta		tileY

	lda 	#0
	sta 	index

loopy:	
	lda 	#0
	sta 	tileX

loopx:
	lda 	mapY
	asl
	asl
	asl
	asl
	clc
	adc 	mapX
	tax
	lda 	map,x

	jsr 	draw_tile

	; remember tile info byte
	ldx 	index
	sta 	mapCache,x
	inc 	index

	inc 	mapX

	; add width to X
	clc
	lda 	tileX
	adc 	#TILE_WIDTH
	sta 	tileX
	cmp		#SCREEN_WIDTH*TILE_WIDTH-1
	bmi 	loopx

	; restore mapX
	sec
	lda 	mapX

	sbc		#SCREEN_WIDTH
	sta 	mapX

	inc 	mapY

	; add height to Y 
	clc
	lda 	tileY
	adc 	#TILE_HEIGHT
	sta 	tileY
	cmp		#SCREEN_HEIGHT*TILE_HEIGHT-1+SCREEN_OFFSET
	bmi 	loopy

	; restore mapY
	sec
	lda 	mapY
	sbc		#SCREEN_HEIGHT
	sta 	mapY

	; draw player
	lda 	#TILE_WIDTH*2
	sta 	tileX
	lda 	#SCREEN_OFFSET+TILE_HEIGHT*2
	sta 	tileY
	lda 	#13
	jsr 	draw_tile

	rts

index: 		.byte 	0

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
	lda 	#$2D
	sta		$0480,x 			; row 1
	sta		$0750,x 			; row 22
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

    ; load info byte
    ldy 	#0
    lda     (tilePtr0),y

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
mapX:	    .byte 	0
mapY:	    .byte 	0

mapCache:	
			.byte 	0,0,0,0,0
			.byte 	0,0,0,0,0
			.byte 	0,0,0,0,0
			.byte 	0,0,0,0,0

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


; Make sure data is algined

.align  256

; 16 x 16
map:
	.byte 	3,2,2,4,4,4,4,4,4,2,3,2,2,3,2,2
	.byte 	2,2,3,2,4,4,4,4,3,2,2,2,3,2,2,3
	.byte 	2,2,2,1,4,1,0,0,0,0,0,6,1,3,2,2
	.byte 	2,3,1,1,4,1,0,1,1,1,0,6,0,1,2,2
	.byte 	3,2,1,1,4,1,0,1,3,1,0,6,0,1,2,3
	.byte 	2,2,1,5,5,5,5,5,5,5,5,6,0,0,2,2
	.byte 	3,2,1,1,4,1,3,1,0,0,0,1,0,1,3,2
	.byte 	2,2,1,1,4,1,1,1,0,0,0,1,0,1,2,2
	.byte 	2,3,1,1,4,0,0,0,0,0,1,1,3,7,2,2
	.byte 	2,2,1,1,4,1,1,0,0,0,1,1,7,7,2,2
	.byte 	2,2,0,0,4,1,1,1,0,0,0,7,7,1,3,2
	.byte 	2,3,0,4,4,1,1,1,0,0,0,7,1,0,2,2
	.byte 	2,3,4,4,1,1,3,1,0,1,2,3,0,0,2,3
	.byte 	2,3,4,0,1,3,1,0,1,2,1,1,2,2,2,2
	.byte 	2,2,4,1,3,1,1,0,1,1,1,1,1,1,2,2
	.byte   2,2,4,2,2,2,3,2,2,2,2,3,2,2,3,2


tileSheet:


; blank
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; grass
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$ac,$a0		;       , 
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0		;
	.byte 	$a0,$a7,$a0,$a0,$a0,$a0,$a0,$a0		;  '     
	.byte 	$a0,$a0,$a0,$a0,$a0,$a7,$a0,$a0     ;      '
	.byte 	$a0,$a0,$a7,$a0,$a0,$a0,$a0,$a0     ;   '
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0     ;
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

 ; tree1
	.byte 	$a0,$a0,$a0,$af,$dc,$a0,$a0,$a0     ;    /\
	.byte 	$a0,$a0,$af,$af,$dc,$dc,$a0,$a0     ;   //\\
	.byte 	$a0,$af,$af,$af,$dc,$dc,$dc,$a0     ;  ///\\\
	.byte 	$af,$af,$af,$af,$dc,$dc,$dc,$dc     ; ////\\\\
	.byte 	$a0,$a0,$a0,$fc,$fc,$a0,$a0,$a0     ;    ||
	.byte 	$a0,$a0,$ac,$fc,$fc,$ae,$a0,$a0     ;   ,||.
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

 ; tree2
	.byte 	$a0,$a0,$a0,$df,$df,$a0,$a0,$a0     ;    __
	.byte 	$a0,$a0,$a8,$ac,$a0,$a9,$a0,$a0     ;   (, )
	.byte 	$a0,$a8,$a0,$a0,$ac,$a0,$a9,$a0     ;  (  , )
	.byte 	$a8,$a0,$ac,$a0,$a0,$ac,$a0,$a9     ; ( ,  , )
	.byte 	$a0,$a8,$df,$a0,$a0,$df,$a9,$a0     ;  (_  _)
	.byte 	$a0,$a0,$a0,$dd,$db,$a0,$a0,$a0     ;    ][ 
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; water
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( )  
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( ) 
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( ) 
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; boardwalk (horizontal)
	.byte 	$df,$df,$df,$df,$df,$df,$df,$df		; ________  
	.byte 	$df,$df,$df,$df,$fc,$df,$df,$df		; ____|___  
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$df		; |_______  
	.byte 	$df,$df,$df,$fc,$df,$df,$df,$df		; ___|____  
	.byte 	$df,$df,$df,$df,$df,$df,$df,$fc		; _______|  
	.byte 	$df,$df,$df,$df,$fc,$df,$df,$df		; ____|___  
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; boardwalk (vertical)
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$fc		; |______|  
	.byte 	$fc,$df,$df,$df,$fc,$df,$df,$fc		; |___|__|  
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$fc		; |______|  
	.byte 	$fc,$df,$df,$fc,$df,$df,$df,$fc		; |__|___|  
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$fc		; |______|  
	.byte 	$fc,$df,$df,$df,$fc,$df,$df,$fc		; |___|__|  
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; cobblestones
	.byte 	$dc,$af,$dc,$af,$dc,$af,$dc,$af 	; \/\/\/\/
	.byte 	$af,$a0,$af,$a0,$af,$a0,$af,$a0 	; / / / / 
	.byte 	$dc,$af,$dc,$af,$dc,$af,$dc,$af 	; \/\/\/\/
	.byte 	$af,$a0,$af,$a0,$af,$a0,$af,$a0 	; / / / / 
	.byte 	$dc,$af,$dc,$af,$dc,$af,$dc,$af 	; \/\/\/\/
	.byte 	$af,$a0,$af,$a0,$af,$a0,$af,$a0 	; / / / / 
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; blank
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; blank
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; blank
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; blank
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; checker board
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
	.byte 	$56,$57,$56,$57,$56,$57,$56,$57
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; player
	.byte 	$00,$00,$00,$ad,$ad,$00,$00,$00     ;    --
	.byte 	$00,$00,$a8,$ef,$ef,$a9,$00,$00     ;   (oo)
	.byte 	$00,$00,$ad,$dc,$af,$ad,$00,$00     ;   -\/-
	.byte 	$00,$af,$00,$fc,$fc,$00,$dc,$00     ;  / || \
	.byte 	$00,$00,$00,$af,$dc,$00,$00,$00     ;    /\
	.byte 	$00,$00,$fc,$00,$00,$fc,$00,$00     ;   |  |
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding