; https://github.com/leiradel/qrc1

qrc_pixel_up     equ qrc_pixel_up_2
qrc_pixel_down   equ qrc_pixel_down_2
qrc_pixel_left   equ qrc_pixel_left_2
qrc_pixel_right  equ qrc_pixel_right_2
qrc_invert_pixel equ qrc_invert_pixel_2
start_pixel      equ $c0

    org 24576

ramtop equ $ - 1

main:
    ; Set H and L to the top-left pixel where the code will be printed, H is Y
    ; and L is X & %11111000. The low bits of X are encoded in register C.
column equ $ + 1
    ld hl, 48 << 8

    ; Set C to the first pixel in the byte.
    ld c, start_pixel

    ; Print it onto the screen.
    jp i25_print

i25_message:
    ds 17

include "plot.asm"
include "../i25_rom.asm"
