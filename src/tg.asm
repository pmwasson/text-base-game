;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Entry for text game contest
;
; Tile based game
; Uses page flipping to remove flicker
; Animated water
; Idle animation (blinking)

;------------------------------------------------
; Constants
;------------------------------------------------

.include "defines.asm"
.include "macros.asm"

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
CACHE_CENTER    = 7+5

KEY_UP 			= 'W'
KEY_DOWN 		= 'S'
KEY_RIGHT		= 'D'
KEY_LEFT		= 'A'
KEY_WAIT 		= ' '
KEY_QUIT        = $1b

;------------------------------------------------
; Zero page usage
;------------------------------------------------

tilePtr0    :=  $50     ; Tile pointer
tilePtr1    :=  $51
screenPtr0  :=  $52     ; Screen pointer
screenPtr1  :=  $53
mapPtr0     :=  $54 	; Map pointer
mapPtr1     :=  $55
textPtr0   	:=  $56 	; Text pointer
textPtr1   	:=  $57

.segment "CODE"
.org    $C00


.proc main


	; Since draw-map draws the whole screen,
	; no need to clear screen at startup

	; set starting position
	lda 	#(MAP_WIDTH-SCREEN_WIDTH)/2
	sta 	mapX
	lda 	#MAP_HEIGHT-SCREEN_HEIGHT-1
	sta 	mapY

	jmp		gameLoop

movement:
	jsr 	sound_walk

gameLoop:
	inc 	gameTime
	bne		:+
	inc 	gameTimeHi
:	
	jsr		draw_screen

commandLoop:	
	jsr 	get_key
	sta 	lastKey		; record last actual key press

    ;------------------
    ; Up
    ;------------------
    cmp     #KEY_UP
    bne     :+
    ldx 	#CACHE_UP
    jsr 	check_movement
    bne		bump
    dec 	mapY
    jmp     movement
:

    ;------------------
    ; Down
    ;------------------
    cmp     #KEY_DOWN
    bne     :+
    ldx 	#CACHE_DOWN
    jsr 	check_movement
    bne		bump
    inc 	mapY
    jmp     movement
:

    ;------------------
    ; Left
    ;------------------
    cmp     #KEY_LEFT
    bne     :+
    ldx 	#CACHE_LEFT
    jsr 	check_movement
    bne		bump
    dec 	mapX
    jmp     movement
:

    ;------------------
    ; Right
    ;------------------
    cmp     #KEY_RIGHT
    bne     :+
    ldx 	#CACHE_RIGHT
    jsr 	check_movement
    bne		bump
    inc 	mapX
    jmp     movement
:

    ;------------------
    ; WAIT
    ;------------------
    cmp     #KEY_WAIT
    bne     :+
    jmp     gameLoop
:

    ;------------------
    ; Quit
    ;------------------
    cmp     #KEY_QUIT
    bne     :+
    lda 	#23
    sta  	CV 			; Make sure cursor is on the bottom row 		
    sta     LOWSCR 		; Make sure exit onto screen 1
    jmp		MONZ
:

    ;------------------
    ; Time-out
    ;------------------
    cmp     #$ff
    bne     :+
    jmp     gameLoop
:

	jmp		commandLoop

bump:
	jsr 	sound_bump
	jmp 	gameLoop

.endproc


;-----------------------------------------------------------------------------
; check_movement
;-----------------------------------------------------------------------------
; X = location to check
; A = 0 if free, 1 if blocked
.proc check_movement
    lda 	mapCache,x
    and 	#1
    rts
.endproc

;-----------------------------------------------------------------------------
; sound_tone
;-----------------------------------------------------------------------------
; A = tone
; X = duration
.proc sound_tone
loop1:
	sta 	SPEAKER
	tay
loop2:
	nop
	nop
	nop
	nop				; add some delay for lower notes
	dey
	bne		loop2
	dex
	bne 	loop1
	rts

.endproc

;-----------------------------------------------------------------------------
; sound_walk
;-----------------------------------------------------------------------------
.proc sound_walk
	lda 	#192 		; tone
	ldx 	#10			; duration
	jmp 	sound_tone	; link returns
.endproc

;-----------------------------------------------------------------------------
; sound_bump
;-----------------------------------------------------------------------------
.proc sound_bump
	lda 	#100 		; tone
	ldx 	#40			; duration
	jmp 	sound_tone	; link returns
.endproc


