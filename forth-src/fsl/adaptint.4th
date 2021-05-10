\ Adaptive integration using trapezoidal rule
\ with Richardson extrapolation
\ Integrate a real function from xa to xb

\ Forth Scientific Library Algorithm #19

\ Usage:  use( fn.name xa xb err )integral
\ Examples:

\ use( FSQRT  0e  1e  1e-3 )integral  F. 0.666666  ok
\ use( FSQRT  0e  2e  1e-4 )integral  F. 1.88562  ok

\ : f1     FDUP FSQRT F*  ;  ok
\ use( f1  0e  1e  1e-3 )integral  F. 0.400001  ok
\ use( f1  0e  2e  1e-4 )integral  F. 2.26274  ok

\ Programmed by J.V. Noble (from "Scientific FORTH" by JVN)
\ ANS Standard Program  -- version of  10/5/1994
\ Revised 4/17/2005 by K. Myneni to use FSL array definitions and
\   vectoring; also modified for use with integrated stack Forths.
\
\ This is an ANS Forth program requiring:
\      The FLOAT and FLOAT EXT word sets
\ Environmental dependencies:
\      This version is for Forths which do not have a separate
\      floating point stack, e.g. kForth.
\ Non STANDARD words:
\      S>F  : S>F   S>D  D>F   ; ( n -- r) 
\      F=0  ( puts 0 on fpstack)
\ function vectoring
\ : USE(    '   ;
\
\     (c) Copyright 1994  Julian V. Noble.     Permission is granted
\     by the author to use this software for any application provided
\     the copyright notice is preserved.
\
\ Revisions:
\   2007-10-25  km; revised the test code; fixed problem in }DOWN (needed CELL-)
\   2007-10-27  km; save base, switch to decimal, and restore base.
\   2009-08-14  km; changed array dimension from 20 to 100, specified
\                   by the constant MAX_SUBDIV, instead of hardcoding it.
\
\  Requires the following under kForth:
\
\    ans-words.4th
\    fsl-util.4th

CR .( ADAPTINT          V1.2          14 August   2009  JVN )
BASE @ DECIMAL

[undefined] s>f [IF] : s>f s>d d>f ;  [THEN]

\ Data structures
0 S>F  FCONSTANT F=0
4 S>F  3 S>F  F/  FCONSTANT F=4/3

100 CONSTANT MAX_SUBDIV
MAX_SUBDIV  FLOAT  ARRAY x{
MAX_SUBDIV  FLOAT  ARRAY e{
MAX_SUBDIV  FLOAT  ARRAY f{
MAX_SUBDIV  FLOAT  ARRAY i{

0 VALUE  N

FVARIABLE  old.i
FVARIABLE  final.i

\ Begin definitions proper

: )int  ( n --)                           \ trapezoidal rule
\   F" ( F(N) + F(N-1) ) * ( X(N) - X(N-1) ) / 2  "
    >R
    x{ R@ } F@   x{ R@ 1- }  F@
    F-  f2/
    f{ R@ } F@   f{ R@ 1- }  F@
        F+  F*
    i{ R> 1- } F!  ;

Defer dummy                                  \ dummy function name

: initialize  ( xt xa xb eps -- integral )  
     1 TO N
     e{ 0 } F!   x{ 1 } F!   x{ 0 } F!
     IS dummy
     x{ 0 } F@   dummy   f{ 0 } F!        \ F" f(0) = dummy( x(0) ) "
     x{ 1 } F@   dummy   f{ 1 } F!        \ F" f(1) = dummy( x(1) ) "
     1 )int
     F=0  final.i  F! ;

: check.N       N  MAX_SUBDIV 1- >   ABORT" Too many subdivisions!"  ;
: e/2   e{ N  1- }  DUP   >R F@   F2/  R>  F! ;
: }down    ( adr n --)
        OVER cell- @  >R   }   DUP   R@ +   R>   MOVE  ;

: move.down    e{ N  1-       }down
               x{ N           }down
               f{ N           }down  ;

: x'   \  F" X(N) = ( X(N) + X(N-1) ) / 2 "
       \  F" F(N) = DUMMY(X(N)) "
       x{ N }  F@   x{ N 1- }  F@    F+  F2/
       FDUP  x{ N }  F!   dummy  f{ N }  F!   ;

: N+1   N 1+   TO N  ;
: N-2   N 2 -  TO N  ;

: subdivide    check.N     e/2   move.down
        i{ N 1- }  F@  old.i  F!
        x'   N )int   N 1+ )int    ;

: converged?   ( -- I[N]+I'[N-1]-I[N-1] flag )
\       F" I(N) + IP(N-1) - I(N-1) "
        i{ N } F@  i{ N 1- } F@   F+  old.i F@  F-
        FDUP   FABS
        e{ N 1- } F@   F2*  F<  ;

: interpolate  ( I[N]+I'[N-1]-I[N-1] -- )

\     F" FINAL.I = ( I(N)+I'(N-1) - OLD.I ) * (4/3) + OLD.I + FINAL.I "
      F=4/3   F*   old.i F@   F+
      final.i F@   F+                    \ accumulate
      final.i F!  ;                      \ store it


: )integral    ( A B ERR xt -- I[A,B] ) 
     initialize
     BEGIN   N 0>   WHILE
        subdivide
        converged?    N+1
        IF    interpolate  N-2
        ELSE  FDROP    THEN
     REPEAT   final.i  F@  ;


BASE !
 
TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester  [THEN]
BASE @ DECIMAL

1e-8 rel-near F!     \ higher accuracy may be specified, but integrator
1e-256 abs-near F!   \   becomes sluggish.
set-near

CR
TESTING )INTEGRAL
t{ use( FSQRT  0e  1e  rel-near F@ )integral  -> 2e 3e F/        r}t 
t{ use( FSQRT  0e  2e  rel-near F@ )integral  -> 32e 9e F/ FSQRT r}t

: f1     FDUP FSQRT F*  ;

t{ use( f1  0e  1e  rel-near F@ )integral  ->  2e 5e F/  r}t
t{ use( f1  0e  2e  rel-near F@ )integral  ->  128e 25e F/ FSQRT r}t

BASE !
[THEN]
