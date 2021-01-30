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

    ;------------------
    ; W = Up
    ;------------------
    cmp     #'W'
    bne     :+
    ldx 	#CACHE_UP
    jsr 	check_movement
    bne		bump
    dec 	mapY
    jmp     movement
:

    ;------------------
    ; S = Down
    ;------------------
    cmp     #'S'
    bne     :+
    ldx 	#CACHE_DOWN
    jsr 	check_movement
    bne		bump
    inc 	mapY
    jmp     movement
:

    ;------------------
    ; A = Left
    ;------------------
    cmp     #'A'
    bne     :+
    ldx 	#CACHE_LEFT
    jsr 	check_movement
    bne		bump
    dec 	mapX
    jmp     movement
:

    ;------------------
    ; D = Right
    ;------------------
    cmp     #'D'
    bne     :+
    ldx 	#CACHE_RIGHT
    jsr 	check_movement
    bne		bump
    inc 	mapX
    jmp     movement
:

    ;------------------
    ; Space = wait
    ;------------------
    cmp     #$20
    bne     :+
    jmp     gameLoop
:

    ;------------------
    ; ESC = Quit
    ;------------------
    cmp     #$1B
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


	; Draw map and player
	;-------------------------------------------------------------------------

	jsr		draw_map


	; draw player
	lda 	#TILE_WIDTH*2
	sta 	tileX
	lda 	#SCREEN_OFFSET+TILE_HEIGHT*2
	sta 	tileY

	lda 	#13
	jsr 	draw_tile

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
	cmp 	#10
	bne		:+ 	
    lda 	#<signText2
    sta 	textPtr0
    lda 	#>signText2
    sta 	textPtr1
    jmp 	tile_print
:
	; sign 3
	cmp 	#12
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
	StringInverse	"__????"
	.byte 	0

signText1:
	.byte 	$8d
	StringInverse	"_WELCOME"
	.byte 	0

signText2:
	.byte 	$8d
	StringInverse	"___TO"
	.byte 	0

signText3:
	.byte 	$8d
	StringInverse	"__THE"
	.byte 	$8d
	StringInverse	"__GAME!"
	.byte 	0

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
	.byte 	2,3,4,4,1,1,3,1,3,2,2,3,3,2,2,3
	.byte 	2,3,4,0,1,3,1,0,9,0,9,1,9,1,3,2
	.byte 	2,2,4,1,3,1,1,0,1,1,1,1,1,1,2,2
	.byte   2,2,4,2,2,2,3,2,2,2,2,3,2,2,3,2



.align  256

tileSheet:


