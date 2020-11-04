; https://github.com/leiradel/qrc1

; qrc1_message contains the message length followed by the message (maximum 14
; bytes).
qrc1_encmessage:
    ; ------------------------------------------------------------------------
    ; Encode the message.
    ; ------------------------------------------------------------------------

    ; Use byte encoding (0b0100 << 4), length high nibble is always 0 since
    ; len <= 14.
    ld hl, qrc1_message
    ld a, (hl)
    ld (hl), $40
    inc hl

    ; Save message length for later for the padding.
    ld c, a

    ; Shift the message to the right by four bits.
    ld b, a
qrc1_shift_msg:
        rrd
        inc hl
    djnz qrc1_shift_msg

    ; A has the low nibble of the last message byte, shift it to the high
    ; nibble and set the low nibble to 0, which is the end of message mark.
    ld (hl), 0
    rrd
    inc hl

    ; HL points to the last byte of the message; save it for later.
    push hl

    ; Pad the rest of the message with $ec and $11.
    ld a, 14
    sub c
    jr z, qrc1_no_padding

    ld b, a
    ld a, $ec
qrc1_pad_msg:
        ld (hl), a
        inc hl
        xor $fd
    djnz qrc1_pad_msg

qrc1_no_padding:

    ; ------------------------------------------------------------------------
    ; Calculate the message ECC.
    ; ------------------------------------------------------------------------

    ; Copy the original encoded message to the scratch buffer, the ECC
    ; evaluation will overwrite it so we need to restore it at the end.
    ld hl, qrc1_message
    ld de, qrc1_scratch
    ld bc, 16
    ldir

    ; Zero the 10 bytes where the ECC will be stored.
    xor a
    ld b, 10
qrc1_zero_ecc:
        ld (hl), a
        inc hl
    djnz qrc1_zero_ecc

    ; HL is the polynomial A.
    ld hl, qrc1_message

    ; IYL is the outer loop counter (i) for the length of A.
    ld iyl, 16
qrc1_loop_i:
        ; Save HL as it'll be incremented in the inner loop.
        push hl

        ; Save A[i] in B to be used inside the inner loop.
        ld b, (hl)

        ; DE is the polynomial B.
        ld de, qrc1_ecc_poly

        ; Evaluate the inner loop count limit.
        ld a, 11
        add a, iyl
        dec a

        ; IYH is inner loop counter (j) up to length(A) - i.
        ld iyh, a
qrc1_loop_j:
            ; A is B[j]
            ld a, (de)

            ; Save DE as we'll use D and E in the gf_mod loop.
            push de

            ; D is A[i], E is the gf_mod result.
            ld d, b
            ld e, 0

            ; A is x, D is y, E is r, C is a scratch register.
            jr qrc1_test_y

qrc1_xor_res:
                ; y had the 0th bit set, r ^= x.
                ld c, a
                xor e
                ld e, a
                ld a, c
qrc1_dont_xor:
                ; x <<= 1, set carry if x >= 256.
                add a, a
                jr nc, qrc1_test_y

                    ; x was >= 256, xor it with the module.
                    xor 285 & $ff
qrc1_test_y:
                ; y >>= 1, update r if the 0th bit is set, end the loop if
                ; it's zero.
                srl d
                jr c, qrc1_xor_res
                jr nz, qrc1_dont_xor

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
        jr nz, qrc1_loop_j

        ; Restore HL since it was changed in the inner loop, and make it point
        ; to the next byte in A.
        pop hl
        inc hl
    
    ; Outer loop test.
    dec iyl
    jr nz, qrc1_loop_i

    ; Restore the original encoded message, since the loops above zero it.
    ld hl, qrc1_scratch
    ld de, qrc1_message
    ld bc, 16
    ldir

    ; ------------------------------------------------------------------------
    ; Apply mask.
    ; ------------------------------------------------------------------------

    ; Copy the checkerboard mask to the scratch buffer.
    ld hl, qrc1_encmessage_mask_0
    ld de, qrc1_scratch
    ld bc, 26
    ldir

    ; Restore the pointer to the last message byte.
    pop hl

    ; Add the offset from the scratch buffer that contains the mask to the
    ; message to point to the corresponding byte in the mask, HL will point to
    ; the byte in the mask that corresponds to the last byte of the message.
    ld de, qrc1_scratch - qrc1_message - 1
    add hl, de

    ; Clear the bits in the mask that correspond to the end of message mark.
    ld a, (hl)
    and $f0
    ld (hl), a

    ; Xor the mask into the encoded message.
    ld hl, qrc1_message
    ld de, qrc1_scratch
    ld b, 26
qrc1_xor_mask:
        ld a, (de)
        xor (hl)
        ld (hl), a
        inc hl
        inc de
    djnz qrc1_xor_mask
    ret

qrc1_print:
    ; Draw the fixed modules.
    ld de, qrc1_fixed_modules

    ; 21 lines.
    ld iyl, 21

qrc1_print_line:
        ; Each line has 3 bytes to cover 21 modules.
        ld iyh, 3

qrc1_print_byte:
            ld a, (de)
            inc de

            ; Set the module depending on the bit pattern.
            ld b, 8

qrc1_print_bits:
                rla

                push af
                call c, qrc_set_pixel
                call qrc_pixel_right
                pop af
            djnz qrc1_print_bits

        dec iyh
        jr nz, qrc1_print_byte

        ; When all rows have been printed, leave the cursor one module to the
        ; right of the bottom-right module.
        dec iyl
        jr z, qrc1_print_end

        ; Otherwise, go down on pixel and left 24 pixels to start a new line.
        call qrc_pixel_down
        ld b, 24

