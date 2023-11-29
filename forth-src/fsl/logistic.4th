\ logistic     The Logistic function and its first derivative
\     logistic =   Exp( c + a x ) / (1 + Exp( c + a x ) )
\   d_logistic = a Exp( c + a x ) / (1 + Exp( c + a x ) )^2

\ Forth Scientific Library Algorithm #4

\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

\ Revisions:
\   2007-10-22  km; added automated test code with higher precision
\                   reference values, computed using HP 48G calculator,
\                   and added more test cases; forced DECIMAL base.
\   2007-10-27  km; save base, switch to decimal, and restore base.

cr .( Logistic          V1.2c          27 October 2007   EFC )
BASE @ DECIMAL

: logistic ( fx fa fc -- fz )
        FROT FROT
        F* F+
        FEXP
        FDUP 1.0e0 F+
        F/
;

: d_logistic ( fx fa fc -- fz )
        FSWAP FROT
        FOVER F* FROT F+
        FEXP
        
        FDUP 1.0e0 F+ FSQUARE
        F/ F*
;

BASE !

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester  [THEN]
BASE @ DECIMAL

1e-12 rel-near F!
1e-12 abs-near F!
set-near

CR
TESTING LOGISTIC  D_LOGISTIC
t{ -1e    1e    0e   logistic  ->  0.268941421370e   r}t
t{  0e    1e    0e   logistic  ->  0.5e              r}t 
t{  1e    1e    0e   logistic  ->  0.731058578630e   r}t
t{ -3.2e  1.5e  0.2e logistic  ->  0.00995180186692e r}t 
t{  0e    1.5e  0.2e logistic  ->  0.549833997312e   r}t
t{  3.2e  1.5e  0.2e logistic  ->  0.993307149076e   r}t
t{  0e    1e    0e   d_logistic -> 0.25e             r}t
t{  3.2e  1.5e  0.2e d_logistic -> 0.00997208500613e r}t

BASE !
[THEN]

