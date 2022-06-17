\ htribk.4th
\
\      HTRIBK ( nm n ar ai tau m zr zi -- )
\
\     integer i,j,k,l,m,n,nm
\     double precision ar(nm,n),ai(nm,n),tau(2,n),zr(nm,m),zi(nm,m)
\     double precision h,s,si
\
\     this procedure is a translation of a complex analogue of
\     the Fortran subroutine, trbak, which is a translation of
\     the algol procedure trbak1, num. math. 11, 181-195(1968)
\     by martin, reinsch, and wilkinson.
\     handbook for auto. comp., vol.ii-linear algebra, 212-226(1971).
\
\     this subroutine forms the eigenvectors of a complex hermitian
\     matrix by back transforming those of the corresponding
\     real symmetric tridiagonal matrix determined by  htridi.
\
\     on input
\
\        nm must be set to the row dimension of two-dimensional
\          array parameters as declared in the calling program
\          dimension statement.
\
\        n is the order of the matrix.
\
\        ar and ai contain information about the unitary trans-
\          formations used in the reduction by  htridi  in their
\          full lower triangles except for the diagonal of ar.
\
\        tau contains further information about the transformations.
\
\        m is the number of eigenvectors to be back transformed.
\
\        zr contains the eigenvectors to be back transformed
\          in its first m columns.
\
\     on output
\
\        zr and zi contain the real and imaginary parts,
\          respectively, of the transformed eigenvectors
\          in their first m columns.
\
\     note that the last component of each returned vector
\     is real and that vector euclidean norms are preserved.
\
\     questions about the Fortran version and comments should
\     be directed to burton s. garbow, mathematics and computer
\     science div, argonne national laboratory
\
\     this version dated august 1983.
\     Forth version dated june 17, 2022.
\     Translated to Forth by Krishna Myneni.
\  -------------------------------------------------------------

BEGIN-MODULE

BASE @ DECIMAL

[UNDEFINED] F+! [IF]
fp-stack? [IF]
: f+! ( a -- ) ( F: r -- ) dup f@ f+ f! ;
[ELSE]
: f+! ( r a -- ) dup >r f@ f+ r> f! ;
[THEN]
[THEN]

0 value N
0 value M
0 value kk
0 value ll
0 value ll1
fvariable h
fvariable s
fvariable si
0 ptr ar{{
0 ptr ai{{
0 ptr tau{{
0 ptr zr{{
0 ptr zi{{

Public:

: htribk ( nm n ar ai tau m zr zi -- )
      to zi{{ to zr{{ to M to tau{{ to ai{{ to ar{{ to N drop
      M 0= IF  EXIT  THEN

\ transform the eigenvectors of the real symmetric
\ tridiagonal matrix to those of the hermitian
\ tridiagonal matrix
      N 0 DO
        M 0 DO
          zr{{ J I }} f@ fnegate tau{{ 1 J }} f@ f* zi{{ J I }} f!
          zr{{ J I }} f@ tau{{ 0 J }} f@ f* zr{{ J I }} f!
        LOOP
      LOOP

      N 1 = IF  EXIT  THEN

\ recover and apply the householder matrices

      N 1 DO
        I 1- to ll
        ll 1+ to ll1
        ai{{ I dup }} f@ h f!
        I to kk
        h f@ f0= invert IF
          M 0 DO
            0.0e0  s f!
            0.0e0 si f!

            ll1 0 DO
              ar{{ kk I }} f@  zr{{ I J }} f@ f*
              ai{{ kk I }} f@  zi{{ I J }} f@ f* f- s f+!
              ar{{ kk I }} f@  zi{{ I J }} f@ f*
              ai{{ kk I }} f@  zr{{ I J }} f@ f* f+ si f+! 
            LOOP

\ double divisions avoid possible underflow
            h f@ s  f@ fover f/ fswap f/ s  f!
            h f@ si f@ fover f/ fswap f/ si f!

            ll1 0 DO
              s f@ ar{{ kk I }} f@ f* si f@ ai{{ kk I }} f@ f*
              f+ fnegate zr{{ I J }} f+!
              s f@ ai{{ kk I }} f@ f* si f@ ar{{ kk I }} f@ f*  
              f- zi{{ I J }} f+! 
            LOOP
          LOOP 
        THEN
      LOOP
;

BASE !
END-MODULE

