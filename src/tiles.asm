;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Game tiles
;
; Tried to group tiles logically but with gaps so new tiles can be inserted
; without having to redraw the map.
; 
; Would be nice to have a pre-processor to include a level of indirection
; between the tile # and the map #



;-----------------------------------------------------------------------------
; Jump table for special tiles
;-----------------------------------------------------------------------------
.align  256

; increment by 4

tile_jump_table:

    jmp     tile_handler_sign               ; $80
    nop
    jmp     tile_handler_guard              ; $84
    nop
    jmp     tile_handler_dog                ; $88
    nop
    jmp     tile_handler_door               ; $8c
    nop
    jmp     tile_handler_dog_house          ; $90
    nop
    jmp     tile_handler_fence              ; $94
    nop
    jmp     tile_handler_hammer             ; $98
    nop
    jmp     tile_handler_jr                 ; $9c
    nop
    jmp     tile_handler_fixer              ; $a0
    nop
    jmp     tile_handler_bridge             ; $a4
    nop
    jmp     tile_handler_mailbox            ; $a8
    nop
    jmp     tile_handler_vase               ; $ac
    nop
    jmp     tile_handler_bed1               ; $b0
    nop
    jmp     tile_handler_bed2               ; $b4
    nop
    jmp     tile_handler_forest             ; $b8
    nop
    jmp     tile_handler_marker             ; $bc
    nop
    jmp     tile_handler_easel              ; $c0
    nop

;-----------------------------------------------------------------------------
; Tile data
;-----------------------------------------------------------------------------

.align  256

tileSheet:

; 0 .. 15  ground

tileBlank:
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileGrass:
    StringHi    "      , "
    StringHi    "        "
    StringHi    " '      "
    StringHi    "     '  "
    StringHi    "  '     "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileFlower:
    StringHi    " @      "
    StringHi    "~|~  @  "
    StringHi    ".   `|' "
    StringHi    "  @   . "
    StringHi    " `|~  * "
    StringHi    "     `|'"
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileBoardwalkH:
    StringHi    "________"
    StringHi    "____|___"
    StringHi    "|_______"
    StringHi    "___|____"
    StringHi    "_______|"
    StringHi    "____|___"
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileBoardwalkV:
    StringHi    "|_|  | |"
    StringHi    "| |  |_|"
    StringHi    "| |__| |"
    StringHi    "|_|  | |"
    StringHi    "| |  |_|"
    StringHi    "| |__| |"
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileCarpet:
    StringHi    " /\  /\ "
    StringHi    "<  ><  >"
    StringHi    " \/  \/ "
    StringHi    " /\  /\ "
    StringHi    "<  ><  >"
    StringHi    " \/  \/ "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileCarpetFancy:
    StringHi    "//\\//\\"
    StringHi    "<<>><<>>"
    StringHi    "\\//\\//"
    StringHi    "//\\//\\"
    StringHi    "<<>><<>>"
    StringHi    "\\//\\//"
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileForestMarker:
    StringHi    "        "
    StringHi    "   `    "
    StringHi    " .    . "
    StringHi    "        "
    StringHi    "    '   "
    StringHi    "        "
    .byte   $bc,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement


    .res    64*(16 - 8)

; 16 .. 23  barriers

 tileTree1:
    StringHi    "   /\   "
    StringHi    "  //\\  "
    StringHi    " ///\\\ "
    StringHi    "////\\\\"
    StringHi    "   ||   "
    StringHi    "  ,||.  "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

 tileTree2:
    StringHi    "   __   "
    StringHi    "  (, )  "
    StringHi    " (  , ) "
    StringHi    "( ,  , )"
    StringHi    " (_  _) "
    StringHi    "   ][   "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileWall:
    StringInv   "    !   "
    StringInv   "____!___"
    StringInv   " !      "
    StringInv   "_!______"
    StringInv   "      ! "
    StringInv   "______!_"
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileFence:
    StringHi    "        "
    StringInv   "  :   : "
    StringHi    "  |   | "
    StringInv   "  :   : "
    StringHi    "  |   | "
    StringHi    "        "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileFenceHole:
    StringHi    "        "
    StringInv   "  :   : "
    StringHi    "      | "
    .byte       $20,$a0,$a0,$a0,$20,$20,$3a,$20
    StringHi    "      | "
    StringHi    "        "
    .byte   $80+5*4+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

    .res    64*(8 - 5)

; 24 .. 39 water

