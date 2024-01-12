\ zeigen22h.4th
\
\ Compute eigenvalues and eigenvectors of 2x2 Hermitian matrix
\
\ A Hermitian matrix is a square complex matrix which, when conjugated 
\   and transposed, is identical to the original matrix. A Hermitian
\   matrix has *real* eigenvalues.
\
\ See Quantum Mechanics, vol. 1, 2nd ed., by Claude Cohen-Tannoudji,
\	Bernard Diu, and Franck Laloe, pp. 420--423.
\
\ Copyright (c) 2003 Krishna Myneni
\ Provided Under the GNU General Public License
\
\ Requires:
\
\	complex.4th
\	fsl-util.4th
\
\ Revisions:
\   2003-02-20  created
\   2019-10-26  revised for FSL matrices and added test code
\   2023-12-05  replace FDUP F* with FSQUARE
\
\ Usage:
\
\ Create a 2x2 complex matrix ( m{{ ), and another matrix to hold the
\   eigenvectors ( ev{{ ):
\
\	2 2 complex matrix m1{{
\	2 2 complex matrix ev{{
\
\ Put the matrix elements of the Hermitian matrix into m1, e.g.
\
\	z11   m{{ 0 0 }} z!
\	z12   m{{ 0 1 }} z!
\	z21   m{{ 1 0 }} z!
\	z22   m{{ 1 1 }} z!
\
\ where z11 ... z22 each are pairs of floating point numbers, 
\ representing a complex number. For a Hermitian matrix, the
\ diagonal elements z11 and z22 must have zero imaginary parts,
\ and the off-diagonal elements z12 and z21 must be complex
\ conjugate pairs.
\
\ Alternately, the matrix elements can all be placed at once:
\
\	z11 z12 z21 z22 2 2 m{{ }}zput
\
\ Compute and print the eigenvalues of m1:
\
\	m{{ }}eigenvalues22 
\	fswap f. f.
\
\ Compute and print the eigenvectors of m{{ :
\
\	m{{ ev{{ }}eigenvectors22
\
\ The 2 columns of ev{{ contain the 2 eigenvectors of m{{. The
\ first column is the eigenvector corresponding to the first 
\ eigenvalue.
\

[undefined] }}zput [IF]
\ store z11 ... z_nm into nxm matrix 
: }}zput ( z11 z12 ... z_nm  n m 'A -- )
      -ROT 2DUP * >R 1- SWAP 1- SWAP }} R>
      0 ?DO  DUP >R z! R> COMPLEX -  LOOP  drop ;
[THEN]

BEGIN-MODULE

BASE @ DECIMAL

: z22_root_part ( 'm -- r | intermediate step in calc)
	>r
	r@ 0 0 }} z@ real  r@ 1 1 }} z@ real  f- fsquare
	r> 0 1 }} z@ |z|^2 4e f*  f+ fsqrt
;

fvariable temp

Public:

\ Return the real eigenvalues of the 2x2 Hermitian matrix m{{ 
: }}eigenvalues22 ( 'm -- r1 r2 )
	>r
	r@ 0 0 }} z@ real  r@ 1 1 }} z@ real f+ .5e f*	
	r>  z22_root_part  .5e  f*
	fover fover f+ temp f!
	f- temp f@ ;

Private:

fvariable z22_phi2
fvariable z22_theta2

Public:

\ Compute the eigenvectors of 2x2 Hermitian matrix m1{{ and
\ place the eigenvectors in the columns of the complex matrix m2{{  
: }}eigenvectors22 ( 'm1 'm2 -- )
	>r >r
	r@ 1 0 }} z@ arg 2e f/ z22_phi2 f!
	r@ 0 0 }} z@ real r@ 1 1 }} z@ real  f-
	r> z22_root_part 
	f/ facos 2e f/ z22_theta2 f!
	z22_theta2 f@ fsin fnegate  z22_phi2 f@ fnegate polar>
	r@ 0 0 }} z!
	z22_theta2 f@ fcos  z22_phi2 f@  polar>
	r@ 1 0 }} z!
	z22_theta2 f@ fcos  z22_phi2 f@ fnegate polar>
	r@ 0 1 }} z!
	z22_theta2 f@ fsin  z22_phi2 f@  polar>
	r> 1 1 }} z! ;

BASE !
END-MODULE

TEST-CODE? [IF]  \ ---------------------------------------------
[undefined] T{ [IF] s" ttester.4th" included [THEN]
BASE @
DECIMAL

: zz}t  rrrr}t ;
: }}22ev1 ( 'mat -- r1 r2 ) dup >r 0 0 }} z@ r> 1 0 }} z@ ;
: }}22ev2 ( 'mat -- r1 r2 ) dup >r 0 1 }} z@ r> 1 1 }} z@ ;

3e  fsqrt       fconstant  sqrt{3}
13e fsqrt       fconstant  sqrt{13}
1e 2e f/ fsqrt  fconstant  1/sqrt{2}
3e sqrt{3} f*   fconstant  3*sqrt{3}


2 2 COMPLEX MATRIX m{{
2 2 COMPLEX MATRIX ev{{

fvariable zeig_eps
1e-15 zeig_eps f!

1e-15 rel-near F!
zeig_eps f@ abs-near f!
set-near

TESTING  }}EIGENVALUES22
 -1e 0e   0e 0e
  0e 0e   1e 0e
2 2 m{{ }}zput
t{  m{{ }}eigenvalues22 ->  -1e 1e rr}t

  0e 0e   1e 0e
  1e 0e   0e 0e
2 2 m{{ }}zput
t{  m{{ }}eigenvalues22 ->  -1e 1e rr}t

  2e 0e   1e 0e
  1e 0e   2e 0e
2 2 m{{ }}zput
t{  m{{ }}eigenvalues22  ->  1e 3e rr}t

TESTING  }}EIGENVECTORS22
  0e 0e   1e 0e
  1e 0e   0e 0e
2 2 m{{ }}zput
t{  m{{ ev{{ }}eigenvectors22  -> }t
t{  ev{{ }}22ev1  ->  1/sqrt{2} 0e zdup znegate zswap zz}t
t{  ev{{ }}22ev2  ->  1/sqrt{2} 0e  zdup  zz}t

  0e 0e   0e -1e
  0e 1e   0e  0e
2 2 m{{ }}zput
t{  m{{ ev{{ }}eigenvectors22  -> }t
t{  ev{{ }}22ev1  ->  -0.5e  0.5e  0.5e 0.5e  zz}t
t{  ev{{ }}22ev2  ->   0.5e -0.5e  0.5e 0.5e  zz}t

BASE !
[THEN]