;-----------------------------------------------------------------------------
; get_key
;-----------------------------------------------------------------------------
; Return key with bit 7 clear, or -1 if timeout
;

.proc get_key

	ldx		#0
	ldy 	#$E0
	
waitForKey:
	lda		KBD
	bmi		gotKey

	inx
	bne 	waitForKey

	iny
	bne 	waitForKey

	; exit with no key after timeout
	lda 	#$ff
	rts

gotKey:	
	sta		KBDSTRB
	and 	#$7f 		; remove upper bit
	rts
.endproc


;-----------------------------------------------------------------------------
; draw_screen
;-----------------------------------------------------------------------------

.proc draw_screen

	; Alternate page to draw
	;-------------------------------------------------------------------------
	lda 	#0		; if showing page 2, draw on page 1
	ldx 	PAGE2
	bmi 	pageSelect
	lda 	#4		; displaying page 1, draw on page 2
pageSelect:
	sta 	drawPage


	; Draw map
	;-------------------------------------------------------------------------

	jsr		draw_map

	; Handle special tiles
	;-------------------------------------------------------------------------
	ldx 	#19
specialLoop:
	lda 	mapCache,x
	bpl		:+
	stx 	mapCacheIndex
	and     #$7C 	; clear bit 7, 1 and 0

 	sta     *+4 	; dynamically set lower byte for jump table
	jsr 	tile_jump_table ; WARNING: don't add anything before list line

	ldx 	mapCacheIndex
:
	dex
	bpl 	specialLoop


	; Draw player
	;-------------------------------------------------------------------------
	lda 	#TILE_WIDTH*2
	sta 	tileX
	lda 	#SCREEN_OFFSET+TILE_HEIGHT*2
	sta 	tileY

	lda 	#13
	jsr 	draw_tile

	; Set display page
	;-------------------------------------------------------------------------

flipPage:
	; flip page
	ldx 	PAGE2
	bmi 	flipToPage1
	sta 	HISCR 			; display page 2
	rts

flipToPage1:
	sta 	LOWSCR 			; diaplay page 1
	rts

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

    ; check if animated
    ldy 	#48+1
    lda 	(tilePtr0),y
    and 	gameTime
    beq 	notAnimated
    inc 	tilePtr1 		; use alternate tile!  +4

notAnimated:
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
    adc 	drawPage 		; previous carry should be clear
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

    ; load info bytes
    ldy 	#0
    lda     (tilePtr0),y

    rts    

; locals
temp:		.byte   0

.endproc


; TODO - put tile code in new file
; May be possible to load different tiles and code for different levels

;-----------------------------------------------------------------------------
; Tile handlers
;-----------------------------------------------------------------------------
; The following routines and called by special tiles.
; They can look at mapX, mapY and mapCacheIndex to figure out which instance
; was called and where it is on the screen


;-----------------------------------------------------------------------------
; tile_handler_coord
;-----------------------------------------------------------------------------
; Set tileX & Y base on cacheIndex
.proc tile_handler_coord
	ldx 	mapCacheIndex
	lda 	mapCacheX,x
	sta 	tileX
	lda 	mapCacheY,x
	sta 	tileY
	clc
	lda 	mapCacheOffsetX,x
	adc 	mapX
	sta 	specialX
	lda 	mapCacheOffsetY,x
	adc 	mapY
	sta 	specialY
	rts
.endproc

;-----------------------------------------------------------------------------
; tile_print
;-----------------------------------------------------------------------------
.proc tile_print
	
	lda 	textX
	sta 	nextX			; make a copy of textX

lineLoop:
    ; calculate screen pointer
    ldy     textY
    lda     textX
    clc
    adc     lineOffset,y    ; + lineOffset
    sta     screenPtr0    
    lda     linePage,y
    adc 	drawPage 		; previous carry should be clear
    sta     screenPtr1

    ldy 	#0
printRow:    
    lda 	(textPtr0),y

    ; End of string
    beq 	done

    ; End of line
    cmp 	#$8d
    bne 	:+
    inc 	textY
    lda 	nextX
    sta 	textX
    clc
    iny
    tya
    adc 	textPtr0
    sta 	textPtr0
    bcc 	lineLoop
    inc 	textPtr1
    jmp 	lineLoop
:

    ; Print!
    sta 	(screenPtr0),y

nextChar:
	iny
	bne 	printRow
	inc 	textPtr1
	jmp 	printRow