; blank
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; grass
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$ac,$a0		;       , 
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0		;
	.byte 	$a0,$a7,$a0,$a0,$a0,$a0,$a0,$a0		;  '     
	.byte 	$a0,$a0,$a0,$a0,$a0,$a7,$a0,$a0     ;      '
	.byte 	$a0,$a0,$a7,$a0,$a0,$a0,$a0,$a0     ;   '
	.byte 	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0     ;
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

 ; tree1
	.byte 	$a0,$a0,$a0,$af,$dc,$a0,$a0,$a0     ;    /\
	.byte 	$a0,$a0,$af,$af,$dc,$dc,$a0,$a0     ;   //\\
	.byte 	$a0,$af,$af,$af,$dc,$dc,$dc,$a0     ;  ///\\\
	.byte 	$af,$af,$af,$af,$dc,$dc,$dc,$dc     ; ////\\\\
	.byte 	$a0,$a0,$a0,$fc,$fc,$a0,$a0,$a0     ;    ||
	.byte 	$a0,$a0,$ac,$fc,$fc,$ae,$a0,$a0     ;   ,||.
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking

 ; tree2
	.byte 	$a0,$a0,$a0,$df,$df,$a0,$a0,$a0     ;    __
	.byte 	$a0,$a0,$a8,$ac,$a0,$a9,$a0,$a0     ;   (, )
	.byte 	$a0,$a8,$a0,$a0,$ac,$a0,$a9,$a0     ;  (  , )
	.byte 	$a8,$a0,$ac,$a0,$a0,$ac,$a0,$a9     ; ( ,  , )
	.byte 	$a0,$a8,$df,$a0,$a0,$df,$a9,$a0     ;  (_  _)
	.byte 	$a0,$a0,$a0,$dd,$db,$a0,$a0,$a0     ;    ][ 
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking

; water
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( )  
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( ) 
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( ) 
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking, animated

; boardwalk (horizontal)
	.byte 	$df,$df,$df,$df,$df,$df,$df,$df		; ________  
	.byte 	$df,$df,$df,$df,$fc,$df,$df,$df		; ____|___  
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$df		; |_______  
	.byte 	$df,$df,$df,$fc,$df,$df,$df,$df		; ___|____  
	.byte 	$df,$df,$df,$df,$df,$df,$df,$fc		; _______|  
	.byte 	$df,$df,$df,$df,$fc,$df,$df,$df		; ____|___  
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; boardwalk (vertical)
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$fc		; |______|  
	.byte 	$fc,$df,$df,$df,$fc,$df,$df,$fc		; |___|__|  
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$fc		; |______|  
	.byte 	$fc,$df,$df,$fc,$df,$df,$df,$fc		; |__|___|  
	.byte 	$fc,$df,$df,$df,$df,$df,$df,$fc		; |______|  
	.byte 	$fc,$df,$df,$df,$fc,$df,$df,$fc		; |___|__|  
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; cobblestones
	.byte 	$dc,$af,$dc,$af,$dc,$af,$dc,$af 	; \/\/\/\/
	.byte 	$af,$a0,$af,$a0,$af,$a0,$af,$a0 	; / / / / 
	.byte 	$dc,$af,$dc,$af,$dc,$af,$dc,$af 	; \/\/\/\/
	.byte 	$af,$a0,$af,$a0,$af,$a0,$af,$a0 	; / / / / 
	.byte 	$dc,$af,$dc,$af,$dc,$af,$dc,$af 	; \/\/\/\/
	.byte 	$af,$a0,$af,$a0,$af,$a0,$af,$a0 	; / / / / 
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; free-movement

; water (alternate)
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( ) 
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( ) 
	.byte 	$a9,$a0,$a8,$a0,$a9,$a0,$a8,$a0		; ) ( ) (
	.byte 	$a8,$a0,$a9,$a0,$a8,$a0,$a9,$a0		; ( ) ( )  
    .byte   1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; blocking, animated

; sign
	.byte 	$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f     ; ________
	.byte 	$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f     ; ________
	.byte 	$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f     ; ________
	.byte 	$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f     ; ________
	.byte 	$a0,$a0,$a0,$fc,$fc,$a0,$a0,$a0     ;    ||
	.byte 	$a0,$a0,$ac,$fc,$fc,$ae,$a0,$a0     ;   ,||.
    .byte   $81,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; Special (0)

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

; player (blink)
	.byte 	$00,$00,$00,$ad,$ad,$00,$00,$00     ;    --
	.byte 	$00,$00,$a8,$ad,$ad,$a9,$00,$00     ;   (--)
	.byte 	$00,$00,$ad,$dc,$af,$ad,$00,$00     ;   -\/-
	.byte 	$00,$af,$00,$fc,$fc,$00,$dc,$00     ;  / || \
	.byte 	$00,$00,$00,$af,$dc,$00,$00,$00     ;    /\
	.byte 	$00,$00,$fc,$00,$00,$fc,$00,$00     ;   |  |
    .byte   0,$3f,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; animated

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

; player (normal)
	.byte 	$00,$00,$00,$ad,$ad,$00,$00,$00     ;    --
	.byte 	$00,$00,$a8,$ef,$ef,$a9,$00,$00     ;   (oo)
	.byte 	$00,$00,$ad,$dc,$af,$ad,$00,$00     ;   -\/-
	.byte 	$00,$af,$00,$fc,$fc,$00,$dc,$00     ;  / || \
	.byte 	$00,$00,$00,$af,$dc,$00,$00,$00     ;    /\
	.byte 	$00,$00,$fc,$00,$00,$fc,$00,$00     ;   |  |
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	; 


; Jump table for special tiles
.align  256

tile_jump_table:

.align 4 
	jmp 	tile_handler_sign

	; fill rest with BRK
	.res	256-4,0