tileWater1:
    StringHi    "( ) ( ) "
    StringHi    ") ( ) ( "
    StringHi    "( ) ( ) "
    StringHi    ") ( ) ( "
    StringHi    "( ) ( ) "
    StringHi    ") ( ) ( "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking, animated

tileDuckL1:
    StringHi    "( ) ( ) "
    StringHi    "   _  ( "
    StringHi    " =(o)__ "
    StringHi    "  (___/ "
    StringHi    "(       "
    StringHi    ") ( ) ( "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking, animated


tileDuckR1:
    StringHi    "( ) ( ) "
    StringHi    ")   _   "
    StringHi    " __(o)= "
    StringHi    " \___)  "
    StringHi    "        "
    StringHi    ") ( ) ( "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking, animated

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileWater2:
    StringHi    ") ( ) ( "
    StringHi    "( ) ( ) "
    StringHi    ") ( ) ( "
    StringHi    "( ) ( ) "
    StringHi    ") ( ) ( "
    StringHi    "( ) ( ) "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking, animated


tileDuckL2:
    StringHi    ") ( ) ( "
    StringHi    "   _  ) "
    StringHi    " =(o)__ "
    StringHi    "  (___/ "
    StringHi    ")       "
    StringHi    "( ) ( ) "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking, animated

tileDuckR2:
    StringHi    ") ( ) ( "
    StringHi    "(   _   "
    StringHi    " __(o)= "
    StringHi    " \___)  "
    StringHi    "        "
    StringHi    "( ) ( ) "
    .byte   1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking, animated

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

    .res    64*(16 - 8)

; 40 .. 47 Decorations (Outdoors) 

tileDoor:
    StringInv   " .____. "
    StringInv   " !    ! "
    StringInv   " !    ! "
    StringInv   " !  O ! "
    StringInv   " !    ! "
    StringInv   " !____! "
    .byte   $80+3*4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; special (3), non-blocking

tileSign:
    StringInv   "        "
    StringInv   "        "
    StringInv   "        "
    StringInv   "        "
    StringHi    "   ||   "
    StringHi    "  ,||.  "
    .byte   $80+0*4+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; Special (0)

tileDogHouse:
    StringHi    "  /=\   "
    StringHi    " /===\  "
    StringHi    "/ASKEY\ "
    StringHi    "|==^==| "
    StringHi    "|=/ \=| "
    StringHi    "|=| |=| "
    .byte   $80+4*4+1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileDogDish:
    StringHi    "        " 
    StringHi    "        "                    
    StringHi    "        "                    
    StringHi    "        "                    
    StringHi    " __     "                    
    StringHi    "{__}    " 
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ;

tileMailBox1:
    StringHi    "   ____ "                    
    StringHi    "  /^\--\"                    
    StringHi    "  |_!__|"                    
    StringHi    "    ||  "                    
    StringHi    "    ||  " 
    StringHi    "   ,||. " 
    .byte   $a9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileMailBox2:
    StringHi    "   ____ "                    
    StringHi    "  /^\--\"                    
    StringHi    "  |[!__|"                    
    StringHi    "    ||  "                    
    StringHi    "    ||  " 
    StringHi    "   ,||. " 
    .byte   $a9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

    .res    64*(8 - 6)

; 48 .. 63 Decorations (Indoors)

tileVase:
    StringHi    "        "
    StringHi    "  ___   "
    StringHi    "  )^(   "
    StringHi    " /.:.\  "
    StringHi    " (^^^)  "
    StringHi    "  \_/   "
    .byte   $ac,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ; special

tileVaseBroken:
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    StringHi    " ,   .  "
    StringHi    " ( \%^. "
    StringHi    "' \_/ \ "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

tileTable:
    StringHi    "  ______"
    StringHi    " /     /"
    StringHi    "'====='|"
    StringHi    " |   | |"
    StringHi    " |   |  "
    StringHi    "        "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileEndTable:
    StringHi    "        "
    StringHi    "  ___   "
    StringHi    " {___}  "
    StringHi    " || ||  "
    StringHi    " |  |   "
    StringHi    "        "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileChair:
    StringHi    " .-==-. "
    StringHi    " | .. | "
    StringHi    " | .. | "
    StringHi    "()____()"
    StringHi    "||____||"
    StringHi    " W    W "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

tileBed1:
    StringHi    "  ()___ "
    StringHi    "()//__/)"
    StringHi    "||(___)/"
    StringHi    "||------"
    StringHi    "||______"
    StringHi    "||      "
    .byte   $b1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; blocking

