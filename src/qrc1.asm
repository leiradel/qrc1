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

    ; Restore the original encoded message, since the loops above zeroed it.
    ld hl, qrc1_scratch
    ld de, qrc1_message
    ld bc, 16
    ldir

    ; ------------------------------------------------------------------------
    ; Apply mask.
    ; ------------------------------------------------------------------------

    ; Xor the mask into the encoded message.
    ld hl, qrc1_message
    ld de, qrc1_encmessage_mask_0
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
        ld b, 12

qrc1_print_cr:
            call qrc1_pixel_left_2
        djnz qrc1_print_cr

    jr qrc1_print_line

qrc1_print_end:

    ; Move the cursor to the first module of the encoded message.
    call qrc1_pixel_left_2
    call qrc1_pixel_left_2

    ; Message bits.
    ld de, qrc1_message
    ld b, $80 ; Most significant bit

    ; Print command sequence.
    ld iy, qrc1_print_cmds

qrc1_print_loop:
        ; Run the command in the upper nibble.
        ld a, (iy)
        rra
        rra
        rra
        rra
        call qrc1_run_command

        ; Run the command in the lower nibble.
        ld a, (iy)
        inc iy
        call qrc1_run_command

    ; The qrc1_cmd_print_ended command discards the top address in the stack
    ; and returns, meaning that it will end this loop and return to the caller
    ; of qrc1_print.
    jr qrc1_print_loop

qrc1_run_command:
    ; Runs the command in the lower nibble of A. This seems to be more lengthy
    ; than using a lookup table (LUT), but the code to use the LUT plus the LUT
    ; itself are bigger than the code here.
    and $0f
    jr z, qrc1_pixel_up_1
    dec a
    jr z, qrc1_pixel_down_1
    dec a
    jr z, qrc1_pixel_left_2
    dec a
    jr z, qrc1_pixel_left_1
    dec a
    jr z, qrc1_uturn_up
    dec a
    jr z, qrc1_uturn_down
    dec a
    jr z, qrc1_pixel_up_9
    dec a
    jr z, qrc1_bit_up_28
    dec a
    jr z, qrc1_bit_up_24
    dec a
    jr z, qrc1_bit_up_12
    dec a
    jr z, qrc1_bit_up_8
    dec a
    jr z, qrc1_bit_down_28
    dec a
    jr z, qrc1_bit_down_24
    dec a
    jr z, qrc1_bit_down_12
    dec a
    jr z, qrc1_bit_down_8

    ; This handles the qrc1_cmd_print_ended command.
    pop af
    ret

; Skips two pixels to the left.
qrc1_pixel_left_2:
    call qrc_pixel_left
    ; fallthrough

; Skips one pixel to the left.
qrc1_pixel_left_1:
    jp qrc_pixel_left

; Makes a U-turn to start going up.
qrc1_uturn_up:
    call qrc_pixel_left
    call qrc_pixel_left
    ; fallthrough

; Skips one pixel up.
qrc1_pixel_up_1:
    jp qrc_pixel_up

; Makes a U-turn to start going down.
qrc1_uturn_down:
    call qrc_pixel_left
    call qrc_pixel_left
    ; fallthrough

; Skips one pixel down.
qrc1_pixel_down_1:
    jp qrc_pixel_down

; Skips nine pixels up.
qrc1_pixel_up_9:
    push iy
    ld iyl, 9
qrc1_pixel_up_9_loop:
        call qrc_pixel_up
    dec iyl
    jr nz, qrc1_pixel_up_9_loop
    pop iy
    ret

; Plots 28 modules up in zig-zag.
qrc1_bit_up_28:
    call qrc1_bit_up_4
    ; fallthrough

; Plots 24 modules up in zig-zag.
qrc1_bit_up_24:
    call qrc1_bit_up_12
    ; fallthrough

; Plots 12 moudles up in zig-zag.
qrc1_bit_up_12:
    call qrc1_bit_up_4
    ; fallthrough

; Plots 8 modules up in zig-zag.
qrc1_bit_up_8:
    call qrc1_bit_up_4
    ; fallthrough

; Plots 4 modules up in zig-zag.
qrc1_bit_up_4:
    call qrc1_set_pixel_if
    call qrc_pixel_left
    call qrc1_set_pixel_if
    call qrc_pixel_up
    call qrc_pixel_right
    call qrc1_set_pixel_if
    call qrc_pixel_left
    call qrc1_set_pixel_if
    call qrc_pixel_up
    jp qrc_pixel_right

