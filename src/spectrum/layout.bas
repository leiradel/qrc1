   10 CLEAR 49999: DIM q(61,61): LET white=3232: LET black=3233
   20 OVER 1
   30 FOR i=0 TO 121 STEP 2
   40 PLOT i,175: DRAW 0,-121
   50 PLOT 0,175-i: DRAW 121,0
   60 NEXT i: OVER 0
   70 REM finders
   80 LET x=1: LET y=1: GO SUB 3000
   90 LET x=55: LET y=1: GO SUB 3000
  100 LET x=1: LET y=55: GO SUB 3000
  105 REM separators
  110 LET x=8: LET y=1: LET w=1: LET h=8: LET c=white: GO SUB 2000
  120 LET x=54: LET y=1: LET w=1: LET h=8: LET c=white: GO SUB 2000
  130 LET x=8: LET y=54: LET w=1: LET h=8: LET c=white: GO SUB 2000
  140 LET x=1: LET y=8: LET w=7: LET h=1: LET c=white: GO SUB 2000
  150 LET x=1: LET y=54: LET w=7: LET h=1: LET c=white: GO SUB 2000
  160 LET x=55: LET y=8: LET w=7: LET h=1: LET c=white: GO SUB 2000
  170 REM alignment
  180 FOR i=5 TO 54 STEP 24
  190 FOR j=5 TO 54 STEP 24
  200 IF q(i+2,j+2) THEN GO TO 240
  210 LET w=5: LET h=5: LET c=black: LET x=j: LET y=i: GO SUB 2000
  220 LET x=j+1: LET y=i+1: LET w=3: LET h=3: LET c=white: GO SUB 2000
  230 LET x=j+2: LET y=i+2: LET c=black: GO SUB 1000
  240 NEXT j: NEXT i
  250 REM timing
  260 FOR i=9 TO 53 STEP 2
  270 LET x=i: LET y=7: LET c=black: GO SUB 1000
  280 LET x=i+1: LET y=7: LET c=white: GO SUB 1000
  290 LET y=i: LET x=7: LET c=black: GO SUB 1000
  300 LET y=i+1: LET x=7: LET c=white: GO SUB 1000
  310 NEXT i
  320 REM format
  330 FOR i=54 TO 61
  340 LET x=i: LET y=9: READ c: GO SUB 1000
  350 LET y=i: LET x=9: READ c: GO SUB 1000
  360 NEXT i
  370 FOR i=1 TO 9
  380 LET x=i: LET y=9: READ c: GO SUB 1000
  390 LET y=i: LET x=9: READ c: GO SUB 1000
  400 NEXT i
  410 DATA white,black,white,white,white,white,black,black,white,white,white,black,black,white,white,black
  420 DATA black,white,white,black,black,white,white,white,black,black,white,white,black,black,white,white,white,white
  430 REM version
  440 FOR i=51 TO 53: FOR j=1 TO 6
  450 READ c
  460 LET y=i: LET x=j: GO SUB 1000
  470 LET x=i: LET y=j: GO SUB 1000
  480 NEXT j: NEXT i
  490 DATA white,white,black,black,black,black
  500 DATA black,black,black,white,black,white
  510 DATA black,black,black,black,white,white
  520 REM payload
  530 LET c=0
  540 FOR i=60 TO 1 STEP -4
  550 FOR j=61 TO 1 STEP -1
  560 FOR k=1 TO 0 STEP -1
  570 LET x=i+k: LET y=j: IF NOT q(y,x) THEN GO SUB 1000: LET c=c+1
  580 NEXT k: NEXT j: IF i=8 THEN LET i=i-1
  590 FOR j=1 TO 61
  600 FOR k=1 TO 0 STEP -1
  610 LET x=i+k-2: LET y=j: IF NOT q(y,x) THEN GO SUB 1000: LET c=c+1
  620 NEXT k: NEXT j: NEXT i
  630 REM checkerboard
  640 FOR i=1 TO 61
  650 FOR j=1 TO 61
  660 IF q(i,j)>=white THEN IF (i+j)/2=INT ((i+j)/2) THEN LET c=white+black-q(i,j): LET x=j: LET y=i: GO SUB 1000
  670 NEXT j: NEXT i
  680 REM binary encoding
  690 LET a=50000
  700 FOR i=1 TO 61
  710 FOR j=1 TO 61
  720 LET l=q(i,j): LET h=INT (l/256): LET l=l-256*h
  730 POKE a,l: POKE a+1,h: LET a=a+2
  740 NEXT j: NEXT i
  750 PRINT a
  999: STOP 
 1000 REM module
 1010 FOR a=176-y-y TO 177-y-y
 1020 FOR b=x+x-2 TO x+x-1
 1030 PLOT INVERSE c=white;b,a
 1040 NEXT b: NEXT a: LET q(y,x)=c: RETURN 
 2000 REM rectangle
 2010 LET xx=x: LET yy=y
 2020 FOR y=yy TO yy+h-1
 2030 FOR x=xx TO xx+w-1
 2040 GO SUB 1000: NEXT x: NEXT y
 2050 LET x=xx: LET y=yy: RETURN 
 3000 REM finder
 3010 LET w=7: LET h=7: LET c=black
 3020 GO SUB 2000
 3030 LET w=5: LET h=5: LET x=x+1: LET y=y+1: LET c=white
 3040 GO SUB 2000
 3050 LET w=3: LET h=3: LET x=x+1: LET y=y+1: LET c=black
 3060 GO TO 2000
