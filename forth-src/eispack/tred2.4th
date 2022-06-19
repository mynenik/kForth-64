\ tred2.4th
\
\      tred2 ( nm n a d e z -- )
\
\      integer i,j,k,l,n,ii,nm,jp1
\      double precision a(nm,n),d(n),e(n),z(nm,n)
\      double precision f,g,h,hh,scale
\
\     this subroutine is a translation of the Fortran subroutine,
\     tred2, which is a translation of the algol procedure tred2,
\     num. math. 11, 181-195(1968) by martin, reinsch, and wilkinson.
\     handbook for auto. comp., vol.ii-linear algebra, 212-226(1971).
\
\     this subroutine reduces a real symmetric matrix to a
\     symmetric tridiagonal matrix using and accumulating
\     orthogonal similarity transformations.
\
\     on input
\
\        nm must be set to the row dimension of two-dimensional
\          array parameters as declared in the calling program
\          dimension statement.
\
\       n is the order of the matrix.
\
\        a contains the real symmetric input matrix.  only the
\          lower triangle of the matrix need be supplied.
\
\     on output
\
\        d contains the diagonal elements of the tridiagonal matrix.
\
\        e contains the subdiagonal elements of the tridiagonal
\          matrix in its last n-1 positions.  e(1) is set to zero.
\
\        z contains the orthogonal transformation matrix
\          produced in the reduction.
\
\        a and z may coincide.  if distinct, a is unaltered.
\
\     questions and comments on the Fotran procedure should be
\     directed to burton s. garbow, mathematics and computer
\     science div, argonne national laboratory
\
\     Fortran version dated august 1983.
\     Forth version dated june 14, 2022.
\     Translated to Forth by Krishna Myneni.
\
\     ------------------------------------------------------------------

BEGIN-MODULE

BASE @ DECIMAL

[UNDEFINED] F+! [IF]
fp-stack? [IF]
: f+! ( a -- ) ( F: r -- ) dup f@ f+ f! ;
[ELSE]
: f+! ( r a -- ) dup >r f@ f+ r> f! ;
[THEN]
[THEN]

[UNDEFINED] FSQUARE [IF] : fsquare fdup f* ; [THEN]

\ Obsolete Fortran function dsign()
: dsign ( F: r1 r2 )
    fswap fabs fswap f0< IF fnegate THEN ;

