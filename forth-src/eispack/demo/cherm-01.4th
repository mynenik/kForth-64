\ cherm-01.4th
\
\ Use EISPACK to find all of the eigenvalues and eigenvectors of
\ some test complex Hermitian matrices. Display the eigenvalues
\ and corresponding eigenvectors.
\
\ For the EISPACK "path" [1] used here (htridi, imtql2, htribk),
\ the complex matrix is stored in two double precision floating
\ point matrices.
\
\ K. Myneni, 2022-06-17
\
\ Revisions:
\   2022-06-18  renamed hermitian-ex01.4th to cherm-01.4th.
\   2022-06-19  fix error handling.
\
\ Notes:
\
\  1. Uses the FSL complex arithmetic library word "Z." to print
\     numbers. For increased output precision, use "ZS.".
\
\ References
\
\  1. Matrix Eigensystem Routines -- EISPACK Guide, 2nd ed.,
\     B.T. Smith, J.M. Boyle, B.S. Garbow, Y. Ikebe, V.C. Klema,
\     and C.B. Moler, ISBN 0-387-07546-1, Springer-Verlag, 1976;
\     see sections 2.1.4 and 2.2.3.

include ans-words
include modules
include fsl/fsl-util
include fsl/complex
include eispack/htridi
include eispack/imtql2
include eispack/htribk

\ utilities to make an identity matrix and display eigenvectors.

0 value N
0 ptr mr{{
0 ptr mi{{
: }}ident ( N ar -- )
   to mr{{  to N 
   mr{{ 0 0 }} N floats erase
   N 0 ?DO 1.0e0 mr{{ I I }} f!  LOOP
;

: .evecs ( N ar ai -- )
   to mi{{  to mr{{  to N
   N 0 ?DO
     [char] [ emit I 1+ . [char] ] emit cr
     N 0 DO
       mr{{ I J }} f@ mi{{ I J }} f@ z. cr
     LOOP
   LOOP ;

cr
.( a. All eigenvalues and eigenvectors of 2 x 2 Hermitian matrix.) cr
cr
.(       3   2-i ) cr
.(      2+i   4  ) cr
cr

2 2 float matrix h2r{{
2 2 float matrix h2i{{

3.0e0 2.0e0
2.0e0 4.0e0
2 2 h2r{{ }}fput

0.0e0 -1.0e0
1.0e0  0.0e0
2 2 h2i{{ }}fput


2 2 float matrix t2{{   \ this is a 2xN matrix
2 2 float matrix z2r{{
2 2 float matrix z2i{{
2 float array diag2{
2 float array subd2{
2 float array subd2s{

\ Tridiagonalize the matrix
2 2 h2r{{ h2i{{ diag2{ subd2{ subd2s{ t2{{ htridi
2 z2r{{ }}ident
\ Find the eigenvalues
2 2 diag2{ subd2{ z2r{{ imtql2
?dup [IF]
  .( imtql2 error code ) . cr
[ELSE]
  .( Eigenvalues: ) 2 diag2{ }fprint cr
  \ Find the eigenvectors
  2 2 h2r{{ h2i{{ t2{{ 2 z2r{{ z2i{{ htribk
  .( Eigenvectors: ) cr
  2 z2r{{ z2i{{ .evecs
[THEN]

cr
.( b. All eigenvalues and eigenvectors of 3 x 3 Hermitian matrix.) cr
cr
.(      1   i  2+i  ) cr
.(     -i   2  1-i  ) cr
.(    2-i  1+i  2   ) cr
cr

3 3 float matrix h3r{{
3 3 float matrix h3i{{

1.0e0  0.0e0  2.0e0
0.0e0  2.0e0  1.0e0
2.0e0  1.0e0  2.0e0
3 3 h3r{{ }}fput

 0.0e0  1.0e0  1.0e0
-1.0e0  0.0e0 -1.0e0
-1.0e0  1.0e0  0.0e0
3 3 h3i{{ }}fput

2 3 float matrix t3{{    \ this is a 2xN matrix
3 3 float matrix z3r{{
3 3 float matrix z3i{{
3 float array diag3{
3 float array subd3{
3 float array subd3s{

3 3 h3r{{ h3i{{ diag3{ subd3{ subd3s{ t3{{ htridi
3 z3r{{ }}ident
3 3 diag3{ subd3{ z3r{{ imtql2
?dup [IF]
  .( imtql2 error code ) . cr
[ELSE]
  .( Eigenvalues: ) 3 diag3{ }fprint cr
  3 3 h3r{{ h3i{{ t3{{ 3 z3r{{ z3i{{ htribk
  .( Eigenvectors: ) cr
  3 z3r{{ z3i{{ .evecs
[THEN]


