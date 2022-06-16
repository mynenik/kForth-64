\ tred1.4th
\
\     TRED1 ( nm n a d e e2 -- )
\
\     integer i,j,k,l,n,ii,nm,jp1
\     double precision a(nm,n),d(n),e(n),e2(n)
\     double precision f,g,h,scale
\
\     this procedure is a translation of the Fortran subroutine,
\     tred1, which is a translation of the algol procedure,
\     tred1, num. math. 11, 181-195(1968) by martin, reinsch,
\     and wilkinson. 
\     handbook for auto. comp., vol.ii-linear algebra, 212-226(1971).
\
\     this procedure reduces a real symmetric matrix
\     to a symmetric tridiagonal matrix using
\     orthogonal similarity transformations.
\
\     on input
\
\        nm -- row dimension of two-dimensional
\          array parameters as declared in the calling program
\          dimension statement.
\
\        n -- order of the matrix.
\
\        a -- contains the real symmetric input matrix.  only the
\          lower triangle of the matrix need be supplied.
\
\     on output
\
\        a contains information about the orthogonal trans-
\          formations used in the reduction in its strict lower
\          triangle.  the full upper triangle of a is unaltered.
\
\        d contains the diagonal elements of the tridiagonal matrix.
\
\        e contains the subdiagonal elements of the tridiagonal
\          matrix in its last n-1 positions.  e(1) is set to zero.
\
\        e2 contains the squares of the corresponding elements of e.
\          e2 may coincide with e if the squares are not needed.
\
\     questions and comments on the Fortran procedure should be directed 
\     to burton s. garbow, mathematics and computer science div, 
\     argonne national laboratory
\
\     Fortran version dated august 1983.
\     Forth version dated june 8, 2022.
\     Translated to Forth by Krishna Myneni.
\     ------------------------------------------------------------------
\

BEGIN-MODULE

BASE @
DECIMAL

0 ptr e2{
0 ptr e{
0 ptr d{
0 ptr a{{
0 value N

0 value ii
0 value ll
fvariable f
fvariable g
fvariable h
fvariable scale

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

Public:

: tred1 ( nm n a d e e2 -- )
      to e2{  to e{  to d{  to a{{  to N drop
      N 0 DO
         a{{ N 1- I }} f@ d{ I } f!
         a{{ I dup }}  f@ a{{ N 1- I }} f!
      LOOP

      N 0 DO
         N I 1+ - to ii
         ii 1- to ll
         0.0e0 h f! 
         0.0e0 scale f!
         ll 0< IF
           0.0e0 e{ ii } f! 
           0.0e0 e2{ ii } f!
           LEAVE
         THEN

\  scale row
         ll 1+ 0 DO  d{ I } f@ fabs scale f+!  LOOP

         scale f@ f0= IF
           ll 1+ 0 DO
             a{{ ll I }} f@ d{ I } f!
             a{{ ii I }} f@ a{{ ll I }} f!
             0.0e0 a{{ ii I }} f!
           LOOP
           0.0e0 e{ ii }  f!
           0.0e0 e2{ ii } f! 
           LEAVE
         THEN

         ll 1+ 0 DO
            d{ I } f@ scale f@ f/ fdup d{ I } f! fsquare h f+!
         LOOP

         scale f@ fsquare h f@ f* e2{ ii } f!
         d{ ll } f@ f f!
         h f@ fsqrt f f@ dsign fnegate g f!
         scale f@ g f@ f* e{ ii } f!
         f f@ g f@ f* fnegate h f+!
         f f@ g f@ f- d{ ll } f!

         ll 0 <> IF
\ form a*u 
           ll 1+ 0 DO  0.0e0 e{ I } f!  LOOP
           ll 1+ 0 DO
             d{ I } f@  f f!
             e{ I } f@  a{{ I dup }} f@  f f@ f* f+ g f!
             ll I 1+ >= IF
               ll 1+ I 1+ DO
                 a{{ I J }} f@ d{ I } f@ f* g f+!
                 a{{ I J }} f@ f f@ f* e{ I } f+!
               LOOP
             THEN
             g f@ e{ I } f!
           LOOP
\ form p
           0.0e0 f f!

           ll 1+ 0 DO
             e{ I } f@ h f@ f/ e{ I } f!
             e{ I } f@ d{ I } f@ f*  f f+!
           LOOP

           f f@ h f@ fdup f+ f/ h f!
\ form q
           ll 1+ 0 DO
             h f@ d{ I } f@ f* fnegate e{ I } f+!
           LOOP

\ form reduced a
           ll 1+ 0 DO
             d{ I } f@ f f!  e{ I } f@ g f!
             ll 1+ I DO
               f f@ e{ I } f@ f*  g f@ d{ I } f@ f* f+ fnegate 
               a{{ I J }} f+!
             LOOP
           LOOP
         THEN

         ll 1+ 0 DO
           d{ I } f@ f f!
           a{{ ll I }} f@    d{ I } f!
           a{{ ii I }} f@    a{{ ll I }} f!
           f f@  scale f@ f* a{{ ii I }} f!
         LOOP
       LOOP ;

BASE !

END-MODULE

\ Test code
\ Test case: 4 x 4 real, symmetric matrix.
4 4 FLOAT MATRIX A{{
 4e  1e -2e  2e
 1e  2e  0e  1e
-2e  0e  3e -2e
 2e  1e -2e -1e
4 4 A{{ }}fput

4 FLOAT ARRAY DIAG{
4 FLOAT ARRAY SUBDIAG{
4 FLOAT ARRAY SUBDIAG2{

\ nm n a d e e2
\ 4 4 A{{ DIAG{ SUBDIAG{ SUBDIAG2{ tred1
