; https://github.com/leiradel/qrc1

#target p

#code _RAM, $4009, last - $4009
    org $4009

; SYSVARS which aren't saved

ERR_NR: equ $4000 ; 1 less than the report code
FLAGS:  equ $4001 ; various flags to control de BASIC system
ERR_SP: equ $4002 ; address of first item on machine stack
RAMTOP: equ $4004 ; address of first byte above BASIC system area
MODE:   equ $4006 ; K, L, F or G cursor
PPC:    equ $4007 ; line number of statement being executed

; SYSVARS which are saved. This is the start of the .P file.

VERSN:  db 0             ; 0 identifies ZX81 BASIC in saved programs
E_PPC:  dw 0             ; number of current line (with program cursor)
D_FILE: dw dfile         ; display file
DF_CC:  dw dfile + 1     ; address of PRINT position in display file
VARS:   dw vararea       ; BASIC variables
DEST:   dw 0             ; address of variable in assignment
E_LINE: dw last          ; address of line being typed
CH_ADD: dw last          ; address of the next character to be interpreted
X_PTR:  dw 0             ; address of the character preceding the S cursor
STKBOT: dw last + 1      ; bottom of calculator's stack
STKEND: dw last + 1      ; end of calculator's stack
BREG:   db 0             ; calculator's b register
MEM:    dw MEMBOT        ; address of area used for calculator's memory
        db 0             ; unused
DF_SZ:  db 2             ; number of blank lines at the bottom of screen
S_TOP:  dw 0             ; number of top program lines in automatic listings
LAST_K: db $FF, $FF, $FF ; shows pressed keys
MARGIN: db 55            ; number of blank lines above or below screen
NXTLIN: dw first_line    ; address of next program line to be executed
OLDPPC: dw 0             ; line number to which CONT jumps
FLAGX:  db 0             ; various flags
STRLEN: dw 0             ; length of string type destination in assignment
T_ADDR: dw $0C8D         ; address of next item in syntax table
SEED:   dw 0             ; seed for RND
FRAMES: dw $FFFF         ; counts frames displayed on the television
COORDS: db 0, 0          ; x and y coordinates of last PLOTted point
PR_CC:  db $BC           ; next position for LPRINT in PRBUFF
S_POSN: db $21, $18      ; column and line number for PRINT position
CDFLAG: db 01000000B     ; various flags
PRBUFF: ds 32            ; printer buffer
        db $76
MEMBOT: ds 30            ; calculator's memory area
        ds 2             ; unused

; A useful reference
;
;  ____0___1___2___3___4___5___6___7___8___9___A___B___C___D___E___F____
;  00 SPC GRA GRA GRA GRA GRA GRA GRA GRA GRA GRA  "  GBP  $   :   ?  0F
;  10  (   )   >   <   =   +   -   *   /   ;   ,   .   0   1   2   3  1F
;  20  4   5   6   7   8   9   A   B   C   D   E   F   G   H   I   J  2F
;  30  K   L   M   N   O   P   Q   R   S   T   U   V   W   X   Y   Z  3F

