; https://github.com/leiradel/qrc1

; qrc11_message contains a $40 byte followed by the message length followed
; by the message (maximum 251 bytes).
qrc11_encmessage:
    ; ------------------------------------------------------------------------
    ; Encode the message.
    ; ------------------------------------------------------------------------

    ; Insert a 0000 nibble to before the length
    ld hl, qrc11_message + 1
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

    ; HL points to the last byte of the message; save it for later.
    push hl

    ; Pad the rest of the message with $ec and $11.
    ld a, 254
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
    ld de, qrc11_message
    ld a, 50
    call qrc11_intl
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
    call qrc11_intl

    ; ------------------------------------------------------------------------
    ; Display QR code with checkerboard mask.
    ; ------------------------------------------------------------------------

    ld hl, qrc11_map
    ld c, 61
qrc11_d1:
        ld b, 61
qrc11_d2:   push bc
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            ld a, e
            srl d
            rr e
            srl d
            rr e
            srl d
            rr e
            ld bc, qrc11_message
            ex de, hl
            add hl, bc
            ex de, hl
            ld b, a
            ld a, (de)
            inc b
qrc11_d3:       rlca
                djnz qrc11_d3
            pop bc
            xor b
            xor c
            rrca
            call nc, qrc11_module
            djnz qrc11_d2
        dec c
        jr nz, qrc11_d1
    ret


    ; ------------------------------------------------------------------------
    ; Interleave blocks.
    ; ------------------------------------------------------------------------

qrc11_intl:
    ldi
    ld bc, 49 + 30
    add hl, bc
    ldi
    ld c, 50 + 30
    add hl, bc
    ldi
    ld c, 50 + 30
    add hl, bc
    ldi
    ld bc, -50-51*4
    add hl, bc
    dec a
    jr nz, qrc11_intl
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

    ; IXL is the outer loop counter (i) for the length of A.
    pop ix
qrc11_loop_i:
        ; Save HL as it'll be incremented in the inner loop.
        push hl

        ; Save A[i] in B to be used inside the inner loop.
        ld b, (hl)

        ; DE is the polynomial B.
        ld de, qrc11_ecc_poly

        ; Evaluate the inner loop count limit.
        ld a, 11

        ; add ixl for dumb assemblers
	db $dd
	add a, l

        dec a

        ; IXH is inner loop counter (j) up to length(A) - i.
        ; ld ixh, a for dumb assemblers
	db $dd
	ld h, a

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
                    xor 285 - 256
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
        ; dec ixh for dumb assemblers
	db $dd
	dec h

        jr nz, qrc11_loop_j

        ; Restore HL since it was changed in the inner loop, and make it point
        ; to the next byte in A.
        pop hl
        inc hl

    ; Outer loop test.
    ; dec ixl for dumb assemblers
    db $dd
    dec l
    jr nz, qrc11_loop_i

    ; Restore the original encoded message, since the loops above zero it.
    pop bc
    pop de
    pop hl
    ldir
    ret


; The ECC version 11 level M polynomial.
qrc11_ecc_poly:
    db 1, 212, 246, 77, 73, 195, 192, 75, 98, 5, 70, 103, 177, 22, 217, 138
    db 51, 181, 246, 72, 25, 18, 46, 228, 74, 216, 195, 11, 106, 130, 150
    ds 51

; The message, it'll be encoded in place.
qrc11_message:
qrc11_block1:
    db $40
    db 0   ; Message length
    ds 48  ; Message source
qrc11_block2:
    ds 51  ; Message source
qrc11_block3:
    ds 51  ; Message source
qrc11_block4:
    ds 51  ; Message source
qrc11_block5:
    ds 51  ; Message source

; Extra space for encoded message
    ds 30 * 5

; Fidex white and black modules
    db $40

qrc11_b1:
    ds 50  ; Message target
qrc11_b1_ecc:
    ds 30  ; Computed ECC
qrc11_b2:
    ds 51  ; Message target
qrc11_b2_ecc:
    ds 30  ; Computed ECC
qrc11_b3:
    ds 51  ; Message target
qrc11_b3_ecc:
    ds 30  ; Computed ECC
qrc11_b4:
    ds 51  ; Message target
qrc11_b4_ecc:
    ds 30  ; Computed ECC
qrc11_b5:
    ds 51  ; Message target
qrc11_b5_ecc:
    ds 30  ; Computed ECC

