ZMAKEBAS=../../../zmakebas/zmakebas
PASMO=../../../pasmo-0.5.3/pasmo

all: qrc1.tap qrc11.tap i25.tap

qrc1.tap: buildtap.lua qrc1.bas qrc1.asm plot.asm ../qrc1_rom.asm ../qrc1_ram.asm
	LUA_PATH=';;../../etc/?.lua' lua buildtap.lua qrc1.bas qrc1.asm $@ "$(PASMO)" "$(ZMAKEBAS)"

qrc11.tap: buildtap.lua qrc11.bas qrc11.asm plot.asm ../qrc11.asm
	LUA_PATH=';;../../etc/?.lua' lua buildtap.lua qrc11.bas qrc11.asm $@ "$(PASMO)" "$(ZMAKEBAS)"

i25.tap: buildtap.lua i25.bas i25.asm plot.asm ../i25.asm
	LUA_PATH=';;../../etc/?.lua' lua buildtap.lua i25.bas i25.asm $@ "$(PASMO)" "$(ZMAKEBAS)"

clean: FORCE
	rm -f qrc1.tap qrc11.tap

.PHONY: FORCE
