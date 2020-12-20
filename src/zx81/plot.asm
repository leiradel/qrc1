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

qrc_invert_pixel:
    ld a, (hl)
    bit 7, a
    jr z, qrc_invert1
        xor $8f
qrc_invert1:
    xor c
    bit 3, a
    jr z, qrc_invert2
        xor $8f
qrc_invert2:
    ld (hl), a
    ret
