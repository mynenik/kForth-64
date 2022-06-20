\ rsymm-02.4th
\
\ Find all eigenvalues and eigenvectors of a real symmetric
\ matrix by tridiagonalizing the matrix and using the implict
\ QL reduction method, per recommended EISPACK path [1].
\
\ K. Myneni, 2022-06-16
\
\ Revisions:
\   2022-06-18 renamed tred2-ex01.4th to rsymm-02.4th
\
\ References:
\  1. Matrix Eigensystem Routines -- EISPACK Guide, 2nd ed.,
\     B.T. Smith, J.M. Boyle, B.S. Garbow, Y. Ikebe, V.C. Klema,
\     and C.B. Moler, ISBN 0-387-07546-1, Springer-Verlag, 1976;
\     see sections 2.1.11 and 2.2.3.

include ans-words
include modules
include fsl/fsl-util
include eispack/tred2
include eispack/imtql2

cr
.( All eigenvalues and eigenvectors of 4x4 real symmetric matrix.)
cr cr
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
4 4 FLOAT MATRIX ot{{

4 4 a{{ diag{ subdiag{ ot{{ tred2
4 4 diag{ subdiag{ ot{{ imtql2
?dup [IF]
cr .( IMTQL2 Error ) . cr
[ELSE]
cr .( Eigenvalues: ) 4 diag{ }fprint cr
cr .( Eigenvectors: ) cr
4 4 ot{{ }}fprint cr
[THEN]