tileBed2:
    StringHi    "        "
    StringHi    "______()"
    StringHi    "      /|"
    StringHi    "---()//|"
    StringHi    "___||/  "
    StringHi    "   ||   "
    .byte   $b5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; blocking

    .res    64*(16 - 7)

; 64 .. 95 People

tilePlayer1:
    StringHiBG  "...--...",'.'
    StringHiBG  ". (--) .",'.'
    StringHiBG  ". -\/- .",'.'
    StringHiBG  "./ || \.",'.'
    StringHiBG  ".  /\  .",'.'
    StringHiBG  ". |  | .",'.'
    .byte   0,$3f,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ; animated

tileFixer1:
    StringHi    " --==   "
    StringHi    "  (..)  "
    StringHi    "  (__)  "
    StringHi    " \/{}\  "
    StringHi    "   {} \ "
    StringHi    "   /\   "
    .byte   $a1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; Blocking, Special (1), animated

tileMrFancy1:
    StringHi    "   ..   "
    StringHi    "  (--)  "
    StringHi    " ( == ) "
    StringHi    " -/::\- "
    StringHi    " {_--_} "
    StringHi    "  I  I  "
    .byte   $85,$3e,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; 

tileGuard1:
    StringHi    "   ,_   "
    StringHi    "  (..)  "
    StringHi    "  (__) ^"
    StringHi    " \/[]\ |"
    StringHi    "   [] \|"
    StringHi    "   ||  |"
    .byte   $85,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; Blocking, Special (1), animated

tilePlayer2:
    StringHiBG  "...--...",'.'
    StringHiBG  ". (oo) .",'.'
    StringHiBG  ". -\/- .",'.'
    StringHiBG  "./ || \.",'.'
    StringHiBG  ".  /\  .",'.'
    StringHiBG  ". |  | .",'.'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; padding

tileFixer2:
    StringHi    " --==   "
    StringHi    "  (..)  "
    StringHi    "  (__)  "
    StringHi    "  /{}\  "
    StringHi    " / {} \ "
    StringHi    "   /\   "
    .byte   $a1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; Blocking, Special (1), animated

tileMrFancy2:
    StringHi    "   ..   "
    StringHi    "  (oo)  "
    StringHi    " ( == ) "
    StringHi    " -/::\- "
    StringHi    " {_--_} "
    StringHi    "  I  I  "
    .byte   $85,$3e,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileGuard2:
    StringHi    "   ,_   "
    StringHi    "  (..) ^"
    StringHi    "  (__) |"
    StringHi    "  /[]\/|"
    StringHi    " / []  |"
    StringHi    "   ||   "
    .byte   $85,$04,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ; Blocking, Special (1), animated

tileForest:
    StringHi    "  ####  "
    StringHi    "  [oo]  "
    StringHi    "  (--)  "
    StringHi    " -{__}- "
    StringHi    "  {__}  "
    StringHi    "   II   "
    .byte   $b9,$61,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; animated


tileQueen:
    StringBlock "# //\\ #"
    StringBlock "|//oo\\|"
    StringBlock "@/({})\@"
    StringBlock "@-{__}-@"
    StringBlock "@\{__}/@"
    StringBlock "@@@II@@@"
    .byte   $85,$71,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileJR:
    StringHi    "        "
    StringHi    "   __   "
    StringHi    "  (oo)  "
    StringHi    "  (==)  "
    StringHi    " _{__}_ "
    StringHi    "   II   "
    .byte   $9d,$41,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileSis:
    StringHi    "        "
    StringHi    "  ####  "
    StringHi    " #(**)# "
    StringHi    "##(==)##"
    StringHi    " /{__}\ "
    StringHi    "   II   "
    .byte   $85,$12,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileForest2:
    StringHi    "  ####  "
    StringHi    "  [oo]  "
    StringHi    "  (==)  "
    StringHi    " -{__}- "
    StringHi    "  {__}  "
    StringHi    "   II   "
    .byte   $b9,$61,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; animated

