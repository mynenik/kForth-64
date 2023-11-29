\ polys             evaluation of various special polynomials.
\        Uses recurrance relations to do the evaluation from lower orders

\ Forth Scientific Library Algorithm #21

\ Ch_n   ACM # 10, Evaluates the nth order Chebyschev Polynomial (first kind),
\        Ch_n(x) = cos( n * cos^-1(x) )

\ He_n   ACM # 11, Evaluates the nth order Hermite Polynomial,
\        He_n(x) = (-1)^n exp( x^2 ) d^n exp( - x^2 ) /dX^n

\ La_n   ACM # 12, Evaluates the nth order Laguerre Polynomial,
\        La_n(x) = exp(x) d^n X^n exp( - x ) /dX^n

\ Lag_n   Evaluates the nth order Generalized Laguerre Polynomial,
\        Lag_n(x,a)

\ Le_n   ACM # 13, Evaluates the nth order Legendre Polynomial,
\        La_n(x) = 1/(2^n n!) d^n (X^2 -1)^n /dX^n

\ Be_n   Evaluates the nth order Bessel Polynomial,
\        Be_n(x) = \sum_k=0^n d_k x^k,  d_k = (2 n - k)!/(2^(n-k) k! (n-k)!

\ These algorithms have very similar internal structure that could in principle
\ be factored out, for reasons of computational efficiency this was factorization
\ was not done.

\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\      2. Uses a local variable mechanism implemented in 'fsl_util.seq'
\      3. The compilation of the test code is controlled by the VALUE ?TEST-CODE
\         and the conditional compilation words in the Programming-Tools wordset

\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ The original publication of Laguerre polynomial evaluation had some
\ errors, these are corrected in this code.

\ see also
\ Conte, S.D. and C. deBoor, 1972; Elementary Numerical Analysis,
\ an algorithmic approach, McGraw-Hill, New York, 396 pages

\ The Bessel polynomial is described in,
\ Rabiner, L.R. and B. Gold, 1975; Theory and Application of Digital
\ Signal Processing, Prentice-Hall, Englewood Cliffs, N.J. 762 pages
\ ISBN 0-13-914101-4

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

\ Revisions:
\   2003-11-27  km; Adapted for kForth
\   2007-10-13  K. Myneni; modified test code for automated tests
\   2007-10-27  km; save base, switch to decimal, and restore base
\   2010-12-19  km; use Private: to hide temporary fvariables
\   2011-09-16  km; use Neal Bridges' anonymous modules
\   2012-02-19  km; use KM/DNW's modules library
CR .( POLYS             V1.1e          19 February  2012 EFC )
BEGIN-MODULE

BASE @ DECIMAL

Private:

FVARIABLE a
FVARIABLE b
FVARIABLE c
FVARIABLE d

Public:

: Ch_n ( n x -- r )         \ nth order 1st kind Chebyschev Polynomial
        \ set up a local fvariable frame
        FDUP  1.0e0 
        ( FRAME| a b c | )  a F!  b F!  c F!

        DUP 0= IF DROP 1.0e0  b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   c F@ b F@ F* 2.0e0 F* a F@ F-
                                   b F@ a F!
                                   b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b F@

        ( |FRAME )
;

: He_n ( n x -- r )           \ nth order Hermite Polynomial
        \ set up a local fvariable frame, c (=x) then b then a
        2.0e0 F* FDUP 1.0e0
        ( FRAME| a b c | )  a F!  b F!  c F!

        DUP 0= IF DROP 1.0e0 b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   c F@ b F@ F*
                                   I 2* S>F a F@ F* F-
                                   b F@ a F!
                                   b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

         b F@   \ b contains the result

         ( |FRAME )
;

: La_n ( n x -- r )           \ nth order Laguerre Polynomial
        \ set up a local fvariable frame, c then b then a
        1.0e0 FOVER F- 1.0e0
        ( FRAME| a b c | )  a F!  b F!  c F!


        DUP 0= IF DROP 1.0e0 b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   I 2* 1+ S>F c F@ F- b F@ F*
                                   I S>F a F@ F* F-
                                   I 1+ S>F F/
                                   b F@ a F!
                                   b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b F@ 
        ( |FRAME )
;

\ nth order generalized Laguerre Polynomial
\ NOTE EXTRA PARAMETER COMPARED TO OTHER POLYNOMIALS,
\      for alpha = 0.0 this polynomial is the same as La_n
: Lag_n ( n x alpha -- r )
        \ set up a local fvariable frame, d then c then b then a
        FSWAP 1.0e0 FOVER F-  1.0e0
        ( FRAME| a b c d | )  a F!  b F!  c F!  d F!

        d F@ b F@ F+ b F!

        DUP 0= IF DROP 1.0e0 b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   I 2* 1+ S>F d F@ F+ c F@ F- b F@ F*
                                   I S>F d F@ F+ a F@ F* F-
                                   I 1+ S>F F/
                                   b F@ a F!
                                   b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b F@
        ( |FRAME )
;

: Le_n ( n x -- r )               \ nth order Legendre Polynomial
        \ set up a local fvariable frame, c then b then a
        FDUP 1.0e0
        ( FRAME| a b c | )  a F!  b F!  c F!

        DUP 0= IF DROP 1.0e0 b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   c F@ b F@ F* FDUP a F@ F-
                                   I S>F I 1+ S>F F/ F* F+
                                   b F@ a F!
                                   b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b F@
        ( |FRAME )
;


: Be_n ( n x -- r )          \ nth order Bessel Polynomial
        \ set up a local fvariable frame, c then b then a
        1.0e0 FOVER F+ 1.0e0
        ( FRAME| a b c | )  a F!  b F!  c F!

        DUP 0= IF DROP 1.0e0 b F!
               ELSE
                   DUP 1 > IF

                              1+ 2 DO
                                   I 2* 1- S>F b F@ F*
                                   c F@ FSQUARE a F@ F* F+
                                   b F@ a F!
                                   b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

         b F@
         ( |FRAME )
;


BASE !
END-MODULE

TEST-CODE? [IF]     \ test code =============================================
[undefined] T{              [IF] include ttester  [THEN]
[undefined] CompareMatrices [IF] include fsl-test-utils [THEN]
[undefined] }Horner         [IF] include horner   [THEN]
BASE @ DECIMAL

DEFER poly
5 6 FLOAT matrix ptable{{
5 6 FLOAT matrix rtable{{
0 ptr table{{
0 value max_order

\ Generate values for orders 3 through max_order,
\ at x = { -0.25, 0, 0.25, 0.50, 0.75 }

FVARIABLE px

: )gen-polys ( 'func 'table nmax -- )
    TO max_order TO table{{  IS poly
    5 0 DO
	I S>F 0.25e0 F*  -0.25e0 F+ px F!
	max_order 1+ 3 DO
	    I px F@  poly  table{{ J I 3 - }} F!
	LOOP
    LOOP
;

FVARIABLE alpha

: )gen-gpoly ( 'func 'table nmax  alpha -- )
    alpha F!
    TO max_order TO table{{  IS poly
    5 0 DO
	I S>F 0.25e0 F*  -0.25e0 F+ px F!
	max_order 1+ 3 DO
	    I px F@ alpha F@ poly  ptable{{ J I 3 - }} F!
	LOOP
    LOOP
;

\ Reference values calculated from formulas for special polynomials:
\
\   http://en.wikipedia.org/wiki/XX_polynomials
\
\   XX = Chebyshev, Hermite, Laguerre, Legendre, Bessel

10 FLOAT array c{

0 value norder 
\ Chebyshev polynomials for orders 0 to 8
: Ch_n_ref ( n x -- r)
    px F! DUP TO norder
    CASE
	0 OF  1e                                           ENDOF
	1 OF  0e  1e                                       ENDOF
	2 OF -1e  0e   2e                                  ENDOF
	3 OF  0e -3e   0e   4e                             ENDOF
	4 OF  1e  0e  -8e   0e    8e                       ENDOF   
	5 OF  0e  5e   0e -20e    0e   16e                 ENDOF
	6 OF -1e  0e  18e   0e  -48e    0e   32e           ENDOF
	7 OF  0e -7e   0e  56e    0e -112e    0e 64e       ENDOF
	8 OF  1e  0e -32e   0e  160e    0e -256e  0e 128e  ENDOF
	ABORT" Tn order out of bounds"
    ENDCASE
    norder 1+ c{ }fput  px F@ c{ norder }Horner
;


\ Hermite polynomials for orders 0 to 8
: He_n_ref ( n x -- r )
    px F! DUP TO norder
    CASE
	0 OF    1e                                         ENDOF
	1 OF    0e 2e                                      ENDOF
	2 OF   -2e 0e   4e                                 ENDOF
	3 OF    0e -12e 0e 8e                              ENDOF
	4 OF   12e 0e   -48e 0e 16e                        ENDOF
	5 OF    0e 120e 0e -160e 0e 32e                    ENDOF
	6 OF -120e 0e   720e 0e -480e 0e 64e               ENDOF
	7 OF    0e -1680e 0e 3360e 0e -1344e 0e 128e       ENDOF
	8 OF 1680e 0e -13440e 0e 13440e 0e -3584e 0e 256e  ENDOF
	ABORT" Tn order out of bounds"
    ENDCASE
    norder 1+ c{ }fput  px F@ c{ norder }Horner
;    

\ Laguerre polynomials for orders 0 to 6
: La_n_ref ( n x -- r )
    px F! DUP TO norder
    CASE
	0 OF   1e                                        ENDOF
	1 OF   1e  1e -1e                                ENDOF
	2 OF   2e  2e -4e 1e                             ENDOF
	3 OF   6e  6e -18e 9e -1e                        ENDOF
	4 OF  24e  24e -96e 72e -16e 1e                  ENDOF
	5 OF 120e  120e -600e 600e -200e 25e -1e         ENDOF
	6 OF 720e  720e -4320e 5400e -2400e 450e -36e 1e ENDOF
	ABORT" Tn order out of bounds"
    ENDCASE
    norder 1+ c{ }fput  px F@  c{ norder }Horner FSWAP F/ 
;    


\ Legendre polynomials for orders 0 to 8
: Le_n_ref ( n x -- r )
    px F! DUP TO norder
    CASE
	0 OF  1e                                             ENDOF
	1 OF  1e 0e 1e                                       ENDOF
	2 OF  2e -1e 0e 3e                                   ENDOF
	3 OF  2e  0e -3e 0e 5e                               ENDOF
	4 OF  8e  3e 0e -30e 0e 35e                          ENDOF
	5 OF  8e  0e 15e 0e -70e 0e 63e                      ENDOF
	6 OF 16e  -5e 0e 105e 0e -315e 0e 231e               ENDOF
	7 OF 16e  0e -35e 0e 315e 0e -693e 0e 429e           ENDOF
	8 OF 128e 35e 0e -1260e 0e 6930e 0e -12012e 0e 6435e ENDOF
	ABORT" Tn order out of bounds"
    ENDCASE
    norder 1+ c{ }fput  px F@ c{ norder }Horner FSWAP F/ 
;

\ Reverse Bessel polynomials for orders 0 to 8
\ see also http://www.research.att.com/~njas/sequences/table?a=1497&fmt=312
: Be_n_ref ( n x -- r )
    px F! DUP TO norder
    CASE
	0 OF  1e                                                         ENDOF
	1 OF  1e 1e                                                      ENDOF
	2 OF  3e 3e 1e                                                   ENDOF
	3 OF  15e 15e 6e 1e                                              ENDOF
	4 OF  105e 105e 45e 10e 1e                                       ENDOF
	5 OF  945e 945e 420e 105e 15e 1e                                 ENDOF
	6 OF  10395e 10395e 4725e 1260e 210e 21e 1e                      ENDOF
	7 OF  135135e 135135e 62370e 17325e 3150e 378e 28e 1e            ENDOF
	8 OF  2027025e 2027025e 945945e 270270e 51975e 6930e 630e 36e 1e ENDOF
	ABORT" Tn order out of bounds"
    ENDCASE
    norder 1+ c{ }fput  px F@ c{ norder }Horner
;    

\ Compare polynomial values computed from recurrence relations
\ with values from formulas.
1e-15 abs-near F!
1e-15 rel-near F!
set-near

CR
TESTING CH_N
t{  use( Ch_n ptable{{ 8 )gen-polys  ->  use( Ch_n_ref rtable{{ 8 )gen-polys  }t
5 6 CompareMatrices ptable{{  rtable{{

TESTING HE_N
t{  use( He_n ptable{{ 8 )gen-polys  ->  use( He_n_ref rtable{{ 8 )gen-polys  }t
5 6 CompareMatrices ptable{{  rtable{{

TESTING LA_N
t{  use( La_n ptable{{ 6 )gen-polys  ->  use( La_n_ref rtable{{ 6 )gen-polys  }t
5 4 CompareMatrices ptable{{  rtable{{

TESTING LE_N
t{  use( Le_n ptable{{ 8 )gen-polys  ->  use( Le_n_ref rtable{{ 8 )gen-polys }t
5 6 CompareMatrices ptable{{  rtable{{

TESTING BE_N
t{  use( Be_n ptable{{ 8 )gen-polys  ->  use( Be_n_ref rtable{{ 8 )gen-polys }t
5 6 CompareMatrices ptable{{  rtable{{

\ Generalized Laguerre table comparison values generated from Mathematica V2.2
\ for alpha = 0.75
\ 4.41667e   5.90365e   ** 7.61446e **   9.56526e  11.7909e   14.3154e
     4.41667e   5.90365e   7.611446e  9.56526e  11.7909e   14.3154e 
     3.00781e   3.57178e   4.10754e   4.62099e   5.11609e   5.59573e 
     1.83333e   1.79687e   1.6724e    1.48342e   1.24821e   0.981352e
     0.877604e  0.506673e  0.103621e -0.291272e -0.651256e -0.959288e 
     0.125e    -0.367187e -0.779687e -1.07754e  -1.2493e   -1.29858e 
5 6 rtable{{ }}fput

1e-5 abs-near F!       \ <-- note the reduced precision for comparison
1e-5 rel-near F!       \       since we are using the above table
TESTING LAG_N
t{  use( Lag_n ptable{{ 8  0.75e  )gen-gpoly  ->  }t
5 6 CompareMatrices ptable{{  rtable{{

BASE !
[THEN]
