; https://github.com/leiradel/qrc1

; qrc11_message contains the message length followed by the message (maximum
; 251 bytes).
qrc11_encmessage:
    ; ------------------------------------------------------------------------
    ; Encode the message.
    ; ------------------------------------------------------------------------

    ; Insert a 0000 nibble to before the length
    ld hl, qrc11_message
    ld c, (hl)
    xor a

    ; Shift the message to the right by four bits.
    ld b, c
    inc b

qrc11_shift_msg:
        rrd
        inc hl
    djnz qrc11_shift_msg

    ; A has the low nibble of the last message byte, shift it to the high
    ; nibble and set the low nibble to 0, which is the end of message mark.
    ld (hl), 0
    rrd
    inc hl

    ; Pad the rest of the message with $ec and $11.
    ld a, 251
    sub c
    jr z, qrc11_no_padding

    ld b, a
    ld a, $ec
qrc11_pad_msg:
        ld (hl), a
        inc hl
        xor $fd
    djnz qrc11_pad_msg

qrc11_no_padding:

    ; ------------------------------------------------------------------------
    ; Calculate the message ECC.
    ; ------------------------------------------------------------------------

    ; Zero the space after the ECC polynomial.
    ld hl, qrc11_ecc_poly_extra
    ld de, qrc11_ecc_poly_extra + 1
    ld bc, 50
    ld (hl), 0
    ldir

    ; Copy each block of the original encoded message to the target buffer,
    ; the ECC evaluation will overwrite it so we need to restore it at the end.
    ld hl, qrc11_block1
    ld de, qrc11_b1
    ld bc, 50
    call qrc11_ecc

    ld hl, qrc11_block2
    ld de, qrc11_b2
    ld bc, 51
    call qrc11_ecc

    ld hl, qrc11_block3
    ld de, qrc11_b3
    ld bc, 51
    call qrc11_ecc

    ld hl, qrc11_block4
    ld de, qrc11_b4
    ld bc, 51
    call qrc11_ecc

    ld hl, qrc11_block5
    ld de, qrc11_b5
    ld bc, 51
    call qrc11_ecc

    ; ------------------------------------------------------------------------
    ; Interleave message and ecc blocks.
    ; ------------------------------------------------------------------------

qrc11_interleave:
    ld hl, qrc11_b1
    ld de, qrc11_message - 1

    ld a, 50
qrc11_dintl:
        call qrc11_dint
        ld bc, qrc11_b1 - qrc11_b5
        add hl, bc
    dec a
    jr nz, qrc11_dintl

    ld hl, qrc11_b2 + 50
    ldi
    ld hl, qrc11_b3 + 50
    ldi
    ld hl, qrc11_b4 + 50
    ldi
    ld hl, qrc11_b5 + 50
    ldi

    ld hl, qrc11_b1_ecc

    ld a, 30
qrc11_eintl:
        call qrc11_eint
        ld bc, qrc11_b1_ecc - qrc11_b5_ecc
        add hl, bc
    dec a
    jr nz, qrc11_eintl

    ret

    ; ------------------------------------------------------------------------
    ; Interleave bytes.
    ; ------------------------------------------------------------------------

qrc11_eint:
    ldi
    ld bc, 50 + 30
    jr qrc11_int

qrc11_dint:
    ldi
    ld bc, 49 + 30

qrc11_int:
    add hl, bc
    ldi
    ld c, 50 + 30
    add hl, bc
    ldi
    ld c, 50 + 30
    add hl, bc
    ldi
    ld c, 50 + 30
    add hl, bc
    ldi
    ret

    ; ------------------------------------------------------------------------
    ; Calculate the block ECC.
    ; ------------------------------------------------------------------------

qrc11_ecc:
    ; Save block parameters for restoring
    push hl
    push de
    push bc

    ; Save message block length for later
    push bc

    ; Save message block address for later
    push de
    ldir

    ; Zero the 30 bytes where the ECC will be stored.
    xor a

    ld b, 30