_SPACE:  equ $00
_QUOTE:  equ $0b
_POUND:  equ $0c
_DOLLAR: equ $0d
_COLLON: equ $0e
_QMARK:  equ $0f
_LBRACE: equ $10
_RBRACE: equ $11
_GT:     equ $12
_LT:     equ $13
_EQUAL:  equ $14
_PLUS:   equ $15
_MINUS:  equ $16
_STAR:   equ $17
_SLASH:  equ $18
_SCOLON: equ $19
_COMMA:  equ $1a
_DOT:    equ $1b
_0:      equ $1c
_1:      equ $1d
_2:      equ $1e
_3:      equ $1f
_4:      equ $20
_5:      equ $21
_6:      equ $22
_7:      equ $23
_8:      equ $24
_9:      equ $25
_A:      equ $26
_B:      equ $27
_C:      equ $28
_D:      equ $29
_E:      equ $2a
_F:      equ $2b
_G:      equ $2c
_H:      equ $2d
_I:      equ $2e
_J:      equ $2f
_K:      equ $30
_L:      equ $31
_M:      equ $32
_N:      equ $33
_O:      equ $34
_P:      equ $35
_Q:      equ $36
_R:      equ $37
_S:      equ $38
_T:      equ $39
_U:      equ $3a
_V:      equ $3b
_W:      equ $3c
_X:      equ $3d
_Y:      equ $3e
_Z:      equ $3f
_RND:    equ $40
_INKEY:  equ $41
_PI:     equ $42
_DBLQ:   equ $c0
_AT:     equ $c1
_TAB:    equ $c2
_CODE:   equ $c4
_VAL:    equ $c5
_LEN:    equ $c6
_SIN:    equ $c7
_COS:    equ $c8
_TAN:    equ $c9
_ASN:    equ $ca
_ACS:    equ $cb
_ATN:    equ $cc
_LN:     equ $cd
_EXP:    equ $ce
_INT:    equ $cf
_SQR:    equ $d0
_SGN:    equ $d1
_ABS:    equ $d2
_PEEK:   equ $d3
_USR:    equ $d4
_STR:    equ $d5
_CHR:    equ $d6
_NOT:    equ $d7
_POWER:  equ $d8
_OR:     equ $d9
_AND:    equ $da
_LE:     equ $db
_GE:     equ $dc
_NE:     equ $dd
_THEN:   equ $de
_TO:     equ $df
_STEP:   equ $e0
_LPRINT: equ $e1
_LLIST:  equ $e2
_STOP:   equ $e3
_SLOW:   equ $e4
_FAST:   equ $e5
_NEW:    equ $e6
_SCROLL: equ $e7
_CONT:   equ $e8
_DIM:    equ $e9
_REM:    equ $ea
_FOR:    equ $eb
_GOTO:   equ $ec
_GOSUB:  equ $ed
_INPUT:  equ $ee
_LOAD:   equ $ef
_LIST:   equ $f0
_LET:    equ $f1
_PAUSE:  equ $f2
_NEXT:   equ $f3
_POKE:   equ $f4
_PRINT:  equ $f5
_PLOT:   equ $f6
_RUN:    equ $f7
_SAVE:   equ $f8
_RAND:   equ $f9
_IF:     equ $fa
_CLS:    equ $fb
_UNPLOT: equ $fc
_CLEAR:  equ $fd
_RETURN: equ $fe
_COPY:   equ $ff
_INVERT: equ $80

; BASIC line with the machine code

line0:
    dw 0             ; line number
    dw line0_end - $ - 2 ; line length
    db $ea           ; REM
    db $76, $76      ; two new lines to hide the machine code in LIST

; ========== START OF USER PROGRAM ==========

    ; Translate the character set from ZX81 to ASCII.
    call to_ascii

    ; Encode the message.
    call qrc1_encmessage

    ; Set DE to the top-left character where the code will be printed.
    ld hl, ($400c)
    ld de, 33 * 6 + 11
    add hl, de
    ex de, hl

    ; Set C to the upper-left pixel in the character.
    ld c, 1

    ; Print it onto the screen.
    call qrc1_print

    ret

to_ascii:
    ; Make HL point to the unencoded message.
    ld hl, qrc1_message

    ; B has the message length.
    ld b, (hl)
    inc hl

xlate_loop:
        ; Put the ZX81 character in A, making sure it's valid and non-inverted.
        ld a, (hl)
        and $3f

        ; Get the corresponding ASCII character in the translation table.
        add a, xlate_table & $ff
        ld e, a
        ld a, 0
        adc a, xlate_table >> 8
        ld d, a
        ld a, (de)

        ; Overwrite with the ASCII char.
        ld (hl), a
        inc hl
    djnz xlate_loop
    ret

