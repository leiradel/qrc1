ZMAKEBAS=../../../zmakebas/zmakebas
PASMO=../../../pasmo-0.5.3/pasmo

all: zxs.tap

zxs.tap: buildp.lua zxs.bas zxs.asm
	lua buildp.lua "$(PASMO)" "$(ZMAKEBAS)"

clean: FORCE
	rm -f zxs.tap

.PHONY: FORCE