done:
	rts

nextX: 		.byte 	0

.endproc

;-----------------------------------------------------------------------------
; tile_handler_sign
;-----------------------------------------------------------------------------
.proc tile_handler_sign
	jsr 	tile_handler_coord

	; Set text location

	lda 	tileY
	sta 	textY
	lda 	tileX
	sta 	textX

	lda 	specialX

	; sign 1
	cmp 	#8
	bne		:+ 	
    lda 	#<signText1
    sta 	textPtr0
    lda 	#>signText1
    sta 	textPtr1
    jmp 	tile_print
:
	; sign 2
	cmp 	#9
	bne		:+ 	
    lda 	#<signText2
    sta 	textPtr0
    lda 	#>signText2
    sta 	textPtr1
    jmp 	tile_print
:
	; sign 3
	cmp 	#10
	bne		:+ 	
    lda 	#<signText3
    sta 	textPtr0
    lda 	#>signText3
    sta 	textPtr1
    jmp 	tile_print
:
	; default
    lda 	#<signText0
    sta 	textPtr0
    lda 	#>signText0
    sta 	textPtr1
    jmp 	tile_print


signText0:
	.byte 	$8d
	StringInv	"  ????"
	.byte 	0

signText1:
	.byte 	$8d
	StringInv	"TUTORIAL"
	.byte 	$8d
	StringInv	"  --->  "
	.byte 	0

signText2:
	StringInv	"  WASD"
	.byte 	$8d
	StringInv	" MOVES,"
	.byte 	$8d
	StringInv	" SPACE "
	.byte 	$8d
	StringInv	" ACTION"
	.byte 	0

signText3:
	StringInv	" STAND"
	.byte 	$8d
	StringInv	" BELOW"
	.byte 	$8d
	StringInv	" TO TALK"
	.byte 	0

.endproc

;-----------------------------------------------------------------------------
; tile_handler_guard
;-----------------------------------------------------------------------------
.proc tile_handler_guard
	jsr 	tile_handler_coord

	; check if guard is above or to the right of the player
	lda 	mapCacheIndex
	cmp 	#CACHE_UP
	beq 	cont
	cmp 	#CACHE_RIGHT
	beq 	cont
	cmp 	#CACHE_DOWN
	bne 	done


cont:
	; check if hit action key
	lda 	lastKey
	cmp 	#KEY_WAIT
	bne 	:+
	inc     state
:	
	
	; display a message on odd states
	lda 	state
	and 	#1
	bne 	:+
	rts 		; even = no display 
:

	; Display message
	; move 1 space to the right
	clc
	lda 	tileX
	adc 	#TILE_WIDTH
	sta 	tileX

	; 1 = hi
	lda 	state
	and 	#3 		; only 2 messages
	cmp 	#1
	bne 	:+
	lda 	#18
	jsr 	draw_tile
	rts
:
	; 3 = hows it going
	lda 	#19
	jsr 	draw_tile

	rts

done:
	; reset state if player moves
	lda 	#0
	sta 	state
	rts

state: 	.byte 0
.endproc


;-----------------------------------------------------------------------------
; tile_handler_dog
;-----------------------------------------------------------------------------
.proc tile_handler_dog

	; animation speed
	lda 	gameTime
	and 	#1
	bne		:+
	rts

:
	jsr 	tile_handler_coord

	; if near dog, wag tail
	; check if guard is above or to the right of the player
	lda 	mapCacheIndex
	cmp 	#CACHE_UP
	beq 	wag
	cmp 	#CACHE_RIGHT
	beq 	wag
	cmp 	#CACHE_DOWN
	beq 	wag
	cmp 	#CACHE_LEFT
	beq 	wag
	cmp 	#CACHE_CENTER
	beq 	wag

	rts 	; not near

wag:

	lda 	#12
	jsr 	draw_tile
	rts
.endproc

; Libraries
;-----------------------------------------------------------------------------

; add utilies
.include "inline_print.asm"


; Globals
;-----------------------------------------------------------------------------

drawPage:	.byte   0 	; should be either 0 or 4
gameTime:   .byte   0   ; +1 every turn
gameTimeHi: .byte   0   ; upper byte
tileX:		.byte 	0
tileY:		.byte 	0
mapX:	    .byte 	0
mapY:	    .byte 	0
specialX:	.byte 	0
specialY: 	.byte   0
textX:		.byte   0
textY:		.byte 	0
lastKey:    .byte   0

