; https://github.com/leiradel/qrc1

; i25_message contains the message length followed by the message.
i25_print:
    ld iy, i25_message
    ld a, (iy)
    inc iy

    ; Divide the message length by 2.
    and a
    rra

    ; Return if the length is odd.
    ret c

    ld d, a

    call i25_narrow
    call qrc_pixel_right
    call i25_narrow
    call qrc_pixel_right

i25_print_loop:
        push de
        push hl

        ld a, (iy + 0)
        sub $30
        ld e, a
        ld d, 0
        ld hl, i25_patterns
        add hl, de
        ld d, (hl)
        push de

        ld a, (iy + 1)
        sub $30
        ld e, a
        ld d, 0
        ld hl, i25_patterns
        add hl, de
        pop de
        ld e, (hl)
        pop hl

        inc iy
        inc iy

        call i25_draw_pair
        call i25_draw_pair
        call i25_draw_pair
        call i25_draw_pair
        call i25_draw_pair

        pop de
    dec d
    jr nz, i25_print_loop

    call i25_wide
    call qrc_pixel_right
    jp i25_narrow

i25_draw_pair:
    sla d
    jr c, i25_draw_wide

    call i25_narrow
    jr i25_next

i25_draw_wide:
    call i25_wide

i25_next:
    call qrc_pixel_right

    sla e
    jp c, qrc_pixel_right
    ret

i25_narrow:
    ld b, 20
i25_narrow_loop1:
        call qrc_invert_pixel
        call qrc_pixel_down
    djnz i25_narrow_loop1

i25_up:
    ld b, 20
i25_narrow_loop2:
        call qrc_pixel_up
    djnz i25_narrow_loop2

    jp qrc_pixel_right

i25_wide:
    ld b, 20
i25_wide_loop1:
        call qrc_invert_pixel
        call qrc_pixel_right
        call qrc_invert_pixel
        call qrc_pixel_left
        call qrc_pixel_down
    djnz i25_wide_loop1

    call qrc_pixel_right
    jr i25_up

i25_patterns:
    db %00110 * 8
    db %10001 * 8
    db %01001 * 8
    db %11000 * 8
    db %00101 * 8
    db %10100 * 8
    db %01100 * 8
    db %00011 * 8
    db %10010 * 8
    db %01010 * 8
