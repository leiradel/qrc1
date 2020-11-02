all: qrc1.p

qrc1.p: zx81.asm ../qrc1.asm
	zasm -uwy $< $@

clean: FORCE
	rm -f qrc1.p zx81.lst

.PHONY: FORCE
