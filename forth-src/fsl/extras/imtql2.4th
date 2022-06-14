\ imtql2.4th
\
\      IMTQL2 ( nm n d e z -- ierr )
\
\      integer i,j,k,l,m,n,ii,nm,mml,ierr
\      double precision d(n),e(n),z(nm,n)
\      double precision b,c,f,g,p,r,s,tst1,tst2,pythag
\
\     this procedure is a translation of the Fortran subroutine,
\     imtql2, which is a translation of the algol procedure imtql2,
\     num. math. 12, 377-383(1968) by martin and wilkinson,
\     as modified in num. math. 15, 450(1970) by dubrulle.
\     handbook for auto. comp., vol.ii-linear algebra, 241-248(1971).
\
\     this subroutine finds the eigenvalues and eigenvectors
\     of a symmetric tridiagonal matrix by the implicit ql method.
\     the eigenvectors of a full symmetric matrix can also
\     be found if  tred2  has been used to reduce this
\     full matrix to tridiagonal form.
\
\     on input
\
\        nm must be set to the row dimension of two-dimensional
\          array parameters as declared in the calling program
\          dimension statement.
\
\        n is the order of the matrix.
\
\        d contains the diagonal elements of the input matrix.
\
\        e contains the subdiagonal elements of the input matrix
\          in its last n-1 positions.  e(1) is arbitrary.
\
\        z contains the transformation matrix produced in the
\          reduction by  tred2, if performed.  if the eigenvectors
\          of the tridiagonal matrix are desired, z must contain
\          the identity matrix.
\
\      on output
\
\        d contains the eigenvalues in ascending order.  if an
\          error exit is made, the eigenvalues are correct but
\          unordered for indices 1,2,...,ierr-1.
\
\        e has been destroyed.
\
\        z contains orthonormal eigenvectors of the symmetric
\          tridiagonal (or full) matrix.  if an error exit is made,
\          z contains the eigenvectors associated with the stored
\          eigenvalues.
\
\        ierr is set to
\          zero       for normal return,
\          j          if the j-th eigenvalue has not been
\                     determined after 30 iterations.
\
\     calls pythag for  dsqrt(a*a + b*b) .
\
\     questions and comments on the Fortran subroutine should be
\     directed to burton s. garbow, mathematics and computer science
\     div, argonne national laboratory
\
\     Fortran version dated august 1983.
\     Forth version dated june 2022.
\     Translated to Forth by Krishna Myneni
\     ------------------------------------------------------------------

[UNDEFINED] F+! [IF]
fp-stack? [IF]
: f+! ( a -- ) ( F: r -- ) dup f@ f+ f! ;
[ELSE]
: f+! ( r a -- ) dup >r f@ f+ r> f! ;
[THEN]
[THEN]

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
0 value m
0 value mml
0 value N
0 value ii
0 value jj
0 value kk
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
0 ptr z{{

Public:

: imtql2 ( nm n d e z -- ierr )
      to z{{  to e{  to d{  to N  drop
      0 to ierr  false to uflow
      N 1 = IF  ierr EXIT  THEN

      N 1 DO
        e{ I } f@ e{ I 1- } f!
      LOOP

      0.0e0 e{ N 1- } f!

      N 0 DO
        0 to jj
\ look for small sub-diagonal element
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
          d{ I 1+ } f@ p f@ f- 2.0e0 e{ I } f@ f* f/ g f!
          g f@ 1.0e0 pythag r f!
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
            d{ ii } f@ g f@ f- s f@ f*  2.0e0 c f@ f* b f@ f* f+ r f!
            s f@ r f@ f* p f!
            g f@ p f@ f+ d{ ii 1+ } f!
            c f@ r f@ f* b f@ f- g f!
\ form vector
            N 0 DO
               z{{ I ii 1+ }} f@ f f!
               s f@ z{{ I ii }} f@ f* c f@ f f@ f* f+ z{{ I ii 1+ }} f!
               c f@ z{{ I ii }} f@ f* s f@ f f@ f* f- z{{ I ii }} f!
            LOOP
          LOOP

          uflow IF
\ recover from underflow
            p f@ fnegate d{ ii 1+ } f+!
            false to uflow
          ELSE
            p f@ fnegate d{ I } f+!
            g f@ e{ I } f!
          THEN
          0.0e0 e{ m } f!
        REPEAT
      LOOP

\ order eigenvalues and eigenvectors
      N 1 DO
        I 1- to ii
        ii to kk
        d{ ii } f@ p f!

        N ii DO
          d{ I } f@ p f@ f< IF
            I to kk
            d{ I } f@ p f!
          THEN
        LOOP

        kk ii <> IF
          d{ ii } f@ d{ kk } f!
          p f@ d{ ii } f!

          N 0 DO
            z{{ I ii }} f@ p f!
            z{{ I kk }} f@ z{{ I ii }} f!
            p f@ z{{ I kk }} f!
          LOOP
        THEN
      LOOP

      ierr ;

BASE !
END-MODULE


