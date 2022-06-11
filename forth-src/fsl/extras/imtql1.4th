\ imtql1.4th
\
\      IMTQL1 ( n d e -- ierr )
\
\      integer i,j,l,m,n,ii,mml,ierr
\      double precision d(n),e(n)
\      double precision b,c,f,g,p,r,s,tst1,tst2,pythag
\
\     this procedure is a translation of the Fortran subroutine imtql1,
\     which is a translation of the algol procedure imtql1,
\     num. math. 12, 377-383(1968) by martin and wilkinson,
\     as modified in num. math. 15, 450(1970) by dubrulle.
\     handbook for auto. comp., vol.ii-linear algebra, 241-248(1971).
\
\     this subroutine finds the eigenvalues of a symmetric
\     tridiagonal matrix by the implicit ql method.
\
\     on input
\
\        n is the order of the matrix.
\
\        d contains the diagonal elements of the input matrix.
\
\        e contains the subdiagonal elements of the input matrix
\          in its last n-1 positions.  e(1) is arbitrary.
\
\      on output
\
\        d contains the eigenvalues in ascending order.  if an
\          error exit is made, the eigenvalues are correct and
\          ordered for indices 1,2,...ierr-1, but may not be
\          the smallest eigenvalues.
\
\        e has been destroyed.
\
\        ierr is set to
\          zero       for normal return,
\          j          if the j-th eigenvalue has not been
\                     determined after 30 iterations.
\
\     calls pythag for  dsqrt(a*a + b*b) .
\
\     questions and comments on the Fortran subroutine should be directed
\     to burton s. garbow, mathematics and computer science div,
\     argonne national laboratory
\
\     Fortran version dated august 1983.
\     Forth version dated june 2022.
\     Translated to Forth by Krishna Myneni.
\     ------------------------------------------------------------------
\

[UNDEFINED] dsign [IF]
\ Obsolete Fortran function dsign()
: dsign ( F: r1 r2 )
    fswap fabs fswap f0< IF fnegate THEN ;
[THEN]
[UNDEFINED] fsquare [IF] : fsquare fdup f* ; [THEN]
[UNDEFINED] pythag [IF]
: pythag ( F: a b -- c ) fsquare fswap fsquare f+ fsqrt ;
[THEN]

BEGIN-MODULE

BASE @ DECIMAL

\ private data for this module
0 value ierr
0 value N
0 value ii
0 value jj
0 value l
0 value m
0 value mml
0 value uflow
fvariable b
fvariable c
fvariable f
fvariable g
fvariable p
fvariable r
fvariable s
0 ptr d{
0 ptr e{

Public:

: imtql1 ( n d e -- ierr )
      to e{ to d{ to N
      0 to ierr  false to uflow
      N 1 = IF  ierr EXIT  THEN

      N 1 DO
        e{ I } f@ e{ I 1- } f!
      LOOP

      0.0e0 e{ N 1- } f!

      N 0 DO
        0 to jj
\  look for small sub-diagonal element
        BEGIN
          N I DO
            I to m
            I N 1- = IF LEAVE THEN
            d{ I } f@ fabs d{ I 1+ } f@ fabs f+
            fdup e{ I } f@ fabs f+
            f= IF LEAVE THEN
          LOOP
          d{ I } f@ p f!
          m I <>
        WHILE
\ set error -- no convergence to an eigenvalue after 30 iterations
          jj 30 = IF I 1+ to ierr LEAVE THEN
          jj 1+ to jj
\ form shift
	  \ g = (d(l+1) - p) / (2.0d0 * e(l))  
          d{ I 1+ } f@ p f@ f- 2.0e0 e{ I } f@ f* f/ g f!
          g f@ 1.0e0 pythag r f!
          \ g = d(m) - p + e(l) / (g + dsign(r,g))
	  d{ m } f@ p f@ f- e{ I } f@ g f@ r f@ fover dsign f+ f/ f+ g f!
          1.0e0 s f!
          1.0e0 c f!
          0.0e0 p f!
          m I - to mml
\ for i=m-1 step -1 until l do --
          mml 0 DO
            m I 1+ - to ii
            e{ ii } f@ s f@ f* f f!
            e{ ii } f@ c f@ f* b f!
            f f@ g f@ pythag   r f!
            r f@ e{ ii 1+ } f!
            r f@ f0= IF
              true to uflow LEAVE
            THEN
            f f@ r f@ f/ s f!
            g f@ r f@ f/ c f!
            d{ ii 1+ } f@ p f@ f- g f!
	    d{ ii } f@ g f@ f- s f@ f*  2.0e0 c f@ f* b f@ f* f+  r f!
            s f@ r f@ f* p f!
            g f@ p f@ f+ d{ ii 1+ } f!
            c f@ r f@ f* b f@ f- g f!
          LOOP

          uflow IF
\  recover from underflow
            d{ ii 1+ } f@ p f@ f- d{ ii 1+ } f!
            false to uflow
          ELSE
            d{ I } f@ p f@ f- d{ I } f!
            g f@ e{ I } f!
          THEN
          0.0e0 e{ m } f!     
        REPEAT

\  order eigenvalues
        I 0 = IF
          p f@ d{ 0 } f!
        ELSE
\ for i=l step -1 until 2 do
          I 2+ 1 DO
            J 1+ I - to ii
            p f@ d{ ii 1- } f@ f>= IF
              LEAVE
            THEN
            d{ ii 1- } f@ d{ ii } f!
          LOOP
          p f@ d{ ii } f!
        THEN      
      LOOP  \ end main loop

      ierr ;

BASE !
END-MODULE

TEST-CODE? [IF]
BASE @ DECIMAL
[UNDEFINED] T{ [IF] include ttester [THEN]

\ Set up a 10 x 10 tridiagonal matrix, a symmetrized Clement
\ matrix, with known eigenvalues, in array packed form. The
\ diagonals are zeros, and the subdiagonal elements are given
\ by SQRT(i*(N - i)), i = 1, N-1. The N eigenvalues are
\ +/- N-1, +/- N-2, ... +/-1.

10 value N
N FLOAT ARRAY diag{
N FLOAT ARRAY subdiag{

: s-Clement ( -- )
    diag{ N FLOATS erase
    0.0e0 subdiag{ 0 } F!
    N 1 DO
      I N OVER - * S>F FSQRT
      subdiag{ I } F!
    LOOP
;

1e-15 rel-near f!
1e-15 abs-near f!
set-near

TESTING IMTQL1
t{ s-Clement ->  }t
t{ N diag{ subdiag{ imtql1 -> 0 }t
t{ diag{ 0 } f@  ->  -9  s>f  r}t
t{ diag{ 1 } f@  ->  -7  s>f  r}t
t{ diag{ 2 } f@  ->  -5  s>f  r}t
t{ diag{ 3 } f@  ->  -3  s>f  r}t
t{ diag{ 4 } f@  ->  -1  s>f  r}t
t{ diag{ 5 } f@  ->   1  s>f  r}t
t{ diag{ 6 } f@  ->   3  s>f  r}t
t{ diag{ 7 } f@  ->   5  s>f  r}t
t{ diag{ 8 } f@  ->   7  s>f  r}t
t{ diag{ 9 } f@  ->   9  s>f  r}t

BASE !

[THEN]


