;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Entry for text game contest
;
; Tile based game
; Uses page flipping to remove flicker
; Animated water
; Idle animation (blinking)
; You can pet the dog!

;------------------------------------------------
; Constants
;------------------------------------------------

.include "defines.asm"
.include "macros.asm"

; Tiles on screen
SCREEN_WIDTH    = 5
SCREEN_HEIGHT   = 4
SCREEN_OFFSET   = 0

; Tile info
TILE_HEIGHT     = 6
TILE_WIDTH      = 8
TILE_BYTES      = 48    ; display bytes
TILE_SIZE       = 64    ; Rounded up
TILE_INFO_BYTE  = 0 
TILE_ANIMATED_BYTE  = 1

; Tile on-screen cache
;  0   1    2    3   4
;  5   6   (7)   8   9
; 10 (11) (12) (13) 14
; 15  16  (17)  18  19

CACHE_UP        = 7
CACHE_LEFT      = 11
CACHE_RIGHT     = 13
CACHE_DOWN      = 17
CACHE_CENTER    = 12

; Key bindings
KEY_UP          = 'W'
KEY_DOWN        = 'S'
KEY_RIGHT       = 'D'
KEY_LEFT        = 'A'
KEY_WAIT        = ' '
KEY_QUIT        = $1b
KEY_IDLE        = $ff

; tiles
tilePlayerId        =   (tilePlayer1            - tileSheet) / TILE_SIZE

tileGrassId         =   (tileGrass              - tileSheet) / TILE_SIZE

tileDialogRightSMId =   (tileDialogRightSM      - tileSheet) / TILE_SIZE
tileDialogRightMDId =   (tileDialogRightMD      - tileSheet) / TILE_SIZE

tileDialogLId       =   (tileDialogL            - tileSheet) / TILE_SIZE
tileDialogRId       =   (tileDialogR            - tileSheet) / TILE_SIZE

tileThoughtLId      =   (tileThoughtL           - tileSheet) / TILE_SIZE
tileThoughtMId      =   (tileThoughtM           - tileSheet) / TILE_SIZE
tileThoughtRId      =   (tileThoughtR           - tileSheet) / TILE_SIZE

tileDog2Id          =   (tileDog2               - tileSheet) / TILE_SIZE

tileBoardwalkHId    =   (tileBoardwalkH         - tileSheet) / TILE_SIZE

tileVaseBrokenId    =   (tileVaseBroken         - tileSheet) / TILE_SIZE

; Player starting location
START_X         = 42  ; 2  
START_Y         = 8  ; 3

; Misc
VASE_COUNT      = 16    ; Max number of vases in the game (must be power of 2)

;------------------------------------------------
; Zero page usage
;------------------------------------------------

tilePtr0    :=  $50     ; Tile pointer
tilePtr1    :=  $51
screenPtr0  :=  $52     ; Screen pointer
screenPtr1  :=  $53
mapPtr0     :=  $54     ; Map pointer
mapPtr1     :=  $55
textPtr0    :=  $56     ; Text pointer
textPtr1    :=  $57
dialogPtr0  :=  $58     ; Dialog chain pointer
dialogPtr1  :=  $59

.segment "CODE"
.org    $C00


.proc main

    ; make sure we are in 40-column mode
    lda     #$15
    jsr     COUT

    ; Since draw-map draws the whole screen,
    ; no need to clear screen at startup

    ; reset game state
    jsr     reset

    jmp     gameLoop

movement:
    jsr     sound_walk

gameLoop:
    inc     gameTime
    bne     :+
    lda     timerExpired
    ora     #1
    sta     timerExpired
:   
    jsr     draw_screen

commandLoop:    
    jsr     get_key
    sta     lastKey     ; record last key press
    sta     dialogKey

    ;------------------------------------------
    ; If in dialog, ignore key presses
    ;------------------------------------------
    ldy     #0
    lda     (dialogPtr0),y
    beq     movement_mode

    ; let dialog handle key presses
    lda     #KEY_IDLE
    sta     lastKey 
    jmp     gameLoop

    ;------------------------------------------
    ; Movement mode
    ;------------------------------------------
movement_mode:

    lda     lastKey
    ;------------------
    ; Up
    ;------------------
    cmp     #KEY_UP
    bne     :+
    ldx     #CACHE_UP
    jsr     check_movement
    bne     bump
    dec     mapY
    jmp     movement
:

    ;------------------
    ; Down
    ;------------------
    cmp     #KEY_DOWN
    bne     :+
    ldx     #CACHE_DOWN
    jsr     check_movement
    bne     bump
    inc     mapY
    jmp     movement
:

    ;------------------
    ; Left
    ;------------------
    cmp     #KEY_LEFT
    bne     :+
    ldx     #CACHE_LEFT
    jsr     check_movement
    bne     bump
    dec     mapX
    jmp     movement
:

    ;------------------
    ; Right
    ;------------------
    cmp     #KEY_RIGHT
    bne     :+
    ldx     #CACHE_RIGHT
    jsr     check_movement
    bne     bump
    inc     mapX
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
    lda     #23
    sta     CV          ; Make sure cursor is on the bottom row         
    sta     LOWSCR      ; Make sure exit onto screen 1
    jmp     MONZ
:

    ;--------------------------
    ; Time-out or unmapped key
    ;--------------------------

    jmp     gameLoop

bump:
    jsr     sound_bump
    jmp     gameLoop

.endproc


;-----------------------------------------------------------------------------
; reset
;-----------------------------------------------------------------------------
; Reset game state
; Note, this is a good place to debug/cheat since you can modify to start
; in whatever state you wish.

.proc reset

    ; set starting position
    lda     #START_X
    sta     mapX
    lda     #START_Y
    sta     mapY

    ; Even though all the state is zero, using separate LDAs so the
    ; state can be hacked from the monitor

    lda     #0
    sta     stateHammer
    lda     #0
    sta     stateBridge

    lda     #0
    ldy     #VASE_COUNT-1
:
    sta     stateVase,y
    dey
    bpl     :-
    sta     stateAnyVase

    lda     #0
    sta     stateTimer
    lda     #0
    sta     stateMarker

    ; Initial dialog
    ldx     #<dialogInit
    ldy     #>dialogInit
    jsr     set_dialog

    rts

