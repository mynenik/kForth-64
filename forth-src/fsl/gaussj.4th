\ ----------------------------------------------------------------------
\ A matrix toolkit, containing:
\
\    gaussj solve mat^-1 get-column get-row transpose mat* mat- mat+ mat+!
\    fillmat }}absmat
\
\ See lufact.4th for additional material.
\ Forth Scientific Library Algorithm #48

\ gaussj ( 'A 'B r c -- bad? )
\ Linear equation solution by Gauss-Jordan elimination, equation (2.1.1)
\ of Numerical Recipes p 34. The input matrix A[] has r x r elements.
\ B[] is an r x c input matrix containing the c right-hand side vectors.
\ On output, A is replaced by its matrix inverse and B is replaced by the
\ corresponding set of solution vectors. The flag is FALSE when gaussj was
\ successful (it can fail because of too small pivots or memory problems).

\ Note that the FSL's LU-method uses N^3/3 operation steps, which is much
\ better than the Gauss-Jordan approach (N^3 steps). However, the Gauss-Jordan
\ method computes the inverse matrix automatically. When the LU-method is used
\ to do this it also needs N^3 steps.
\ The Gauss-Jordan method should be most efficient when you have a (large)
\ number of right-hand vectors (m). In this case you only need one call to get
\ all solutions at once, versus m calls using lubksb.
\ The Gauss-Jordan method is more convenient when iterative improvement of the
\ solution is needed (see the SOLVE procedure).