tileQueen2:
    StringBlock "# //\\ #"
    StringBlock "|//oo\\|"
    StringBlock "@/(==)\@"
    StringBlock "@-{__}-@"
    StringBlock "@\{__}/@"
    StringBlock "@@@II@@@"
    .byte   $85,$31,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileJR2:
    StringHi    "        "
    StringHi    "   __   "
    StringHi    "  (oo)  "
    StringHi    "  (==)  "
    StringHi    " -{__}- "
    StringHi    "   II   "
    .byte   $9d,$41,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileSis2:
    StringHi    "        "
    StringHi    "  ####  "
    StringHi    " #(..)# "
    StringHi    "##(==)##"
    StringHi    " /{__}\ "
    StringHi    "   II   "
    .byte   $85,$22,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tilePainter:
    StringHi    "   /\   "
    StringHi    "  (OO)  "
    StringHi    "  \==/* "
    StringHi    " --[]-| "
    StringHi    "   ||   "
    StringQuote "   @@   "
    .byte   $85,$04,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tilePainter2:
    StringHi    "   /\   "
    StringHi    "  (OO)  "
    StringHi    "  \==/ *"
    StringHi    " --[]-/ "
    StringHi    "   ||   "
    StringQuote "   @@   "
    .byte   $85,$04,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

    .res    64*(32 - 24)

; 96 .. 103 Animals

tileDog1:
    StringHi    "        "
    StringHi    "        "
    StringHi    "     __ "
    StringHi    "\__()'`;"
    StringHi    "/    /` "
    StringHi    "\\--\\  "
    .byte   $89,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ; Special (2)

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileDog2:
    StringHi    "        "
    StringHi    "        "
    StringHi    "     __ "
    StringHi    "___()'`;"
    StringHi    "/    /` "
    StringHi    "\\--\\  "
    .byte   $89,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ; Special (2)

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; filler
    StringHi    "        "
    StringHi    "        "
    StringHi    "    ?   "
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

; 104 .. 127 Interface

tileDialogRightSM:
    StringHiBG  "~______~",'~'
    StringHiBG  "<      |",'~'
    StringHiBG  "|      |",'~'
    StringHiBG  "|______|",'~'
    StringHiBG  "~~~~~~~~",'~'
    StringHiBG  "~~~~~~~~",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

tileDialogRightMD:
    StringHiBG  "~______~",'~'
    StringHiBG  "<      |",'~'
    StringHiBG  "|      |",'~'
    StringHiBG  "|      |",'~'
    StringHiBG  "|      |",'~'
    StringHiBG  "|______|",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

tileDialogL:
    StringHiBG  "~_______",'~'
    StringHiBG  "|       ",'~'
    StringHiBG  "|       ",'~'
    StringHiBG  "|       ",'~'
    StringHiBG  "|       ",'~'
    StringHiBG  "|_______",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

tileDialogR:
    StringHiBG  "_______~",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "_______|",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

tileThoughtL:
    StringHiBG  "~~______",'~'
    StringHiBG  "~(      ",'~'
    StringHiBG  "(       ",'~'
    StringHiBG  "(       ",'~'
    StringHiBG  "(       ",'~'
    StringHiBG  "~(______",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

tileThoughtM:
    StringHiBG  "________",'~'
    StringHiBG  "        ",'~'
    StringHiBG  "        ",'~'
    StringHiBG  "        ",'~'
    StringHiBG  "        ",'~'
    StringHiBG  "________",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

tileThoughtR:
    StringHiBG  "______~~",'~'
    StringHiBG  "      )~",'~'
    StringHiBG  "       )",'~'
    StringHiBG  "       )",'~'
    StringHiBG  "       )",'~'
    StringHiBG  "______)~",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

    .res    64*(24-7)

; 128+ Objects

tileHammer:
    StringHi    "   ___  "
    StringHi    "  [_ _} "
    StringHi    "    I   "
    StringHi    "    I   "
    StringHi    "    I   "
    StringHi    "        "
    .byte   $80+6*4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement


tileBrokenBridge:
    StringHi    "_     __"
    StringHi    "_>    >_"
    StringHi    "<    <__"
    StringHi    "_>    >_"
    StringHi    "<    <__"
    StringHi    "_>    >_"
    .byte   $a5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileWallPainting:
    StringInv   "   /\   "
    StringInv   " +----+ "
    StringInv   " !    ! "
    StringInv   " !    ! "
    StringInv   " +----+ "
    StringInv   "        "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileEasel:
    StringBlock " _____  "
    StringBlock " @@@@@  "
    StringBlock " @@@@@  "
    StringBlock " %%%%%  "
    StringBlock " | | |  "
    StringBlock " |   |  "
    .byte   $c1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tilePen:
    StringHi    "        "
    StringHi    "    .   "
    StringHi    "    |   "
    StringHi    "    '   "
    StringHi    "        "
    StringHi    "        "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement


