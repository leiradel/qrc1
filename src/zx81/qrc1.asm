; https://github.com/leiradel/qrc1

    org 16514

    db $76, $76      ; two new lines to hide the machine code in LIST


main:
    ; Translate the character set from ZX81 to ASCII.
    call to_ascii

    ; Encode the message.
    call qrc1_encmessage

    ; Set HL to the top-left character where the code will be printed.
    ld hl, ($400c)
    ld de, 33 * 6 + 11
    add hl, de

    ; Set C to the upper-left pixel in the character.
    ld c, 1

    ; Print it onto the screen.
    call qrc1_print

    ret

to_ascii:
    ; Make HL point to the unencoded message.
    ld hl, qrc1_message

    ; B has the message length.
    ld b, (hl)
    inc hl

xlate_loop:
        ; Put the ZX81 character in A, making sure it's valid and non-inverted.
        ld a, (hl)
        and $3f

        ; Get the corresponding ASCII character in the translation table.
        add a, xlate_table & $ff
        ld e, a
        ld a, 0
        adc a, xlate_table >> 8
        ld d, a
        ld a, (de)

        ; Overwrite with the ASCII char.
        ld (hl), a
        inc hl
    djnz xlate_loop
    ret

xlate_table:
    ; spc gra gra gra gra gra gra gra gra gra gra  "   £   $   :   ?
    db ' ', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '"', '?', '$', ':', '?'

    ;  (   )   >   <   =   +   -   *   /   ;   ,   .   0   1   2   3
    db '(', ')', '>', '<', '=', '+', '-', '*', '/', ';', ',', '.', '0', '1', '2', '3'

    ;  4   5   6   7   8   9   A   B   C   D   E   F   G   H   I   J
    db '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'

    ;  K   L   M   N   O   P   Q   R   S   T   U   V   W   X   Y   Z
    db 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'

include "plot.asm"
include "../qrc1_rom.asm"
include "../qrc1_ram.asm"
