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

; tiles
tilePlayerId =          (tilePlayer1            - tileSheet) / TILE_SIZE
tileDialogRightSMId =   (tileDialogRightSM      - tileSheet) / TILE_SIZE
tileDialogRightMDId =   (tileDialogRightMD      - tileSheet) / TILE_SIZE
tileDog2Id =            (tileDog2               - tileSheet) / TILE_SIZE

; Player starting location
START_X         = 2   
START_Y         = 3

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

.segment "CODE"
.org    $C00


.proc main

    ; make sure we are in 40-column mode
    lda     #$15
    jsr     COUT

    ; Since draw-map draws the whole screen,
    ; no need to clear screen at startup

    ; set starting position
    lda     #START_X
    sta     mapX
    lda     #START_Y
    sta     mapY

    jmp     gameLoop

movement:
    jsr     sound_walk

gameLoop:
    inc     gameTime
    bne     :+
    inc     gameTimeHi
:   
    jsr     draw_screen

commandLoop:    
    jsr     get_key
    sta     lastKey     ; record last key press

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

    ;------------------
    ; Time-out
    ;------------------
    cmp     #$ff
    bne     :+
    jmp     gameLoop
:

    jmp     commandLoop

bump:
    jsr     sound_bump
    jmp     gameLoop

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
    lda     #$ff
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
; fill_screen
;-----------------------------------------------------------------------------

.proc fill_screen
    ldx     #0
loop:
    lda     #$a0
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
; draw_tile
;-----------------------------------------------------------------------------
; Tiles are 48 bytes, but pad to 64 so no page crossings

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
    .byte   $8d
    StringInv   " HOUSE"
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
    jsr     tile_handler_coord

    ; check if guard is above or to the right of the player
    lda     mapCacheIndex
    cmp     #CACHE_UP
    beq     :+
    cmp     #CACHE_RIGHT
    beq     :+
    cmp     #CACHE_DOWN
    bne     done
:

    ; check if hit action key
    lda     lastKey
    cmp     #KEY_WAIT
    bne     display

    inc     state
    lda     state
    cmp     #3
    bmi     :+
    lda     #0
    sta     state
    jmp     display
:   
    jsr     sound_talk

display:    
    ; display a message based on state
    lda     state
    bne     :+
    rts     ; zero = no display 
:

    ; Display message
    ; move 1 space to the right
    clc
    lda     tileX
    adc     #TILE_WIDTH
    sta     tileX
    sta     textX

    ; set text pointers
    inc     textX
    inc     textY

    ; 1 = hi
    lda     state
    cmp     #1
    bne     :+
    lda     #tileDialogRightSMId
    jsr     draw_tile

    lda     #<guardText1
    sta     textPtr0
    lda     #>guardText1
    sta     textPtr1
    jmp     tile_print
    rts

:
    ; 2 = hows it going
    lda     #tileDialogRightMDId
    jsr     draw_tile
    lda     #<guardText2
    sta     textPtr0
    lda     #>guardText2
    sta     textPtr1
    jmp     tile_print

    rts

done:
    ; reset state if player moves
    lda     #0
    sta     state
    rts

state:  .byte 0

guardText1:
    .byte   $8d
    StringHi    "Hi!"
    .byte   0

guardText2:
    .byte   $8d
    StringHi    "How's"
    .byte   $8d
    StringHi    "it"
    .byte   $8d
    StringHi    "going?"
    .byte   0
.endproc


;-----------------------------------------------------------------------------
; tile_handler_dog
;-----------------------------------------------------------------------------
.proc tile_handler_dog

    jsr     tile_handler_coord

    ; check if player is near dog
    lda     mapCacheIndex
    cmp     #CACHE_UP
    beq     :+
    cmp     #CACHE_RIGHT
    beq     :+
    cmp     #CACHE_DOWN
    beq     :+
    cmp     #CACHE_LEFT
    beq     :+
    cmp     #CACHE_CENTER
    beq     winning

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

winning:
    jmp     end_screen_80

state:  .byte   0
dogText1:
    .byte   $8d
    StringHi    "BARK!"
    .byte   0


.endproc


;-----------------------------------------------------------------------------
; Ending Screen
;-----------------------------------------------------------------------------

; Ending requires an 80-column card

.proc end_screen_80
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
    .byte               "-->",0
    jsr     RDKEY
    jsr     inline_print
    .byte               " Goodbye <--",0

    jmp     MONZ
.endproc


; Libraries
;-----------------------------------------------------------------------------

; add utilies
.include "inline_print.asm"


; Globals
;-----------------------------------------------------------------------------

drawPage:   .byte   0   ; should be either 0 or 4
gameTime:   .byte   0   ; +1 every turn
gameTimeHi: .byte   0   ; upper byte
tileX:      .byte   0
tileY:      .byte   0
mapX:       .byte   START_X
mapY:       .byte   START_Y
specialX:   .byte   0
specialY:   .byte   0
textX:      .byte   0
textY:      .byte   0
lastKey:    .byte   0

mapCacheIndex:
            .byte   0

mapCache:   .res    SCREEN_WIDTH*SCREEN_HEIGHT


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
; Game Map
;-----------------------------------------------------------------------------

.include "map.asm"

;-----------------------------------------------------------------------------
; Game tiles
;-----------------------------------------------------------------------------

.include "tiles.asm"