.endproc

;-----------------------------------------------------------------------------
; check_movement
;-----------------------------------------------------------------------------
; X = location to check
; A = 0 if free, 1 if blocked
.proc check_movement
    lda     mapCache,x
    and     #1
    rts
.endproc

;-----------------------------------------------------------------------------
; sound_tone
;-----------------------------------------------------------------------------
; A = tone
; X = duration
.proc sound_tone
loop1:
    sta     SPEAKER
    tay
loop2:
    nop
    nop
    nop
    nop             ; add some delay for lower notes
    dey
    bne     loop2
    dex
    bne     loop1
    rts

.endproc

;-----------------------------------------------------------------------------
; sound_walk
;-----------------------------------------------------------------------------
.proc sound_walk
    lda     #50         ; tone
    ldx     #5          ; duration
    jsr     sound_tone
    lda     #190        ; tone
    ldx     #3          ; duration
    jmp     sound_tone  ; link returns
.endproc

;-----------------------------------------------------------------------------
; sound_bump
;-----------------------------------------------------------------------------
.proc sound_bump
    lda     #100        ; tone
    ldx     #20         ; duration
    jsr     sound_tone
    lda     #90         ; tone
    ldx     #10         ; duration
    jmp     sound_tone  ; link returns
.endproc

;-----------------------------------------------------------------------------
; sound_talk
;-----------------------------------------------------------------------------
.proc sound_talk
    lda     #60         ; tone
    ldx     #15         ; duration
    jsr     sound_tone  ; link returns
    lda     #40         ; tone
    ldx     #10         ; duration
    jmp     sound_tone  ; link returns
.endproc

;-----------------------------------------------------------------------------
; sound_bark
;-----------------------------------------------------------------------------
.proc sound_bark
    lda     #20         ; tone
    ldx     #40         ; duration
    jsr     sound_tone
    lda     #200        ; tone
    ldx     #5          ; duration
    jsr     sound_tone
    lda     #50         ; tone
    ldx     #40         ; duration
    jmp     sound_tone  ; link returns
.endproc

;-----------------------------------------------------------------------------
; sound_door
;-----------------------------------------------------------------------------
.proc sound_door
    lda     #200        ; tone
    ldx     #4          ; duration
    jmp     sound_tone  ; link returns
.endproc

;-----------------------------------------------------------------------------
; sound_pickup
;-----------------------------------------------------------------------------
.proc sound_pickup
    lda     #200        ; tone
    ldx     #25         ; duration
    jsr     sound_tone 
    lda     #100        ; tone
    ldx     #20         ; duration
    jsr     sound_tone 
    lda     #35         ; tone
    ldx     #100        ; duration
    jmp     sound_tone  ; link return
.endproc

;-----------------------------------------------------------------------------
; sound_crash
;-----------------------------------------------------------------------------
.proc sound_crash
    lda     #35         ; tone
    ldx     #100        ; duration
    jsr     sound_tone 
    lda     #100        ; tone
    ldx     #20         ; duration
    jsr     sound_tone 
    lda     #200        ; tone
    ldx     #25         ; duration
    jmp     sound_tone  ; link return
.endproc

;-----------------------------------------------------------------------------
; sound_timer
;-----------------------------------------------------------------------------
.proc sound_timer
    lda     #150        ; tone
    ldx     #200        ; duration
    jmp     sound_tone  ; link return
.endproc


;-----------------------------------------------------------------------------
; get_key
;-----------------------------------------------------------------------------
; Return key with bit 7 clear, or -1 if timeout
;

.proc get_key

    ldx     #0
    ldy     #$E0
    
waitForKey:
    lda     KBD
    bmi     gotKey

    inx
    bne     waitForKey

    iny
    bne     waitForKey

    ; exit with no key after timeout
    lda     #KEY_IDLE
    rts

gotKey: 
    sta     KBDSTRB
    and     #$7f        ; remove upper bit
    rts
.endproc


;-----------------------------------------------------------------------------
; draw_screen
;-----------------------------------------------------------------------------

.proc draw_screen

    ; Alternate page to draw
    ;-------------------------------------------------------------------------
    lda     #0      ; if showing page 2, draw on page 1
    ldx     PAGE2
    bmi     pageSelect
    lda     #4      ; displaying page 1, draw on page 2
pageSelect:
    sta     drawPage


    ; Draw map
    ;-------------------------------------------------------------------------

    jsr     draw_map

    ; Handle special tiles
    ;-------------------------------------------------------------------------
    ldx     #19
specialLoop:
    lda     mapCache,x
    bpl     :+
    stx     mapCacheIndex
    and     #$7C    ; clear bit 7, 1 and 0

    sta     *+4     ; dynamically set lower byte for jump table
    jsr     tile_jump_table ; WARNING: don't add anything before this line

    ldx     mapCacheIndex
:
    dex
    bpl     specialLoop


    ; Draw player
    ;-------------------------------------------------------------------------
    lda     #TILE_WIDTH*2
    sta     tileX
    lda     #SCREEN_OFFSET+TILE_HEIGHT*2
    sta     tileY

    lda     #tilePlayerId
    jsr     draw_tile


    ; Draw Dialog
    ;-------------------------------------------------------------------------
    ldy     #0
    lda     (dialogPtr0),y
    beq     flipPage

    ; set text
    ldy     #1
    lda     (dialogPtr0),y
    sta     textPtr0
    ldy     #2
    lda     (dialogPtr0),y
    sta     textPtr1

    ; pick correct window
    ldy     #0
    lda     (dialogPtr0),y
    cmp     #DIALOG_TALK
    bne     :+
    jsr     draw_dialog
    jmp     next_dialog
:
    jsr     draw_thought

next_dialog:
    lda     dialogKey
    cmp     #KEY_WAIT
    bne     flipPage

    ; go to next dialog
    clc
    lda     dialogPtr0
    adc     #3
    sta     dialogPtr0
    lda     dialogPtr1
    adc     #0
    sta     dialogPtr1

    ; Set display page
    ;-------------------------------------------------------------------------

flipPage:
    ; flip page
    ldx     PAGE2
    bmi     flipToPage1
    sta     HISCR           ; display page 2
    rts

flipToPage1:
    sta     LOWSCR          ; diaplay page 1
    rts

.endproc

