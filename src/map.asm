;-----------------------------------------------------------------------------
; Paul Wasson - 2021
;-----------------------------------------------------------------------------
; Game map
; 64 wide
; height is easy to change and will be added to as the map progresses
; Need to block all the edges: 2 tiles on the side and top and 1 on the bottom

.align  256

; Easy to change height, but more work to change width.  64 wide seems to give lots of room.
; Can adjust height as needed

; 64 x 16
map:
    ;       0                       8                       16                      24                      32                        40                          48                      56                   
    ;       |                       |                       |                       |                       |                         |                           |                       |   
    .byte   16,16,16,17,16,16,16,16,17,16,17,16,16,16,16,24,24,24,24,24,18,18,18,18,18,18,18,18,18,18,18,18,18,16,16,17,16, 17,16, 16,16, 17,17, 16,17, 16, 16,16,16,17,17,16,16,16,17,16,17,17,16,17,16,16,16,16 ;0
    .byte   16,18,18,18,18,18,18,18,18,16,17,16,17,16,16,17,24,24,24,24,18,18,18,18,18,18,18,18,18,53,54,51,18,16,17,16,16, 16,17, 17,16, 17,16, 16,16, 17, 16,16,17,16,16,17,16,17,16,16,16,17,16,16,16,17,16,17
    .byte   16,18,18,18,18,130,18,18,18,1, 1, 1, 1, 0, 0, 0, 0,24,24,24,18,18,18,48, 6,52, 6,48,18, 6, 6,52,18, 1, 2, 2, 2,  2,17,  2, 2,  1, 2, 17,16, 16,  1, 0, 1, 0,16,16,16,16, 0, 1, 1, 0, 0,16,16,16,16,16
    .byte   16,18,18,53,54, 0,51,52,18, 2, 0,17, 0, 1,74, 1, 0, 0,24,24,18,18,18, 6, 6, 6, 6, 6,18, 6, 6, 6,18,16, 0, 2, 2, 17, 1,  1, 0,  0, 1,  1,17, 16,  1,16,16, 1,16,16,16,16, 0,16,16,16, 0, 1, 1,16,16,16
    .byte   17,18,18, 0, 0, 0, 0, 0,40, 0, 8, 3, 3, 9, 0,17, 0, 0,24,24,18,18,130,6,52,50,52, 6, 6, 6, 6,48,18, 0, 1, 2,17,  1, 1,  2,24, 24, 2,  0, 2, 17,  1, 1, 0, 0,16,16,16, 1, 0,16,16,16,16,16, 0, 0,16,16
    .byte   16,18,18,50, 0, 0, 0, 0,18, 2,44, 1, 2, 4, 0, 0, 0, 0,24,24,18,18,18, 6, 6, 6, 6, 6,18,18,18,18,18, 1, 0, 2, 2,  1,66, 25,24, 26,24,  1, 2, 17,  0,16, 1, 1,16,16,16, 0,16,16, 0, 0, 0, 1,16, 1,17,16
    .byte   16,18,18,18,18,40,18,18,18, 2, 0, 1, 0, 4, 0, 1, 0, 0,24,24,18,18,18,18,40,18,18,18,18, 2, 2, 2, 2, 0, 1, 0, 0,  1, 1, 24,25, 24,25,  0, 2, 17,  1, 1,16, 0,16,16,16, 1,16,16, 1,16,16, 0, 1, 0,16,17
    .byte   16,17, 1,42,43, 1, 0, 0,17, 0, 0, 1, 0, 4, 0, 1, 0, 1,24,24, 1, 2, 2, 2,46, 2, 2, 2, 2, 2, 1, 0, 1, 0, 1,41, 0,  1, 1, 24,26, 24,24,  0, 2, 17,  1, 1, 0, 0,16,16,16, 1,16,16, 1,16,16,16,16,16,16,17
    .byte   17,16, 0, 1, 0, 0, 1, 0,17, 1, 1, 1, 1, 4, 0, 1,65, 1,24,24, 0, 1, 0,41,12,44, 0, 1, 0, 1,17, 1, 0,17, 1, 1, 0,  1, 1,  2,24, 24, 2,  1,17,  1,  0, 0, 1, 1,16,16,16, 0,16, 1, 1,16, 0, 1, 1, 0,17,16 ;8
    .byte   16,17,19,19,19,19,20,19,16, 0, 0,17, 0,10, 3, 3, 3,3,129,129,3, 3, 3, 3,11, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 9, 1, 17, 1,  0, 1,  0, 1,  0,17,  1,  1,16, 0, 0, 1,16,16, 0,16, 0,16, 1, 7,16,16, 1,16,17
    .byte   17,16, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0,24,24, 0, 4, 1, 0, 1, 0, 1, 0, 1, 0, 0,17, 0, 1, 0, 4, 0, 17,17, 17, 2,  2,17, 17, 1,  1,  0, 0,16, 1, 0,41,16, 1,16, 1, 1, 0,16,16, 1, 1,17,16
    .byte   16,16, 1,17,16,16,16,16,17,16,17,16,16,16,17,17,17,16,16,24, 1, 4, 1, 0, 1,75, 0, 0,17, 0, 1, 1, 1, 1, 0, 4, 1,  0, 0,  1,17, 17, 1,  1, 0,  1,  0, 0, 1, 0, 1, 1, 0, 0,72,16,16,16,16,16, 1,16,16,16
    .byte   16,17, 1,16, 1, 0, 1,16, 1, 1, 1,16,17,16, 2,16,16,16,16,24,16, 4, 0,17, 2, 0,16, 1, 0, 1,16, 1, 1,16, 1,10, 3,  3, 3,  3, 3,  3, 3,  3, 3,  3,  3, 3, 3, 3, 9, 0,16, 1,16,16, 1, 1, 1,16, 1, 1,16,17
    .byte   16,16, 1,17,16,16, 1,16, 0,16, 1,16, 1, 0, 1,17,16,128,1,24,17, 4, 1, 2,18,18,18,18,18,18,18,18,18,18,17, 0, 1,  1, 1,  0,17, 16, 0,  1, 1,  1,  0, 0, 0, 1, 0,16,16, 1,16,16, 1,16, 0,16,16, 0,16,16
    .byte   16,17, 1, 1, 1, 0, 1, 1, 1,16, 1, 1, 0,16, 1,16,16,16, 1,24,16, 4, 1, 2,18, 0,73,58,18,18,18,18,18,18,18,18,18, 18,18, 18,18, 18,18, 18,18, 18, 18,18,18,17, 1,16, 0, 0,16,16, 0,16, 1,16,16, 0,16,17
    .byte   16,16,16,17, 1,16,16,16,17,16, 0,16,16,16, 0,17,16,16, 1,24, 1, 4, 1, 0,18, 6, 5, 6,18, 5,52,52,52, 5,18,18,130,18,18,130,18,130,18,130,18, 18,130,18,18, 0, 1,16, 1,16,16,16, 1,16, 1,16,16, 1,16,16
    .byte   16,17, 1, 1, 0,17,17, 1, 1, 0, 1,16,17,16, 0, 1, 1, 1, 1,24, 0, 4, 1, 1,18, 6, 5, 6,18,52,55,56,57,52,18, 6, 6,  6, 6,  6, 6,  6, 6,  6, 6,  6,  6,18,18, 1, 0,16, 1, 1, 0, 1, 1,16, 0, 1, 1, 0,16,17 ;16
    .byte   16,16,16,17, 1, 1, 1,16,17,16,17,16,16,16,16,17,17,16,24,24, 2, 4,41,67,18, 6, 5, 6,18, 5,52,52,52, 5,18, 6, 6,  6, 6,  6, 6,  6, 6,  6, 6,  6,  6,18,18,17,17,16,16,16,17,16,17,17,16,17,16,16,16,16
    .byte   16,17, 0, 1, 1,17, 1,16,16,16,17, 0, 2, 1, 1,16,16,16,24,24, 1,10, 3, 9,47, 5, 5, 6,18, 5, 5, 5, 5, 5,18,18,18,  6, 6,  6,18, 18,18, 18,18, 18, 18,18,18, 2, 2, 2, 1, 2, 2, 1, 2, 1, 2, 0, 1, 1,16,17
    .byte   16,16,16,17,16,16, 1,16,17,16,17, 1,16,16, 2,17, 0, 1,24,24, 2, 2, 2, 2,18, 6, 6, 6,18, 6,18,18,18,18,18, 6,41,  6, 6,  6,41,  6, 6,  6, 5,  6,  6, 6, 8, 3, 9, 0, 1, 0, 1, 1, 0, 1, 0, 0,96, 0,16,16
    .byte   16,17,16,16,16,17, 1, 1, 1, 1, 0, 1,17,16, 1, 1, 1,16,24,24,17,16,17,16,18, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,  6, 6,  6, 6,  6, 6,  6, 5,  6,  6, 6, 8, 3, 9, 2, 2, 1, 2, 2, 1,80,131,1, 1, 1,16,17
    .byte   16,17,16,16,16,17,17,16,16,16,17,16,17,16,16,16,16,16,24,24,16,16,16,16,18,18,18,18,18,18,18,18,18,18,18,18,18, 18,18, 18,18, 18,18, 18,18, 18, 18,18,18,16,16,17,16,17,16,16,16,17,16,16,16,17,16,17
