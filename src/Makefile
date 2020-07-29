all: c/qrc1 zx81/qrc1.p

c/qrc1: c/qrc1.c
	gcc -O2 -o $@ $+ -lm

zx81/qrc1.p: zx81/zx81.asm qrc1.asm
	~/Develop/zasm/Linux/zasm -uwy $< $@

clean: FORCE
	rm -f c/qrc1 zx81/qrc1.p zx81/zx81.lst

.PHONY: FORCE
