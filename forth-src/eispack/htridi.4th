\ htridi.4th
\
\     HTRIDI ( nm n ar ai d e e2 tau -- )
\
\      integer i,j,k,l,n,ii,nm,jp1
\      double precision ar(nm,n),ai(nm,n),d(n),e(n),e2(n),tau(2,n)
\      double precision f,g,h,fi,gi,hh,si,scale,pythag
\
\     this procedure is a translation of the Fortran subroutine,
\     htridi, which is a translation of a complex analogue of
\     the algol procedure tred1, num. math. 11, 181-195(1968)
\     by martin, reinsch, and wilkinson.
\     handbook for auto. comp., vol.ii-linear algebra, 212-226(1971).
\
\     this subroutine reduces a complex hermitian matrix
\     to a real symmetric tridiagonal matrix using
\     unitary similarity transformations.
\
\     on input
\
\        nm must be set to the row dimension of two-dimensional
\          array parameters as declared in the calling program
\          dimension statement.
\
\        n is the order of the matrix.
\
\        ar and ai contain the real and imaginary parts,
\          respectively, of the complex hermitian input matrix.
\          only the lower triangle of the matrix need be supplied.
\
\     on output
\
\        ar and ai contain information about the unitary trans-
\          formations used in the reduction in their full lower
\          triangles.  their strict upper triangles and the
\          diagonal of ar are unaltered.
\
\        d contains the diagonal elements of the the tridiagonal matrix.
\
\        e contains the subdiagonal elements of the tridiagonal
\          matrix in its last n-1 positions.  e(1) is set to zero.
\
\        e2 contains the squares of the corresponding elements of e.
\          e2 may coincide with e if the squares are not needed.
\
\        tau contains further information about the transformations.
\
\     calls pythag for  dsqrt(a*a + b*b) .
\
\     questions and comments on the Fortran subroutine should be
\     directed to burton s. garbow, mathematics and computer science
\     div, argonne national laboratory
\
\     Fortran version dated august 1983.
\     Forth version dated june 16, 2022.
\     Translated to Forth by Krishna Myneni.
\     ------------------------------------------------------------------
[UNDEFINED] F+! [IF]
fp-stack? [IF]
: f+! ( a -- ) ( F: r -- ) dup f@ f+ f! ;
[ELSE]
: f+! ( r a -- ) dup >r f@ f+ r> f! ;
[THEN]
[THEN]

[UNDEFINED] FSQUARE [IF] : fsquare fdup f* ; [THEN]
[UNDEFINED] pythag [IF]
: pythag ( F: a b -- c ) fsquare fswap fsquare f+ fsqrt ;
[THEN]

BEGIN-MODULE

BASE @ DECIMAL

