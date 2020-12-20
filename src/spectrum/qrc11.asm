; https://github.com/leiradel/qrc1

;qrc_pixel_up     equ qrc_pixel_up_1
;qrc_pixel_down   equ qrc_pixel_down_1
;qrc_pixel_left   equ qrc_pixel_left_1
;qrc_pixel_right  equ qrc_pixel_right_1
;qrc_invert_pixel equ qrc_invert_pixel_1
;start_pixel      equ $80

qrc_pixel_up     equ qrc_pixel_up_2
qrc_pixel_down   equ qrc_pixel_down_2
qrc_pixel_left   equ qrc_pixel_left_2
qrc_pixel_right  equ qrc_pixel_right_2
qrc_invert_pixel equ qrc_invert_pixel_2
start_pixel      equ $c0

;qrc_pixel_up     equ qrc_pixel_up_4
;qrc_pixel_down   equ qrc_pixel_down_4
;qrc_pixel_left   equ qrc_pixel_left_4
;qrc_pixel_right  equ qrc_pixel_right_4
;qrc_invert_pixel equ qrc_invert_pixel_4
;start_pixel      equ $f0

    org 24576

main:
    ; Encode the message.
    call qrc11_encmessage

    ; Set H and L to the top-left pixel where the code will be printed, H is Y
    ; and L is X & %11111000. The low bits of X are encoded in register C.
    ld hl, 40 << 8 | 8 << 3

    ; Set C to the first pixel in the byte (pixels here are 4x4 real pixels).
    ld c, start_pixel

    ; Print it onto the screen.
    call qrc11_print

    ret

include "plot.asm"
include "../qrc11.asm"
