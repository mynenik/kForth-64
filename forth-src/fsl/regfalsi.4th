\ Regula Falsi -- ANS compatible version V1.1  12/14/2005
\ Finds roots of real transcendental functions by hybrid
\       secant/binary search method

\ Forth Scientific Library Algorithm #7

\ Usage example:
\       : F1    ( x -- [x-e**-x])   FDUP  FNEGATE  FEXP  F-  ;
\       use( F1  0e 1e 1.E-6 )falsi  5.671432E-1  ok
\
\ or, if it is desired to return the root, instead of automatically
\ printing it,
\
\       use( F1  0e 1e 1.E-6 )root  
\
\ Environmental dependencies:
\       Integrated data/fp stack
\       ANS FLOAT and FLOAT EXT wordsets
\       Non-standard words in fsl-util.x:
\         F2/  -FROT  USE(  PUBLIC: PRIVATE:  RESET-SEARCH-ORDER
\       Common usage words [UNDEFINED]  DEFER  IS

\     (c) Copyright 1994  Julian V. Noble.  Permission is granted
\     by the author to use this software for any application provided
\     the copyright notice is preserved.

\ Revisions:
\   2003-10-14  km; Adapted for kForth (integrated data/fp stack)
\   2005-12-14  km; changed all instances of SF@ and SF! 
\                   to F@ and F!, and use common words DEFER and
\                   IS for vectoring.
\   2007-10-10  km; added automated test code.
\   2007-10-27  km; save base, switch to decimal, and restore base
\   2007-10-31  km; changed fvariable names of A and B to YA and YB
\                   to avoid masking the flocals implementation in
\                   fsl-util.
\   2010-12-29  km; make Private internal data and helper words,
\                   move )ROOT from test code to main code, and
\                   revise Usage instructions.
\   2010-12-31  km; modifications to avoid infinite loop in
\                   convergence test when EPSILON is too small                   
\   2011-09-16  km; use Neal Bridges' anonymous modules.
\   2012-02-19  km; use KM/DNW's modules library
\   2021-05-10  km; fix path to sph_bes.4th in test code.
CR .( REGFALSI          V1.1g          10 May       2021  JVN )
BEGIN-MODULE

BASE @ DECIMAL

Public:

[UNDEFINED] f0>   [IF]  : f0>  0e F> ;      [THEN]

\ tested in F-PC  10/6/1994

\ Data structures

Private:

FVARIABLE YA                      \ f(xa)
FVARIABLE YB                      \ f(xb)
FVARIABLE XA                      \ lower end of interval
FVARIABLE XB                      \ upper end of interval
FVARIABLE XA_LAST
FVARIABLE XB_LAST
FVARIABLE EPSILON                 \ precision

DEFER DUMMY                       \ vectored function name

\ End data structures

: SAVE-LAST ( -- ) XA F@ XA_LAST F!  XB F@ XB_LAST F! ;

: X'    ( -- x')               \ secant extrapolation
\         F" XA + (XA - XB) * A / (B - A) "    ;
          XA F@  FDUP   XB F@  F-       ( xa xa-xb )
          YA F@  YB F@  FOVER  F-  F/  F*  F+   ;

: <X'>  ( -- <x'>)             \ binary search extrapolation
\         F" (XA + XB) / 2 "  ;
          XA F@  XB F@  F+  F2/  ;

: SAME-SIGN?   ( x y -- flag)    F*   F0>  ;

: !END    ( x --)    FDUP  DUMMY   FDUP  ( -- x f[x] f[x] )
          YA F@  SAME-SIGN?
          IF   YA F!  XA F!   ELSE   YB F!  XB F!   THEN  ;

: SHRINK ( -- )
       SAVE-LAST  X'  !END   <X'>  !END  ;     \ combine extrapolations

: INITIALIZE    ( xt lower upper precision --)
        EPSILON F!    XB F!    XA F!       \ store parameters
        IS DUMMY                           \ xt -> DUMMY
        SAVE-LAST
        XA F@  DUMMY  YA F!                \ compute fn at endpts
        XB F@  DUMMY  YB F!
        YA F@  YB F@
        SAME-SIGN?  ABORT" EVEN # OF ROOTS IN INTERVAL!"  ;

: CONVERGED?    ( -- f)
\       F" ABS( XA - XB ) < EPSILON "   ;
        XA F@ XA_LAST F@ F=  XB F@ XB_LAST F@ F= AND 
        XA F@   XB F@  F-  FABS EPSILON F@  F<  OR  ;

Public:

: )root  ( xt -- ) ( F: upper lower precision -- root )
    initialize BEGIN shrink converged? UNTIL <x'> ;

: )FALSI        ( xt lower upper precision --)
     )root ( FS.) F.  ;

BASE !
END-MODULE
    
TEST-CODE? [IF]   \ test code ===================================
[undefined] T{  [IF]  s" ttester.4th" included  [THEN]
BASE @ DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

: f1  ( x -- [x-e**-x])   FDUP  FNEGATE  FEXP  F-  ;

CR
TESTING )ROOT
t{ use( FSIN 3e 3.2e abs-near F@ )root  FSIN -> 0e  r}t
t{ use( FSIN 3e 3.2e abs-near F@ )root       -> PI  r}t
t{ use( f1   0e 1e   abs-near F@ )root  f1   -> 0e  r}t
t{ use( f1   0e 1e   abs-near F@ )root  -> 5.671432904097833E-1 r}t

[undefined] sphbes [IF] s" fsl/sph_bes.4th" included [THEN]
\ First few roots of spherical Bessel functions, j0 through j2
: j0  ( x -- j0[x] )  sphbes jbes{ 0 } f@ ;
: j1  ( x -- j1[x] )  sphbes jbes{ 1 } f@ ;
: j2  ( x -- j2[x] )  sphbes jbes{ 2 } f@ ;

t{ use( j0 3e 4e abs-near f@ )root  -> PI  r}t
t{ use( j0 6e 7e abs-near f@ )root  -> 2e PI f* r}t
t{ use( j1 4e 5e abs-near f@ )root  -> 4.493409457909064e0 r}t
t{ use( j1 7e 8e abs-near f@ )root  -> 7.725251836937708e0 r}t
t{ use( j2 5e 6e abs-near f@ )root  -> 5.763459196894550e0 r}t
t{ use( j2 9e 10e abs-near f@ )root -> 9.095011330476355e0 r}t

BASE !
[THEN]
