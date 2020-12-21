10 REM ${#@temp.bin}
20 FAST
30 CLS
40 PRINT AT 0,0;"Enter message (max 8 digits)"
50 INPUT M$
60 LET L=LEN M$
70 IF L=0 THEN GOTO 50
80 PRINT AT 1,0;M$;"                                "
90 IF L>8 THEN LET L=8
100 LET W=L*28+32
110 LET C=(256-W)/2
120 POKE ${column},C/8
130 LET O=${i25_message}
140 POKE O,L
150 FOR I=1 TO L
160 POKE O+I,CODE M$(I)+20
170 NEXT I
180 FOR I=5 TO 15
190 PRINT AT I,0;"                                "
200 NEXT I
210 RANDOMIZE USR ${main}
220 GOTO 40
