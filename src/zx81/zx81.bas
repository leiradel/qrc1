10 REM ${ASM}
20 FAST
30 CLS
40 PRINT AT 0,0;"ENTER MESSAGE (MAX 14 CHARS)"
50 INPUT M$
60 LET L=LEN M$
70 IF L=0 THEN GOTO 50
80 PRINT AT 1,0;M$;"                                "
90 IF L>14 THEN LET L=14
100 LET O=${MESSAGE}
110 POKE O,L
120 FOR I=1 TO L
130 POKE O+I,CODE M$(I)
140 NEXT I
150 FOR I=6 TO 16
160 PRINT AT I,10;"           "
170 NEXT I
180 RAND USR ${MAIN}
190 GOTO 40
