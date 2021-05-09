\ elip     Complete Elliptic Integral         ACM Algorithm #149

\ Forth Scientific Library Algorithm #2

\ Evaluates the Complete Elliptic Integral,
\     Elip[a, b] = int_0^{\pi/2} 1/Sqrt{a^2 cos^2(t) + b^2 sin^2(t)} dt

\ This function can be used to evaluate the complete elliptic integral
\ of the first kind, by using the relation K[m] = a Elip[a,b],  m = 1 - b^2/a^2
 
\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\      2. The FCONSTANT PI (3.1415926536...)
\ 
\ Both a recursive form and an iterative form are given, but because of the
\ large stack consumption the recursive form is probably not of much
\ practical use.

\ Caution: this code can potentially go into an endless loop
\          for certain values of the parameters.

\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided the
\ copyright notice is preserved.
\
\ Revisions:
\   2006-11-07  km; ported to kForth with minor revisions.
\   2007-10-27  km; revised the test code; save base, switch to
\                   decimal, and restore base.

CR .( ELIP     V1.2c                 27 September 2007   EFC )
BASE @ DECIMAL

: elip1 ( fa  fb -- elip[a,b] )     \ recursive form

     FOVER FOVER FOVER F- FABS
     FSWAP 1.0e-8 F*
     F< IF
	 FDROP
         pi 2.0e F/ FSWAP F/
     ELSE
         FOVER FOVER F+ 2.0e F/
         FROT  FROT  F* FSQRT
         RECURSE
     THEN
;

: elip2 ( fa  fb -- elip[a,b] )     \ nonrecursive version

    BEGIN
	FOVER FOVER F+ 2.0e F/
	FROT  FROT  F* FSQRT

	FOVER FOVER FOVER F- FABS
	FSWAP 1.0e-8 F*
    F< UNTIL

    FDROP

    pi 2.0e F/ FSWAP F/

;

BASE !

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester  [THEN]
BASE @ DECIMAL

1e-9 rel-near F!
1e-9 abs-near F!
set-near

\ test driver,  calculates the complete elliptic integral of the first
\ kind (K(m)) using the relation: K[m] = a Elip[a,b], m = 1 - b^2/a^2
\ compare with Abramowitz & Stegun, Handbook of Mathematical Functions,
\ Table 17.1
CR
TESTING ELIP1  ELIP2
\  m     K(m) exact    a Elip1[a,b]    a Elip2[a,b]
\ 0.0    1.57079633   
t{  1000.0e  1000.0e elip1 1000.0e F*  ->  PI 2e F/  r}t 
t{  1000.0e  1000.0e elip2 1000.0e F*  ->  PI 2e F/  r}t

\ 0.44   1.80632756
t{   400.0e   299.33259e elip1 400.0e F*  -> 1.80632756e r}t
t{   400.0e   299.33259e elip2 400.0e F*  -> 1.80632756e r}t

\ 0.75   2.15651565
t{  1000.0e   500.0e  elip1  1000.0e F*  -> 2.15651565e r}t
t{  1000.0e   500.0e  elip2  1000.0e F*  -> 2.15651565e r}t

\ 0.96   3.01611249
t{   500.0e   100.0e  elip1   500.0e F*  -> 3.01611249e r}t
t{   500.0e   100.0e  elip2   500.0e F*  -> 3.01611249e r}t

BASE !
[THEN]

