\ Solution of cubic equation with real coefficients
\ ANS compatible version of 10/6/1994

\ Forth Scientific Library Algorithm #6


\ Environmental dependencies:
\       This version is for systems with an integrated fp/data stack
\       FLOAT, FLOAT EXT wordsets
\       Complex library of JVN/DNW
\       double precision floats (64 bits for output tests)

\ Additional words (if not present):
\
\       : S>F     S>D  D>F  ;
\       : FTUCK  ( F: x y -- y x y)     FSWAP FOVER ;
\       : F0>  0.0e FSWAP F< ;
\       3.1415926536e FCONSTANT PI

\ Source of algorithms:
\ Complex roots: Abramowitz & Stegun, p. 17 3.8.2
\ Real roots:    Press, et al., "Numerical Recipes" (1st ed.) p. 146
\
\       0 = x^3 + ax^2 + bx + c
\       q = b / 3 - a^2 / 9
\       r = ( b a/3 - c) / 2 - ( a / 3 )^3
\
\       D = q^3 + r^2
\
\       If D > 0, 1 real and a pair of cc roots;
\          D = 0, all roots real, at least 2 equal;
\          D < 0, all roots real
\
\ Case I: D > 0
\
\       s1 = [ r + sqrt(D) ]^1/3
\       s2 = [ r - sqrt(D) ]^1/3
\
\       x1 = s1 + s2 - a / 3
\       Re(x2) = - (s1 + s2) / 2  - a / 3
\       Im(x2) = sqrt(3) * (s1 - s2) / 2
\
\       x3 = conjg(x2)
\
\ Case II: D < 0
\
\       K = -2 * sqrt(-q)
\       phi = acos( -r / sqrt(-q^3) )
\
\       x1 = K * cos(phi / 3) - a / 3
\       x2 = K * cos( (phi + 2*pi) / 3) - a / 3
\       x3 = K * cos( (phi + 4*pi) / 3) - a / 3
\
\     (c) Copyright 1994  Julian V. Noble.     Permission is granted
\     by the author to use this software for any application provided
\     the copyright notice is preserved.
\
\ Revisions:
\
\   2005-08-26  km; extensive rewrite: removed use of %; replaced fconstant
\                   F=3 with "3e"; renamed INITIALIZE to more descriptive word
\                   DISCRIMINANT; modified 1real and 3real to store roots instead of
\                   generating output; rename .ROOT to "root"; added word
\                   CUBIC-ROOTS which finds solutions without producing output.
\   2005-09-02  km; fixed problem with word "cubic-roots"
\   2007-11-25  km; added automated test code and BASE handling; changed
\                   variable names A, B, and C to aa, bb, and cc to avoid
\                   masking of FLOCALS

CR .( CUBIC             V1.1d         25 November  2007  JVN )
BASE @ DECIMAL

[undefined]  f0>  [IF] : f0>     0e FSWAP F< ;  [THEN]
[undefined]  f**2 [IF] : f**2    FDUP  F* ;     [THEN]
[undefined]  f**3 [IF] : f**3    FDUP  FDUP  F* F*  ;  [THEN]

\ Cube root by Newton's method

: X'    ( N x -- x')
        ftuck   f**2  F/  FSWAP  F2*  F+  3e  F/  ;           \ X' = (N/X^2 + 2*X)/3

: fcbrt  ( N -- N^1/3)   
        FDUP  F0<  >R  FABS
        FDUP  FSQRT		         (  -- N x)
        BEGIN   ZDUP     X'              (  -- N x x')
          ftuck    F-  FOVER   F/  FABS
          1.E-8  F<  
	UNTIL
        X'  R> IF  FNEGATE  THEN  ;

\ Solve cubic

FVARIABLE aa    FVARIABLE bb   FVARIABLE cc     \ coeffs
FVARIABLE Q     FVARIABLE R                     \ derived stuff
FVARIABLE S1    FVARIABLE S2

ZVARIABLE Z1
ZVARIABLE Z2
ZVARIABLE Z3

: discriminant    ( a b c -- D )
        cc F!   bb F!   3e F/  aa F!
        bb F@  3e F/  aa F@ f**2 F-  Q F!                       \  Q = B/3 - A^2
        aa F@  bb F@  F*   cc F@ F-  F2/  aa F@ f**3  F-  R F!  \  R = (A*B - C)/2 - A^3
        Q F@  f**3   R F@ f**2  F+    ;                       \  d = Q^3 + R^2


