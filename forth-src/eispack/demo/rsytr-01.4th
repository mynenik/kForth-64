\ rsytr-01.4th
\
\ Find all eigenvalues and eigenvectors of a real symmetric
\ tridiagonal matrix using the implict QL reduction method,
\ per recommended EISPACK path [1].
\
\ K. Myneni, 2022-06-18
\
\ References:
\  1. Matrix Eigensystem Routines -- EISPACK Guide, 2nd ed.,
\     B.T. Smith, J.M. Boyle, B.S. Garbow, Y. Ikebe, V.C. Klema,
\     and C.B. Moler, ISBN 0-387-07546-1, Springer-Verlag, 1976;
\     see section 2.1.15.
\
include ans-words
include modules
include fsl/fsl-util
include eispack/imtql2

cr .( All eigenvalues and eigenvectors of real)
cr .( symmetric tridiagonal 3x3 matrix.) cr 
cr .(   0    1     0  )
cr .(   1    0   sqrt2)
cr .(   0  sqrt2   0  ) cr

3 FLOAT ARRAY d{       \ input: diagonal     output: eigenvalues
3 FLOAT ARRAY s{       \ input: subdiagonal  output: none
3 3 FLOAT MATRIX z{{   \ input: identity     output: eigenvectors

2.0e0 fsqrt fconstant sqrt2

\ Diagonal elements are zero for this example.
\ First element of subdiagonal array is always set to zero.
0.0e0 0.0e0 0.0e0 3 d{ }fput
0.0e0 1.0e0 sqrt2 3 s{ }fput

1.0e0 0.0e0 0.0e0
0.0e0 1.0e0 0.0e0
0.0e0 0.0e0 1.0e0
3 3 z{{ }}fput     \ identity matrix on input

3 3 d{ s{ z{{ imtql2
?dup [IF]
cr .( IMTQL2 Error ) . cr
[ELSE]
cr .( Eigenvalues: ) 3 d{ }fprint cr
cr .( Eigenvectors: ) cr
3 3 z{{ }}fprint cr
[THEN]

