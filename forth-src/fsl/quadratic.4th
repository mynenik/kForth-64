\ quadratic.fs

\ Forth Scientific Library Algorithm #63

\ Solve for the two complex solutions of the quadratic equation:
\
\   a*x^2 + b*x + c = 0
\
\ for real coefficients a, b, and c. The two complex roots are 
\ z1 = x1r + i*x1i and z2 = x2r + i*x2i
\
\ File dependencies:
\   fsl-util.x              for Public: / Private: visibility control
\   ttester-xf.x/ttester.x  (needed only for automated tests)
\
\ Environmental dependencies:
\   1. requires FLOATING and FLOATING EXT wordsets
\   2. requires the following words from the FSL complex arithmetic 
\      module (FSL #60):
\
\        zdup  conjg  z+  z*  z*f  |z| 
\
\   3. supports unified or separate floating point stack
\   4. uses [UNDEFINED] from Forth 200x
\
\ Provides:
\   q_discriminant
\   solve_quadratic
\   zq_residual
\   q_root_error
\
\  Copyright 2002--2011, K. Myneni, krishna.myneni@ccreweb.org
\  Permission is granted to modify and use this code
\  for any application, provided this notice is preserved.
\
\ Notes:
\
\   1. Ensure that argument "a" is not zero, or an infinity will result;
\      the correct solution of the simple linear equation will not be
\      given.
\  
\   2. The complex number roots, returned by solve_quadratic, are 
\      ordered as follows: 
\   
\         a) For real roots, r1 and r2, with r1 < r2, the return
\            order is ( F: -- z2 z1 ), where z1 = r1 +i0, z2 = r2 + i0
\
\         b) For complex conjugate roots, z1 = e - i*f, z2 = e + i*f,
\            (f > 0), the ordering on the stack is ( F: -- z2 z1 ).
\
\  3. The error in a computed root may be determined using Q_ROOT_ERROR.
\
\ Revisions:
\
\   2002-11-02  km; first version.
\   2003-10-25  Christopher Brannon; fixed problem with calculation
\                 of complex roots.
\   2007-11-04  km; revised comments; added test code; save and restore base. 
\   2009-08-05  km; revised to preserve accuracy when the product a*c is
\                   much less than b^2; see [1]. Added new test case.
\   2009-08-11  km; added test case for purely imaginary roots.
\   2009-08-18  km; factored the code with modification of example posted
\                   to comp.lang.forth by "humptydumpty", and used words from
\                   the jvn-dnw complex library; revised comments; V1.2
\   2009-08-19  km; additional comments, change "zconj" to "conjg"; V1.2b
\   2009-08-26  km; revised q_discriminant and added (q_discriminant). Also
\                   added q_check to test for b=0 AND c=0 case, and a test
\                   for this case.
\   2009-09-07  km; added zq_residual and q_root_error, based on formula
\                   derived by "humptydumpty" relating the magnitude of
\                   the residual to the magnitude of the error in the root
\   2009-09-14  km; fixed a problem, pointed out by Michael L. Gassanenko, with
\                   use of q_root_error for the b=0, c=0 case; also fixed
\                   q_root_error to avoid 0/0; V1.2d
\   2011-01-24  km; use Private: and Public: to control data/code visibility;
\                   revised comments; ver 1.3.
\   2011-01-27  km; revised comments; allow use of either ttester or 
\                   ttester-xf for test code; ver 1.3b
\   2011-09-16  km; use Neal Bridges' anonymous modules.
\   2012-02-19  km; use KM/DNW's modules library.
\ References:
\
\ 1. W.H. Press, et. al., Numerical Recipes in C, 2nd ed., pp. 183--184,
\    eqns. 5.6.4 and 5.6.5.

CR .( QUADRATIC         V1.3c         19 February  2012   KM, HD)
BEGIN-MODULE

BASE @ DECIMAL

Public:

[UNDEFINED] fsquare [IF] : fsquare fdup f* ;      [THEN]
[UNDEFINED] f2dup   [IF] : f2dup   fover fover ;  [THEN]
[UNDEFINED] ftuck   [IF] : ftuck   fswap fover ;  [THEN]

: q_discriminant ( F: a b c -- d )
     frot f* -4e f* fswap fsquare f+ ;

Private:

\ For thread-safety, make the following variables per thread 
\ variables if using this code in a multi-threaded Forth 
\ environment.
fvariable qa
fvariable 2qa
fvariable qb
fvariable qc

: (q_discriminant) ( F: -- d )
    qb f@ fsquare 4e qa f@ f* qc f@ f* f- ;  
    
: q_real_roots ( F: d -- r1 r2 )
    fsqrt qb f@ fdup f0< IF f- ELSE f+ fnegate THEN 2e f/ 
    qc f@ fover f/ fswap qa f@ f/ ;

: q_complex_roots ( F: d -- z1 z2 )
    fabs  fsqrt   2qa f@  f/           \ imaginary part 
    qb f@ fnegate 2qa f@  f/           \ real part
    fswap zdup conjg                   \ complex conjugate
;

: q_check ( -- flag )
    qb f@ f0= >r qc f@ f0= r> and ;

Public:

: solve_quadratic ( F: a b c -- z1 z2 ) 
    qc f! qb f! fdup qa f! 2e f* 2qa f!
    q_check IF 0e 0e zdup EXIT THEN 
    (q_discriminant)
    fdup f0<  IF                       \ complex conjugate roots
       q_complex_roots 
    ELSE                               \ two real roots
       q_real_roots                    \ F: -- r1 r2
       0e ftuck                        \ promote to z1 z2
    THEN
;

\ Return the complex residual for the given root
: zq_residual ( F: zroot -- zres )
    zdup qa f@ z*f qb f@ 0e z+ z* qc f@ 0e z+ ;

\ Return the error in the magnitude of the root, given the root
: q_root_error ( F: zroot -- rerror )
    zq_residual |z| fdup f0= invert
    IF (q_discriminant) fabs fsqrt f/ THEN ;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
\ Set the flag below to 1 to use ttester-xf, 0 for ttester
0 constant USE_TTESTER-XF

[UNDEFINED] T{  [IF] 
USE_TTESTER-XF [IF] s" ttester-xf" [ELSE] s" ttester"  [THEN]
included
[THEN]
BASE @ DECIMAL

USE_TTESTER-XF [IF]  \  setup for ttester-xf 

1e-256 FT-ABS-ERROR F!
1e-15  FT-REL-ERROR F!
set-ft-mode-rel0
: ?}t  }t ;
[ELSE]               \  setup for ttester

1e-256 abs-near f!
1e-15  rel-near f!   
set-near
: ?}t  rrrr}t ;
[THEN]

\ Uncomment next line to see message when testing, or only errors are shown.
\ true VERBOSE !


\ Examples from:
\
\    http://www.purplemath.com/modules/quadform.htm

-2e 3e F/       fconstant -2/3
-3e 2e F/       fconstant -3/2
 5e fsqrt       fconstant sqrt{5}
 2e fsqrt 3e F/ fconstant sqrt{2}/3
 3e fsqrt 2e F/ fconstant sqrt{3}/2
10e fsqrt 2e F/ fconstant sqrt{10}/2


CR
TESTING solve_quadratic
t{ 1e  0e  0e solve_quadratic ->  0e               0e    0e               0e   ?}t
t{ 1e  3e -4e solve_quadratic ->  1e               0e   -4e               0e   ?}t
t{ 2e -4e -3e solve_quadratic ->  1e sqrt{10}/2 F- 0e    1e sqrt{10}/2 F+ 0e   ?}t
t{ 1e -2e -4e solve_quadratic ->  1e sqrt{5} F-    0e    1e sqrt{5} F+    0e   ?}t
t{ 9e 12e  4e solve_quadratic ->  -2/3             0e   -2/3              0e   ?}t
t{ 3e  4e  2e solve_quadratic ->  -2/3      sqrt{2}/3   -2/3 sqrt{2}/3 fnegate ?}t
t{ 1e  3e  3e solve_quadratic ->  -3/2      sqrt{3}/2   -3/2 sqrt{3}/2 fnegate ?}t
t{ 1e  0e  1e solve_quadratic ->  0e               1e    0e              -1e   ?}t

\ Test case which loses accuracy with ordinary quadratic formula:
\ 
\        x^2 + x + c = 0
\
\ when c << 1, the approximate solution is  x1 = -c,  x2 = -1 + c
\
t{ 1e 1e 1e-17 solve_quadratic -> -1e-17           0e    -1e 1e-17 f+     0e   ?}t


BASE !
[THEN]