qrc11_zero_ecc:
        ld (de), a
        inc de
    djnz qrc11_zero_ecc

    ; HL is the polynomial A.
    pop hl

    ; IYL is the outer loop counter (i) for the length of A.
    pop iy
qrc11_loop_i:
        ; Save HL as it'll be incremented in the inner loop.
        push hl

        ; Save A[i] in B to be used inside the inner loop.
        ld b, (hl)

        ; DE is the polynomial B.
        ld de, qrc11_ecc_poly

        ; Evaluate the inner loop count limit.
        ld a, 31
        add a, iyl
        dec a

        ; IYH is inner loop counter (j) up to length(A) - i.
        ld iyh, a
qrc11_loop_j:
            ; A is B[j]
            ld a, (de)

            ; Save DE as we'll use D and E in the gf_mod loop.
            push de

            ; D is A[i], E is the gf_mod result.
            ld d, b
            ld e, 0

            ; A is x, D is y, E is r, C is a scratch register.
            jr qrc11_test_y

qrc11_xor_res:
                ; y had the 0th bit set, r ^= x.
                ld c, a
                xor e
                ld e, a
                ld a, c
qrc11_dont_xor:
                ; x <<= 1, set carry if x >= 256.
                add a, a
                jr nc, qrc11_test_y

                    ; x was >= 256, xor it with the module.
                    xor 285 & $ff
qrc11_test_y:
                ; y >>= 1, update r if the 0th bit is set, end the loop if
                ; it's zero.
                srl d
                jr c, qrc11_xor_res
                jr nz, qrc11_dont_xor

            ; A[i + j] ^= gf_mod(...)
            ld a, (hl)
            xor e
            ld (hl), a

            ; Restore DE.
            pop de

            ; Update HL and DE to point to the next bytes of A and B.
            inc hl
            inc de

        ; Inner loop test.
        dec iyh
        jr nz, qrc11_loop_j

        ; Restore HL since it was changed in the inner loop, and make it point
        ; to the next byte in A.
        pop hl
        inc hl

    ; Outer loop test.
    dec iyl
    jr nz, qrc11_loop_i

    ; Restore the original encoded message, since the loops above zero it.
    pop bc
    pop de
    pop hl
    ldir

    ; All done, there's no need to perform the masking step because the mask is
    ; embedded in the fixed modules binary pattern so it's automatically
    ; applied when the modules are plotted.
    ret

qrc11_print:
    ; IY points to the RLE fixed module data.
    ld iy, qrc11_fixed

    ; Print loop, D is the X coordinate and E is the Y coordinate, both count
    ; towards zero.
    ld de, 61 << 8 | 61

qrc11_print_row:
            ; Get RLE code.
            ld a, (iy)
            inc iy

            ; Save in B because we'll need the lower six bits later.
            ld b, a

            ; Mask the RLE command.
            and $c0
            ; Zero means print black pixels.
            jr z, qrc11_print_black

            ; 0x40 means print white pixels.
            cp $40
            jr z, qrc11_print_white

            ; 0x80 means print mask pixels, put pixel count in B.
            ld a, b
            and $3f

            ld b, a
qrc11_print_mask_loop:
                ; Only set the pixel if (i+j)%2==0.
                ld a, d
                xor e
                rra
                call nc, qrc_invert_pixel

                ; Move cursor to the right.
                call qrc_pixel_right
                dec d
            djnz qrc11_print_mask_loop

            ; Continue line.

qrc11_print_continue:
        ; Check if X is zero, meaning the end of the row was reached.
        ld a, d
        or a
        jr nz, qrc11_print_row

        ; Row ended, check for end of data.
        dec e
        jr z, qrc11_print_modules

        ; Continue to the next row, set D to 61 for the new row.
        ld d, 61

        ; Move the cursor to the beginning of the next row.
        call qrc_pixel_down

        ld b, d
qrc11_print_cr:
            call qrc_pixel_left
        djnz qrc11_print_cr

    ; Continue on the next line.
    jr qrc11_print_row

qrc11_print_black:
    ; Pixel count in already in B.

