all: qrc1 zxtext2p

qrc1: qrc1.c
	gcc -O2 -o $@ $+ -lm

zxtext2p: zxtext2p.c
	gcc -O2 -o $@ $+

clean: FORCE
	rm -f qrc1 zxtext2p

.PHONY: FORCE