;-----------------------------------------------------------------------------
; draw_map
;-----------------------------------------------------------------------------

.proc draw_map


    lda     #SCREEN_OFFSET
    sta     tileY

    lda     #0
    sta     index

loopy:  
    lda     #0
    sta     tileX

    ; set map pointer for the current line
    lda     mapY
    ror
    ror
    ror                     ; Multiply by 64
    and     #$c0
    clc
    adc     #<map
    sta     mapPtr0

    lda     #0
    adc     #>map
    sta     mapPtr1
    lda     mapY 
    lsr
    lsr                     ; Divide by 4
    clc
    adc     mapPtr1
    sta     mapPtr1

loopx:
    ldy     mapX    ; +x
    lda     (mapPtr0),y

    jsr     draw_tile

    ; remember tile info byte
    ldx     index
    sta     mapCache,x
    inc     index

    inc     mapX

    ; add width to X
    clc
    lda     tileX
    adc     #TILE_WIDTH
    sta     tileX
    cmp     #SCREEN_WIDTH*TILE_WIDTH-1
    bmi     loopx

    ; restore mapX
    sec
    lda     mapX

    sbc     #SCREEN_WIDTH
    sta     mapX

    inc     mapY

    ; add height to Y 
    clc
    lda     tileY
    adc     #TILE_HEIGHT
    sta     tileY
    cmp     #SCREEN_HEIGHT*TILE_HEIGHT-1+SCREEN_OFFSET
    bmi     loopy

    ; restore mapY
    sec
    lda     mapY
    sbc     #SCREEN_HEIGHT
    sta     mapY

    rts

index:      .byte   0

.endproc

;-----------------------------------------------------------------------------
; fill_screen (screen1)
;-----------------------------------------------------------------------------

.proc fill_screen
    ldx     #0
loop:
    lda     #$a0

    ; 8 starting points, 3 rows each = 24 rows
    sta     $400,x
    sta     $480,x
    sta     $500,x
    sta     $580,x
    sta     $600,x
    sta     $680,x
    sta     $700,x
    sta     $780,x
    inx 
    cpx     #40*3
    bne     loop
    rts
.endproc

;-----------------------------------------------------------------------------
; draw_char
; y = row
; a = col
; x = character
;
; Only use this routine for special overwriting of a single character.
; Should use draw_tile or tile_print for fast results
;-----------------------------------------------------------------------------
.proc draw_char
    clc
    adc     lineOffset,y    ; + lineOffset
    sta     screenPtr0    
    lda     linePage,y
    adc     drawPage        ; previous carry should be clear
    sta     screenPtr1
    ldy     #0
    txa
    sta     (screenPtr0),y
    rts
.endproc

;-----------------------------------------------------------------------------
; draw_tile
;-----------------------------------------------------------------------------
; Tiles are 48 bytes, but pad to 64 so no page crossings
; Use padding bits for additional information, such as animation speed

.proc draw_tile
    ; calculate tile pointer
    sta     temp            ; Save a copy of A

    ror
    ror
    ror                     ; Multiply by 64
    and     #$c0
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
    ldy     #TILE_BYTES + TILE_ANIMATED_BYTE
    lda     (tilePtr0),y
    and     gameTime
    beq     notAnimated
    inc     tilePtr1        ; use alternate tile!  +4

notAnimated:
    ; copy tileY
    lda     tileY
    sta     temp

    ; 8 rows
    ldx     #TILE_HEIGHT

loopy:
    ; calculate screen pointer
    ldy     temp            ; copy of tileY
    lda     tileX
    clc
    adc     lineOffset,y    ; + lineOffset
    sta     screenPtr0    
    lda     linePage,y
    adc     drawPage        ; previous carry should be clear
    sta     screenPtr1

    ; set 8 bytes
    ldy     #TILE_WIDTH-1
loopx:
    lda     (tilePtr0),y
    beq     skip
    sta     (screenPtr0),y
skip:
    dey
    bpl     loopx

    ; assumes aligned such that there are no page crossing
    lda     tilePtr0
    adc     #TILE_WIDTH
    sta     tilePtr0

    inc     temp        ; next line

    dex
    bne     loopy

    ; load info bytes
    ldy     #TILE_INFO_BYTE
    lda     (tilePtr0),y
    rts    

; locals
temp:       .byte   0

.endproc


;-----------------------------------------------------------------------------
; set_dialog
;-----------------------------------------------------------------------------
; Start a dialog chain

.proc set_dialog
    ; set pointer
    stx     dialogPtr0
    sty     dialogPtr1

    ; save position
    lda     mapCacheIndex
    sta     dialogCacheIndex

    ; keypress has already been handled
    lda     #KEY_IDLE
    sta     dialogKey

    rts
.endproc



;-----------------------------------------------------------------------------
; draw_dialog
;-----------------------------------------------------------------------------
.proc draw_dialog

    ; Position the dialog box based on position
    lda     dialogCacheIndex

    ; if above, use tile 1,0
    cmp     #CACHE_UP
    bne     :+

    lda     #TILE_HEIGHT*0  ; row
    sta     tileY
    sta     textY
    lda     #TILE_WIDTH*1   ; col 
    sta     tileX
    sta     textX

    ; Draw dialog stem directly on screen
    ; Upper right of tile 2,1
    lda     #TILE_WIDTH*2
    ldy     #TILE_HEIGHT*1
    ldx     #'\' + $80
    jsr     draw_char
    jmp     dialog
:

    ; if left, use tile 0,1
    cmp     #CACHE_LEFT
    bne     :+

    lda     #TILE_HEIGHT*1  ; row
    sta     tileY
    sta     textY
    lda     #TILE_WIDTH*0   ; col 
    sta     tileX
    sta     textX

    ; Draw dialog stem directly on screen
    ; Upper right of tile 1,2
    lda     #TILE_WIDTH*1
    ldy     #TILE_HEIGHT*2
    ldx     #'\' + $80
    jsr     draw_char
    jmp     dialog
:

    ; if right, use tile 3,1
    cmp     #CACHE_RIGHT
    bne     :+

    lda     #TILE_HEIGHT*1  ; row
    sta     tileY
    sta     textY
    lda     #TILE_WIDTH*3   ; col 
    sta     tileX
    sta     textX

    ; Draw dialog stem directly on screen
    ; Upper right of tile 3,2
    lda     #TILE_WIDTH*4-1
    ldy     #TILE_HEIGHT*2
    ldx     #'/' + $80
    jsr     draw_char
    jmp     dialog
