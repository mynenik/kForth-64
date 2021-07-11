\ eigen33.4th
\
\ Eigenvalues and eigenvectors for a 3x3 matrix.
\
\ Requires:
\
\   ans-words.4th
\   struct.4th
\   fsl/fsl-util.4th
\   fsl/dynmem.4th
\   fsl/extras/vector.4th
\   fsl/complex.4th
\   fsl/cubic.4th
\   fsl/lufact.4th
\   fsl/backsub.4th
\
\ Revisions:
\   2012-04-07  km  Use KM/DNW's modules framework.

BASE @
DECIMAL

Begin-Module

\ Some helper words

\ Round fp value to u significant digits

variable power

: power-of-ten ( f -- n | return power of ten factor which scales f such that 0<|f'|<10)
    0 power !
    FDUP  F0=   IF FDROP 0 EXIT THEN
    FABS  FDUP 1e F<
    IF    BEGIN  10e F* -1 power +! FDUP  1e F>=  UNTIL
    ELSE  FDUP 10e F>=    
      IF  BEGIN  10e F/  1 power +! FDUP 10e F<   UNTIL  THEN  
    THEN  FDROP power @ ;

: significant-digits ( f u -- f' | round to u significant decimal digits )
    >R FDUP power-of-ten R> 1- ABS 1 MAX SWAP - DUP >R s>f 10e FSWAP F** 
    F* FROUND R> NEGATE s>f 10e FSWAP F** F* ;

Public:
  
: cpoly33 ( 'A -- a b c | compute coefficients of the characteristic polynomial for 3x3 matrix) 
    >R
    R@ 0 0 }} F@  R@ 1 1 }} F@  R@ 2 2 }} F@ F+ F+ FNEGATE     \ a
    R@ 0 0 }} F@  R@ 1 1 }} F@ F*
    R@ 1 1 }} F@  R@ 2 2 }} F@ F* F+
    R@ 0 0 }} F@  R@ 2 2 }} F@ F* F+
    R@ 1 2 }} F@  R@ 2 1 }} F@ F* F-
    R@ 0 1 }} F@  R@ 1 0 }} F@ F* F-
    R@ 0 2 }} F@  R@ 2 0 }} F@ F* F-                           \ b
    R@ 0 0 }} F@  R@ 1 2 }} F@ F*  R@ 2 1 }} F@ F*
    R@ 0 1 }} F@  R@ 1 0 }} F@ F*  R@ 2 2 }} F@ F* F+
    R@ 0 2 }} F@  R@ 1 1 }} F@ F*  R@ 2 0 }} F@ F* F+
    R@ 0 0 }} F@  R@ 1 1 }} F@ F*  R@ 2 2 }} F@ F* F-
    R@ 0 1 }} F@  R@ 1 2 }} F@ F*  R@ 2 0 }} F@ F* F-
    R@ 0 2 }} F@  R@ 1 0 }} F@ F*  R@ 2 1 }} F@ F* F-          \ c
    R> DROP
;

