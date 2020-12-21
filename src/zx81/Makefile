ZXTEXT2P=../../etc/zxtext2p
PASMO=../../../pasmo-0.5.3/pasmo

all: qrc1.p i25.p

qrc1.p: buildp.lua qrc1.bas qrc1.asm plot.asm ../qrc1.asm
	LUA_PATH=';;../../etc/?.lua' lua buildp.lua qrc1.bas qrc1.asm $@ "$(PASMO)" "$(ZXTEXT2P)"

i25.p: buildp.lua i25.bas i25.asm plot.asm ../i25.asm
	LUA_PATH=';;../../etc/?.lua' lua buildp.lua i25.bas i25.asm $@ "$(PASMO)" "$(ZXTEXT2P)"

clean: FORCE
	rm -f qrc1.p i25.p

.PHONY: FORCE
