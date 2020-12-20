; https://github.com/leiradel/qrc1

qrc_pixel_up     equ qrc_pixel_up_4
qrc_pixel_down   equ qrc_pixel_down_4
qrc_pixel_left   equ qrc_pixel_left_4
qrc_pixel_right  equ qrc_pixel_right_4
qrc_invert_pixel equ qrc_invert_pixel_4
start_pixel      equ $f0

    org 24576

ramtop equ $ - 1

main:
    ; Encode the message.
    call qrc1_encmessage

    ; Set H and L to the top-left pixel where the code will be printed, H is Y
    ; and L is X & %11111000. The low bits of X are encoded in register C.
    ld hl, 48 << 8 | 10 << 3

    ; Set C to the first pixel in the byte.
    ld c, start_pixel

    ; Print it onto the screen.
    call qrc1_print

    ret

include "plot.asm"
include "../qrc1.asm"