3 FLOAT array lambda{

: lambda33 ( 'A -- flag | compute eigenvalues of 3x3 real matrix; lambdas in z1,z2,z3)
    >R
    R@ cpoly33  cubic-roots
    R> drop
    \ store real parts of eigenvalues in the array lambda{
    z1 z@ FDROP lambda{ 0 } F!
    z2 z@ FDROP lambda{ 1 } F!
    z3 z@ FDROP lambda{ 2 } F!
;

Private:

3 3 FLOAT matrix  A'{{
LUMATRIX  lu3 

3 FLOAT array  b{
3 FLOAT array  y{
3 FLOAT array  w{
3 FLOAT array  z{
3 FLOAT array  zold{

Public:

\ The normalized eigenvectors

3 3 FLOAT MATRIX  e{{

FVARIABLE tol
1e-4 tol F!         \ tolerance for eigenvector components

: ?converged ( -- flag | check for convergence of iterated eigenvector solution z{ )
     3 0 DO
       zold{ i } F@ FABS  z{ i } F@ FABS  FOVER F- FABS FSWAP 
       FDUP F0> IF  F/ tol F@ F<  ELSE  FDROP  FDROP TRUE  THEN 
     LOOP 
     AND AND ;

VARIABLE icount
100 CONSTANT MAX_ITER

: eig33 ( 'A -- | compute eigenvalues and eigenvectors of 3x3 matrix )
    dup lambda33
    IF      \ all 3 eigenvalues are real
      lu3 3 lu-malloc
      3 0 DO
        DUP A'{{ 3 3 }}fcopy
	lambda{ i } F@ 4 significant-digits   \ round lambda to 4 significant digits
        3 0 DO  A'{{ i i }} F@ FOVER F- A'{{ i i }} F!  LOOP
	FDROP

	\ Check for zero diagonal elements on A'{{ -- if so, replace with small finite value

	3 0 DO  A'{{ i i }} F@ FABS tol F@ F< IF tol F@ A'{{ i i }} F! THEN  LOOP

        A'{{ lu3 lufact
	lu3 b{ backsub-init drop

        \ Begin iterative solution of eigenvector

        1e 1e 1e  3 y{ }fput 
	0e 0e 0e  3 z{ }fput
	0 icount !
        BEGIN
	  z{ zold{ 3 }fcopy
	  y{ b{ 3 }fcopy  3 solve-Ux=y  b{ w{ 3 }fcopy   \ Uw = y; solve for w
	  w{ z{ 3 }fcopy  3 z{ vnorm
	  z{ b{ 3 }fcopy  3 solve-Ly=b  b{ y{ 3 }fcopy   \ Ly = z; solve for y
	  1 icount +!
	  icount @ MAX_ITER >=  ABORT" *** CONVERGENCE FAILED *** "
	  ?converged	  
        UNTIL
        \ CR 3 z{ }fprint
	3 0 DO  z{ I } F@ e{{ I J }} F!  LOOP
      LOOP
      DROP
      lu3 lu-free 
    ELSE
      DROP TRUE ABORT" Complex eigenvalues! We can't deal with them yet."
    THEN
;

End-Module
BASE !

\ Test case

TEST-CODE?
[IF]
[undefined] T{      [IF]  include ttester.4th  [THEN]
DECIMAL

1e-14 rel-near F!
1e-14 abs-near F!
set-near
3 3 FLOAT matrix  A{{

2e  1e  0e 
1e  3e  1e
0e  1e  4e 

3 3 A{{ }}fput

\ CR .( The test matrix is: ) CR
\ 3 3 A{{ }}fprint

TESTING lambda33 
A{{ lambda33 drop
t{ z1 z@  fdrop  ->   1.26794919243112e  r}t
t{ z2 z@  fdrop  ->   4.73205080756888e  r}t 
t{ z3 z@  fdrop  ->   3e                 r}t

1e-4 rel-near F!
1e-4 abs-near F!
\ CR CR .( The corresponding eigenvectors are: ) CR
TESTING eig33
A{{ eig33
\ First eigenvector
t{ e{{ 0 0 }} F@  ->  -0.788675134594813e  r}t
t{ e{{ 1 0 }} F@  ->   0.577350269189626e  r}t
t{ e{{ 2 0 }} F@  ->  -0.211324865405187e  r}t

\ Second eigenvector
t{ e{{ 0 1 }} F@  ->   0.211324865405187e  r}t
t{ e{{ 1 1 }} F@  ->   0.577350269189626e  r}t
t{ e{{ 2 1 }} F@  ->   0.788675134594813e  r}t

\ Third eigenvector
t{ e{{ 0 2 }} F@  ->  -0.577350269189625e  r}t
t{ e{{ 1 2 }} F@  ->  -0.577350269189626e  r}t
t{ e{{ 2 2 }} F@  ->   0.577350269189626e  r}t
 
[THEN]