mapCacheIndex:
			.byte 	0

mapCache:	.res 	SCREEN_WIDTH*SCREEN_HEIGHT


; Data
;-----------------------------------------------------------------------------

mapCacheX:
	.byte 	0,8,16,24,32
	.byte 	0,8,16,24,32
	.byte 	0,8,16,24,32
	.byte 	0,8,16,24,32
mapCacheY:
	.byte 	0,0,0,0,0
	.byte   6,6,6,6,6
	.byte 	12,12,12,12,12
	.byte 	18,18,18,18,18
mapCacheOffsetX:
	.byte 	0,1,2,3,4
	.byte 	0,1,2,3,4
	.byte 	0,1,2,3,4
	.byte 	0,1,2,3,4
mapCacheOffsetY:
	.byte 	0,0,0,0,0
	.byte 	1,1,1,1,1
	.byte 	2,2,2,2,2
	.byte 	3,3,3,3,3

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
	.byte 	 3, 2, 2, 4, 4, 4, 4, 4, 4, 2, 3, 2, 2, 3, 2, 2
	.byte 	 2, 2, 3, 2, 4, 4, 4, 4, 3, 2, 2, 2, 3, 2, 2, 3
	.byte 	 2, 2, 2, 1, 4, 1, 0, 0, 0, 0, 0, 6, 1, 3, 2, 2
	.byte 	 2, 3, 1, 1, 4, 1, 0, 1, 1, 1,11, 6, 0, 1, 2, 2
	.byte 	 3, 2, 1, 1, 4, 1, 0, 1, 3, 1, 0, 6, 0, 1, 2, 3
	.byte 	 2, 2, 1, 5, 5, 5, 5, 5, 5, 5, 5, 6, 0, 0, 2, 2
	.byte 	 3, 2, 1, 1, 4, 1, 3, 1, 0, 0, 0, 1, 0, 1, 3, 2
	.byte 	 2, 2, 1, 1, 4, 1, 1, 1, 0, 0, 0, 1, 0, 1, 2, 2
	.byte 	 2, 3, 1, 1, 4, 0, 0, 0, 0, 1,15,15,15,15,15, 2
	.byte 	 2, 2, 1, 1, 4, 1, 1, 0, 0, 1,15, 7, 7, 7,15, 2
	.byte 	 2, 2, 0, 0, 4, 1, 1, 1,10, 0, 0, 7, 7, 7,15, 2
	.byte 	 2, 3, 0, 4, 4, 1, 1, 1, 0, 1,15, 7, 7, 7,15, 2
	.byte 	 2, 3, 4, 4, 1, 1, 3, 1, 3, 2,15,15,15,15,15, 3
	.byte 	 2, 3, 4, 0, 1, 3, 1, 0, 9, 9, 9,10, 1, 1, 3, 2
	.byte 	 2, 2, 4, 1, 3, 1, 1, 0, 1, 1, 1, 1, 1, 1, 2, 2
	.byte    2, 2, 4, 2, 2, 2, 3, 2, 2, 2, 2, 3, 2, 2, 3, 2



.align  256

tileSheet:


; blank
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement


; grass
	StringHi	"      , "
	StringHi	"        "
	StringHi	" '      "
	StringHi	"     '  "
	StringHi	"  '     "
	StringHi	"        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

 ; tree1
 	StringHi	"   /\   "
	StringHi	"  //\\  "
	StringHi	" ///\\\ "
	StringHi	"////\\\\"
	StringHi	"   ||   "
	StringHi	"  ,||.  "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking

 ; tree2
 	StringHi	"   __   "
	StringHi	"  (, )  "
	StringHi	" (  , ) "
	StringHi	"( ,  , )"
	StringHi	" (_  _) "
	StringHi	"   ][   "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking

; water
 	StringHi	"( ) ( ) "
	StringHi	") ( ) ( "
	StringHi	"( ) ( ) "
	StringHi	") ( ) ( "
	StringHi	"( ) ( ) "
	StringHi	") ( ) ( "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking, animated