:

    ; if down, use tile 3,3
    cmp     #CACHE_DOWN
    bne     :+

    lda     #TILE_HEIGHT*3  ; row
    sta     tileY
    sta     textY
    lda     #TILE_WIDTH*3   ; col 
    sta     tileX
    sta     textX

    ; Upper right of tile 2,3
    ; (down one row)
    lda     #TILE_WIDTH*3-1
    ldy     #TILE_HEIGHT*3+1
    ldx     #'_' + $80
    jsr     draw_char
    jmp     dialog
:

    ; Must be middle (player), use tile 2,1
    lda     #TILE_HEIGHT*1  ; row
    sta     tileY
    sta     textY
    lda     #TILE_WIDTH*2   ; col 
    sta     tileX
    sta     textX

    ; Draw dialog stem directly on screen
    ; Upper right of tile 2,2
    lda     #TILE_WIDTH*3-1
    ldy     #TILE_HEIGHT*2
    ldx     #'/' + $80
    jsr     draw_char

dialog:
    ; draw box
    lda     #tileDialogLId
    jsr     draw_tile
    clc     
    lda     tileX
    adc     #TILE_WIDTH
    sta     tileX
    lda     #tileDialogRId
    jsr     draw_tile

    ; set text starting point
    inc     textX
    inc     textY

    ; draw text
    jmp     tile_print      ; link return

dialogIndex:    .byte   0

.endproc

;-----------------------------------------------------------------------------
; draw_thought
;-----------------------------------------------------------------------------
.proc draw_thought

    ; use tile 1,1
    lda     #TILE_HEIGHT*1  ; row
    sta     tileY
    sta     textY
    lda     #TILE_WIDTH*1   ; col 
    sta     tileX
    sta     textX

    ; Draw thought bubble directly on screen
    ; Upper right of tile 2,2
    lda     #TILE_WIDTH*3-1
    ldy     #TILE_HEIGHT*2
    ldx     #'o' + $80
    jsr     draw_char

dialog:
    ; draw box
    lda     #tileThoughtLId
    jsr     draw_tile
    clc     
    lda     tileX
    adc     #TILE_WIDTH
    sta     tileX
    lda     #tileThoughtMId
    jsr     draw_tile
    clc     
    lda     tileX
    adc     #TILE_WIDTH
    sta     tileX
    lda     #tileThoughtRId
    jsr     draw_tile

    ; set text starting point
    inc     textX
    inc     textX
    inc     textY

    ; draw text
    jmp     tile_print      ; link return

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
    ldx     mapCacheIndex
    lda     mapCacheX,x
    sta     tileX
    sta     textX
    lda     mapCacheY,x
    sta     tileY
    sta     textY
    clc
    lda     mapCacheOffsetX,x
    adc     mapX
    sta     specialX
    lda     mapCacheOffsetY,x
    adc     mapY
    sta     specialY
    rts
.endproc

;-----------------------------------------------------------------------------
; tile_adjacent
;-----------------------------------------------------------------------------
; Set carry bit if mapCacheIndex is next to player
.proc tile_adjacent
    lda     mapCacheIndex
    cmp     #CACHE_UP
    beq     :+
    cmp     #CACHE_DOWN
    beq     :+
    cmp     #CACHE_RIGHT
    beq     :+
    cmp     #CACHE_LEFT
    beq     :+
    clc
    rts
:
    sec
    rts

.endproc

;-----------------------------------------------------------------------------
; tile_not_right_edge
;-----------------------------------------------------------------------------
; Set carry bit if mapCacheIndex is not on the right edge (4,9,14,19)
.proc tile_not_right_edge
    lda     mapCacheIndex
    cmp     #4
    beq     :+
    cmp     #9
    beq     :+
    cmp     #14
    beq     :+
    cmp     #19
    beq     :+
    sec
    rts
:
    clc
    rts

.endproc

;-----------------------------------------------------------------------------
; tile_print
;-----------------------------------------------------------------------------
.proc tile_print
    
    lda     textX
    sta     nextX           ; make a copy of textX

lineLoop:
    ; calculate screen pointer
    ldy     textY
    lda     textX
    clc
    adc     lineOffset,y    ; + lineOffset
    sta     screenPtr0    
    lda     linePage,y
    adc     drawPage        ; previous carry should be clear
    sta     screenPtr1

    ldy     #0
printRow:    
    lda     (textPtr0),y

    ; End of string
    beq     done

    ; End of line
    cmp     #$8d
    bne     :+
    inc     textY
    lda     nextX
    sta     textX
    clc
    iny
    tya
    adc     textPtr0
    sta     textPtr0
    bcc     lineLoop
    inc     textPtr1
    jmp     lineLoop
:

    ; Print!
    sta     (screenPtr0),y

nextChar:
    iny
    bne     printRow
    inc     textPtr1
    jmp     printRow

done:
    rts

nextX:      .byte   0

.endproc



;-----------------------------------------------------------------------------
; tile_handler_sign
;-----------------------------------------------------------------------------
.proc tile_handler_sign
    jsr     tile_handler_coord

    ; choose message
    lda     specialX

    ; Mr Fancy
    cmp     #22
    bne     :+  
    lda     #<signTextFancy
    sta     textPtr0
    lda     #>signTextFancy
    sta     textPtr1
    jmp     tile_print
:
    ; Duck Pond
    cmp     #35
    bne     :+  
    lda     #<signDuck
    sta     textPtr0
    lda     #>signDuck
    sta     textPtr1
    jmp     tile_print
:
    ; Forest Trail
    cmp     #51
    bne     :+  
    lda     #<signTrail
    sta     textPtr0
    lda     #>signTrail
    sta     textPtr1
    jmp     tile_print
:
    ; default
    lda     #<signTextDefault
    sta     textPtr0
    lda     #>signTextDefault
    sta     textPtr1
    jmp     tile_print


signTextDefault:
    .byte   $8d
    StringInv   "  ????"
    .byte   0

signTextFancy:
    .byte   $8d
    StringInv   "MR FANCY"
    .byte   0

