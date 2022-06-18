\ rsymm-01.4th
\
\ Find eigenvalues of a real symmetric matrix by
\ tridiagonalizing the matrix and using the implict
\ QL reduction method, using an EISPACK "path" [1].
\ 
\ K. Myneni, 2022-06-16
\
\ Revisions:
\   2022-06-18 renamed tred1-ex01.4th to rsymm-01.4th
\
\ References:
\  1. Matrix Eigensystem Routines -- EISPACK Guide, 2nd ed.,
\     B.T. Smith, J.M. Boyle, B.S. Garbow, Y. Ikebe, V.C. Klema,
\     and C.B. Moler, ISBN 0-387-07546-1, Springer-Verlag, 1976;
\     see sections 2.1.12 and 2.2.3.

include ans-words
include modules
include fsl/fsl-util
include eispack/tred1 
include eispack/imtql1

cr
.(  All eigenvalues of 4 x 4 real symmetric matrix ) cr cr
.(     4  1 -2  2  ) cr
.(     1  2  0  1  ) cr
.(    -2  0  3 -2  ) cr
.(     2  1 -2 -1  ) cr   

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
4 diag{ subdiag{ imtql1 dup
[IF]
cr .( IMTQL1 Error ) . cr
[ELSE]
drop
cr .( Eigenvalues: ) 4 diag{ }fprint cr
[THEN]






