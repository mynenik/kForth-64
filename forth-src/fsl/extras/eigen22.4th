\ eigen22.4th
\
\ Compute the eigenvalues and eigenvectors of a real 2x2 matrix.
\ 
\ Notes:
\
\  1. Even though the input matrix is real, the eigenvalues are
\     complex, in general. The complex eigenvalues are returned.
\
\ Requires:
\   fsl-util
\   complex
\   quadratic
\
\ Revisions:
\   2012-04-07  km  Use KM/DNW modules interface over original FSL modules.
\
\ Copyright (c) 2010 Krishna Myneni
\
\ Permission is granted to use this code for any purpose, provided
\ the above copyright notice is retained.
\
BASE @
DECIMAL

Begin-Module

Private:

zvariable lambda1
zvariable lambda2

Public:

\ Return the complex eigenvalues of a real 2x2 matrix
: }}feigenvalues22 ( 'mat -- lambda1 lambda2 )
    >r
    1e
    r@ 0 0 }} F@  r@ 1 1 }} F@  F+ fnegate
    r@ 0 0 }} F@  r@ 1 1 }} F@  F* 
    r@ 0 1 }} F@  r> 1 0 }} F@  F* F-
    solve_quadratic
    zover lambda1 z!  zdup lambda2 z!
;

Private:

2 2 COMPLEX MATRIX ev{{  \ eigenvector matrix

Public:

\ Compute and place the two normalized eigenvectors in the 
\ columns of ev{{ ;  use only after finding eigenvalues
: }}feigenvectors22 ( 'mat  -- ) 
	>r
	\ Compute eigenvector for lambda1
	r@ 0 1 }} F@  r@ 0 0 }} F@ lambda1 F@ F- F/ fnegate
	ev{{ 0 0 }} F! 	1e ev{{ 1 0 }} F!
	
	\ Compute eigenvector for lambda2
	r@ 0 1 }} F@  r> 0 0 }} F@ lambda2 F@ F- F/ fnegate
	ev{{ 0 1 }} F!  1e ev{{ 1 1 }} F!

	\ Normalize the vectors
	ev{{ 0 0 }} f@  ev{{ 1 0 }} f@ |z|
	ev{{ 0 0 }} f@  fover f/  ev{{ 0 0 }} f!
	ev{{ 1 0 }} f@  fswap f/  ev{{ 1 0 }} f!
	ev{{ 0 1 }} f@  ev{{ 1 1 }} f@ |z|
	ev{{ 0 1 }} f@  fover f/  ev{{ 0 1 }} f!
	ev{{ 1 1 }} f@  fswap f/  ev{{ 1 1 }} f!
;

\ Return the eigenvalues and compute the eigenvectors;
\   input matrix columns are replaced by its eigenvectors.
: }}feigen22 ( 'mat -- lambda1 lambda2  )
      dup >r }}feigenvalues22  r@ }}feigenvectors22
      ev{{ r> 2 2 }}fcopy
;


End-Module
BASE !

TEST-CODE? [IF]  \ ---------------------------------------------
[undefined] T{ [IF] s" ttester.4th" included [THEN]
[undefined] }}fput [IF] s" array-utils0.4th" included [THEN]
BASE @
DECIMAL

: zz}t  rrrr}t ;
: }}22ev1 ( 'mat -- r1 r2 ) dup >r 0 0 }} f@ r> 1 0 }} f@ ;
: }}22ev2 ( 'mat -- r1 r2 ) dup >r 0 1 }} f@ r> 1 1 }} f@ ;
 
1e 2e f/ fsqrt  fconstant  1/sqrt{2}
3e 3e fsqrt f*  fconstant  3*sqrt{3}

2 2 FLOAT MATRIX m{{

1e-15 rel-near F!
1e-15 abs-near F!
set-near

TESTING  }}FEIGENVALUES22
 -1e 0e
  0e 1e
2 2 m{{ }}fput
t{  m{{ }}feigenvalues22 ->  1e 0e -1e 0e zz}t

  0e 1e
  1e 0e
2 2 m{{ }}fput
t{  m{{ }}feigenvalues22 -> 1e 0e -1e 0e  zz}t

  2e 1e
  1e 2e
2 2 m{{ }}fput
t{  m{{ }}feigenvalues22  ->  1e 0e  3e 0e  zz}t 

TESTING }}FEIGEN22
  0e 1e
  1e 0e
2 2 m{{ }}fput
t{  m{{ }}feigen22  ->  1e 0e -1e 0e zz}t
t{  m{{ }}22ev1  ->  1/sqrt{2} 1/sqrt{2}  rr}t
t{  m{{ }}22ev2  ->  1/sqrt{2} fnegate 1/sqrt{2} rr}t

  2e 1e
  1e 2e
2 2 m{{ }}fput
t{  m{{ }}feigen22  ->  1e 0e  3e 0e  zz}t
t{  m{{ }}22ev1  ->  1/sqrt{2} fnegate 1/sqrt{2}  rr}t
t{  m{{ }}22ev2  ->  1/sqrt{2} 1/sqrt{2}  rr}t

  2e -3e
  4e -5e
2 2 m{{ }}fput
t{  m{{ }}feigen22  ->  -1e 0e  -2e 0e  zz}t
t{  m{{ }}22ev1  -> 1/sqrt{2}  1/sqrt{2}  rr}t
t{  m{{ }}22ev2  -> 0.6e 0.8e rr}t

  3e -9e
  4e -3e
2 2 m{{ }}fput
t{  m{{ }}feigen22  ->  0e 3*sqrt{3} zdup conjg  zz}t

BASE !
[THEN]