signDuck:
    .byte   $8d
    StringInv   "  DUCK"
    .byte   $8d
    StringInv   "  POND"
    .byte   0

signTrail:
    .byte   $8d
    StringInv   " FOREST"
    .byte   $8d
    StringInv   " TRAIL"
    .byte   0

.endproc

;-----------------------------------------------------------------------------
; tile_handler_door
;-----------------------------------------------------------------------------
.proc tile_handler_door

    ; is the player next to the door?
    jsr     tile_adjacent
    bcc     on_door

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     on_door

    ; set up dialog
    ldx     #<dialogDoor
    ldy     #>dialogDoor
    jsr     set_dialog

on_door:
    ; is player on the door?
    lda     mapCacheIndex
    cmp     #CACHE_CENTER
    beq     :+
    rts
:
    ; is the player just idle
    lda     lastKey
    bpl     :+
    rts
:
    ; also ignore "wait"
    cmp     #KEY_WAIT
    bne     :+
    rts
:
    jmp     sound_door      ; link return

.endproc

;-----------------------------------------------------------------------------
; tile_handler_guard
;-----------------------------------------------------------------------------
.proc tile_handler_guard
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; set up dialog
    ldx     #<dialogGuard
    ldy     #>dialogGuard
    jsr     set_dialog
:
    rts

.endproc




;-----------------------------------------------------------------------------
; tile_handler_jr
;-----------------------------------------------------------------------------
.proc tile_handler_jr
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; set up dialog
    ldx     #<dialogJr
    ldy     #>dialogJr
    jsr     set_dialog
:
    rts
.endproc


;-----------------------------------------------------------------------------
; tile_handler_marker
;-----------------------------------------------------------------------------
.proc tile_handler_marker
    lda     mapCacheIndex
    cmp     #CACHE_CENTER
    bne     :+
    lda     #1
    sta     stateMarker
:
    rts
.endproc

;-----------------------------------------------------------------------------
; start_timer
;-----------------------------------------------------------------------------

.proc start_timer
    ; cheat by clearing gameTime!
    lda     #0
    sta     gameTime
    sta     timerExpired
    sta     stateMarker
    lda     #1
    sta     stateTimer
    jsr     sound_timer
    rts
.endproc

;-----------------------------------------------------------------------------
; tile_handler_forest
;-----------------------------------------------------------------------------
; stateTimer:
;       0 = idle
;       1 = in-progress
;      -1 = failed
;       2 = sucess

.proc tile_handler_forest
    jsr     tile_handler_coord

    ; Delay race start until dialog is finished
    ; if state is 1, and dialog is not active, start
    lda     state
    beq     :+
    ldy     #0
    lda     (dialogPtr0),y
    bne     :+

    sty     state           ; clear state 
    jsr     start_timer
:

    ; If timer is active, display it (if possible)
    lda     stateTimer
    cmp     #1
    bne     done_timer

    ; check if timer expired
    lda     timerExpired
    bne     done_timer

    ; check if room to display timer
    jsr     tile_not_right_edge
    bcc     done_timer

    ; Dialog one space to the right
    clc
    lda     tileX
    adc     #TILE_WIDTH
    sta     tileX
    sta     textX
    inc     textX
    inc     textY

    lda     #tileDialogRightSMId
    jsr     draw_tile

    lda     gameTime
    and     #$f0        ; 16 choice (up to 16 characters each)
    sta     textPtr0
    lda     #>timerText
    sta     textPtr1
    jsr     tile_print

done_timer:
    jsr     tile_adjacent
    bcs     :+
    rts
:
    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    beq     :+
    rts
:

    ; check race status
    lda     stateTimer
    cmp     #1
    bne     not_in_race

    ; expired, failed
    lda     timerExpired
    beq     :+

    ; failed
    lda     #$ff
    sta     stateTimer
    jmp     not_in_race

:
 
    ; if timer > d0 ("zero"), also fail
    lda     gameTime
    bpl     :+ 
    cmp     #$d0
    bmi     :+

    ; failed
    lda     #$ff
    sta     stateTimer
    jmp     not_in_race
:

    ; win if marker set and timer less than $e0
    lda     stateMarker
    beq     :+          ; marker not set

    ; won!
    lda     #2
    sta     stateTimer
    jmp     not_in_race

:
    ; race still going on, ignore the key-press
    rts

not_in_race:

    lda     stateTimer
    bmi     lost
    beq     init

    ; Won!
    ldx     #<dialogForestWon
    ldy     #>dialogForestWon
    jsr     set_dialog
    rts

lost:
    ldx     #<dialogForestLost
    ldy     #>dialogForestLost
    jsr     set_dialog

    ; start timer when dialog is finished
    lda     #1
    sta     state
    rts

init:
    ldx     #<dialogForestInit
    ldy     #>dialogForestInit
    jsr     set_dialog

    ; start timer when dialog is finished
    lda     #1
    sta     state
    rts


state:  .byte 0

.endproc

;-----------------------------------------------------------------------------
; tile_handler_fixer
;-----------------------------------------------------------------------------
; uses stateHammer and stateBridge
.proc tile_handler_fixer

    ; Delay bridge fix until dialog is finished
    ; if state is 1, and dialog is not active, set bridge
    lda     state
    beq     :+
    ldy     #0
    lda     (dialogPtr0),y
    bne     :+
    lda     #1
    sta     stateBridge
:

    jsr     tile_adjacent
    bcs     :+
    rts
:

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    beq     :+
    rts
:

    lda     stateBridge
    bne     bridge

    ; no bridge

    lda     stateHammer
    bne     hammer

    ; no hammer

    ldx     #<dialogFixerInit
    ldy     #>dialogFixerInit
    jsr     set_dialog
    rts

hammer:
    ; found hammer so set bridge
    lda     #1
    sta     state

    ldx     #<dialogFixerBridge
    ldy     #>dialogFixerBridge
    jsr     set_dialog
    rts

bridge:
    ; bridge fixed
    ldx     #<dialogFixerDone
    ldy     #>dialogFixerDone
    jsr     set_dialog
    rts

state:  .byte 0

.endproc

;-----------------------------------------------------------------------------
; tile_handler_doghouse
;-----------------------------------------------------------------------------
.proc tile_handler_doghouse
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; set up dialog
    ldx     #<dialogDoghouse
    ldy     #>dialogDoghouse
    jsr     set_dialog
