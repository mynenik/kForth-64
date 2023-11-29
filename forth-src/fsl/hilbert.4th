\ HILBERT      Hilbert matrix routines

\ Forth Scientific Library Algorithm #25

\ HILBERT      Generates a finite segment of a Hilbert Matrix
\ HILBERT-INV  generates the inverse of a finite segment of a Hilbert
\              Matrix (ACM #50)
\ HILBERT-DET  calculates the determinant for a Hilbert matrix of a given order


\ These matrices provide severe test cases for matrix inverters and determinant
\ calculation routines.  They become numerically ill-conditioned even for
\ moderate sizes of 'n'.

\ This is an ANS Forth program requiring:
\      1. *** This is the integrated data/fp stack version 
\      2. The word 'S>F' to convert an integer to a float
\      3. The word '}}' to dereference a two-dimensional array.
\      4. The test code Uses '}}malloc' and '}}free' to allocate and
\         release memory for dynamic matrices ( 'DMATRIX' ).
\      5. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset


\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6


\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.

\ Revisions:
\    2007-09-22  km; replaced test code with automated tests
\    2007-10-27  km; save base, switch to decimal, and restore base
\    2021-05-15  km; update for separate fp stack and convert to module

CR .( HILBERT           V1.2           15 May     2021   EFC )

BEGIN-MODULE

BASE @ DECIMAL
0 ptr h{{

Public:

\ Make a n x n Hilbert matrix; store in matrix with address &h
: HILBERT ( &h n -- )  
    swap to h{{
    DUP 0 DO
	DUP 0 DO
	    1.0E0 I J + 1+ S>F F/
	    h{{ I J }} F!
	LOOP
    LOOP
    DROP ;

Private:
0 ptr hinv{{
0 value hn

Public:

\ Compute inverse of Hilbert matrix;
\ store inverse in matrix with address &s
: HILBERT-INV ( &s n -- )
    to hn  to hinv{{
    hn DUP * S>F FDUP hinv{{ F!
    
    hn 1 ?DO                \ do diagonals
	hn DUP I + SWAP I - *   S>F
        I DUP *    S>F F/
	FSQUARE F*
	FDUP hinv{{ I I }} F!
    LOOP
    FDROP

    hn 1- 0 ?DO                \ do off-diagonals
	hn I 1+ DO
	    hn DUP  I +  SWAP I - * S>F
            I DUP * S>F F/ FNEGATE
            hinv{{ J I 1- }} F@ F*
            hinv{{ J I }} F!
	LOOP
    LOOP

    hn 1 ?DO                  \ normalize
	I 1+ 0 DO
	    I J + 1+ S>F
            hinv{{ I J }} DUP >R F@ FSWAP F/
            FDUP R> F!
            hinv{{ J I }} F!
	LOOP
    LOOP ;

\ Calculates determinant of n order matrix.
\ The actual matrix is implicit
: HILBERT-DET ( n -- det )
    to hn
    1.0E0  1.0E0
    hn 0 DO
	hn 0 DO
	    I J < IF   \ numerator accumulation
		I J - S>F FSQUARE FROT F* FSWAP
	    THEN

	    I J + 1+ S>F F*    \ denominator accumulation
	LOOP
    LOOP
    F/ ;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]    
[undefined] CompareMatrices [IF] include fsl-test-utils.4th [THEN]
BASE @ DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

0.5e     fconstant  1/2
1e 3e f/ fconstant  1/3
0.25e    fconstant  1/4
0.2e     fconstant  1/5
1e 6e f/ fconstant  1/6
1e 7e f/ fconstant  1/7


4 4 FLOAT MATRIX results-for-4{{
       1e      1/2      1/3     1/4
       1/2     1/3      1/4     1/5
       1/3     1/4      1/5     1/6
       1/4     1/5      1/6     1/7
4 4 results-for-4{{ }}fput


4 4 FLOAT MATRIX invresults-for-4{{ 
       16e  -120e   240e  -140e
      -120e  1200e -2700e  1680e
       240e -2700e  6480e -4200e
      -140e  1680e -4200e  2800e
4 4 invresults-for-4{{ }}fput


FLOAT DMATRIX s{{

CR
TESTING HILBERT  HILBERT-INV  HILBERT-DET 
t{ & s{{ 4 4 }}malloc ->   }t
t{ malloc-fail?       -> 0 }t
t{ s{{ 4 HILBERT      ->   }t
4 4 CompareMatrices s{{  results-for-4{{ 

t{ s{{ 4 HILBERT-INV  ->   }t
4 4 CompareMatrices s{{  invresults-for-4{{ 

t{ & s{{ }}free       ->   }t

t{ 2 HILBERT-DET  ->       1e 12e f/       r}t
t{ 3 HILBERT-DET  ->       1e 2160e f/     r}t
t{ 4 HILBERT-DET  ->       1e 6048000e f/  r}t
t{ 5 HILBERT-DET  ->       3.7493E-12      r}t

BASE !
[THEN]

