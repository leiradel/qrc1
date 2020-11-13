; https://github.com/leiradel/qrc1

;qrc_pixel_up     equ qrc_pixel_up_1
;qrc_pixel_down   equ qrc_pixel_down_1
;qrc_pixel_left   equ qrc_pixel_left_1
;qrc_pixel_right  equ qrc_pixel_right_1
;qrc_invert_pixel equ qrc_invert_pixel_1
;start_pixel      equ $80

;qrc_pixel_up     equ qrc_pixel_up_2
;qrc_pixel_down   equ qrc_pixel_down_2
;qrc_pixel_left   equ qrc_pixel_left_2
;qrc_pixel_right  equ qrc_pixel_right_2
;qrc_invert_pixel equ qrc_invert_pixel_2
;start_pixel      equ $c0

qrc_pixel_up     equ qrc_pixel_up_4
qrc_pixel_down   equ qrc_pixel_down_4
qrc_pixel_left   equ qrc_pixel_left_4
qrc_pixel_right  equ qrc_pixel_right_4
qrc_invert_pixel equ qrc_invert_pixel_4
start_pixel      equ $f0

    org 24576

main:
    ; Encode the message.
    call qrc1_encmessage

    ; Set H and L to the top-left pixel where the code will be printed, H is Y
    ; and L is X & %11111000. The low bits of X are encoded in register C.
    ld hl, 48 << 8 | 10 << 3

    ; Set C to the first pixel in the byte (pixels here are 4x4 real pixels).
    ld c, start_pixel

    ; Print it onto the screen.
    call qrc1_print

    ret

; Routines that use 1x1 square pixels for the modules.

qrc_pixel_up_1:
    dec h
    ret

qrc_pixel_down_1:
    inc h
    ret

qrc_pixel_left_1:
    rlc c
    ret nc
    ld a, l
    sub $08
    ld l, a
    ret

qrc_pixel_right_1:
    rrc c
    ret nc
    ld a, l
    add a, $08
    ld l, a
    ret

qrc_invert_pixel_1:
    push hl
    push hl

    ld a, h
    add a, high_y & $ff
    ld l, a
    ld a, 0
    adc a, high_y >> 8
    ld h, a
    ld a, (hl)

    pop hl
    rra
    rr l
    rra
    rr l
    rra
    rr l

    and $1f
    or $40
    ld h, a

    ld a, (hl)
    xor c
    ld (hl), a
    pop hl
    ret

high_y:
    ; This table is indexed with the Y coordinate [0, 191] and provides a byte
    ; encoded as (y[6-7] << 6) | (y[0-2] << 3) | y[3-5] which can be used to
    ; assemble the screen address of the corresponding line.
    db $00, $08, $10, $18, $20, $28, $30, $38, $01, $09, $11, $19, $21, $29, $31, $39
    db $02, $0a, $12, $1a, $22, $2a, $32, $3a, $03, $0b, $13, $1b, $23, $2b, $33, $3b
    db $04, $0c, $14, $1c, $24, $2c, $34, $3c, $05, $0d, $15, $1d, $25, $2d, $35, $3d
    db $06, $0e, $16, $1e, $26, $2e, $36, $3e, $07, $0f, $17, $1f, $27, $2f, $37, $3f
    db $40, $48, $50, $58, $60, $68, $70, $78, $41, $49, $51, $59, $61, $69, $71, $79
    db $42, $4a, $52, $5a, $62, $6a, $72, $7a, $43, $4b, $53, $5b, $63, $6b, $73, $7b
    db $44, $4c, $54, $5c, $64, $6c, $74, $7c, $45, $4d, $55, $5d, $65, $6d, $75, $7d
    db $46, $4e, $56, $5e, $66, $6e, $76, $7e, $47, $4f, $57, $5f, $67, $6f, $77, $7f
    db $80, $88, $90, $98, $a0, $a8, $b0, $b8, $81, $89, $91, $99, $a1, $a9, $b1, $b9
    db $82, $8a, $92, $9a, $a2, $aa, $b2, $ba, $83, $8b, $93, $9b, $a3, $ab, $b3, $bb
    db $84, $8c, $94, $9c, $a4, $ac, $b4, $bc, $85, $8d, $95, $9d, $a5, $ad, $b5, $bd
    db $86, $8e, $96, $9e, $a6, $ae, $b6, $be, $87, $8f, $97, $9f, $a7, $af, $b7, $bf

; Routines that use 2x2 square pixels for the modules.

qrc_pixel_up_2:
    dec h
    dec h
    ret

qrc_pixel_down_2:
    inc h
    inc h
    ret

qrc_pixel_left_2:
    rlc c
    rlc c
    ret nc
    ld a, l
    sub $08
    ld l, a
    ret

qrc_pixel_right_2:
    rrc c
    rrc c
    ret nc
    ld a, l
    add a, $08
    ld l, a
    ret

qrc_invert_pixel_2:
    call qrc_invert_pixel_1
    inc h
    call qrc_invert_pixel_1
    dec h
    ret

; Routines that use 4x4 square pixels for the modules.

qrc_pixel_up_4:
    dec h
    dec h
    dec h
    dec h
    ret

qrc_pixel_down_4:
    inc h
    inc h
    inc h
    inc h
    ret

qrc_pixel_left_4:
    ld a, c
    rlca
    rlca
    rlca
    rlca
    ld c, a
    ret nc
    ld a, l
    sub $08
    ld l, a
    ret

qrc_pixel_right_4:
    ld a, c
    rrca
    rrca
    rrca
    rrca
    ld c, a
    ret nc
    ld a, l
    add a, $08
    ld l, a
    ret

qrc_invert_pixel_4:
    call qrc_invert_pixel_1
    inc h
    call qrc_invert_pixel_1
    inc h
    call qrc_invert_pixel_1
    inc h
    call qrc_invert_pixel_1
    dec h
    dec h
    dec h
    ret

include "../qrc1.asm"