:
    rts

.endproc

;-----------------------------------------------------------------------------
; tile_handler_mailbox
;-----------------------------------------------------------------------------
.proc tile_handler_mailbox
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; set up dialog
    ldx     #<dialogMailbox
    ldy     #>dialogMailbox
    jsr     set_dialog
:
    rts

.endproc

;-----------------------------------------------------------------------------
; tile_handler_fence
;-----------------------------------------------------------------------------
.proc tile_handler_fence
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; set up dialog
    ldx     #<dialogFence
    ldy     #>dialogFence
    jsr     set_dialog
:
    rts

.endproc

;-----------------------------------------------------------------------------
; tile_handler_bed
;-----------------------------------------------------------------------------
.proc tile_handler_bed
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; set up dialog
    ldx     #<dialogBed
    ldy     #>dialogBed
    jsr     set_dialog
:
    rts

.endproc

;-----------------------------------------------------------------------------
; tile_handler_easel
;-----------------------------------------------------------------------------
.proc tile_handler_easel

    jsr     tile_adjacent
    bcc     :+

    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    jsr     askey_portrait
:
    rts

.endproc

;-----------------------------------------------------------------------------
; tile_handler_dog
;-----------------------------------------------------------------------------
.proc tile_handler_dog

    jsr     tile_handler_coord

    jsr     tile_adjacent
    bcs     :+

    ; not near, reset state and exit
    lda     #0
    sta     state
    rts
:

    ; animation speed
    lda     gameTime
    and     #1
    beq     :+
    lda     #tileDog2Id
    jsr     draw_tile
:

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+
    lda     #10         ; how long to display text
    sta     state
    jsr     sound_bark
:

    lda     state
    beq     :+
    dec     state

    inc     textX
    inc     textX
    lda     #<dogText1
    sta     textPtr0
    lda     #>dogText1
    sta     textPtr1
    jsr     tile_print
:

    rts

state:  .byte   0
dogText1:
    .byte   $8d
    StringHi    "BARK!"
    .byte   0


.endproc

;-----------------------------------------------------------------------------
; tile_handler_hammer
;-----------------------------------------------------------------------------
; stateHammer: 0 = hammer on ground, -1 = picking up, 1 = picked up

.proc tile_handler_hammer
    jsr     tile_handler_coord

    ; clear hammer display if state not zero
    lda     stateHammer
    beq     :+

    lda     #tileGrassId
    jsr     draw_tile
    ; if hammer is picked up, nothing else to do
    rts
:

    ; hammer not picked up yet

    ; check if player on hammer
    lda     mapCacheIndex
    cmp     #CACHE_CENTER
    beq     :+
    ; player not on hammer, so nothing else to do
    rts

:
    ; change state, play sound and show dialog
    lda     #1
    sta     stateHammer

    jsr     sound_pickup

    ldx     #<dialogHammer
    ldy     #>dialogHammer
    jsr     set_dialog
    rts
  
.endproc

;-----------------------------------------------------------------------------
; tile_handler_vase
;-----------------------------------------------------------------------------
; stateVase[]: 0 = good, 1 = broken

.proc tile_handler_vase
    jsr     tile_handler_coord

    ; show broken vase if state not zero
    lda     specialX
    and     #VASE_COUNT-1
    tax
    lda     stateVase,x
    bne     broken_vase

    ; vase is not broken

    ; check if player on vase
    lda     mapCacheIndex
    cmp     #CACHE_CENTER
    bne     not_on_good_vase

    ; set vase to broken
    lda     #1
    sta     stateVase,x
    sta     stateAnyVase

    ; display dialog
    ldx     #<dialogVaseBreak
    ldy     #>dialogVaseBreak
    jsr     set_dialog

    ; CRASH!
    jsr     sound_crash

    rts

not_on_good_vase:

    ; check if next to vase
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; display dialog
    ldx     #<dialogVaseGood
    ldy     #>dialogVaseGood
    jsr     set_dialog
:
    rts


broken_vase:
    ; draw broken vase
    lda     #tileVaseBrokenId
    jsr     draw_tile

    ; check if next to vase
    jsr     tile_adjacent
    bcc     :+

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     :+

    ; display dialog
    ldx     #<dialogVaseBad
    ldy     #>dialogVaseBad
    jsr     set_dialog
:
    rts

.endproc


;-----------------------------------------------------------------------------
; tile_handler_bridge
;-----------------------------------------------------------------------------
; stateBridge: 0 = broken, 1 = fixed

.proc tile_handler_bridge
    jsr     tile_handler_coord

    ; if bridge is not fixed, all done
    lda     stateBridge
    bne     :+
    rts
:
    lda     #tileBoardwalkHId
    jsr     draw_tile

    ; clear cache so can walk over
    lda     #0
    ldy     mapCacheIndex
    sta     mapCache,y
    rts

.endproc

;-----------------------------------------------------------------------------
; Askey portrait
;-----------------------------------------------------------------------------

; Ending requires an 80-column card

.proc askey_portrait
    ; 80 columns
    jsr     $c300
    jsr     HOME
    jsr     inline_print
    StringQuoteReturn   "  @Good boy!@"
    StringQuoteReturn   "                >=~y,,                   Congratulations, you found Askey!"
    StringQuoteReturn   "             (;-=    C@/."
    StringQuoteReturn   "           >^<-yrC-   \[ `-                  Thanks for playing!"
    StringQuoteReturn   "     ;g@\`     ^^@    ]F   >,"
    StringQuoteReturn   "     V~s             ^A     ]"
    StringQuoteReturn   "      'v    ,=,   . ,@       L"
    StringQuoteReturn   "         ,@--@*\>  [@       /@           _,>,ww~=~r-~+.c"
    StringQuoteReturn   "               ]v  P,    ,=*}*-~,,,w=^@@@               ;@=c         ,-,c"
    StringQuoteReturn   "               ] C  -@*@`    P                           @h.-]*=~~r@J<@"
    StringQuoteReturn   "               [ |           C                             - *@@@*@"
    StringQuoteReturn   "               C ]            y                            ]"
    StringQuoteReturn   "               L J             \          -@-``'            L"
    StringQuoteReturn   "               ]  L             -       /\       ,A[@Y,     ]"
    StringQuoteReturn   "                )  v                   A    >wr@L   \  \;    @~"
    StringQuoteReturn   "                 ]w @.               yC.r@-`   >- ,<     `@v   ["
    StringQuoteReturn   "                   \S; ` @.   |   ,=@-     .~^-  C          t  C"
    StringQuoteReturn   "                    \  ]`'[   [@@-         ^~=-'            ]  C"
    StringQuoteReturn   "                    /  |  }   L                            /\  ]"
    StringQuoteReturn   "                 ]*-   /  |   C                            *^^^*"
    StringQuoteReturn   "                  @@@@-  r    |"
    StringQuoteReturn   "                         '*==*                     by Paul Wasson, 2021"
    .byte               0
    jsr     RDKEY

    lda     #$15
    jsr     COUT

    rts
