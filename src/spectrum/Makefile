ZMAKEBAS=../../../zmakebas/zmakebas
PASMO=../../../pasmo-0.5.3/pasmo

all: qrc1.tap qrc11.tap

qrc1.tap: build1.lua qrc1.bas qrc1.asm plot.asm ../qrc1.asm
	lua build1.lua "$(PASMO)" "$(ZMAKEBAS)"

qrc11.tap: build11.lua qrc11.bas qrc11.asm plot.asm ../qrc11.asm
	lua build11.lua "$(PASMO)" "$(ZMAKEBAS)"

clean: FORCE
	rm -f qrc1.tap qrc11.tap

.PHONY: FORCE
