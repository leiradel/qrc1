ZASM=../../../zasm/Linux/zasm

all: debug

debug: debug.c debug.h
	gcc -O2 -o $@ $+

debug.h: debug.bin
	xxd -i $< $@

debug.bin: debug.asm
	$(ZASM) -uwy $< $@

clean: FORCE
	rm -f debug debug.h debug.bin

.PHONY: FORCE
