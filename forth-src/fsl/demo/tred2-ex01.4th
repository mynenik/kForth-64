\ tred2-ex01.4th
\
\ Find eigenvalues and eigenvectors of a real symmetric
\  matrix by tridiagonalizing the matrix and using the 
\ implict QL reduction method.

include ans-words
include modules
include fsl/fsl-util
include fsl/extras/tred2
include fsl/extras/imtql2

\ 4 x 4 real symmetric matrix example

4 4 FLOAT MATRIX A{{
 4.0e0  1.0e0 -2.0e0  2.0e0
 1.0e0  2.0e0  0.0e0  1.0e0
-2.0e0  0.0e0  3.0e0 -2.0e0
 2.0e0  1.0e0 -2.0e0 -1.0e0
4 4 A{{ }}fput

4 FLOAT ARRAY diag{
4 FLOAT ARRAY subdiag{
4 4 FLOAT MATRIX ot{{

4 4 a{{ diag{ subdiag{ ot{{ tred2
4 4 diag{ subdiag{ ot{{ imtql2 . cr

cr .( Eigenvalues: ) cr
4 diag{ }fprint

cr .( Eigenvectors: ) cr
4 4 ot{{ }}fprint