.endproc


; Libraries
;-----------------------------------------------------------------------------

; add utilies
.include "inline_print.asm"


; Globals
;-----------------------------------------------------------------------------

drawPage:       .byte   0   ; should be either 0 or 4
gameTime:       .byte   0   ; +1 every turn
tileX:          .byte   0
tileY:          .byte   0
mapX:           .byte   START_X
mapY:           .byte   START_Y
specialX:       .byte   0
specialY:       .byte   0
textX:          .byte   0
textY:          .byte   0
lastKey:        .byte   0
dialogKey:      .byte   0
timerExpired:   .byte   0
mapCacheIndex:  .byte   0
mapCache:       .res    SCREEN_WIDTH*SCREEN_HEIGHT
dialogCacheIndex:
                .byte   0
; game state

stateHammer:    .byte  0
stateBridge:    .byte  0
stateAnyVase:   .byte  0
stateVase:      .res   VASE_COUNT
stateTimer:     .byte  0
stateMarker:    .byte  0

; Lookup tables
;-----------------------------------------------------------------------------

mapCacheX:
    .byte   0,8,16,24,32
    .byte   0,8,16,24,32
    .byte   0,8,16,24,32
    .byte   0,8,16,24,32
mapCacheY:
    .byte   0,0,0,0,0
    .byte   6,6,6,6,6
    .byte   12,12,12,12,12
    .byte   18,18,18,18,18
mapCacheOffsetX:
    .byte   0,1,2,3,4
    .byte   0,1,2,3,4
    .byte   0,1,2,3,4
    .byte   0,1,2,3,4
mapCacheOffsetY:
    .byte   0,0,0,0,0
    .byte   1,1,1,1,1
    .byte   2,2,2,2,2
    .byte   3,3,3,3,3

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

;-----------------------------------------------------------------------------
; Dialog
;-----------------------------------------------------------------------------

DIALOG_END =        0
DIALOG_TALK =       1
DIALOG_THOUGHT =    2

dialogInit: 
            .byte   DIALOG_THOUGHT
            .word   textInit
            .byte   DIALOG_END

dialogJr:   
            .byte   DIALOG_TALK
            .word   textJr1
            .byte   DIALOG_TALK
            .word   textJr2
            .byte   DIALOG_TALK
            .word   textJr3
            .byte   DIALOG_END

dialogGuard:
            .byte   DIALOG_TALK
            .word   textGuard1
            .byte   DIALOG_TALK
            .word   textGuard2
            .byte   DIALOG_END

dialogDoor: 
            .byte   DIALOG_THOUGHT
            .word   textDoor
            .byte   DIALOG_END

dialogDoghouse: 
            .byte   DIALOG_THOUGHT
            .word   textDoghouse
            .byte   DIALOG_END

dialogFence: 
            .byte   DIALOG_THOUGHT
            .word   textFence
            .byte   DIALOG_END

dialogMailbox: 
            .byte   DIALOG_THOUGHT
            .word   textMailbox1
            .byte   DIALOG_END

dialogHammer: 
            .byte   DIALOG_THOUGHT
            .word   textHammer
            .byte   DIALOG_END

dialogVaseGood: 
            .byte   DIALOG_THOUGHT
            .word   textVaseGood
            .byte   DIALOG_END

dialogVaseBreak: 
            .byte   DIALOG_TALK
            .word   textVaseBreak1
            .byte   DIALOG_THOUGHT
            .word   textVaseBreak2
            .byte   DIALOG_END

dialogVaseBad: 
            .byte   DIALOG_THOUGHT
            .word   textVaseBad
            .byte   DIALOG_END

dialogBed: 
            .byte   DIALOG_THOUGHT
            .word   textBed
            .byte   DIALOG_END

dialogFixerInit:
            .byte   DIALOG_TALK
            .word   textFixerInit1
            .byte   DIALOG_TALK
            .word   textFixerInit2
            .byte   DIALOG_END

dialogFixerBridge:
            .byte   DIALOG_TALK
            .word   textFixerBridge
            .byte   DIALOG_END

dialogFixerDone:
            .byte   DIALOG_TALK
            .word   textFixerDone1
            .byte   DIALOG_TALK
            .word   textFixerDone2
            .byte   DIALOG_END

dialogForestInit:
            .byte   DIALOG_TALK
            .word   textForestInit1
            .byte   DIALOG_TALK
            .word   textForestInit2
            .byte   DIALOG_TALK
            .word   textForestGo
            .byte   DIALOG_END

dialogForestWon:
            .byte   DIALOG_TALK
            .word   textForestWon1
            .byte   DIALOG_TALK
            .word   textForestWon2
            .byte   DIALOG_TALK
            .word   textForestWon3
            .byte   DIALOG_END

dialogForestLost:
            .byte   DIALOG_TALK
            .word   textForestLost1
            .byte   DIALOG_TALK
            .word   textForestLost2
            .byte   DIALOG_TALK
            .word   textForestGo
            .byte   DIALOG_END



; Standard dialog boxes are 14 wide and 4 high
;   --------------
;   --------------
;   --------------
;   --------------
;
; Thought bubbles are 20 wide and 4 high. (Can go 21 wide after first row)
;   --------------------
;   --------------------
;   --------------------
;   --------------------
;
; Could get 1 more row if use overwrite bottom of the box.  Use _ for spaces.
; Use CR with upper bit set ($8D) to go to the next line.