qrc1_print_cr:
            call qrc_pixel_left
        djnz qrc1_print_cr

    jr qrc1_print_line

qrc1_print_end:

    ; Move the cursor to the first module of the encoded message.
    ld b, 4
qrc1_move_left:
        call qrc_pixel_left
    djnz qrc1_move_left

    ; Message bits.
    ld de, qrc1_message
    ld b, $80 ; Most significant bit

    ; Six nibbles up.
    ld iyl, 6
    call qrc1_nibbles_up

    ; Update the cursor.
    call qrc_pixel_down
    call qrc_pixel_left
    call qrc_pixel_left

    ; Six nibbles down.
    ld iyl, 6
    call qrc1_nibbles_down

    ; Update the cursor.
    call qrc_pixel_up
    call qrc_pixel_left
    call qrc_pixel_left

    ; Six nibbles up.
    ld iyl, 6
    call qrc1_nibbles_up

    ; Update the cursor.
    call qrc_pixel_down
    call qrc_pixel_left
    call qrc_pixel_left

    ; Six nibbles down.
    ld iyl, 6
    call qrc1_nibbles_down

    ; Update the cursor.
    call qrc_pixel_up
    call qrc_pixel_left
    call qrc_pixel_left

    ; Seven nibbles up.
    ld iyl, 7
    call qrc1_nibbles_up

    ; Jump the timing marks.
    call qrc_pixel_up

    ; More three nibbles up.
    ld iyl, 3
    call qrc1_nibbles_up

    ; Update the cursor.
    call qrc_pixel_down
    call qrc_pixel_left
    call qrc_pixel_left

    ; Three nibbles down.
    ld iyl, 3
    call qrc1_nibbles_down

    ; Jump the timing marks.
    call qrc_pixel_down

    ; Seven nibbles down.
    ld iyl, 7
    call qrc1_nibbles_down

    ; Update the cursor, two pixels to the left, nine pixels up.
    call qrc_pixel_left
    call qrc_pixel_left

    ld iyl, 9
qrc1_loop_up8:
        call qrc_pixel_up
    dec iyl
    jr nz, qrc1_loop_up8

    ; Two nibbles up.
    ld iyl, 2
    call qrc1_nibbles_up

    ; Update the cursor, jump the timing marks.
    call qrc_pixel_left
    call qrc_pixel_left
    call qrc_pixel_left
    call qrc_pixel_down

    ; Two nibbles down.
    ld iyl, 2
    call qrc1_nibbles_down

    ; Update the cursor.
    call qrc_pixel_left
    call qrc_pixel_left
    call qrc_pixel_up

    ; Two nibbles up.
    ld iyl, 2
    call qrc1_nibbles_up

    ; Update the cursor.
    call qrc_pixel_left
    call qrc_pixel_left
    call qrc_pixel_down

    ; Two nibbles down.
    ld iyl, 2
    call qrc1_nibbles_down

    ; Done.
    ret

qrc1_nibbles_up:
        call qrc1_set_pixel_if
        call qrc_pixel_left
        call qrc1_set_pixel_if
        call qrc_pixel_up
        call qrc_pixel_right
        call qrc1_set_pixel_if
        call qrc_pixel_left
        call qrc1_set_pixel_if
        call qrc_pixel_up
        call qrc_pixel_right
    dec iyl
    jr nz, qrc1_nibbles_up
    ret

qrc1_nibbles_down:
        call qrc1_set_pixel_if
        call qrc_pixel_left
        call qrc1_set_pixel_if
        call qrc_pixel_down
        call qrc_pixel_right
        call qrc1_set_pixel_if
        call qrc_pixel_left
        call qrc1_set_pixel_if
        call qrc_pixel_down
        call qrc_pixel_right
    dec iyl
    jr nz, qrc1_nibbles_down
    ret

qrc1_set_pixel_if:
    ld a, (de)
    and b
    call nz, qrc_set_pixel

    srl b
    ret nz

    inc de
    ld b, $80
    ret

; The ECC level M polynomial.
qrc1_ecc_poly:
    db 1, 216, 194, 159, 111, 199, 94, 95, 113, 157, 193
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; The checkerboard mask.
qrc1_encmessage_mask_0:
    db $09, $99, $99, $66, $66, $66, $99, $99, $99, $66, $66, $66, $99, $99, $99, $96
    db $66, $99, $96, $66, $66, $66, $99, $99, $66, $99

; The message, it'll be encoded in place.
qrc1_message:
    db 0  ; Message length
    ds 15 ; Message
    ds 10 ; Computed ECC

; Some scratch bytes.
qrc1_scratch:
    ds 26

; The fixed modules encoded in binary.
qrc1_fixed_modules:
    db $fe, $03, $f8
    db $82, $82, $08
    db $ba, $02, $e8
    db $ba, $02, $e8
    db $ba, $82, $e8
    db $82, $02, $08
    db $fe, $ab, $f8
    db $00, $00, $00
    db $aa, $00, $90
    db $00, $00, $00
    db $02, $00, $00
    db $00, $00, $00
    db $02, $00, $00
    db $00, $80, $00
    db $fe, $00, $00
    db $82, $00, $00
    db $ba, $80, $00
    db $ba, $00, $00
    db $ba, $80, $00
    db $82, $00, $00
    db $fe, $80, $00
