\ Horner          Evaluation of a polynomial by the Horner method

\ Forth Scientific Library Algorithm #3

\ This routine evaluates an Nth order polynomial Y(X) at point X
\ Y(X) = \sum_i=0^N a[i] x^i                  (NOTE: N+1 COEFFICIENTS)
\ by the Horner scheme.  This algorithm minimizes the number of multiplications
\ required to evaluate the polynomial.
\ The implementation demonstrates the use of array aliasing.

\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      3. Test code uses 'ExpInt' for real exponential integrals

\ This algorithm is described in many places, e.g.,
\ Conte, S.D. and C. deBoor, 1972; Elementary Numerical Analysis, an algorithmic
\ approach, McGraw-Hill, New York, 396 pages

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.
\

\ Revisions:
\    2006-11-07  km; ported to kForth with minor revisions.
\    2007-10-12  km; revised the test code for automated tests.
\    2007-10-27  km; save base, switch to decimal, and restore base.
\    2011-09-16  km; use Neal Bridges' anonymous modules.
\    2012-02-19  km; use KM/DNW's modules library
CR .( HORNER            V1.5d          19 February  2012   EFC )

BEGIN-MODULE

BASE @ DECIMAL

Private:

0 ptr ha{

Public:

: }Horner ( fx 'a n -- fy)

    SWAP  to ha{ 
    >R  0.0e

    0 R> DO
	FOVER F*
	ha{ I } F@ F+  
    -1 +LOOP

    FSWAP FDROP
;

BASE !
END-MODULE

TEST-CODE? [IF]     \ test code =============================================
[undefined] expint  [IF]  include expint   [THEN]
[undefined] T{      [IF]  include ttester  [THEN]
BASE @ DECIMAL

1e-8 rel-near F!
1e-8 abs-near F!
set-near


\ initialize with data for real exponential integral
6 FLOAT ARRAY ArrayZ{
    -0.57721566e
     0.99999193e
    -0.24991055e
     0.05519968e
    -0.00976004e
     0.00107857e
6 ArrayZ{ }fput
    
5 FLOAT ARRAY ArrayY{    
     0.2677737343e
     8.6347608925e
    18.059016973e
     8.5733287401e
     1.0e
5 ArrayY{ }fput

5 FLOAT ARRAY ArrayW{
     3.9584969228e
    21.0996530827e
    25.6329561486e
     9.5733223454e
     1.0e
5 ArrayW{ }fput


: local_exp ( x -- expint[x] )

        FDUP
        1.0e F< IF
                    FDUP ArrayZ{  5 }Horner
                    FSWAP FLN F-
                ELSE
                    FDUP  ArrayY{ 4 }Horner
                    FOVER ArrayW{ 4 }Horner
                    F/
                    FOVER F/
                    FSWAP -1.0e F* FEXP F*
                THEN
;


\ compare ExpInt as coded in V1.0 against the general purpose
\ Horner routine

CR
TESTING }HORNER

t{  0.2e local_exp  ->  0.2e expint  r}t
t{  0.5e local_exp  ->  0.5e expint  r}t
t{  1.0e local_exp  ->  1.0e expint  r}t
t{  2.0e local_exp  ->  2.0e expint  r}t
t{  5.0e local_exp  ->  5.0e expint  r}t
t{ 10.0e local_exp  -> 10.0e expint  r}t

BASE !
[THEN]