xlate_table:
    ; spc gra gra gra gra gra gra gra gra gra gra  "   £   $   :   ?
    db ' ', '?', '?', '?', '?', '?', '?', '?', '?', '?', '?', '"', '?', '$', ':', '?'

    ;  (   )   >   <   =   +   -   *   /   ;   ,   .   0   1   2   3
    db '(', ')', '>', '<', '=', '+', '-', '*', '/', ';', ',', '.', '0', '1', '2', '3'

    ;  4   5   6   7   8   9   A   B   C   D   E   F   G   H   I   J
    db '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'

    ;  K   L   M   N   O   P   Q   R   S   T   U   V   W   X   Y   Z
    db 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'

; Moves the cursor one pixel to the left.
qrc_pixel_left:
    ; 1 -> 2 | 0001 -> 0010 dec de
    ; 4 -> 8 | 0100 -> 1000 dec de
    ; 2 -> 1 | 0010 -> 0001
    ; 8 -> 4 | 1000 -> 0100
    ld a, 5
    and c
    jr z, qrc_dont_dec
        sla c
        dec de
        ret
qrc_dont_dec:
    srl c
    ret

; Moves the cursor one pixel to the right.
qrc_pixel_right:
    ; 1 -> 2 | 0001 -> 0010
    ; 4 -> 8 | 0100 -> 1000
    ; 2 -> 1 | 0010 -> 0001 inc de
    ; 8 -> 4 | 1000 -> 0100 inc de
    ld a, 5
    and c
    jr nz, qrc_dont_inc
        srl c
        inc de
        ret
qrc_dont_inc:
    sla c
    ret

; Moves the cursor one pixel up.
qrc_pixel_up:
    ; 1 -> 4 | 0001 -> 0100 sub de, 33
    ; 2 -> 8 | 0010 -> 1000 sub de, 33
    ; 4 -> 1 | 0100 -> 0001
    ; 8 -> 2 | 1000 -> 0010
    ld a, 3
    and c
    jr z, qrc_dont_sub
        sla c
        sla c
        ld a, e
        sub 33
        ld e, a
        ld a, d
        sbc 0
        ld d, a
        ret
qrc_dont_sub:
    srl c
    srl c
    ret

; Moves the cursor one pixel down.
qrc_pixel_down:
    ; 1 -> 4 | 0001 -> 0100
    ; 2 -> 8 | 0010 -> 1000
    ; 4 -> 1 | 0100 -> 0001 add de, 33
    ; 8 -> 2 | 1000 -> 0010 add de, 33
    ld a, 3
    and c
    jr nz, qrc_dont_add
        srl c
        srl c
        ld a, e
        add 33
        ld e, a
        ld a, d
        adc 0
        ld d, a
        ret
qrc_dont_add:
    sla c
    sla c
    ret

qrc_set_pixel:
    ld a, (de)
    bit 7, a
    jr z, qrc_invert1
        xor $8f
qrc_invert1:
    or c
    bit 3, a
    jr z, qrc_invert2
        xor $8f
qrc_invert2:
    ld (de), a
    ret

#include "../qrc1.asm"

; ========== END OF USER PROGRAM ==========

    db $76 ; new line
line0_end:

; Line 10

first_line:
    db 0, 10
    dw line10_end - $ - 2
    db _FAST, $76
line10_end:

; Line 20

    db 0, 20
    dw line20_end - $ - 2
    db _CLS, $76
line20_end:

; Line 30

    db 0, 30
    dw line30_end - $ - 2
    db _PRINT, _AT, _VAL, _QUOTE, _0, _QUOTE, _COMMA
    db _VAL, _QUOTE, _0, _QUOTE, _SCOLON, _QUOTE
    db _E, _N, _T, _E, _R, _SPACE, _M, _E, _S, _S, _A, _G, _E, _SPACE, _LBRACE
    db _M, _A, _X, _SPACE, _1, _4, _SPACE, _C, _H, _A, _R, _S, _RBRACE
    db _QUOTE, $76
