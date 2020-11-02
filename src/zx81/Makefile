ZXTEXT2P=../../etc/zxtext2p
ZASM=../../../zasm/Linux/zasm

all: zx81.p

zx81.p: buildp.lua zx81.bas zx81.asm
	lua buildp.lua "$(ZASM)" "$(ZXTEXT2P)"

clean: FORCE
	rm -f zx81.p

.PHONY: FORCE
