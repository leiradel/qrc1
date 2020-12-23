; https://github.com/leiradel/qrc1

    org 16514

    db $76, $76      ; two new lines to hide the machine code in LIST

main:
    ; Set HL to the top-left character where the code will be printed.
    ld hl, ($400c)
column equ $ + 1
    ld de, 0
    add hl, de
    ld de, 33 * 6 + 1
    add hl, de

    ; Set C to the upper-left pixel in the character.
    ld c, 1

    ; Print it onto the screen.
    jp i25_print

i25_message:
    ds 9

include "plot.asm"
include "../i25_rom.asm"