qrc11_print_black_loop:
        ; Set the pixel and move the cursor to the right.
        call qrc_invert_pixel
        call qrc_pixel_right
        dec d
    djnz qrc11_print_black_loop

    ; Continue line.
    jr qrc11_print_continue

qrc11_print_white:
    ; Put pixel count in B.
    ld a, b
    and $3f
    ld b, a

qrc11_print_white_loop:
        ; Move the cursor to the right without setting the pixel.
        call qrc_pixel_right
        dec d
    djnz qrc11_print_white_loop

    ; Continue line.
    jr qrc11_print_continue

qrc11_print_modules:
    ; Move the cursor to the bottom-right pixel.
    call qrc_pixel_left

    ; Message bits.
    ld de, qrc11_message - 1
    ld b, $80 ; Most significant bit

    ; Set the current plot direction to up.
    xor a
    ld (qrc11_plot_direction), a

    ; IY points to the RLE module data.
    ld iy, qrc11_modules

qrc11_modules_loop:
        ; Run the command in the upper nibble.
        ld a, (iy)
        rra
        rra
        rra
        rra
        call qrc11_module_command

        ; Run the command in the lower nibble.
        ld a, (iy)
        inc iy
        call qrc11_module_command

        ; Check if IY is at the end of the RLE commands.
        ld a, iyl
        cp qrc11_modules_end & $ff
        jr nz, qrc11_modules_loop
        ld a, iyh
        cp qrc11_modules_end >> 8
        jr nz, qrc11_modules_loop

        ret

qrc11_module_command:
    ; Runs the command in the lower nibble of A. This seems to be more lengthy
    ; than using a lookup table (LUT), but the code to use the LUT plus the LUT
    ; itself are bigger than the code here.

    ; *  0: u-turn (29 usages)
    and $0f
    jr z, qrc11_uturn

    ; *  1: skip 1 (20 usages)
    dec a
    jr z, qrc11_skip_1

    ; *  2: pairs 54 (18 usages)
    dec a
    jr z, qrc11_pairs_54

    ; *  3: pairs 6 (17 usages)
    dec a
    jr z, qrc11_pairs_6

    ; *  4: pairs 19 (13 usages)
    dec a
    jr z, qrc11_pairs_19

    ; *  5: skip 5 (12 usages)
    dec a
    jr z, qrc11_skip_5

    ; *  6: pairs 4 (10 usages)
    dec a
    jr z, qrc11_pairs_4

    ; *  7: left 1 (7 usages)
    dec a
    jp z, qrc_pixel_left

    ; *  8: right 1 (6 usages)
    dec a
    jp z, qrc_pixel_right

    ; *  9: bits 1 (5 usages)
    dec a
    jr z, qrc11_bits_1

    ; * 10: bits 5 (5 usages)
    dec a
    jr z, qrc11_bits_5

    ; * 11: pairs 17 (2 usages)
    dec a
    jr z, qrc11_pairs_17

    ; * 12: pairs 41 (2 usages)
    dec a
    jr z, qrc11_pairs_41

    ; * 13: pairs 52 (2 usages)
    dec a
    jr z, qrc11_pairs_52

    ; * 14: skip 7 (2 usages)
    dec a
    jr z, qrc11_skip_7

    ; * 15: pairs 20 (1 usages)
    jr qrc11_pairs_20

; Makes an U-turn and inverts the direction.
qrc11_uturn:
    call qrc_pixel_left
    call qrc_pixel_left

    ld a, (qrc11_plot_direction)
    xor 1
    ld (qrc11_plot_direction), a
    ; fallthrough

; Skips one pixel.
qrc11_skip_1:
    ld a, (qrc11_plot_direction)
    and 1

    jp nz, qrc_pixel_down
    jp qrc_pixel_up

; Plots 108 modules in zig-zag.
qrc11_pairs_54:
    call qrc11_pairs_2
    ; fallthrough

qrc11_pairs_52:
    call qrc11_pairs_11
    ; fallthrough

qrc11_pairs_41:
    call qrc11_pairs_20
    ; fallthrough

qrc11_pairs_21:
    call qrc11_pairs_1
    ; fallthrough