\ private data for this module
0 value N
0 value p2leq1
0 value ii
0 value ll
0 value ll1
0 ptr tau{{
0 ptr e2{
0 ptr e{
0 ptr d{
0 ptr ai{{
0 ptr ar{{
fvariable f
fvariable fi
fvariable g
fvariable gi
fvariable h
fvariable hh
fvariable scale
fvariable si

Public:

: htridi ( nm n ar ai d e e2 tau -- )
      to tau{{ to e2{ to e{ to d{ to ai{{ to ar{{ to N drop

      1.0e0 tau{{ 0 N 1- }} f!
      0.0e0 tau{{ 1 N 1- }} f!

      N 0 DO
        ar{{ I dup }} f@ d{ I } f!
      LOOP
\  for i=n step -1 until 1 do --
      false to p2leq1

      N 0 DO
        N I 1+ - to ii
        ii 1- to ll
        ll 1+ to ll1
        0.0e0 h f!
        0.0e0 scale f!

        ll 0 < IF
          0.0e0 e{ ii }  f!
          0.0e0 e2{ ii } f!
        ELSE
\ scale row (algol tol then not needed)
          ll1 0 DO
            ar{{ ii I }} f@ fabs ai{{ ii I }} f@ fabs f+
            scale f+!
          LOOP

          scale f@ f0= IF
            1.0e0 tau{{ 0 ll }} f!
            0.0e0 tau{{ 1 ll }} f!
            0.0e0 e{ ii } f!
            0.0e0 e2{ ii } f!
          ELSE 
            ll1 0 DO
              ar{{ ii I }} f@ scale f@ f/ ar{{ ii I }} f!
              ai{{ ii I }} f@ scale f@ f/ ai{{ ii I }} f!
              ar{{ ii I }} f@ fsquare ai{{ ii I }} f@ fsquare
              f+ h f+!
            LOOP

            scale f@ fsquare h f@ f* e2{ ii } f!
            h f@ fsqrt g f!
            g f@ scale f@ f* e{ ii } f!
            ar{{ ii ll }} f@ ai{{ ii ll }} f@ pythag f f!
\ form next diagonal element of matrix t
            f f@ f0= IF
              tau{{ 0 ii }} f@ fnegate tau{{ 0 ll }} f!
              tau{{ 1 ii }} f@ si f!
              g f@ ar{{ ii ll }} f!
            ELSE
              ai{{ ii ll }} f@ tau{{ 1 ii }} f@ f*
              ar{{ ii ll }} f@ tau{{ 0 ii }} f@ f* f- f f@ f/
              tau{{ 0 ll }} f!
              ar{{ ii ll }} f@ tau{{ 1 ii }} f@ f*
              ai{{ ii ll }} f@ tau{{ 0 ii }} f@ f* f+ f f@ f/
              si f!
              f f@ g f@ f* h f+!
              1.0e0 g f@ f f@ f/ f+ g f!
              g f@ ar{{ ii ll }} f@ f* ar{{ ii ll }} f!
              g f@ ai{{ ii ll }} f@ f* ai{{ ii ll }} f!
              ll 0= IF true to p2leq1 THEN
            THEN

            p2leq1 invert IF
              0.0e0 f f!

              ll1 0 DO
                0.0e0  g f!
                0.0e0 gi f!
\ form element of a*u
                I 1+ 0 DO
                  ar{{ J I }} f@ ar{{ ii I }} f@ f*
                  ai{{ J I }} f@ ai{{ ii I }} f@ f* f+ g f+!
                  ar{{ J I }} f@ ai{{ ii I }} f@ f* fnegate
                  ai{{ J I }} f@ ar{{ ii I }} f@ f* f+ gi f+!
                LOOP

                ll I 1+ >= IF
                  ll1 I 1+ DO
                    ar{{ I J }} f@ ar{{ ii I }} f@ f*
                    ai{{ I J }} f@ ai{{ ii I }} f@ f* f- g f+!
                    ar{{ I J }} f@ ai{{ ii I }} f@ f*
                    ai{{ I J }} f@ ar{{ ii I }} f@ f* f+ fnegate
                    gi f+!
                  LOOP
                THEN
\ form element of p
                g  f@ h f@ f/ e{ I } f!
                gi f@ h f@ f/ tau{{ 1 I }} f!
                e{ I } f@       ar{{ ii I }} f@ f*
                tau{{ 1 I }} f@ ai{{ ii I }} f@ f* f- f f+!
              LOOP

              f f@ h f@ fdup f+ f/ hh f!
\ form reduced a
              ll1 0 DO
                ar{{ ii I }} f@ f f!
                e{ I } f@ hh f@ f f@ f* f- g f!
                g f@ e{ I } f!
                ai{{ ii I }} f@ fnegate fi f!
                tau{{ 1 I }} f@ hh f@ fi f@ f* f- gi f!
                gi f@ fnegate tau{{ 1 I }} f!

                I 1+ 0 DO
                  f f@ e{ I } f@ f* g f@ ar{{ ii I }} f@ f* f+
                  fnegate fi f@ tau{{ 1 I }} f@ f* f+
                  gi f@ ai{{ ii I }} f@ f* f+ ar{{ J I }} f+!
                  f f@ tau{{ 1 I }} f@ f* g f@ ai{{ ii I }} f@ f*
                  f+ fi f@ e{ I } f@ f* f+ gi f@ ar{{ ii I }} f@
                  f* f+ fnegate ai{{ J I }} f+!
                LOOP
              LOOP
            ELSE
              false to p2leq1
            THEN

            ll1 0 DO
              scale f@ fdup
              ar{{ ii I }} f@ f* ar{{ ii I }} f!
              ai{{ ii I }} f@ f* ai{{ ii I }} f!
            LOOP

            si f@ fnegate tau{{ 1 ll }} f!
          THEN
        THEN
        d{ ii } f@ hh f!
        ar{{ ii dup }} f@ d{ ii } f!
        hh f@  ar{{ ii dup }} f!
        h f@ fsqrt scale f@ f* ai{{ ii dup }} f!
      LOOP
;

BASE !
END-MODULE


TEST-CODE? [IF]
BASE @ DECIMAL
[UNDEFINED] T{ [IF] include ttester [THEN]

1e-15 rel-near f!
1e-15 abs-near f!
set-near

CR
TESTING HTRIDI

2 value N
N N FLOAT MATRIX H2r{{
N N FLOAT MATRIX H2i{{
2 N FLOAT MATRIX Tr2{{
N FLOAT ARRAY diag2{
N FLOAT ARRAY subd2{
N FLOAT ARRAY subd2s{

\ 2x2 Hermitian matrix
\
\   3   2-i
\  2+i   4
\
3.0e0 2.0e0
2.0e0 4.0e0
N N H2r{{ }}fput

0.0e0 -1.0e0
1.0e0  0.0e0
N N H2i{{ }}fput

t{ N N H2r{{ H2i{{ diag2{ subd2{ subd2s{ Tr2{{ htridi -> }t
t{ diag2{ 0 } f@ -> 3.0e0 r}t
t{ diag2{ 1 } f@ -> 4.0e0 r}t
t{ subd2{ 1 } f@ -> 5.0e0 fsqrt r}t

3 to N
N N FLOAT MATRIX H3r{{
N N FLOAT MATRIX H3i{{
2 N FLOAT MATRIX Tr3{{
N FLOAT ARRAY diag3{
N FLOAT ARRAY subd3{
N FLOAT ARRAY subd3s{

\ 3x3 Hermitian matrix
\
\   1   i  2+i
\  -i   2  1-i
\ 2-i  1+i  2
 
1.0e0  0.0e0  2.0e0
0.0e0  2.0e0  1.0e0
2.0e0  1.0e0  2.0e0
N N H3r{{ }}fput

 0.0e0  1.0e0  1.0e0
-1.0e0  0.0e0 -1.0e0
-1.0e0  1.0e0  0.0e0
N N H3i{{ }}fput

t{ N N H3r{{ H3i{{ diag3{ subd3{ subd3s{ Tr3{{ htridi -> }t
t{ diag3{ 0 } f@  ->   6.0e0 7.0e0 f/  r}t
t{ diag3{ 1 } f@  ->  15.0e0 7.0e0 f/  r}t
t{ diag3{ 2 } f@  ->   2.0e0           r}t
t{ subd3{ 1 } f@  ->  41.0e0 49.0e0 f/ fsqrt r}t
t{ subd3{ 2 } f@  ->   7.0e0 fsqrt     r}t

BASE !
[THEN]

