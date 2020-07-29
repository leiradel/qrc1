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
        add iyl
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
