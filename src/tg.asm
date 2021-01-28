;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Entry for text game contest
;
; Use text-base sprite and page flipping
;

.include "defines.asm"

.segment "CODE"
.org    $2000


.proc main

	; clear screen
	jsr     HOME

	; fill screen
	lda		#'.' | $80
	jsr		fill_screen_1

    ; display a greeting
    jsr     inline_print
    .byte   "Text Game - Paul Wasson - January 2021",13,0

    ; exit
    jmp		MONZ

.endproc

;-----------------------------------------------------------------------------
; fill_screen_1 or 2
;-----------------------------------------------------------------------------
; fill screen with character in A
; Careful to not overwrite "holes" in memory space

.proc fill_screen_1
	ldx		#0
loop:
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

.proc fill_screen_2
	ldx		#0
loop:
	sta		$800,x
	sta		$880,x
	sta		$900,x
	sta		$980,x
	sta		$a00,x
	sta		$a80,x
	sta		$b00,x
	sta		$b80,x
	inx
	cpx		#40*3
	bne		loop
	rts
.endproc

;-----------------------------------------------------------------------------
; draw_sprite_6x6
;-----------------------------------------------------------------------------
; Zero page: 
; 	sx - sprite x: 0..34
;	sy - sprite y: 0..18
;


; Libraries
;-----------------------------------------------------------------------------

; add utilies
.include "inline_print.asm"

; Globals
;-----------------------------------------------------------------------------

; Data
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




