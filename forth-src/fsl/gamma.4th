\ gamma             The Gamma, loggamma and reciprocal gamma functions
\ Calulates Gamma[x], Log[ Gamma[x] ] and 1/Gamma[x] functions
\ (for real arguments)

\ Forth Scientific Library Algorithm #18

\ This is an ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. Uses the words 'REAL*4' and ARRAY to create floating point arrays.
\      3. The word '}' to dereference a one-dimensional array.
\      4. Uses the word '}Horner' for fast polynomial evaluation.
\      5. The FCONSTANT PI (3.1415926536...)
\      6. The following words:
\               : S>F       S>D D>F ;  \ convert from single to float
\               : FTRUNC    F>D D>F ;  \ truncate a float
\               : FTRUNC>S  F>D D>S ;  \ convert float to single with truncation
\               : F>        FSWAP F< ; \ float greater than
\      7. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset. 

\ Baker, L., 1992; C Mathematical Function Handbook, McGraw-Hill,
\ New York, 757 pages,  ISBN 0-07-911158-0

\ The reciprocal Gamma function is ACM Algorithm #80

\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

\
\ Revisions:
\   2006-11-07  km; ported to kForth; removed use of %
\   2007-10-18  km; revised test code for automated tests;
\                   used }fput to initialize arrays
\   2007-10-27  km; save base, switch to decimal, and restore base
\   2011-09-16  km; use Neal Bridges' anonymous modules interface
\   2012-02-19  km; use KM/DNW's modules library 
cr .( GAMMA             V1.2e          19 February  2012  EFC )
BEGIN-MODULE
BASE @ DECIMAL

Private:

9 FLOAT ARRAY b{
4 FLOAT ARRAY ser{
14 FLOAT ARRAY b-inv{

FVARIABLE X-TMP           \ scratch space to be kind on the fstack
FVARIABLE Z-TMP

0.918938533e FCONSTANT logsr2pi

: init-b-ser
     1.0e
    -0.577191652e
     0.988205891e
    -0.897056937e
     0.918206857e
    -0.756704078e
     0.482199394e
    -0.193527818e
     0.035868343e      9 b{ }fput

     0.08333333333333e
    -0.002777777777e
     0.000793650793e
    -0.000595238095e   4 ser{ }fput

     1.0e
    -0.422784335092e
    -0.233093736365e
     0.191091101162e
    -0.024552490887e
    -0.017645242118e
     0.008023278113e
    -0.000804341335e
    -0.000360851496e
     0.000145624324e
    -0.000017527917e
    -0.000002625721e
     0.000001328554e
    -0.000000181220e  14 b-inv{ }fput

;

init-b-ser

: non-negative-x ( fx -- fy | fy = log{gamma{x}} )

    FDUP 1.0e F> IF

	FDUP 2.0e F> IF
	    X-TMP F!

            1.0e X-TMP F@ F/
            FDUP Z-TMP F! FDUP F*

            ser{ 3 }Horner Z-TMP F@ F*
                                            
            logsr2pi F+ X-TMP F@ F-
            X-TMP F@ FLN
            X-TMP F@ 0.5e F- F*
            F+

	ELSE
	    1.0e F- b{ 8 }Horner FLN
	THEN

    ELSE
	FDUP F0= 0= IF
	    FDUP X-TMP F!
            b{ 8 }Horner
            X-TMP F@ F/ FLN
	THEN

    THEN
;


: ?negative-integer ( fx -- fx  t/f)

    \ check to see if x is a negative integer, or zero
    FDUP F0< IF
	FDUP FDUP FTRUNC F- F0=
    ELSE
	FDUP F0=
    THEN
;

: rgam ( fx -- fz )
    FDUP
    b-inv{ 13 }Horner
    FOVER 1.0e F+ F* F*
;

: rgam-large-x ( fx -- fz )

    1.0e                                  \ the AA loop
    BEGIN
	FSWAP 1.0e F-
        FSWAP FOVER F*
        FOVER 1.0e F> 0=
    UNTIL

    FOVER 1.0e F= IF
	FSWAP FDROP 1.0e FSWAP F/
    ELSE
	FSWAP rgam FSWAP F/
    THEN
;

: rgam-small-x ( fx -- fz ) 

    FDUP -1.0e F= IF
	FDROP 0.0e
    ELSE
	FDUP -1.0e F> IF rgam
	ELSE
	    FDUP             \ the CC loop
            BEGIN
		FSWAP 1.0e F+
                FDUP -1.0e F<
	    WHILE
		    FSWAP
                    FOVER F*
	    REPEAT

            rgam F*

	THEN
    THEN
;

Public:

                                            \ Log Gamma function
: loggam ( fx -- fy | fy= log{gamma{x}} )   \ input arg is returned if routine aborts

    \ check to make sure x is not a negative integer or zero
    ?negative-integer ABORT" loggam has 0 or negative integer argument "

    FDUP F0< IF
	FABS 1.0e F+   Z-TMP F!
        PI Z-TMP F@ F* FSIN FABS PI FSWAP F/ FLN
        Z-TMP F@
        non-negative-x
        F-
    ELSE
	non-negative-x
    THEN
;

                               \ Gamma function
: gamma ( fx -- g{x} )         \ input arg is returned if routine aborts

    \ check to make sure x is not a negative integer or zero
    ?negative-integer ABORT" gamma has 0 or negative integer argument "

    FDUP loggam FEXP

    FOVER F0< IF
	FOVER FTRUNC>S NEGATE  2 MOD
        2* 1- S>F F*
    THEN

    FSWAP FDROP
;


: rgamma ( fx -- 1/g{x} )         \ reciprocal gamma function

    FDUP F0= >R FDUP 1.0e F= R> OR 0=    \ will return x if x is zero or one
    IF
	FDUP 1.0e F< IF
	    rgam-small-x
	ELSE
	    rgam-large-x
	THEN
    THEN
;

BASE !
END-MODULE

TEST-CODE? [IF]     \ test code =============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

[undefined] finv [IF] : finv ( x -- 1/x ) 1e FSWAP F/ ; [THEN]

1e-7 rel-near F!             \ <-- note tolerance is set relatively low;
1e-7 abs-near F!             \     accuracy of Gamma function calculation is not high
set-near

PI FSQRT  FCONSTANT  SQRTPI

CR
TESTING GAMMA
t{  1.0e gamma  ->  1e            r}t
t{  2.0e gamma  ->  1e            r}t
t{  3.0e gamma  ->  2e            r}t
t{  4.0e gamma  ->  6e            r}t
t{  5.0e gamma  ->  24e           r}t
t{ -2.5e gamma  ->  SQRTPI -8e F* 15e F/  r}t
t{ -1.5e gamma  ->  SQRTPI 4e F* 3e F/  r}t
t{ -0.5e gamma  ->  SQRTPI -2e F*  r}t
t{  0.5e gamma  ->  SQRTPI        r}t
t{  1.5e gamma  ->  SQRTPI 2e F/  r}t
t{  2.5e gamma  ->  SQRTPI 3e F* 4e F/  r}t
 
TESTING RGAMMA
t{  5.0e rgamma  ->    5e   gamma finv  r}t
t{ -1.5e rgamma  ->   -1.5e gamma finv  r}t
t{ -0.5e rgamma  ->   -0.5e gamma finv  r}t
t{  0.5e rgamma  ->    0.5e gamma finv  r}t

BASE !
[THEN]