: 1real     ( D -- | roots stored in z1, z2, z3 )  
        FSQRT   R F@  FOVER  F+  fcbrt S1 F!    ( sqrt[D] )  \  S1 = (R + sqrt(D))^1/3
        FNEGATE  R F@  F+        fcbrt S2 F!    (  -- )      \  S2 = (R - sqrt(D))^1/3
        S1 F@ S2 F@  F+  FDUP   aa F@  F-       ( s1+s2 x1)  \  x1 = S1 + S2 - A/3 + i*0
        0e z1 z!                                \ real root
        FNEGATE  F2/  aa F@ F-   FDUP           ( Re[x2]  Re[x2] )  
	\  x2 = -(S1 + S2)/2 - A/3 + i*SQRT(3)*(S1 - S2)/2
        S1 F@  S2 F@  F-  F2/  3e  FSQRT  F*   ftuck   ( Re[x2] Im[x2] Re[x2] Im[x2] )
        z2 z!                                    ( Re[x2] Im[x2] )
        FNEGATE z3 z! ;                          \  x3 = conjg(x2)


: root     ( K angle -- K x )
        3e F/  FCOS   FOVER  F*  aa F@  F-  ;

: 3real   ( -- | roots stored in z1, z2, z3 ) 
        Q F@  FABS  FSQRT                   ( K )            \  K=SQRT(ABS(Q))
        R F@  FNEGATE                       ( K  -r )        
        FOVER   f**3  F/   FACOS            ( K phi )        \  phi = ACOS(-R/K^3)
        FSWAP   F2*   FNEGATE               ( -- phi K )     \  K = -2*K
        FOVER                      root 0e z1 z!             \  x1
        FOVER   PI  F2*       F+   root 0e z2 z!             \  x2
        FSWAP   PI  F2* F2*   F+   root 0e z3 z!             \  x3
        FDROP   ;


: +?    FDUP F0> IF ." + "  ELSE  ." - "  FABS  THEN  ;

: .equ'n   CR  ." x^3 "
        aa F@  3e F*   +?  ( E.) F.  ."  x^2 "
        bb F@  +?  ( E.) F.  ." x "  cc F@  +?  ( E.) F.  ."  = 0"  ;

: >roots     ( a b c -- | roots are computed and displayed; roots also stored in z1,z2,z3 )
        discriminant                          ( -- D )
        CR  .equ'n
        FDUP  f0>                           \ test discriminant
        IF      CR  ." 1 real, 2 complex conjugate roots" 
	        1real
		CR z1 z@ FDROP F.
		CR z2 z@       z.
		CR z3 z@       z.
        ELSE    FDROP   
                CR  ." 3 real roots"  
		3real
		CR z1 z@ FDROP F.
		CR z2 z@ FDROP F.
		CR z3 z@ FDROP F. 
        THEN  CR  ;

: cubic-roots    ( a b c -- flag | flag=TRUE if all roots real; roots stored in z1,z2,z3 )
    discriminant FDUP F0> IF
	1real  FALSE
    ELSE
	FDROP 3real  TRUE 
    THEN ;

: RESIDUAL   ( z -- | z = x + iy )   
        S2 F!  S1 F!
        S1 F@ f**2   S2 F@ f**2  3e F*   F-  bb F@  F+     \  x*(x^2 - 3*y^2) + A*(x^2 - y^2) + x*B + C
        S1 F@ F*
        aa F@ 3e F*
        S1 F@ f**2   S2 F@ f**2 F-   F*  F+
        cc F@  F+ 
        3e  S1 F@  f**2 F*   S2 F@  f**2   F-             \  y*(3*x^2 - y^2 + 2*x*A + B)
        S1 F@ F2*   aa F@  F*  3e F*   F+
        bb  F@ F+    S2 F@ F*    CR z.  ;
\ Use to test quality of solution

BASE !
			 
TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester  [THEN]    
BASE @ DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

: zzz}t  6 0 DO ftester LOOP ...}t ;

CR
TESTING CUBIC-ROOTS

\ x^3 - 2 x^2 + 1 x - 2 = 0
\ 1 real, 2 complex conjugate roots: 2, i, -i
t{ -2e 1e -2e cubic-roots  ->  false }t
t{ z1 z@  z2 z@  z3 z@  ->  2e 0e  0e 1e  0e -1e  zzz}t

\ x^3 - 2 x^2 - 1 x + 2 = 0
\ 3 real roots:  -1, 2, 1 
t{ -2e -1e 2e cubic-roots  ->  true }t
t{ z1 z@  z2 z@  z3 z@  ->  -1e 0e  2e 0e  1e 0e  zzz}t

\ x^3 - 4 x^2 - 1 x + 22 = 0
\ 1 real, 2 complex conjugate roots: -2, 3  + i*sqrt{2}, 3  - i*sqrt{2}
t{ -4e -1e 22e cubic-roots  ->  false }t
t{ z1 z@  z2 z@  z3 z@  ->  -2e 0e  3e 2e fsqrt  zdup conjg  zzz}t    

\ % -2 % 0 RESIDUAL
\ -2.384186e-6 + i 0.0 ok
\ % 3 % 2 FSQRT RESIDUAL
\ -14.458536e-7 + i -4.286459e-6 ok
\ % 3 % 2 FSQRT FNEGATE RESIDUAL
\ -3.131728e-6 + i 4.763296e-6 ok

BASE !
[THEN]
