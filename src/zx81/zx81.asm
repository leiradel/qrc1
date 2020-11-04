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

; Moves the cursor one pixel to the left.
qrc_pixel_left:
    ; 1 -> 2 | 0001 -> 0010 dec hl
    ; 4 -> 8 | 0100 -> 1000 dec hl
    ; 2 -> 1 | 0010 -> 0001
    ; 8 -> 4 | 1000 -> 0100
    ld a, 5
    and c
    jr z, qrc_dont_dec
        sla c
        dec hl
        ret
qrc_dont_dec:
    srl c
    ret

; Moves the cursor one pixel to the right.
qrc_pixel_right:
    ; 1 -> 2 | 0001 -> 0010
    ; 4 -> 8 | 0100 -> 1000
    ; 2 -> 1 | 0010 -> 0001 inc hl
    ; 8 -> 4 | 1000 -> 0100 inc hl
    ld a, 5
    and c
    jr nz, qrc_dont_inc
        srl c
        inc hl
        ret
qrc_dont_inc:
    sla c
    ret

; Moves the cursor one pixel up.
qrc_pixel_up:
    ; 1 -> 4 | 0001 -> 0100 sub hl, 33
    ; 2 -> 8 | 0010 -> 1000 sub hl, 33
    ; 4 -> 1 | 0100 -> 0001
    ; 8 -> 2 | 1000 -> 0010
    ld a, 3
    and c
    jr z, qrc_dont_sub
        sla c
        sla c
        ld a, l
        sub 33
        ld l, a
        ld a, h
        sbc a, 0
        ld h, a
        ret
qrc_dont_sub:
    srl c
    srl c
    ret

; Moves the cursor one pixel down.
qrc_pixel_down:
    ; 1 -> 4 | 0001 -> 0100
    ; 2 -> 8 | 0010 -> 1000
    ; 4 -> 1 | 0100 -> 0001 add hl, 33
    ; 8 -> 2 | 1000 -> 0010 add hl, 33
    ld a, 3
    and c
    jr nz, qrc_dont_add
        srl c
        srl c
        ld a, l
        add a, 33
        ld l, a
        ld a, h
        adc a, 0
        ld h, a
        ret
qrc_dont_add:
    sla c
    sla c
    ret

qrc_set_pixel:
    ld a, (hl)
    bit 7, a
    jr z, qrc_invert1
        xor $8f
qrc_invert1:
    or c
    bit 3, a
    jr z, qrc_invert2
        xor $8f
qrc_invert2:
    ld (hl), a
    ret

include "../qrc1.asm"