0 value ii
0 value kk
0 value ll
0 value ll1
0 value N
0 ptr a{{
0 ptr z{{
0 ptr d{
0 ptr e{
fvariable f
fvariable g
fvariable h
fvariable hh
fvariable scale

: l.510 ( -- )
    N 0 DO
      z{{ N 1- I }} f@ d{ I } f!
      0.0e0 z{{ N 1- I }} f!
    LOOP

    1.0e0 z{{ N 1- dup }} f!
    0.0e0 e{ 0 } f!
;

Public:

: tred2 ( nm n a d e z -- )
      to z{{  to e{  to d{  to a{{  to N  drop

      N 0 DO
        N I DO
          a{{ I J }} f@  z{{ I J }} f!
        LOOP
        a{{ N 1- I }} f@ d{ I } f!
      LOOP

      N 1 = IF l.510 EXIT THEN

\ for i=n step -1 until 2 do --
      N 1 DO
         N I - to ii
         ii 1- to ll
         ll 1+ to ll1
         0.0e0 h f!
         0.0e0 scale f!

         ll 1 < IF
           d{ ll } f@ e{ ii } f!

           ll1 0 DO
             z{{ ll I }} f@ d{ I } f!
             0.0e0 z{{ ii I }} f!
             0.0e0 z{{ I ii }} f!
           LOOP
         ELSE
\ scale row (algol tol then not needed)
           ll1 0 DO
             d{ I } f@ fabs scale f+!
           LOOP

           scale f@ f0= IF
             d{ ll } f@ e{ ii } f!
             ll1 0 DO
               z{{ ll I }} f@ d{ I } f!
               0.0e0 z{{ J I }} f!
               0.0e0 z{{ I J }} f!
             LOOP
           ELSE
             ll1 0 DO
               d{ I } f@ scale f@ f/ d{ I } f!
               d{ I } f@ fsquare h f+!
             LOOP

             d{ ll } f@ f f!
             h f@ fsqrt f f@ dsign fnegate g f!  
             g f@ scale f@ f* e{ ii } f!
             f f@ g f@ f* fnegate h f+!
             f f@ g f@ f- d{ ll } f!
\ form a*u
             ll1 0 DO
               0.0e0 e{ I } f!
             LOOP

             ll1 0 DO
               d{ I } f@ f f!
               f f@ z{{ I ii }} f!
               z{{ I dup }} f@ f f@ f* e{ I } f@ f+ g f!
               ll I 1+ >= IF
                 ll1 I 1+ DO
                   z{{ I J }} f@ d{ I } f@ f* g f+!
                   z{{ I J }} f@ f f@ f* e{ I } f+!
                 LOOP
               THEN
               g f@ e{ I } f!
             LOOP
\ form p
             0.0e0 f f!

             ll1 0 DO
               e{ I } f@ h f@ f/ e{ I } f!
               e{ I } f@ d{ I } f@ f* f f+!
             LOOP

             f f@ h f@ fdup f+ f/ hh f!
\ form q
             ll1 0 DO
                hh f@ d{ I } f@ f* fnegate e{ I } f+! 
             LOOP
\ form reduced a
            ll1 0 DO
              d{ I } f@ f f!
              e{ I } f@ g f!

              ll1 I DO
                f f@ e{ I } f@ f*  g f@ d{ I } f@ f* f+ fnegate
                z{{ I J }} f+!
              LOOP

              z{{ ll I }} f@ d{ I } f!
              0.0e0 z{{ ii I }} f!
            LOOP
          THEN
        THEN

        h f@ d{ ii } f!
      LOOP

\ accumulation of transformation matrices
      N 1 DO
        I  1- to ll
        ll 1+ to ll1
        z{{ ll dup }} f@ z{{ N 1- ll }} f!
        1.0e0 z{{ ll dup }} f!
        d{ I } f@ h f!

        h f@ f0= invert IF
          ll1 0 DO
            z{{ I J }} f@ h f@ f/ d{ I } f!
          LOOP

          I to kk

          ll1 0 DO
            0.0e0 g f!
            ll1 0 DO
              z{{ I J }} f@ z{{ I kk }} f@ f* g f+!
            LOOP

            ll1 0 DO
              g f@ d{ I } f@ f* fnegate z{{ I J }} f+!
            LOOP
          LOOP
        THEN

        ll1 0 DO
          0.0e0 z{{ I J }} f!
        LOOP
      LOOP
      l.510  
;

BASE !
END-MODULE

TEST-CODE? [IF]
BASE @ DECIMAL
[UNDEFINED] T{ [IF] include ttester [THEN]


4 4 FLOAT MATRIX A{{
 4e  1e -2e  2e
 1e  2e  0e  1e
-2e  0e  3e -2e
 2e  1e -2e -1e
4 4 A{{ }}fput

4 FLOAT ARRAY DIAG{
4 FLOAT ARRAY SUBDIAG{
4 4 FLOAT MATRIX OT{{

1e-15 rel-near f!
1e-15 abs-near f!
set-near

TESTING TRED2
t{  4 4 a{{ diag{ subdiag{ ot{{ tred2 ->  }t
t{  diag{ 0 }    f@ ->  147e  65e f/  r}t
t{  diag{ 1 }    f@ ->  692e 585e f/  r}t
t{  diag{ 2 }    f@ ->   50e   9e f/  r}t
t{  diag{ 3 }    f@ ->   -1e          r}t
t{  subdiag{ 0 } f@ ->    0e          r}t
t{  subdiag{ 1 } f@ ->   -6e  65e f/  r}t
t{  subdiag{ 2 } f@ ->   65e  81e f/ fsqrt r}t
t{  subdiag{ 3 } f@ ->    3e          r}t
t{  ot{{ 0 0 }}  f@ ->    4e  65e f/ fsqrt r}t
t{  ot{{ 0 1 }}  f@ ->  289e 585e f/ fsqrt r}t
t{  ot{{ 0 2 }}  f@ ->    2e   3e f/       r}t
t{  ot{{ 0 3 }}  f@ ->    0e               r}t
t{  ot{{ 1 0 }}  f@ ->   36e  65e f/ fsqrt r}t
t{  ot{{ 1 1 }}  f@ ->  196e 585e f/ fsqrt fnegate r}t
t{  ot{{ 1 2 }}  f@ ->    1e   3e f/        r}t
t{  ot{{ 1 3 }}  f@ ->    0e                r}t 
t{  ot{{ 2 0 }}  f@ ->    5e  13e f/ fsqrt  r}t
t{  ot{{ 2 1 }}  f@ ->   20e 117e f/ fsqrt  r}t
t{  ot{{ 2 2 }}  f@ ->   -2e   3e f/        r}t
t{  ot{{ 2 3 }}  f@ ->    0e                r}t
t{  ot{{ 3 0 }}  f@ ->    0e                r}t
t{  ot{{ 3 1 }}  f@ ->    0e                r}t
t{  ot{{ 3 2 }}  f@ ->    0e                r}t
t{  ot{{ 3 3 }}  f@ ->    1e                r}t

BASE !
[THEN]

