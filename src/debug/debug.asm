CMD_PORT        equ $de
CMD_PIXEL_LEFT  equ 0
CMD_PIXEL_RIGHT equ 1
CMD_PIXEL_UP    equ 2
CMD_PIXEL_DOWN  equ 3
CMD_SET_PIXEL   equ 4
CMD_MESSAGE     equ 5

    org 0

    ld sp, 0

    call print
    db "copying message to encode", 0

    ld hl, message
    ld de, qrc1_message
    ld bc, 15
    ldir

    call print
    db "encoding message", 0

    call qrc1_encmessage

    call print
    db "printing qr code", 0

    call qrc1_print

    call print
    db "end of execution", 0

    halt

print:
    ld a, CMD_MESSAGE
    out (CMD_PORT), a
    ex (sp), hl
    push af

print_loop:
        ld a, (hl)
        inc hl

        out (CMD_PORT), a
        or a
    jr nz, print_loop

    pop af
    ex (sp), hl
    ret

message:
    db 12, "cutt.ly/QRC1"

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

qrc_set_pixel:
    ld a, CMD_SET_PIXEL
    out (CMD_PORT), a
    ret

#include "../qrc1.asm"
