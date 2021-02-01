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

tile_jump_table:

    jmp     tile_handler_sign
    nop
    jmp     tile_handler_guard
    nop
    jmp     tile_handler_dog
    nop
    jmp     tile_handler_door
    nop

    ; fill rest with BRK
    .res    256-5,0

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

    .res    64*(16 - 7)

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
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

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
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileDogDish:
    StringHi    "        " 
    StringHi    "        "                    
    StringHi    "        "                    
    StringHi    "        "                    
    StringHi    " __     "                    
    StringHi    "{__}    " 
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ;

tileMailBox:
    StringHi    "   ____ "                    
    StringHi    "  /^\--\"                    
    StringHi    "  |_!__|"                    
    StringHi    "    ||  "                    
    StringHi    "    ||  " 
    StringHi    "   ,||. " 
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

    .res    64*(8 - 5)

; 48 .. 63 Decorations (Indoors)

tileVase:
    StringHi    "        "
    StringHi    "  ___   "
    StringHi    "  )^(   "
    StringHi    " /.:.\  "
    StringHi    " (^^^)  "
    StringHi    "  \_/   "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileVaseBroken:
    StringHi    "        "
    StringHi    "        "
    StringHi    "        "
    StringHi    " ,   .  "
    StringHi    " ( \%^. "
    StringHi    "' \_/ \ "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

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
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileBed1:
    StringHi    "  ()___ "
    StringHi    "()//__/)"
    StringHi    "||(___)/"
    StringHi    "||------"
    StringHi    "||______"
    StringHi    "||      "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

tileBed2:
    StringHi    "        "
    StringHi    "______()"
    StringHi    "      /|"
    StringHi    "---()//|"
    StringHi    "___||/  "
    StringHi    "   ||   "
    .byte   1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; blocking

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
    .byte   $85,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; Blocking, Special (1), animated

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
    .byte   $85,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; Blocking, Special (1), animated

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

tileDad:
    StringHi    "  ####  "
    StringHi    "  [oo]  "
    StringHi    "  (--)  "
    StringHi    " -{__}- "
    StringHi    "  {__}  "
    StringHi    "   II   "
    .byte   $85,$61,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; animated


tileMom:
    StringHi    "  //\\  "
    StringHi    " //oo\\ "
    StringHi    " /({})\ "
    StringHi    " -{__}- "
    StringHi    "  {__}  "
    StringHi    "   II   "
    .byte   $85,$71,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileJR:
    StringHi    "        "
    StringHi    "   __   "
    StringHi    "  (oo)  "
    StringHi    "  (==)  "
    StringHi    " _{__}_ "
    StringHi    "   II   "
    .byte   $85,$41,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileSis:
    StringHi    "        "
    StringHi    "  ####  "
    StringHi    " #(**)# "
    StringHi    "##(==)##"
    StringHi    " /{__}\ "
    StringHi    "   II   "
    .byte   $85,$12,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileDad2:
    StringHi    "  ####  "
    StringHi    "  [oo]  "
    StringHi    "  (==)  "
    StringHi    " -{__}- "
    StringHi    "  {__}  "
    StringHi    "   II   "
    .byte   $85,$61,0,0,0,0,0,0,0,0,0,0,0,0,0,0    ; animated

tileMom2:
    StringHi    "  //\\  "
    StringHi    " //oo\\ "
    StringHi    " /(==)\ "
    StringHi    " -{__}- "
    StringHi    "  {__}  "
    StringHi    "   II   "
    .byte   $85,$31,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileJR2:
    StringHi    "        "
    StringHi    "   __   "
    StringHi    "  (oo)  "
    StringHi    "  (==)  "
    StringHi    " -{__}- "
    StringHi    "   II   "
    .byte   $85,$41,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

tileSis2:
    StringHi    "        "
    StringHi    "  ####  "
    StringHi    " #(..)# "
    StringHi    "##(==)##"
    StringHi    " /{__}\ "
    StringHi    "   II   "
    .byte   $85,$22,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

    .res    64*(32 - 16)

; 96 .. 103 Animals

tileDog1:
    StringHi    "        "
    StringHi    "        "
    StringHi    "     __ "
    StringHi    "\__()'`;"
    StringHi    "/    /` "
    StringHi    "\\--\\  "
    .byte   $80+2*4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ; Special (2)

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
    .byte   $80+2*4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0   ; Special (2)

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

tileDialogRightLG1:
    StringHiBG  "~_______",'~'
    StringHiBG  "<       ",'~'
    StringHiBG  "|       ",'~'
    StringHiBG  "|       ",'~'
    StringHiBG  "|       ",'~'
    StringHiBG  "|_______",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

tileDialogRightLG2:
    StringHiBG  "_______~",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "       |",'~'
    StringHiBG  "_______|",'~'
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0             ; padding

    .res    64*(24-4)

; 128+ Objects

tileHammer:
    StringHi    "   ___  "
    StringHi    "  [_ _} "
    StringHi    "    I   "
    StringHi    "    I   "
    StringHi    "    I   "
    StringHi    "        "
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement


tileBrokenBridge:
    StringHi    "_     __"
    StringHi    "_>    >_"
    StringHi    "<    <__"
    StringHi    "_>    >_"
    StringHi    "<    <__"
    StringHi    "_>    >_"
    .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; free-movement