\ mat^-1 ( 'A n -- bad? )
\ Matrix inversion by Gauss-Jordan elimination.
\ The input matrix A[] has n by n elements. On output, A is replaced by its
\ matrix inverse.
\ The flag is FALSE when mat^-1 was successful (it can fail because of too
\ small pivots, a singular matrix, or memory problems).

\ mat*  ( 'A ra ca 'B rb cb xt-C -- )
\ Matrix multiplication, works for any set of (floating-point) matrices.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrices are not altered in any way. Bounds checks are done.

\ get-column ( 'A ra ca xt-C c -- 'C ra 1 )
\ Cut column c out of a ra x ca matrix A and return the result as the ra x 1
\ matrix C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix A is not altered in any way.

\ get-row ( 'A ra ca xt-C r -- 'C 1 ca )
\ Cut row r out of the ra x ca matrix A and return the result as the 1 x ca
\ matrix C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix A is not altered in any way.

\ transpose  ( 'A ra ca xt-C -- )
\ Transpose a (floating-point) matrix A , that is, interchange its rows and
\ columns.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix A is not altered in any way.

\ mat+!  ( 'A ra ca 'B rb cb -- )
\ Matrix addition of A to B. Bounds checks are done.

\ mat-  ( 'A ra ca 'B rb cb xt-C -- )
\ Matrix subtraction of B from A , with the result left in C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix is not altered in any way. Bounds checks are done.

\ mat+  ( 'A ra ca 'B rb cb xt-C -- )
\ Matrix addition of B to A , with the result left in C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix is not altered in any way. Bounds checks are done.

\ }}absmat ( 'A r c -- )  ( F: -- e )
\ Used on a 1-row or 1-column matrix A this gives the Euclidean 'length'.
\ ( Gives square root of sum of squares of all elements. )

\ fillmat ( 'A r c -- ) ( F: e -- )
\ Initialize all matrix elements of A to the number e.

\ solve ( 'A 'X 'Y MaxSteps n m -- steps bad? ) ( F: MaxError -- err cnv )
\ Returns the solution X to A*X=Y, where A is an n x m coefficient
\ matrix, X is m x 1 , and Y is n x 1 , with m <= n.
\ If m < n, solve returns an X that represents a least squares fit through
\ all data points Y (n x 1).
\ Again, A and Y are kept intact.
\ Solve is able to solve sets of equations that are nearly singular, or
\ "noisy", using a successive, automatic, refinement method.
\ Refinement is done by passing in an X that is a good guess to the wanted
\ solution vector. If you have no idea of the solution, use a zero-filled X.
\ The maximum number of iterations is controlled with MaxSteps.
\ Iteration stops when the error, measured by the norm of (A*X-Y),
\ is less than MaxError; the final error is returned on the stack
\ as  err .  The norm of the last correction to X is returned
\ as  cnv .  The boolean  bad?  is false if a solution is reached,
\ +1 if m > n , and +2 if a matrix inversion failed.

\ This is an ANS Forth program requiring:
\       1. The Floating-Point word sets
\       2. Uses FSL words from fsl_util.xxx and (for the tests) from r250.xxx
\       3. Uses : F> FSWAP F< ;
\               : F2DUP ( F: r1 r2 -- r1 r2 r1 r2 ) FOVER FOVER ;
\               : 1/F  ( F: r -- 1/r ) 1e FSWAP F/ ;
\               : F+! ( addr -- ) ( F: r -- )  DUP F@ F+ F! ;
\               : FSQUARE ( F: r1 -- r2 ) FDUP F* ;

\ Note: the code uses 5 fp stack cells (iForth vsn 1.07) when executing
\       the test words.

\ See: 'Numerical recipes in Pascal, The Art of Scientific Computing',
\ William H. Press, Brian P. Flannery, Saul A. Teukolsky and William
\ T. Vetterling, Chapter 2 (2.1, 2.7): Solution of Linear Algebraic Equations.
\ 1989; Cambridge University Press, Cambridge, ISBN 0-521-37516-9

\ (c) Copyright 1995 Marcel Hendrix.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

\ Revisions:
\    1995-05-05  mh; V1.0
\    1997-01-19  mh; Vsn 1.1 Improved doc. (thanks to "C. Montgomery" <CGM@physics.utoledo.edu>)
\    2003-11-16  km; Ported to kForth
\    2007-11-03  km; save and restore base; conditional defs of extra words.
\    2007-12-02  km; rewrote test code for automated tests
\    2010-10-11  km; put temporary variables in the private wordlist
\    2011-09-16  km; use Neal Bridges' anonymous modules
\    2012-02-19  km; use KM/DNW's modules library
\    2021-07-07  km; updated for use on separate fp stack system also
CR .( GAUSSJ & MATRICES V1.1d           07 July     2021 MH,KM )

BEGIN-MODULE

BASE @ DECIMAL

Public:

[undefined] f>    [IF] : F> FSWAP F< ;  [THEN]
[undefined] f2dup [IF] : F2DUP ( r1 r2 -- r1 r2 r1 r2 ) FOVER FOVER ; [THEN]
[undefined] 1/F   [IF] : 1/F  ( f -- 1/f )   1e FSWAP F/ ; [THEN]
[undefined] F+!   [IF] : F+!  ( f a --   )   DUP >R F@ F+ R> F! ; [THEN] 
[undefined] FSQUARE [IF] : FSQUARE ( f -- f^2)    FDUP F* ; [THEN]

Private:

INTEGER DARRAY indxc{   \ used for bookkeeping on the pivoting
INTEGER DARRAY indxr{   \       "               "
INTEGER DARRAY ipiv{    \       "               "

0 VALUE irow
0 VALUE icol
0 VALUE n
0 ptr A{{

: search-pivot ( 'A n -- r c bad? )
    -1 -1 
    ( LOCALS| irow icol n A{{ |) TO irow  TO icol  TO n  TO A{{
    0e ( big )
    n 0 DO              \ outer loop of the search for a pivot element
          ipiv{ I } @
          0<> IF
                n 0 DO
                        ipiv{ I } @ -1
                        = IF A{{ J I }} F@ FABS F2DUP
                             F> IF FDROP
                              ELSE FSWAP FDROP J TO irow  I TO icol
                              THEN
       
                 ELSE ipiv{ I } ( singular matrix?)
                             @ IF FDROP -1 -1 1 UNLOOP UNLOOP EXIT
                             THEN
                        THEN
                  LOOP
            THEN
      LOOP
      ( big ) FDROP irow icol 0 ;


1e-100 FCONSTANT smallestpivot  \ choose a number related to the float size


\ Linear equation solution by Gauss-Jordan elimination, equation (2.1.1)
\ of Numerical Recipes p 34. The input matrix A[] has r x r elements.

\ B[] is an r x c input matrix containing the c right-hand side vectors.
\ On output, A is replaced by its matrix inverse and B is replaced by the
\ corresponding set of solution vectors. The flag is FALSE when gaussj was
\ successful (it can fail because of too small pivots or memory problems).

Private:

0 VALUE irow
0 VALUE icol
0 VALUE m
0 VALUE n
0 ptr B{{
0 ptr A{{

Public:

: gaussj ( 'A 'B r c -- bad? )
        0 0 
	( LOCALS| irow icol m n B{{ A{{ |) 
	TO irow  TO icol  TO m  TO n  TO B{{  TO A{{
        & indxc{ n }malloc malloc-fail?
        & indxr{ n }malloc malloc-fail? OR
        & ipiv{  n }malloc malloc-fail? OR IF TRUE EXIT THEN
        n 0 DO  -1 ipiv{ I } !  LOOP
	n 0 DO                  \ [i] main loop over columns to be reduced
      		A{{ n search-pivot IF & ipiv{ }free  & indxr{ }free  & indxc{ }free
                            2DROP TRUE UNLOOP EXIT
                       THEN
      TO icol TO irow  1 ipiv{ icol } +!

\ We now have the pivot element, so we interchange rows, if needed, to
\ put the pivot element on the diagonal. The columns are not physically
\ interchanged, only relabeled: indexc^[i], the column of the ith pivot
\ element, is the ith column that is reduced, while indexr^[i] is the
\ row in which that pivot element was originally located. If indexr^[i]
\ <> indexc^[i] there is an implied column interchange. With this form
\ of bookkeeping, the solution b's will end up in the correct order, and
\ the inverse matrix will be scrambled by columns.

    irow icol <> IF
        n 0  DO  A{{ irow I }} DUP F@   A{{ icol I }} DUP F@
[ fp-stack? ] [IF] 
	  SWAP F! F!
[ELSE]
          2>R F! 2R> ROT F!
[THEN]  
        LOOP
        m 0 ?DO  B{{ irow I }} DUP F@   B{{ icol I }} DUP F@
[ fp-stack? ] [IF]
	  SWAP F! F!
[ELSE]
          2>R F! 2R> ROT F!
[THEN]
        LOOP
    THEN
    irow indxr{ I } !  icol indxc{ I } ! 
    A{{ icol DUP }} DUP F@ 
[ fp-stack? ] [IF]
          1e F!
[ELSE]
          2>R 1e ROT F! 2R> 
[THEN]
          FDUP FABS smallestpivot F<
          IF & ipiv{ }free  & indxr{ }free  & indxc{ }free
             FDROP TRUE UNLOOP EXIT
        THEN
    1/F ( -- pivinv) 
    n 0  DO  FDUP A{{ icol I }} DUP >R F@ F*  R> F! LOOP
    m 0 ?DO  FDUP B{{ icol I }} DUP >R F@ F*  R> F! LOOP FDROP
    n 0 DO
           I icol
           <> IF
                A{{ I icol }} DUP >R F@ ( -- dum) 0e R> F!
         
                n 0  DO  
                  A{{ J I }} DUP >R F@ FOVER R> A{{ icol I }} F@
[ fp-stack? ] [IF]
                 F* F- F!
[ELSE]
                  ROT >R F* F- R> F!
[THEN]
                LOOP
                m 0 ?DO  
                  B{{ J I }} DUP >R F@ FOVER R> B{{ icol I }} F@ 
[ fp-stack? ] [IF]
                  F* F- F!
[ELSE]
		  ROT >R F* F- R> F!
[THEN]
                LOOP
                FDROP
           THEN
      LOOP
LOOP    ( end main loop over the columns to be reduced )

\ Unscramble the solution in view of column interchanges

   0 n 1- DO
            indxr{ I } @  indxc{ I } @
            <> IF
                 n 0 DO
                        A{{ I indxr{ J } @ }} DUP F@
                        A{{ I indxc{ J } @ }} DUP F@
[ fp-stack? ] [IF]
                        SWAP F! F!
[ELSE] 
			2>R F! 2R> ROT F!
[THEN]
                   LOOP
             THEN
    -1 +LOOP

   & ipiv{ }free  & indxr{ }free  & indxc{ }free  FALSE ;


\ Matrix inversion by Gauss-Jordan elimination.
\ The input matrix A[] has n x n elements. On output, a is replaced by its
\ matrix inverse.
\ The flag is FALSE when mat^-1 was successful (it can fail because of too
\ small pivots, a singular matrix, or memory problems).
\ This is very simple because gaussj supports c=0.
: mat^-1 ( 'A n -- bad? ) PAD ( dummy 'B ) SWAP 0 gaussj ;

\ Matrix multiplication, works for any set of (floating-point) matrices.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrices are not altered in any way. Bounds checks are done.

Private:

0 VALUE kk
0 VALUE c3
0 VALUE r3
0 VALUE c2
0 VALUE r2
0 VALUE c1
0 VALUE r1
0 ptr mult{{
0 ptr b{{
0 ptr a{{ 

Public:

: mat*  ( 'A ra ca 'B rb cb xt-C -- )
        0 0 0 
	( LOCALS| kk c3 r3 mult{{ c2 r2 b{{ c1 r1 a{{ |)
	TO kk  TO c3  TO r3  TO mult{{  TO c2  TO r2  TO b{{  
	TO c1  TO r1  TO a{{ 
        c1 r2 <> ABORT" mat* :: bounds mismatch"
        r1 TO r3  c2 TO c3
        mult{{ r3 c3 }}malloc malloc-fail? ABORT" mat* :: out of memory"

        mult{{ EXECUTE TO mult{{
        r3 0 DO
                I TO kk
                c3 0 DO
                          0e c1 0 ?DO
                                        a{{ kk I }} F@
                                        b{{ I  J }} F@  F*
                                        F+ ( accumulate on fstack)
                                 LOOP
                          mult{{ J I }} F!
                    LOOP
            LOOP ;

\ Cut column c out of a ra x ca matrix and return the result as the ra x 1
\ matrix C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix A is not altered in any way.
Private:

0 VALUE row
0 VALUE col
0 VALUE c1
0 VALUE r1
0 ptr a{{
0 ptr b{{
0 ptr c{{

Public:

: get-column ( 'A ra ca xt-C c -- 'C ra 1 )
        ( LOCALS| col b{{ c1 r1 a{{ |)
	TO col  TO b{{  TO c1  TO r1  TO a{{
        b{{ r1 1 }}malloc malloc-fail? ABORT" get-column :: out of memory"
        b{{ EXECUTE TO b{{
        r1 0 ?DO
                a{{ I col }} F@
                b{{ I  0  }} F!
            LOOP
        b{{ r1 1 ;

\ Cut row r out of the ra x ca matrix A and return the result as a the 1 x ca
\ matrix C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix A is not altered in any way.
: get-row ( 'A ra ca xt-C r -- 'C 1 ca )
        ( LOCALS| row b{{ c1 r1 a{{ |)
	TO row  TO b{{  TO c1  TO r1  TO a{{
        b{{ 1 c1 }}malloc malloc-fail? ABORT" get-row :: out of memory"
        b{{ EXECUTE TO b{{
        c1 0 ?DO
                a{{ row I }} F@
                b{{  0  I }} F!
            LOOP
        b{{ 1 c1 ;

\ Transpose a (floating-point) matrix A , that is, interchange its rows and
\ columns.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix A is not altered in any way.
: transpose  ( 'A ra ca xt-C -- )
        ( LOCALS| b{{ c1 r1 a{{ |)
	TO b{{  TO c1  TO r1  TO a{{
        b{{ c1 r1 }}malloc malloc-fail? ABORT" transpose :: out of memory"
        b{{ EXECUTE TO b{{
        r1 0 ?DO
                c1 0 ?DO
                         a{{ J I }} F@
                         b{{ I J }} F!
                    LOOP
      
      LOOP ;

\ Matrix addition of A to B. Bounds checks are done.
: mat+!  ( 'A ra ca 'B rb cb -- )
        ( LOCALS| c2 r2 b{{ c1 r1 a{{ |)
	TO c2  TO r2  TO b{{  TO c1  TO r1  TO a{{
        r1 r2 <>  c1 c2 <> OR ABORT" mat+! :: bounds mismatch"
        r2 0 ?DO
                c2 0 ?DO
                        a{{ J I }} F@
                        b{{ J I }} F+!
                    LOOP
            LOOP ;

\ Matrix subtraction of B from A , with the result left in C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix is not altered in any way. Bounds checks are done.
: mat-  ( 'A ra ca 'B rb cb xt-C -- )
        ( LOCALS| c{{ c2 r2 b{{ c1 r1 a{{ |)
	TO c{{  TO c2  TO r2  TO b{{  TO c1  TO r1  TO a{{
        r1 r2 <> c1 c2 <> OR ABORT" mat- :: bounds mismatch"
        c{{ r1 c1 }}malloc malloc-fail? ABORT" mat- :: out of memory"
        c{{ EXECUTE TO c{{
        r1 0 ?DO
                c1 0 ?DO
                        a{{ J I }} F@
                        b{{ J I }} F@  F-
                        c{{ J I }} F!
                    LOOP

            LOOP ;

\ Matrix addition of B to A , with the result left in C.
\ The result matrix C (execution token on the stack) must be freed first.
\ The original matrix is not altered in any way. Bounds checks are done.
: mat+  ( 'A r1 c1 'B r2 c2 'head -- )
        ( LOCALS| c{{ c2 r2 b{{ c1 r1 a{{ |)
	TO c{{  TO c2  TO r2  TO b{{  TO c1  TO r1  TO a{{
        r1 r2 <> c1 c2 <> OR ABORT" mat+ :: bounds mismatch"
        c{{ r1 c1 }}malloc malloc-fail? ABORT" mat+ :: out of memory"
        c{{ EXECUTE TO c{{
        r1 0 ?DO
                c1 0 ?DO
                        a{{ J I }} F@
                        b{{ J I }} F@  F+
                        c{{ J I }} F!
                    LOOP
            LOOP ;

\ Used on a 1-row or 1-column matrix A this gives the Euclidean 'length'.
\ ( Gives square root of sum of squares of all elements. )
: }}absmat ( 'A r c -- )  ( F: -- e )
        ( LOCALS| c1 r1 a{{ |)
	TO c1  TO r1  TO a{{
        0e  r1 0 ?DO  c1 0 ?DO  a{{ J I }} F@  FSQUARE  F+  LOOP LOOP  FSQRT ;

\ Initialize all matrix elements of A to the number e.

: fillmat ( 'A r c fval -- )
        ( LOCALS| c1 r1 a{{ |)
[ fp-stack? invert ] [IF] 2>R [THEN] 
        TO c1  TO r1  TO a{{  
[ fp-stack? invert ] [IF] 2R> [THEN]
        r1 0 DO  c1 0 DO FDUP a{{ J I }} F! LOOP LOOP FDROP ;

\ solve ( 'A 'X 'Y MaxSteps n -- steps ) ( F: MaxError -- err cnv )
\ Returns the solution X to A*X=Y, where A is an n x m coefficient
\ matrix, X is m x 1 , and Y is n x 1 , with m <= n.
\ If m < n, solve returns an X that represents a least squares fit through
\ all data points Y (n x 1). Again, A and Y are kept intact.
\ Solve is able to solve sets of equations that are nearly singular, using a
\ successive, automatic, refinement method. Refinement is done by passing in
\ an X that is a good guess to the wanted solution vector. If you have no
\ idea of the solution, use a zero-filled X.
\ The maximum number of iterations is controlled with MaxSteps.
\ Iteration stops when the error, measured by the norm of (A*X-Y),
\ is less than MaxError; the final error is returned on the stack
\ as  err .  The norm of the last correction to X is returned
\ as  cnv .  The boolean  bad?  is false if a solution is reached,
\ +1 if m > n , and +2 if a matrix inversion failed.
\ After a suggestion of Dr. Jos Bergervoet, personal communication.
\ Solve is more powerful than mprove (Press et al).

Private:

FLOAT DMATRIX At{{
FLOAT DMATRIX qd{{
FLOAT DMATRIX Q{{
FLOAT DMATRIX QAt{{
FLOAT DMATRIX Ax{{
FLOAT DMATRIX dif{{
FLOAT DMATRIX delta{{

FVARIABLE maxerror

0 VALUE iters
0 VALUE MaxSteps
0 VALUE m
0 VALUE n
0 ptr y{{
0 ptr x{{
0 ptr A{{

\ Do not forget to zero-fill X when you have no idea of the solution at all!

Public:

: solve \ ( 'A 'X 'Y n m MaxSteps fmaxerror -- ferror fconvergence steps bad? )
        maxerror F!
        1 ( LOCALS| iters MaxSteps m n y{{ x{{ A{{ |)
	TO iters  TO MaxSteps  TO m  TO n  TO y{{  TO x{{  TO A{{
        n m < IF -1 1  1e38 1e38 EXIT THEN

        A{{  n m  & At{{   transpose
        At{{ m n  A{{ n m  & Q{{   mat*         \ Q is (m x m)

        Q{{ m mat^-1                            \ Q <- (At*A)^-1
           IF  & Q{{  }}free
               & At{{ }}free                    \ mat^-1 failed.
              -1 2 1e38 1e38 EXIT
         THEN

        Q{{ m m  At{{ m n  & QAt{{ mat*         \ QAt <- (A*At)^-1 * At

        & Q{{ }}free  & At{{ }}free

        BEGIN
           A{{ n m      x{{ m 1  & Ax{{    mat*
           y{{ n 1     Ax{{ n 1  & dif{{   mat-
           QAt{{ m n  dif{{ n 1  & delta{{ mat*
           delta{{ m 1  x{{ m 1  mat+!

           dif{{ n 1 }}absmat maxerror F@ F>
           iters MaxSteps < AND
        WHILE
           & delta{{ }}free   & dif{{ }}free   & Ax{{ }}free
           iters 1+ TO iters
  
      REPEAT

          dif{{ n 1 }}absmat ( error)
        delta{{ m 1 }}absmat ( convergence)
        iters                ( steps taken)

        & QAt{{ }}free  &    Ax{{ }}free
        & dif{{ }}free  & delta{{ }}free
        0 ;


BASE !
END-MODULE

TEST-CODE? [IF] \ ---------------------------------------------------------
[undefined] T{      [IF]  include ttester.4th  [THEN]    
[undefined] CompareArrays [IF] include fsl/fsl-test-utils.4th [THEN]
[undefined] hilbert [IF]  include fsl/hilbert.4th  [THEN]
BASE @ DECIMAL
    
\ Read ahead in a text file. This doesn't work with a terminal.
\ A nice feature: the read text is interpreted, so { 1e 2e F+ } is valid.
\ Data starts on the _next_ line.

: READ-INFILE   REFILL 0= ABORT" REFILL :: not possible"
                SOURCE EVALUATE ;

\ Read a matrix (won't work from the terminal). The matrix head passed
\ should be empty (free the contents first). The reading starts on the next
\ line of the text file.
\ Example:  FLOAT MATRIX A{{    & A{{ 55 20 }}FREAD
\                               ...
\                               & A{{ }}free
\                               & A{{ 5 2 }}FREAD
\
\                               ....
0 VALUE cols
0 VALUE rows
0 ptr m{{	    
: }}FREAD ( 'head rows cols -- )
        ( LOCALS| cols rows m{{ |)
	TO cols  TO rows  TO m{{
        m{{ rows cols }}malloc  malloc-fail? ABORT" }}FREAD failed"
        m{{ EXECUTE TO m{{
        rows
        0 ?DO   READ-INFILE ( coefficients)
                0 cols 1- DO  m{{ J I }} F!  -1 +LOOP
         LOOP
        REFILL 0= ABORT" REFILL :: not possible" ; nondeferred

\ Let's use it

FLOAT DMATRIX A{{  & A{{ 3 3 }}FREAD    This field is not read...
    1e   8e  -7e
    2e  -3e   4e
    3e   7e   1e

FLOAT DMATRIX B{{  & B{{ 3 2 }}FREAD    Solution vectors for A X = B given below
     0e  12e
    16e   4e  
    32e  24e

FLOAT DMATRIX x0{{  & x0{{ 3 1 }}FREAD    first solution
    5e
    2e
    3e

FLOAT DMATRIX x1{{  & x1{{ 3 1 }}FREAD    second solution
    3e
    2e
    1e
    
FLOAT DMATRIX C{{  
FLOAT DMATRIX D{{
FLOAT DMATRIX I{{


FLOAT DMATRIX oldA{{
FLOAT DMATRIX oldB{{
FLOAT DMATRIX oldC{{
    
FLOAT DMATRIX rowA{{
FLOAT DMATRIX rowB{{    
FLOAT DMATRIX colA{{
FLOAT DMATRIX colB{{    


0 ptr m{{
: IdentityMatrix ( 'head N -- | allocate and initialize an NxN identity matrix)
    2DUP 2>R
    DUP }}malloc  malloc-fail? ABORT" }}IdentityMatrix failed"
    2R> SWAP EXECUTE TO m{{
    m{{ OVER DUP  0e fillmat
    0 ?DO 1e m{{ I I }} F!  LOOP ;


CR
TESTING  GET-ROW  GET-COLUMN  TRANSPOSE 

set-exact

( GET-ROW : Should be [1,8,-7] )
t{  A{{ 3 3  & rowA{{  0  get-row  ->  rowA{{ 1 3  }t
t{  rowA{{ 0 0 }} F@  rowA{{ 0 1 }} F@  rowA{{ 0 2 }} F@ -> 1e 8e -7e rrr}t
t{  & rowA{{ }}free  ->  }t

( GET-COLUMN : Should be [8,-3,7]^T)
t{  A{{ 3 3  & colA{{ 1 get-column  -> colA{{ 3 1  }t
t{  colA{{ 0 0 }} F@  colA{{ 1 0 }} F@  colA{{ 2 0 }} F@ -> 8e -3e 7e rrr}t

( TRANSPOSE : Should be [8,-3,7])
t{  colA{{ 3 1  & rowA{{ transpose  ->  }t
t{  rowA{{ 0 0 }} F@  rowA{{ 0 1 }} F@  rowA{{ 0 2 }} F@ -> 8e -3e 7e rrr}t
t{  & rowA{{ }}free  & colA{{ }}free  ->  }t


TESTING  MAT-  MAT+  }}ABSMAT  MAT+!  MAT^-1  MAT*

1e-15 rel-near F!
1e-15 abs-near F!
set-near

( Matrix A - Matrix B --> Matrix C )
t{  A{{ 3 3  & rowA{{ 0  get-row  ->  rowA{{ 1 3  }t
t{  A{{ 3 3  & rowB{{ 1  get-row  ->  rowB{{ 1 3  }t
t{  rowA{{ 1 3  rowB{{ 1 3  & C{{ mat-  ->  }t
t{  C{{ 0 0 }} F@  C{{ 0 1 }} F@  C{{ 0 2 }} F@ ->  -1e 11e -11e rrr}t
t{  & rowA{{ }}free  & rowB{{ }}free  & C{{ }}free  ->  }t

( Matrix A + Matrix B --> Matrix C )
t{  A{{ 3 3  & rowA{{ 1  get-row  ->  rowA{{ 1 3  }t
t{  A{{ 3 3  & rowB{{ 2  get-row  ->  rowB{{ 1 3  }t
t{  rowA{{ 1 3  rowB{{ 1 3  & C{{ mat+  ->  }t
t{  C{{ 0 0 }} F@  C{{ 0 1 }} F@  C{{ 0 2 }} F@ ->  5e 4e 5e rrr}t

( The length of vector C )
t{  C{{ 1 3 }}absmat  -> 66e fsqrt  r}t

( C + [33,44,55] )
t{  33e rowA{{ 0 0 }} F!  44e rowA{{ 0 1 }} F!  55e rowA{{ 0 2 }} F!  ->  }t
t{  rowA{{ 1 3  C{{ 1 3 mat+!  ->  }t
t{  C{{ 0 0 }} F@  C{{ 0 1 }} F@  C{{ 0 2 }} F@ -> 38e 48e 60e  rrr}t
t{  & C{{  }}free    ->  }t
t{  & rowA{{ }}free  ->  }t
t{  & rowB{{ }}free  ->  }t

( Invert the 5x5 Hilbert matrix using MAT^-1 )
1e-11 rel-near F!
1e-11 abs-near F!
set-near
t{  & C{{ 5 5 }}malloc  malloc-fail?  ->  0  }t
t{  C{{ 5 hilbert  ->      }t
t{  & oldC{{ 5 5 }}malloc  malloc-fail?  -> 0 }t
t{  C{{ oldC{{ 5 5 }}fcopy  ->  }t       \ Keep a copy of original C
t{  C{{ 5 mat^-1   ->  0   }t            \ C is replaced by its inverse
t{  & D{{ 5 5 }}malloc  malloc-fail?  ->  0  }t
t{  D{{ 5 hilbert-inv  ->  }t            \ D is reference matrix
5 5 CompareMatrices C{{ D{{
t{  & D{{ }}free  ->  }t

( Verify the inverse matrix above by multiplication: C C^-1 = I )
t{  & I{{ 5  IdentityMatrix  ->  }t
t{  oldC{{ 5 5  C{{ 5 5  & D{{  mat*  ->  }t
5 5 CompareMatrices  D{{  I{{
t{  & C{{ }}free  & D{{ }}free  & oldC{{ }}free  & I{{ }}free  ->  }t


TESTING GAUSSJ  SOLVE

1e-15 rel-near F!
1e-15 abs-near F!
set-near

( Keep a copy of the original A and B matrices )
t{  & oldA{{ 3 3 }}malloc  A{{ oldA{{ 3 3 }}fcopy  ->  }t
t{  & oldB{{ 3 2 }}malloc  B{{ oldB{{ 3 2 }}fcopy  ->  }t
    
( Use GAUSSJ to solve the two sets of linear equations, A X = B )
( Each set has three equations and three unknowns )
t{  A{{ B{{ 3 2 gaussj ->  0 }t

( Verify the two solution vectors, X, which have been placed in B )
t{  B{{ 3 2  & colB{{ 0 get-column  ->  colB{{ 3 1  }t
3 1 CompareMatrices  colB{{  x0{{
t{  & colB{{ }}free  ->  }t

t{  B{{ 3 2  & colB{{ 1 get-column  ->  colB{{ 3 1  }t
3 1 CompareMatrices  colB{{  x1{{
t{  & colB{{ }}free  ->  }t
    
( Verify that GAUSSJ replaced A with its inverse:  A A^-1 = I )
t{  & I{{ 3  IdentityMatrix  ->  }t
t{ oldA{{ 3 3  A{{ 3 3  & C{{  mat*  ->  }t
3 3 CompareMatrices  C{{  I{{
t{ & C{{ }}free  & I{{ }}free  ->  }t

( Compute X by taking the product A^-1 B, and verify )
( A^-1 B{{ ..,0 }} )
t{  oldB{{ 3 2  & colA{{ 0 get-column  ->  colA{{ 3 1  }t
t{  A{{ 3 3  colA{{ 3 1  & C{{ mat*  ->  }t
3 1 CompareMatrices C{{ x0{{
t{  & C{{ }}free  & colA{{ }}free  ->  }t

( A^-1 B{{..,1 }} )
t{  oldB{{ 3 2  & colA{{ 1 get-column  ->  colA{{ 3 1  }t
t{  A{{ 3 3  colA{{ 3 1  & C{{ mat*  ->  }t
3 1 CompareMatrices C{{  x1{{
t{  & C{{ }}free  & colA{{ }}free ->  }t

( Use SOLVE to find the solution vectors, one at a time, and verify )
variable result
t{  & C{{ 3 1 }}malloc  ->  }t

( Solve first set of equations )
t{  C{{ 3 1 1e fillmat  ->  }t  \ initial guess for solution
t{  oldB{{ 3 2  & colB{{ 0 get-column  ->  colB{{ 3 1  }t
t{  oldA{{ C{{ colB{{ 3 3 10 rel-near F@ solve result ! drop f2drop  ->  }t
t{  result @  ->  0  }t
3 1 CompareMatrices  C{{  x0{{
t{  & colB{{ }}free  ->  }t

( Solve second set of equations )
t{  C{{ 3 1 1e fillmat  ->  }t  \ initial guess for solution
t{  oldB{{ 3 2  & colB{{ 1 get-column  ->  colB{{ 3 1  }t
t{  oldA{{ C{{ colB{{ 3 3 10 rel-near F@ solve result ! drop f2drop  ->  }t
t{  result @  ->  0  }t
3 1 CompareMatrices  C{{  x1{{

t{  & A{{ }}free  & B{{ }}free  & C{{ }}free  & x0{{ }}free  & x1{{ }}free ->  }t
t{  & oldA{{ }}free  & oldB{{ }}free  & colB{{ }}free ->  }t

( Use SOLVE to find a least-squares approximation through the data points in Y, )
( given a function described by the unknown coefficients in X. There are )
( more data points than unknowns, and noise is present.)
( Note that only 2 steps provide an adequate result already!)

FLOAT DMATRIX noise{{

& oldA{{ 4 3 }}fread          A X = B
     1e  0e  0e               \ 1 * x1                  =  4
     0e  1e  0e               \          1 * x2         =  5
     0e  0e  1e               \                 1 * x3  =  6
     1e  1e  1e               \ an extra row (sum of above 3!)

& oldB{{ 4 1 }}fread
     4e 
     5e 
     6e 
    15e

( The obvious solution to the above matrix equation is X = [4, 5, 6]^T )

( Add noise to coefficients matrix A )
& noise{{ 4 3 }}fread
     0e     0e     1e-16   
    -1e-15  0e     0e     
     0e     1e-17  0e      
     0e    -1e-18  0e     

t{  oldA{{ 4 3  noise{{ 4 3  & A{{ mat+  ->  }t
t{  & noise{{ }}free  ->  }t

( Add noise to B vector )
& noise{{ 4 1 }}fread
    1e-16         
   -1e-15
    5e-17
   -3e-16

t{  oldB{{ 4 1  noise{{ 4 1  & B{{ mat+  ->  }t
t{  & noise{{ }}free  ->  }t

( Set initial guess for solution; pretend to have no idea by filling with zeros)
& C{{ 3 1 }}fread
    0e
    0e
    0e

( Find the least-squares solution )
t{  A{{ C{{ B{{ 4 3  10  1e-9  solve result ! drop f2drop  ->  }t
t{  result @  ->  0  }t
3 1 CompareMatrices C{{  oldB{{

( Refine the solution in C by iterating SOLVE )
( Use old solution as initial guess, and specify smaller max error )
t{  A{{ C{{ B{{ 4 3  10  1e-16  solve result ! drop f2drop  ->  }t
t{  result @  ->  0  }t
3 1 CompareMatrices C{{  oldB{{

t{  & A{{ }}free  & B{{ }}free  & C{{ }}free  ->  }t
t{  & oldA{{ }}free & oldB{{ }}free  ->  }t

BASE !
[THEN]