; Guard

textInit:
    .byte   $8d
    .byte   $8d
    StringHi    "  Where's Askey's?"
    .byte   0

textGuard1:
    .byte   $8d
    .byte   $8d
    StringHi    "     Hi!"
    .byte   0

textGuard2:
    .byte   $8d
    StringHi    "    How's"
    .byte   $8d
    StringHi    "  it going?"
    .byte   0

; Dog House

textDoghouse:
    .byte   $8d
    StringHi    "   Askey's doghouse"
    .byte   $8d
    StringHi    "      is empty."
    .byte   0

; Fence

textFence:
    .byte   $8d
    StringHi    " Oh no! There is a"
    .byte   $8d
    StringHi    " hole in the fence."
    .byte   0

; Hammer

textHammer:
    .byte   $8d
    .byte   $8d
    StringHi    "    Hammer time!"
    .byte   0

; JR

textJr1:
    .byte   $8d
    StringHi    " Sorry, but I"
    .byte   $8d
    StringHi    " haven't seen"
    .byte   $8d
    StringHi    " Askey today."
    .byte   0

textJr2:
    .byte   $8d
    StringHi    "That sure was"
    .byte   $8d
    StringHi    "a bad storm"
    .byte   $8d
    StringHi    "last night."
    .byte   0

textJr3:
    .byte   $8d
    StringHi    " The storm"
    .byte   $8d
    StringHi    " took out the"
    .byte   $8d
    StringHi    " bridge."
    .byte   0

; Fixer

textFixerInit1:
    StringHi    "I came to fix"
    .byte   $8d
    StringHi    "the bridge."
    .byte   $8d
    StringHi    "but I lost my"
    .byte   $8d
    StringHi    "hammer."
    .byte   0

textFixerInit2:
    .byte   $8d
    StringHi    " I think it"
    .byte   $8d
    StringHi    " might be in"
    .byte   $8d
    StringHi    " the forest."
    .byte   0

textFixerBridge:
    StringHi    "You found my"
    .byte   $8d
    StringHi    "hammer! I'll"
    .byte   $8d
    StringHi    "get this fixed"
    .byte   $8d
    StringHi    "in no time."
    .byte   0

textFixerDone1:
    .byte   $8d
    StringHi    "  Thanks for "
    .byte   $8d
    StringHi    "  finding my"
    .byte   $8d
    StringHi    "  hammer."
    .byte   0

textFixerDone2:
    .byte   $8d
    StringHi    "Hope you can"
    .byte   $8d
    StringHi    "find your dog."
    .byte   0

; Mailbox

textMailbox1:
    .byte   $8d
    .byte   $8d
    StringHi    "The mailbox is empty."
    .byte   0

; Vase

textVaseGood:
    .byte   $8d
    StringHi    "That vase looks pretty"
    .byte   $8d
    StringHi    "      fancy!"
    .byte   0

textVaseBreak1:
    .byte   $8d
    StringHi    " C R A S H !!"
    .byte   0

textVaseBreak2:
    .byte   $8d
    StringHi    "      Oh no!"
    .byte   $8d
    StringHi    " The vase slipped!"
    .byte   0

textVaseBad:
    .byte   $8d
    .byte   $8d
    StringHi    "Oh man, its busted."
    .byte   0

; Door

textDoor:
    .byte   $8d
    .byte   $8d
    StringHi    "The door is unlocked."
    .byte   0

; Bed

textBed:
    .byte   $8d
    .byte   $8d
    StringHi    "  I'm not tired."
    .byte   0

; Forest

textForestInit1:
    StringHi    "If you can run"
    .byte   $8d
    StringHi    "the forest"
    .byte   $8d
    StringHi    "loop before I"
    .byte   $8d
    StringHi    "count down to"
    .byte   0

textForestInit2:
    StringHi    "zero, I'll"
    .byte   $8d
    StringHi    "give you a"
    .byte   $8d
    StringHi    "prize. Start"
    .byte   $8d
    StringHi    "when I say go."
    .byte   0

textForestGo:
    .byte   $8d
    .byte   $8d
    StringHi    "    GO!!!"
    .byte   0

textForestLost1:
    .byte   $8d
    StringHi    "Better luck"
    .byte   $8d
    StringHi    "next time."
    .byte   0

textForestLost2:
    .byte   $8d
    StringHi    " Want to"
    .byte   $8d
    StringHi    "try again?"
    .byte   0

textForestWon1:
    .byte   $8d
    StringHi    "    Wow!"
    .byte   $8d
    StringHi    " You did it!"
    .byte   0

textForestWon2:
    .byte   $8d
    StringHi    " You win a"
    .byte   $8d
    StringHi    "commemorative"
    .byte   $8d
    StringHi    "   pen!"
    .byte   0

textForestWon3:
    .byte   $8d
    StringHi    " Your faster"
    .byte   $8d
    StringHi    "than Mr. Zip!"
    .byte   0

;-----------------------------------------------------------------------------
; Count down
;-----------------------------------------------------------------------------

.align 256

; padded to 16 bytes each
timerText:

.align 16
    .byte       $8d
    StringHi   " Ten!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   "Nine!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   "Eight!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   "Seven!"
    .byte       0

.align 16
    StringHi   "Six &"
    .byte       $8d
    StringHi   "a half"
    .byte       0

.align 16
    .byte       $8d
    StringHi   " Six!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   " Five!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   " Four!"
    .byte       0

.align 16
    StringHi   "Four"
    .byte       $8d
    StringHi   "again!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   "Three!"
    .byte       0

.align 16
    StringHi   "Two &"
    .byte       $8d
    StringHi   "a half"
    .byte       0

.align 16
    .byte       $8d
    StringHi   " Two!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   " One!"
    .byte       0

.align 16
    .byte       $8d
    StringHi   "Zero!!"
    .byte       0

.align 16
    StringHi   "Times"
    .byte       $8d
    StringHi   " up!"
    .byte       0

.align 16
    StringHi   " Too"
    .byte       $8d
    StringHi   " bad."
    .byte       0

;-----------------------------------------------------------------------------
; Game Map
;-----------------------------------------------------------------------------

.include "map.asm"

;-----------------------------------------------------------------------------
; Game tiles
;-----------------------------------------------------------------------------

.include "tiles.asm"

