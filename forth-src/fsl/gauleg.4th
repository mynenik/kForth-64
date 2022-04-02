\ gauleg     Gauss-Legendre Integration (reentrant version)

\ Forth Scientific Library Algorithm #27

\ Given lower and upper limits of integration X1 and X2
\ the routine gauleg returns the abscissas and weights of the Gauss-Legendre
\ N-point quadrature formula.

\ The integral of f(x) is then calculated numerically as:
\ z = \int_x1^x2 f(x) dx = \sum_i=0^n-1 w[i] f( x[i] )
\ the routine )gl-integrate is provided to do this calculation using the
\ previously calculated values of x and w.


\ This is an ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. The FCONSTANT PI (3.1415926536...)
\      3. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      4. Uses the words 'FLOAT' and 'ARRAY' to create floating point arrays.
\      5. The word '}' to dereference a one-dimensional array.
\      6. Uses the words 'DARRAY' and '&!' to set array pointers.
\      7. The test code uses '}malloc' and '}free' to allocate and release
\         memory for dynamic arrays ( 'DARRAY' ) (from the file DYNMEM).
\      8. The compilation of the test code is controlled by the VALUE
\         TEST-CODE? and the conditional compilation words in the
\         Programming-Tools wordset

\      requirements 2 through 6 are provided in the file FSL-UTIL


\ This program implements the function GAULEG as described in 
\ Press, W.H., B.P. Flannery, S.A. Teukolsky, and W.T. Vetterling, 1986;
\ Numerical Recipes, The Art of Scientific Computing, Cambridge University
\ Press, 818 pages,   ISBN 0-521-30811-9

\ Revisions:
\    2004-08-06  km; adapted for kForth
\    2007-09-22  km; revised EPS to 3e-11, in accordance with NR in C, 2nd ed.
\    2007-10-27  km; save base, switch to decimal, and restore base
\    2011-09-16  km; use Neal Bridges' anonymous modules
\    2012-02-19  km; use KM/DNW's modules library
\    2022-03-25  km; make )GL-INTEGRATE re-entrant
\    2022-04-02  km; make re-entrant for unified fp stack as well
\
\  (c) Copyright 1995 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.


CR .( GAULEG            V1.1f          02 April     2022   EFC,KM )

BEGIN-MODULE

BASE @ DECIMAL

Private:

3.0E-11 FCONSTANT eps

FVARIABLE xm       \ scratch variables
FVARIABLE xl
FVARIABLE z
FVARIABLE p1
FVARIABLE pp

FLOAT DARRAY x{    \ aliases to user arrays
FLOAT DARRAY w{

: calc-pp ( n -- n f )           \ NOTE: changes Z


       BEGIN
         1.0E0 p1 F!    0.0E0 pp F!

         DUP 1+ 1 DO
                     pp F@
                     p1 F@    FDUP pp F!

                     I 2* 1- S>F F*
                     z F@ F*

                     FSWAP I 1- NEGATE S>F F* F+
                     I S>F F/

                     p1 F!

         LOOP         

         >R z F@ p1 F@ F* pp F@ F- R@ S>F F*
         z F@ FDUP F* 1.0E0 F- F/       pp F!
	 R>

         p1 F@ pp F@ F/ FNEGATE

         z F@ FDUP FROT F+ FDUP z F!
         

         F- FABS eps F<
       UNTIL

       pp F@ FDUP F*
;

Public:

VARIABLE gleg-n

: gauleg ( &x &w n x1 x2 -- ) 
        
         FOVER FOVER F+ 0.5E0 F* xm F!
         FSWAP F- 0.5E0 F* xl F!
 
        \ validate the parameter N
         DUP 1 < ABORT" bad value of N (must be > 0) for gauleg "
 

         SWAP & w{ &!     SWAP & x{ &!

         DUP gleg-n ! 
	 1+ 2/  0 DO
              PI gleg-n @ S>F 0.5E0 F+ F/
              I S>F 0.75E0 F+ F*     FCOS z F!
	      gleg-n @
              calc-pp ROT DROP
              z F@ FDUP F* FNEGATE 1.0E0 F+ F*
              2.0E0 xl F@ F* FSWAP F/
              FDUP  w{ I } F!     
	      w{ gleg-n @ 1- I - } F!
              xl F@ z F@ F* FDUP FNEGATE xm F@ F+   x{ I } F!
              xm F@ F+     x{ gleg-n @ 1- I - } F!


           LOOP

         \ DROP
;

\ do the integration
fp-stack? [IF]
: )gl-integrate ( xtfunc &x &w n -- ) ( F: -- r )
         \ validate the parameter N
         DUP 1 < ABORT" bad value of N (must be > 0) for )gl-integrate "
         0.0E0
         0 DO   \ xtfunc &x &w ; F: rsum
            over I } F@ 2 pick execute
            dup  I } F@ F*
            F+             \ xtfunc &x &w ;  F: rsum2
         LOOP
         2drop drop ;
[ELSE]
: )gl-integrate ( xtfunc &x &w n -- r )
        \ validate the parameter N
         DUP 1 < ABORT" bad value of N (must be > 0) for )gl-integrate "
         >R 0.0E0   \ xtfunc &x &w rsum
         R> 0 DO
               3 pick I } f@  \ xtfunc &x &w rsum rx
               6 pick execute \ xtfunc &x &w rsum rf
               4 pick I } f@  f*
               F+
         LOOP
         2>r 2drop drop 2r> ;
[THEN]

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]    
[undefined] CompareArrays [IF] include fsl-test-utils.4th [THEN]
BASE @ DECIMAL

3.0e-11 rel-near F!
3.0e-11 abs-near F!
set-near

FLOAT DARRAY x{
FLOAT DARRAY wgt{

: func ( x -- f[x] )          \ function to integrate

        FDUP 0.2E0 F+ F*
;

: ifunc ( x -- I[x] )         \ its (indefinite) integral

       FDUP  3.0E0 F/ 0.10E0 F+
       FOVER F* F*
;

8 FLOAT ARRAY x8{
    -0.960289856498e   -0.796666477414e   -0.525532409916e   -0.183434642496e 
     0.183434642496e    0.525532409916e    0.796666477414e    0.960289856498e
8 x8{ }fput

8 FLOAT ARRAY w8{
     0.10122853629e   0.222381034453e   0.313706645878e   0.362683783378e
     0.362683783378e  0.313706645878e   0.222381034453e   0.10122853629e
8 w8{ }fput

CR
TESTING GAULEG GL-INTEGRATE
8 value N
t{ & x{ N }malloc    ->  }t
t{ & wgt{ N }malloc  ->  }t
t{ x{ wgt{ N -1.0E0  1.0E0 gauleg  ->  }t
8 CompareArrays  x{    x8{
8 CompareArrays  wgt{  w8{

t{ use( func x{ wgt{ N )gl-integrate  ->  1e ifunc -1e ifunc F- r}t
t{ & x{ }free  ->  }t
t{ & wgt{ }free -> }t

BASE !
[THEN]
