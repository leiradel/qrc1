CMD_PORT         equ $de
CMD_PIXEL_LEFT   equ 0
CMD_PIXEL_RIGHT  equ 1
CMD_PIXEL_UP     equ 2
CMD_PIXEL_DOWN   equ 3
CMD_SET_PIXEL    equ 4
CMD_MESSAGE      equ 5
CMD_PRINT_WORD   equ 6
CMD_INVERT_PIXEL equ 7
CMD_SET_XY       equ 8

    org 0

    ld sp, 0

    call print
    db "copying message to encode", 0

    ld hl, message
    ld de, qrc11_message + 1
    ld b, 0
    ld c, (hl)
    inc c
    ldir

    call print
    db "encoding message", 0

    call qrc11_encmessage

    call print
    db "printing qr code", 0

    call qrc11_print

    call print
    db "done", 0

    halt

print:
    pop hl
    push af
    ld a, CMD_MESSAGE
    out (CMD_PORT), a

print_loop:
        ld a, (hl)
        inc hl

        out (CMD_PORT), a
        or a
    jr nz, print_loop

    pop af
    jp (hl)

message:
    db 8, "leiradel"

qrc_pixel_left:
    ld a, CMD_PIXEL_LEFT
    out (CMD_PORT), a
    ret

qrc_pixel_right:
    ld a, CMD_PIXEL_RIGHT
    out (CMD_PORT), a
    ret

qrc_pixel_up:
    ld a, CMD_PIXEL_UP
    out (CMD_PORT), a
    ret

qrc_pixel_down:
    ld a, CMD_PIXEL_DOWN
    out (CMD_PORT), a
    ret

qrc_invert_pixel:
    ld a, CMD_INVERT_PIXEL
    out (CMD_PORT), a
    ret

#include "../qrc11.asm"