qrc11_pairs_20:
    call qrc11_pairs_1
    ; fallthrough

qrc11_pairs_19:
    call qrc11_pairs_2
    ; fallthrough

qrc11_pairs_17:
    call qrc11_pairs_6
    ; fallthrough

qrc11_pairs_11:
    call qrc11_pairs_5
    ; fallthrough

qrc11_pairs_6:
    call qrc11_pairs_1
    ; fallthrough

qrc11_pairs_5:
    call qrc11_pairs_1
    ; fallthrough

qrc11_pairs_4:
    call qrc11_pairs_2
    ; fallthrough

qrc11_pairs_2:
    call qrc11_pairs_1
    ; fallthrough

qrc11_pairs_1:
    call qrc11_set_pixel_if
    call qrc_pixel_left
    call qrc11_set_pixel_if
    call qrc_pixel_right
    jp qrc11_skip_1

qrc11_skip_7:
    call qrc11_skip_2
    ; fallthrough

qrc11_skip_5:
    call qrc11_skip_1
    ; fallthrough

qrc11_skip_4:
    call qrc11_skip_2
    ; fallthrough

qrc11_skip_2:
    call qrc11_skip_1
    jp qrc11_skip_1

qrc11_bits_5:
    call qrc11_bits_1
    ; fallthrough

qrc11_bits_4:
    call qrc11_bits_2
    ; fallthrough

qrc11_bits_2:
    call qrc11_bits_1
    ; fallthrough

qrc11_bits_1:
    call qrc11_set_pixel_if
    jp qrc11_skip_1

; Plots a module if the corresponding bit in the encoded message is set.
qrc11_set_pixel_if:
    ld a, (de)
    and b
    call nz, qrc_invert_pixel

    ; Skip to the next bit.
    rrc b
    ret nc

    ; Increment the pointer to the encoded message if the bit in B wrapped.
    inc de
    ret

; RLE data to plot the fixed modules plus the checkerboard. RLE commands are
; encoded in the highest two bits of each byte, with the remaining six holding
; the data for the command:
;
; * 0x00: print black pixels, data is the number of pixels
; * 0x40: print white pixels, data is the number of pixels
; * 0x80: print mask pixels, data is the number of pixels
; * 0xc0: not used
qrc11_fixed:
    db $07, $42, $80 | 41, $41, $02, $41, $07
    db $01, $45, $01, $41, $01, $80 | 41, $41, $02, $41, $01, $45, $01
    db $01, $41, $03, $41, $01, $42, $80 | 41, $03, $41, $01, $41, $03, $41, $01
    db $01, $41, $03, $41, $01, $42, $80 | 41, $01, $41, $01, $41, $01, $41, $03, $41, $01
    db $01, $41, $03, $41, $01, $41, $01, $80 | 19, $05, $80 | 17, $02, $42, $01, $41, $03, $41, $01
    db $01, $45, $01, $42, $80 | 19, $01, $43, $01, $80 | 17, $01, $43, $01, $45, $01

    ; The following line uses the mask RLE command to draw the horizontal
    ; timing pattern. If the mask used in the QR Code wasn't the checkerboard,
    ; the line would have to be encoded using alternating $01 and $41 commands
    ; to draw the black and white pixels for the timing, which would have been
    ; terrible.
    db $07, $41, $01, $80 | 19, $01, $41, $01, $41, $01, $80 | 20, $41, $07

    db $49, $80 | 19, $01, $43, $01, $80 | 20, $48
    db $01, $41, $01, $41, $01, $41, $01, $42, $80 | 19, $05, $80 | 20, $43, $01, $42, $01, $41
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $84, $05, $80 | 19, $05, $80 | 19, $05, $84
    db $84, $01, $43, $01, $80 | 19, $01, $43, $01, $80 | 19, $01, $43, $01, $84
    db $84, $01, $41, $01, $41, $01, $80 | 19, $01, $41, $01, $41, $01, $80 | 19, $01, $41, $01, $41, $01, $84
    db $84, $01, $43, $01, $80 | 19, $01, $43, $01, $80 | 19, $01, $43, $01, $84
    db $84, $05, $80 | 19, $05, $80 | 19, $05, $84
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $86, $01, $80 | 54
    db $86, $41, $80 | 54
    db $42, $05, $80 | 54
    db $03, $41, $01, $42, $80 | 54
    db $04, $42, $01, $80 | 21, $05, $80 | 19, $05, $84
    db $48, $01, $80 | 19, $01, $43, $01, $80 | 19, $01, $43, $01, $84
    db $07, $42, $80 | 19, $01, $41, $01, $41, $01, $80 | 19, $01, $41, $01, $41, $01, $84
    db $01, $45, $01, $42, $80 | 19, $01, $43, $01, $80 | 19, $01, $43, $01, $84
    db $01, $41, $03, $41, $01, $41, $01, $80 | 19, $05, $80 | 19, $05, $84
    db $01, $41, $03, $41, $01, $42, $80 | 52
    db $01, $41, $03, $41, $01, $41, $01, $80 | 52
    db $01, $45, $01, $42, $80 | 52
    db $07, $41, $01, $80 | 52

