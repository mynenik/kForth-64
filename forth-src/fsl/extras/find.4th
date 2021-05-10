\ find.4th
\
\ Find the element in an array closest to a given value, and 
\ return its index.
\
\ Based on the routine locate() in Numerical Recipes in C, The
\ Art of Scientific Computing, 2nd ed., by W. H. Press, S. A.
\ Teukolsky, W. T. Vetterling, and B. P. Flannery, Cambridge
\ University Press, 1994.
\
\ Forth version for use with the Forth Scientific Library,
\ by Krishna Myneni
\
\ Revisions:
\   2010-10-16 km  ported from the xyplot library modules
\   2011-09-16 km  use Neal Bridges' anonymous modules
\   2012-02-19 km  use KM/DNW's modules library

BEGIN-MODULE

BASE @
DECIMAL

Private:

0 ptr findA{
0 value findN
0 value findJ
variable ordering
fvariable findDel1

Public:

\ Return index of point with closest x to fx in FLOAT ARRAY 'A

: }ffind ( fx n 'A -- u | return index 0 <= u < n )
	to findA{  to findN
	findA{ 0 } F@  findA{ findN 1- } F@  F<  ordering !
	findN 0
	BEGIN
	  2dup - 1 >
	WHILE
	  2dup 2>R
	  + 2/ dup >R 
	  findA{ swap } F@ 
	  fover F<= ordering @ =
	  R> swap 2R> rot
	  IF drop swap ELSE nip THEN 
	REPEAT
	nip dup to findJ
	findA{ swap } F@ fover F- fabs findDel1 F!
	findJ findN 1- < IF
	  findA{ findJ 1+ } F@ F- fabs
	  findDel1 F@ F< IF  findJ 1+ to findJ  THEN
	ELSE
	  fdrop
	THEN
	findJ ;

BASE !
END-MODULE


