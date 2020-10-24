; ROM routines
PLOT_SUB:	equ	$22E5
SCANNING:	equ	$24FB
STK_FETCH:	equ	$2BF1
REPORT_A:	equ	$34E7

; System variables
CH_ADD:		equ	$5C5D

	org	50000
start:	ld	hl, qstr
	ld	(CH_ADD), hl
	call	SCANNING
	call	STK_FETCH
	ld	a, b
	or	a
	jp	nz, REPORT_A
	ld	a, c
	cp	252
	jp	nc, REPORT_A
	ld	hl, qrc11_message + 1
	ld	(hl), a
	inc	hl
	ex	de, hl
	ldir
	include	"../qrc11.asm"

qrc11_module:
	push	bc
	push	hl
	sla	b
	sla	c
	ld	a, 189
	sub	b
	ld	b, c
	ld	c, a
	ld	a, 50
	add	a, b
	ld	b, a
	push	bc
	call	PLOT_SUB
	pop	bc
	inc	b
	push	bc
	call	PLOT_SUB
	pop	bc
	inc	c
	push	bc
	call	PLOT_SUB
	pop	bc
	dec	b
	call	PLOT_SUB
	pop	hl
	pop	bc
	ret

qstr:	db	"q$", 13

qrc11_map:
	incbin	"../v11.bin"
