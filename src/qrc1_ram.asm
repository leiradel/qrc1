; https://github.com/leiradel/qrc1

; The ECC level M polynomial.
qrc1_ecc_poly:
    db 1, 216, 194, 159, 111, 199, 94, 95, 113, 157, 193
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; The message, it'll be encoded in place.
qrc1_message:
    db 0  ; Message length
    ds 15 ; Message
    ds 10 ; Computed ECC

; Some scratch bytes.
qrc1_scratch:
    ds 16
