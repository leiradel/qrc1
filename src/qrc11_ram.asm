; https://github.com/leiradel/qrc1

; The ECC version 11 level M polynomial.
qrc11_ecc_poly:
    db 1, 212, 246, 77, 73, 195, 192, 75, 98, 5, 70, 103, 177, 22, 217, 138
    db 51, 181, 246, 72, 25, 18, 46, 228, 74, 216, 195, 11, 106, 130, 150
qrc11_ecc_poly_extra:
    ds 51

; The message, it'll be encoded in place.
qrc11_block1:
    db $40
qrc11_message:
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

qrc11_plot_direction:
    db 0
