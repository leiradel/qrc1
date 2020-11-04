ZXTEXT2P=../../etc/zxtext2p
PASMO=../../../pasmo-0.5.3/pasmo

all: zx81.p

zx81.p: buildp.lua zx81.bas zx81.asm
	lua buildp.lua "$(PASMO)" "$(ZXTEXT2P)"

clean: FORCE
	rm -f zx81.p

.PHONY: FORCE
