\ tridiag.4th
\
\ Tridiagonalize a square matrix using a series of Householder
\ transforms. The input matrix is replaced by its similar 
\ tridiagonal matrix.
\
\ Copyright 2022 Krishna Myneni. Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.
\
\ Glossary:
\
\   }}TRIDIAG ( N amatrix -- )
\
\ See example(s) of use in test code.
\
\ References:
\  1. Wikipedia entry on Householder transformation,
\       https://en.wikipedia.org/wiki/Householder_transformation
\ 
\  2. Wikipedia entry on matrix similarity,
\       https://en.wikipedia.org/wiki/Matrix_similarity
\
\ Requires:
\   fsl/fsl-util
\   fsl/dynmem
\   fsl/extras/mmul
\

BEGIN-MODULE
BASE @

FLOAT DMATRIX Ap{{
FLOAT DMATRIX P{{
FLOAT DARRAY  v{

fvariable alpha
fvariable 2r
0 value N
0 ptr AA{{

Public:

: }}tridiag ( N a -- )
    \ Initialization
    to AA{{ to N
    N 2- 0 <= IF EXIT THEN

    & v{ N }malloc
    & P{{ N N }}malloc
    & Ap{{ N N }}malloc
    malloc-fail? IF 1 throw THEN
 
    N 2- 0 DO
      0.0e0 N I 1+ DO  AA{{ I J }} f@ fsquare f+ LOOP fsqrt
      AA{{ I 1+ I }} f@ f0< IF fnegate THEN fnegate fdup alpha f!
      fdup AA{{ I 1+ I }} f@ f- f* 2.0e0 f* fsqrt 2r f!
      \ Find reflection plane normal vector, v{
      I 1+ 0 DO 0.0e0 v{ I } f! LOOP
      AA{{ I 1+ I }} f@ alpha f@ f- 2r f@ f/ v{ I 1+ } f!
      N I 2+ DO  AA{{ I J }} f@     2r f@ f/ v{ I } f!  LOOP
      \ Find similarity transform matrix, P{{, for reflection about plane
      N 0 DO
        N 0 DO
          v{ J } f@ v{ I } f@ f* 2.0e0 f* fnegate
          I J = IF 1.0e0 f+ THEN P{{ J I }} f!
        LOOP
      LOOP
      \ Apply similarity transformation to matrix, AA{{
      AA{{  P{{ Ap{{ N N N df_mmul
      P{{  Ap{{ AA{{ N N N df_mmul
    LOOP
    
    \ cleanup
    & Ap{{ }}free
    & P{{  }}free
    & v{  }free  
;

BASE !
END-MODULE


TEST-CODE? [IF]
[UNDEFINED] T{ [IF] include ttester.4th [THEN]
BASE @ DECIMAL

1e-14 rel-near f!
1e-14 abs-near f!
set-near

\ Test case: 4 x 4 real, symmetric matrix (see ref. [1]).
4 4 FLOAT MATRIX A{{
 4e  1e -2e  2e
 1e  2e  0e  1e
-2e  0e  3e -2e
 2e  1e -2e -1e
4 4 A{{ }}fput

CR
TESTING }}TRIDIAG
4 A{{ }}tridiag
t{ A{{ 0 0 }} f@  ->  4.0e0  r}t
t{ A{{ 0 1 }} f@  -> -3.0e0  r}t
t{ A{{ 0 2 }} f@  ->  0.0e0  r}t
t{ A{{ 0 3 }} f@  ->  0.0e0  r}t
t{ A{{ 1 0 }} f@  ->  A{{ 0 1 }} f@     r}t
t{ A{{ 1 1 }} f@  -> 10.0e0 3.0e0   f/  r}t
t{ A{{ 1 2 }} f@  -> -5.0e0 3.0e0   f/  r}t
t{ A{{ 1 3 }} f@  ->  0.0e0             r}t
t{ A{{ 2 0 }} f@  ->  0.0e0             r}t
t{ A{{ 2 1 }} f@  ->  A{{ 1 2 }} f@     r}t
t{ A{{ 2 2 }} f@  -> -33.0e0 25.0e0 f/  r}t
t{ A{{ 2 3 }} f@  ->  68.0e0 75.0e0 f/  r}t
t{ A{{ 3 0 }} f@  ->  0.0e0             r}t
t{ A{{ 3 1 }} f@  ->  0.0e0             r}t
t{ A{{ 3 2 }} f@  ->  A{{ 2 3 }} f@     r}t
t{ A{{ 3 3 }} f@  ->  149.0e0 75.0e0 f/ r}t

BASE !
[THEN]

