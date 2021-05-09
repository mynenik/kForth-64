\ sph_bes       Regular spherical Bessel functions jn(x), n=0-9
\
\ Forth Scientific Library Algorithm #43
\
\ Uses Miller's method of downward recursion, as described
\ in Abramowitz & Stegun, "Handbook of Mathematical Functions"
\ 10.5 ff. The recursion is
\
\     j(n-1) = (2n+1) j(n) / x  - j(n+1)
\
\ The downward recursion is started with j40 = 0, j39 = 1 . The
\ resulting functions are normalized using
\
\     Sum (n=0 to inf) { (2n+1) * jn(x)^2 } = 1 .
\
\ Usage:  3e SPHBES  leaves jn(3), n=0-9,
\         in the double-length (64-bit) array JBES{
\
\ Programmed by J.V. Noble
\ ANS Standard Program  -- version of  10/25/1994
\
\ This code conforms with ANS requiring:
\      The FLOAT and FLOAT EXT word sets
\ Environmental dependencies:
\ 
\       Required: 64-bit IEEE floating point internal storage format
\       If a similar precision but different internal format
\       is used, DF@ and DF! should be replaced by F@ and F!
\       to prevent loss of precision in conversion

\ Note: if 32-bit precision is desired, the sum and the functions
\ must be renormalized at  n = 30, n = 20 and n = 10.
\ Replace FLOAT by "1 SFLOATS", DF@ and DF! by SF@ and SF!


\ Non STANDARD words (see definitions below):
\
\      2-   S>F  F=0  F=1  1/F  F**2
\
\     (c) Copyright 1994  Julian V. Noble.     Permission is granted
\     by the author to use this software for any application provided
\     the copyright notice is preserved.
\
\ Revisions:
\    
\    2003-10-27  km; ported to kForth with revisions for
\                    integrated stack
\    2007-11-24  km; added automated test code and base handling;
\                    revised comments.

CR .( SPH-BES           V1.0b          25 November  2007   JVN )
BASE @ DECIMAL

[undefined] 2-    [IF] : 2-    1-  1-  ;    [THEN]
[undefined] s>f   [IF] : s>f   S>D  D>F   ; ( n -- r) [THEN]
[undefined] f=0   [IF] 0e  FCONSTANT  f=0  ( puts 0e on stack) [THEN] 
[undefined] f=1   [IF] 1e  FCONSTANT  F=1  ( puts 1e on stack) [THEN]
[undefined] 1/f   [IF] : 1/f  ( r -- 1/r ) 1e FSWAP F/ ; [THEN]
[undefined] f**2  [IF] : f**2  ( r -- r*r)  FDUP  F* ;   [THEN]

\ data structures

10 FLOAT ARRAY  JBES{     \ holds j0-j9

FVARIABLE  SUM                         \ temps to off-load from fp stack
FVARIABLE  X 

: SETUP    ( x -- 0e 1e 79)
     X DF!   79 S>F  SUM DF!
     F=0 F=1    79  ;

: NORMALIZE     SUM  DF@  FSQRT  1/F
      10 0   DO   FDUP   JBES{ I }  DUP >R  DF@  F*  R>  DF!   LOOP
      FDROP  ;

: DO_X=0    FDROP  F=1  JBES{ 0 } DF!
            10 1  DO    F=0   JBES{ I }   DF!    LOOP   ;

: ITERATE   ( jn+1 jn 2n+1 -- jn jn-1 2n-1)
      DUP >R  S>F   FOVER  F*    ( jn+1 jn jn*[2n+1] )
      X DF@  F/    FROT  F-      (  -- jn jn-1)
      FDUP  F**2                 (  -- jn jn-1 jn-1^2 )
      R> 2-  DUP  >R             (  -- jn jn-1 jn-1^2 2n-1 )
      S>F  F*
      SUM DF@   F+   SUM DF! R>  ;

: SPHBES  ( x -- )
      FDUP   F0=
      IF     DO_X=0   EXIT    THEN
      SETUP
      11 39 DO   ITERATE   -1 +LOOP
      0  9  DO   ITERATE -ROT
                 FDUP   JBES{ I }  DF!
		 ROT 
      -1 +LOOP
      DROP   FDROP  FDROP        \ clean up stacks
      NORMALIZE  ;

BASE !

TEST-CODE? [IF]     \ test code =============================================
[undefined] T{      [IF]  include ttester  [THEN]
BASE @ DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

(
Reference values for the spherical Bessel functions are
from:

http://people.scs.fsu.edu/~burkardt/math_src/test_values/test_values.html

See the files:

  bessel_j0_spherical_values.txt
  bessel_j1_spherical_values.txt
)

CR
TESTING SPHBES
t{ 0.1e sphbes  ->  }t
t{ jbes{ 0 } F@  ->  0.9983341664682815e   r}t
t{ jbes{ 1 } F@  ->  0.03330001190255757e  r}t

t{ 0.2e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.9933466539753061e   r}t
t{ jbes{ 1 } F@  ->  0.06640038067032223e  r}t

t{ 0.4e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.9735458557716262e  r}t
t{ jbes{ 1 } F@  ->  0.1312121544218529e  r}t

t{ 0.6e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.9410707889917256e  r}t
t{ jbes{ 1 } F@  ->  0.1928919568034122e  r}t

t{ 0.8e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.8966951136244035e  r}t
t{ jbes{ 1 } F@  ->  0.2499855053465475e  r}t

t{ 1.0e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.8414709848078965e  r}t
t{ jbes{ 1 } F@  ->  0.3011686789397568e  r}t

t{ 1.2e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.7766992383060220e  r}t
t{ jbes{ 1 } F@  ->  0.3452845698577903e  r}t

t{ 1.4e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.7038926642774716e  r}t
t{ jbes{ 1 } F@  ->  0.3813753724123076e  r}t

t{ 1.6e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.6247335019009407e  r}t
t{ jbes{ 1 } F@  ->  0.4087081401263934e  r}t

t{ 1.8e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.5410264615989973e  r}t
t{ jbes{ 1 } F@  ->  0.4267936423844913e  r}t

t{ 2.0e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.4546487134128408e  r}t
t{ jbes{ 1 } F@  ->  0.4353977749799916e  r}t

t{ 2.2e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.3674983653725410e  r}t
t{ jbes{ 1 } F@  ->  0.4345452193763121e  r}t

t{ 2.4e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.2814429918963129e  r}t
t{ jbes{ 1 } F@  ->  0.4245152947656493e  r}t
 
t{ 2.6e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.1982697583928709e  r}t
t{ jbes{ 1 } F@  ->  0.4058301968314685e  r}t

t{ 2.8e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.1196386250556803e  r}t
t{ jbes{ 1 } F@  ->  0.3792360591872637e  r}t

t{ 3.0e sphbes ->  }t
t{ jbes{ 0 } F@  ->  0.04704000268662241e  r}t
t{ jbes{ 1 } F@  ->  0.3456774997623560e   r}t

t{ 3.2e sphbes ->  }t
t{ jbes{ 0 } F@  ->  -0.01824191982111872e  r}t
t{ jbes{ 1 } F@  ->   0.3062665174917607e   r}t

t{ 3.4e sphbes ->  }t
t{ jbes{ 0 } F@  ->  -0.07515914765495039e  r}t
t{ jbes{ 1 } F@  ->   0.2622467779189737e   r}t

t{ 3.6e sphbes ->  }t
t{ jbes{ 0 } F@  ->  -0.1229223453596812e  r}t
t{ jbes{ 1 } F@  ->   0.2149544641595738e  r}t

t{ 3.8e sphbes ->  }t
t{ jbes{ 0 } F@  ->  -0.1610152344586103e  r}t
t{ jbes{ 1 } F@  ->   0.1657769677515280e  r}t

t{ 4.0e sphbes ->  }t
t{ jbes{ 0 } F@  ->  -0.1892006238269821e  r}t
t{ jbes{ 1 } F@  ->   0.1161107492591575e  r}t

BASE !
[THEN]