; boardwalk (horizontal)
 	StringHi	"________"
	StringHi	"____|___"
	StringHi	"|_______"
	StringHi	"___|____"
	StringHi	"_______|"
	StringHi	"____|___"
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; boardwalk (vertical)
 	StringHi	"|__||  |"
	StringHi	"|  ||  |"
	StringHi	"|  ||__|"
	StringHi	"|__||  |"
	StringHi	"|  ||  |"
	StringHi	"|  ||__|"
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; cobblestones
 	StringHi	" /\  /\ "
	StringHi	"<  ><  >"
	StringHi	" \/  \/ "
 	StringHi	" /\  /\ "
	StringHi	"<  ><  >"
	StringHi	" \/  \/ "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; water (alternate)
	StringHi	") ( ) ( "
	StringHi	"( ) ( ) "
	StringHi	") ( ) ( "
	StringHi	"( ) ( ) "
	StringHi	") ( ) ( "
 	StringHi	"( ) ( ) "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking, animated

; sign
 	StringInv	"        "
 	StringInv	"        "
 	StringInv	"        "
 	StringInv	"        "
	StringHi	"   ||   "
	StringHi	"  ,||.  "
    .byte   $80+0*4+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; Special (0)

; Merchant
	StringHi	"   __   "
	StringHi	"  (..)  "
	StringHi	"  (__)  "
	StringHi	" \/[]\/ "
	StringHi	"   []   "
	StringHi	"   ||   "
    .byte   $80+1*4+1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; Blocking, Special (1), animated

; dog1
	StringHi	"        "
	StringHi	"        "
	StringHi	"     __ "
	StringHi	"\__()'`;"
	StringHi	"/    /` "
	StringHi	"\\--\\  "
    .byte   $80+2*4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; Special (2)

; dog2
	StringHi	"        "
	StringHi	"        "
	StringHi	"     __ "
	StringHi	"___()'`;"
	StringHi	"/    /` "
	StringHi	"\\--\\  "
    .byte   $80+2*4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; Special (2)

; player (blink)
	StringHiBG	"...--...",'.'
	StringHiBG	". (--) .",'.'
	StringHiBG	". -\/- .",'.'
	StringHiBG	"./ || \.",'.'
	StringHiBG	".  /\  .",'.'
	StringHiBG	". |  | .",'.'
    .byte   0,$3f,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; animated

; Merchant (animated)
	StringHi	"   __   "
	StringHi	"  (..)  "
	StringHi	"  (__)  "
	StringHi	" \/[]\  "
	StringHi	"   [] \ "
	StringHi	"   ||   "
    .byte   $80+1*4+1,$04,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; Blocking, Special (1), animated

; wall
 	StringInv	"    !   "
 	StringInv	"____!___"
 	StringInv	" !      "
 	StringInv	"_!______"
 	StringInv	"      ! "
 	StringInv	"______!_"
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking

; blank
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
	StringHi	"        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; player (normal)
	StringHiBG	"...--...",'.'
	StringHiBG	". (oo) .",'.'
	StringHiBG	". -\/- .",'.'
	StringHiBG	"./ || \.",'.'
	StringHiBG	".  /\  .",'.'
	StringHiBG	". |  | .",'.'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; padding

; DialogRightSM
	StringHiBG	"~~_____~",'~'
	StringHiBG	"~/     \",'~'
	StringHiBG	"<  Hi! |",'~'
	StringHiBG	"~\_____/",'~'
	StringHiBG	"~~~~~~~~",'~'
	StringHiBG	"~~~~~~~~",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 			; padding

; DialogRightMD
	StringHiBG	"~~~____~",'~'
	StringHiBG	"~~/    \",'~'
	StringHiBG	"~/HOW'S|",'~'
	StringHiBG	"<  IT  |",'~'
	StringHiBG	"~\GOING|",'~'
	StringHiBG	"~~\_?__/",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 			; padding

; DialogRightLG1
	StringHiBG	"~~~_____",'~'
	StringHiBG	"~~/     ",'~'
	StringHiBG	"~/      ",'~'
	StringHiBG	"<       ",'~'
	StringHiBG	"~\      ",'~'
	StringHiBG	"~~\_____",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 			; padding

; DialogRightLG2
	StringHiBG	"_______~",'~'
	StringHiBG	"       \",'~'
	StringHiBG	"       |",'~'
	StringHiBG	"       |",'~'
	StringHiBG	"       |",'~'
	StringHiBG	"_______/",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 			; padding

; Jump table for special tiles
.align  256

tile_jump_table:

	jmp 	tile_handler_sign
	nop
	jmp 	tile_handler_guard
	nop
	jmp 	tile_handler_dog
	nop

	; fill rest with BRK
	.res	256-4,0