; RLE data to plot the message modules. Each nibble is one of the following
; comands:
;
; *  0: u-turn (29 usages)
; *  1: skip 1 (20 usages)
; *  2: pairs 54 (18 usages)
; *  3: pairs 6 (17 usages)
; *  4: pairs 19 (13 usages)
; *  5: skip 5 (12 usages)
; *  6: pairs 4 (10 usages)
; *  7: left 1 (7 usages)
; *  8: right 1 (6 usages)
; *  9: bits 1 (5 usages)
; * 10: bits 5 (5 usages)
; * 11: pairs 17 (2 usages)
; * 12: pairs 41 (2 usages)
; * 13: pairs 52 (2 usages)
; * 14: skip 7 (2 usages)
; * 15: pairs 20 (1 usages)
qrc11_modules:
    db $d0 ; pairs 52 + u-turn
    db $d0 ; pairs 52 + u-turn
    db $65 ; pairs 4  + skip 5
    db $45 ; pairs 19 + skip 5
    db $40 ; pairs 19 + u-turn
    db $45 ; pairs 19 + skip 5
    db $45 ; pairs 19 + skip 5
    db $60 ; pairs 4  + u-turn
    db $67 ; pairs 4  + left 1
    db $a8 ; bits 5   + right 1
    db $47 ; pairs 19 + left 1
    db $a8 ; bits 5   + right 1
    db $b6 ; pairs 17 + pairs 4
    db $e0 ; skip 7   + u-turn
    db $7a ; left 1   + bits 5
    db $91 ; bits 1   + skip 1
    db $82 ; right 1  + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $06 ; u-turn   + pairs 4
    db $54 ; skip 5   + pairs 19
    db $54 ; skip 5   + pairs 19
    db $56 ; skip 5   + pairs 4
    db $06 ; u-turn   + pairs 4
    db $54 ; skip 5   + pairs 19
    db $54 ; skip 5   + pairs 19
    db $56 ; skip 5   + pairs 4
    db $06 ; u-turn   + pairs 4
    db $7a ; left 1   + bits 5
    db $84 ; right 1  + pairs 19
    db $7a ; left 1   + bits 5
    db $84 ; right 1  + pairs 19
    db $79 ; left 1   + bits 1
    db $91 ; bits 1   + skip 1
    db $99 ; bits 1   + bits 1
    db $86 ; right 1  + pairs 4
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $02 ; u-turn   + pairs 54
    db $13 ; skip 1   + pairs 6
    db $03 ; u-turn   + pairs 6
    db $12 ; skip 1   + pairs 54
    db $0e ; u-turn   + skip 7
    db $1f ; skip 1   + pairs 20
    db $54 ; skip 5   + pairs 19
    db $07 ; u-turn   + left 1
    db $45 ; pairs 19 + skip 5
    db $b0 ; pairs 17 + u-turn
    db $c0 ; pairs 41 + u-turn
    db $c0 ; pairs 41 + u-turn
qrc11_modules_end:
