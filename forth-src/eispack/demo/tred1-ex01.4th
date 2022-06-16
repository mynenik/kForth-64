\ tred1-ex01.4th
\
\ Find eigenvalues of a real symmetric matrix by
\ tridiagonalizing the matrix and using the implict
\ QL reduction method.

include ans-words
include modules
include fsl/fsl-util
include eispack/tred1 
include eispack/imtql1

\ 4 x 4 real symmetric matrix example

4 4 FLOAT MATRIX A{{
 4.0e0  1.0e0 -2.0e0  2.0e0
 1.0e0  2.0e0  0.0e0  1.0e0
-2.0e0  0.0e0  3.0e0 -2.0e0
 2.0e0  1.0e0 -2.0e0 -1.0e0
4 4 A{{ }}fput 

4 FLOAT ARRAY diag{
4 FLOAT ARRAY subdiag{
4 FLOAT ARRAY subdiag2{

\ Tridiagonalize the matrix using TRED1

4 4 A{{ diag{ subdiag{ subdiag2{ tred1
4 diag{ subdiag{ imtql1 . cr \ print error code from IMTQL1
4 diag{ }fprint  \ print eigenvalues





