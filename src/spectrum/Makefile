ZMAKEBAS=../../../zmakebas/zmakebas
PASMO=../../../pasmo-0.5.3/pasmo

all: zxs1.tap zxs11.tap

zxs1.tap: build1.lua zxs1.bas zxs1.asm ../qrc1.asm
	lua build1.lua "$(PASMO)" "$(ZMAKEBAS)"

zxs11.tap: build11.lua zxs11.bas zxs11.asm ../qrc11.asm
	lua build11.lua "$(PASMO)" "$(ZMAKEBAS)"

clean: FORCE
	rm -f zxs1.tap zxs11.tap

.PHONY: FORCE