; Plots 28 modules down in zig-zag.
qrc1_bit_down_28:
    call qrc1_bit_down_4
    ; fallthrough

; Plots 24 modules down in zig-zag.
qrc1_bit_down_24:
    call qrc1_bit_down_12
    ; fallthrough

; Plots 12 modules down in zig-zag.
qrc1_bit_down_12:
    call qrc1_bit_down_4
    ; fallthrough

; Plots 8 modules down in zig-zag.
qrc1_bit_down_8:
    call qrc1_bit_down_4
    ; fallthrough

; Plots 4 modules down in zig-zag.
qrc1_bit_down_4:
    call qrc1_set_pixel_if
    call qrc_pixel_left
    call qrc1_set_pixel_if
    call qrc_pixel_down
    call qrc_pixel_right
    call qrc1_set_pixel_if
    call qrc_pixel_left
    call qrc1_set_pixel_if
    call qrc_pixel_down
    jp qrc_pixel_right

; Plots a module if the corresponding bit in the encoded message is set.
qrc1_set_pixel_if:
    ld a, (de)
    and b
    call nz, qrc_set_pixel

    ; Skip to the next bit.
    rrc b
    ret nc

    ; Increment the pointer to the encoded message if the bit in B wrapped.
    inc de
    ret

; Print commands constants to encode the print commands sequence below.
qrc1_cmd_pixel_up_1   equ 0
qrc1_cmd_pixel_down_1 equ 1
qrc1_cmd_pixel_left_2 equ 2
qrc1_cmd_pixel_left_1 equ 3
qrc1_cmd_uturn_up     equ 4
qrc1_cmd_uturn_down   equ 5
qrc1_cmd_pixel_up_9   equ 6
qrc1_cmd_bit_up_28    equ 7
qrc1_cmd_bit_up_24    equ 8
qrc1_cmd_bit_up_12    equ 9
qrc1_cmd_bit_up_8     equ 10
qrc1_cmd_bit_down_28  equ 11
qrc1_cmd_bit_down_24  equ 12
qrc1_cmd_bit_down_12  equ 13
qrc1_cmd_bit_down_8   equ 14
qrc1_cmd_print_ended  equ 15

; Print commands sequence that drives the printing of the QR Code.
qrc1_print_cmds:
    db qrc1_cmd_bit_up_24   << 4 | qrc1_cmd_uturn_down
    db qrc1_cmd_bit_down_24 << 4 | qrc1_cmd_uturn_up
    db qrc1_cmd_bit_up_24   << 4 | qrc1_cmd_uturn_down
    db qrc1_cmd_bit_down_24 << 4 | qrc1_cmd_uturn_up
    db qrc1_cmd_bit_up_28   << 4 | qrc1_cmd_pixel_up_1
    db qrc1_cmd_bit_up_12   << 4 | qrc1_cmd_uturn_down
    db qrc1_cmd_bit_down_12 << 4 | qrc1_cmd_pixel_down_1
    db qrc1_cmd_bit_down_28 << 4 | qrc1_cmd_pixel_left_2
    db qrc1_cmd_pixel_up_9  << 4 | qrc1_cmd_bit_up_8
    db qrc1_cmd_uturn_down  << 4 | qrc1_cmd_pixel_left_1
    db qrc1_cmd_bit_down_8  << 4 | qrc1_cmd_uturn_up
    db qrc1_cmd_bit_up_8    << 4 | qrc1_cmd_uturn_down
    db qrc1_cmd_bit_down_8  << 4 | qrc1_cmd_print_ended

; The ECC level M polynomial.
qrc1_ecc_poly:
    db 1, 216, 194, 159, 111, 199, 94, 95, 113, 157, 193
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; The checkerboard mask.
qrc1_encmessage_mask_0:
    db $09, $99, $99, $66, $66, $66, $99, $99, $99, $66, $66, $66, $99
    db $99, $99, $96, $66, $99, $96, $66, $66, $66, $99, $99, $66, $99

; The message, it'll be encoded in place.
qrc1_message:
    db 0  ; Message length
    ds 15 ; Message
    ds 10 ; Computed ECC

; Some scratch bytes.
qrc1_scratch:
    ds 16

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