line30_end:

; Line 40

    db 0, 40
    dw line40_end - $ - 2
    db _INPUT, _M, _DOLLAR, $76
line40_end:

; Line 50

    db 0, 50
    dw line50_end - $ - 2
    db _LET, _L, _EQUAL, _LEN, _M, _DOLLAR
    db $76
line50_end:

; Line 60

    db 0, 60
    dw line60_end - $ - 2
    db _IF, _L, _EQUAL, _VAL, _QUOTE, _0, _QUOTE
    db _THEN, _GOTO, _VAL, _QUOTE, _4, _0, _QUOTE
    db $76
line60_end

; Line 70

    db 0, 70
    dw line70_end - $ - 2
    db _PRINT, _AT, _VAL, _QUOTE, _1, _QUOTE, _COMMA
    db _VAL, _QUOTE, _0, _QUOTE, _SCOLON, _M, _DOLLAR, _SCOLON, _QUOTE
    ds 32
    db _QUOTE, $76
line70_end:

; Line 80

    db 0, 80
    dw line80_end - $ - 2
    db _IF, _L, _GT, _VAL, _QUOTE, _1, _4, _QUOTE
    db _THEN, _LET, _L, _EQUAL, _VAL, _QUOTE, _1, _4, _QUOTE
    db $76
line80_end:

; Line 90

    db 0, 90
    dw line90_end - $ - 2
    db _LET, _O, _EQUAL, _VAL, _QUOTE
    db _0 + ((qrc1_message / 10000) % 10)
    db _0 + ((qrc1_message /  1000) % 10)
    db _0 + ((qrc1_message /   100) % 10)
    db _0 + ((qrc1_message /    10) % 10)
    db _0 + ((qrc1_message /     1) % 10)
    db _QUOTE, $76
line90_end:

; Line 100

    db 0, 100
    dw line100_end - $ - 2
    db _POKE, _O, _COMMA, _L, $76
line100_end:

; Line 110

    db 0, 110
    dw line110_end - $ - 2
    db _FOR, _I, _EQUAL, _VAL, _QUOTE, _1, _QUOTE, _TO, _L
    db $76
line110_end:

; Line 120

    db 0, 120
    dw line120_end - $ - 2
    db _POKE, _O, _PLUS, _I, _COMMA, _CODE, _M, _DOLLAR, _LBRACE, _I, _RBRACE
    db $76
line120_end:

; Line 130

    db 0, 130
    dw line130_end - $ - 2
    db _NEXT, _I, $76
line130_end:

; Line 140

    db 0, 140
    dw line140_end - $ - 2
    db _FOR, _I, _EQUAL, _VAL, _QUOTE, _6, _QUOTE
    db _TO, _VAL, _QUOTE, _1, _6, _QUOTE
    db $76
line140_end:

; Line 150

    db 0, 150
    dw line150_end - $ - 2
    db _PRINT, _AT, _I, _COMMA, _VAL, _QUOTE, _1, _0, _QUOTE, _SCOLON, _QUOTE
    ds 11
    db _QUOTE, $76
line150_end

; Line 160
    db 0, 160
    dw line160_end - $ - 2
    db _NEXT, _I, $76
line160_end

; Line 170

    db 0, 170
    dw line170_end - $ - 2
    db _RAND, _USR, _VAL, _QUOTE, _1, _6, _5, _1, _6, _QUOTE, $76
line170_end:

; Line 180

    db 0, 180
    dw line150_end - $ - 2
    db _GOTO, _VAL, _QUOTE, _3, _0, _QUOTE, $76
line180_end:

; Display file

dfile:
  db $76 ; Display file begins with a new line
  ds 32  ; 24 lines with 32 characters and a new line
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76
  ds 32
  db $76

; BASIC variables

vararea:
  db $80

; End of program

last:
