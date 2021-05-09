\ expint     Real Exponential Integral         ACM Algorithm #20

\ Forth Scientific Library Algorithm #1

\ Evaluates the Real Exponential Integral,
\     E1(x) = - Ei(-x) =   int_x^\infty exp^{-u}/u du      for x > 0
\ using a rational approximation

\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\ 

\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided the
\ copyright notice is preserved.
\
\ Ported to kForth with minor revisions by K. Myneni, 2006-11-07
\ Revisions:
\    ?           km; removed use of "%"
\    2007-10-14  km; revised test code to perform automated tests
\    2007-10-27  km; save base, switch to decimal, and restore base.

CR .( EXPINT     V1.1c                 27 October   2007   EFC )
BASE @ DECIMAL

: expint ( fx -- expint[x] )
    
    FDUP
    1.0e F< IF
	FDUP 0.00107857e F* 0.00976004e F-
	FOVER F*
	0.05519968e F+
	FOVER F*
        0.24991055e F-
        FOVER F*
        0.99999193e F+
        FOVER F*
        0.57721566e F-
        FSWAP FLN F-
    ELSE
	FDUP 8.5733287401e F+
        FOVER F*
        18.059016973e F+
        FOVER F*
        8.6347608925e F+
        FOVER F*
        0.2677737343e F+

        FOVER
        FDUP 9.5733223454e F+
        FOVER F*
        25.6329561486e F+
        FOVER F*
        21.0996530827e F+
        FOVER F*
        3.9584969228e F+

        FSWAP FDROP
        F/
        FOVER F/
        FSWAP -1.0e F* FEXP
        F*

    THEN
;

BASE !

TEST-CODE? [IF]     \ test code =============================================
[undefined] T{      [IF]  include ttester  [THEN]
BASE @ DECIMAL

1e-7 rel-near F!
1e-7 abs-near F!
set-near

\ Generate selected E1 values and compare with values
\ from Abramowitz & Stegun, Handbook of Mathematical
\ Functions, Table 5.1

CR
TESTING expint
t{  0.5e expint  ->  0.5597736e    r}t
t{  1.0e expint  ->  0.2193839e    r}t
t{  2.0e expint  ->  0.0489005e    r}t
t{  5.0e expint  ->  0.001148296e  r}t
t{ 10.0e expint  ->  0.4156969e-5  r}t

BASE !
[THEN]
