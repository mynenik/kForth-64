\ Dets      Determinant of a matrix in LU form

\ Forth Scientific Library Algorithm #34

\ det       The determinant of a matrix in LU form
\ det-i     The determinant of a matrix in LU form, result returned as
\           as a factor and a power of 10 (useful for very large and
\           very small determinants).

\ Presumes that the matrix has been converted in LU form (using LUFACT)
\ before being called.

\ This code is an ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      3. Uses the words 'FLOAT' and 'DARRAY' to create floating point arrays
\         plus 'INTEGER' to create integer arrays.
\      4. The word '}' to dereference a one-dimensional array, and '}}' to
\         dereference two dimensional arrays.
\      5. Uses the words 'DARRAY' and '&!' to set array pointers.
\      6. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset
\      7. The test code uses 'HILBERT' and 'HILBERT-DET' for generating the testt

\ see,
\ Baker, L., 1989; C Tools for Scientists and Engineers,
\ McGraw-Hill, New York, 324 pages,   ISBN 0-07-003355-2


\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.

\ Revisions:
\  ?           km; updated for use with Gforth structures package
\  2007-10-27  km; save base, switch to decimal, and restore base
\  2010-04-30  km; det and deti code was different from FSL code for
\                  unkonwn reason; restored the code as closely to 
\                  FSL version as possible
\  2011-09-16  km; use Neal Bridges' anonymous module interface
\  2012-02-19  km; use KM/DNW's modules library
\  2021-05-16  km; updated for use with separate fp stack system
CR .( DETS              V1.0g          16 May       2021  EFC )
BEGIN-MODULE
BASE @ DECIMAL

Private:


FLOAT  DMATRIX a{{            \ pointer to users matrix
INTEGER DARRAY pivot{          \ pointer to users array of LU pivots

: ?odd ( n -- t/f )  DUP 2/ 2* - ;

0 value nexp

: large-det ( fdet -- fdet' ) 

    BEGIN
	0.10e F*
	nexp 1+ to nexp
	10.0e FOVER FABS F< 0=
    UNTIL ;

: small-det ( fdet -- fdet' ) 

    BEGIN
	10.0e F*
	nexp 1- to nexp
	FDUP FABS 0.10e F< 0=
    UNTIL ;

Public:

0 value npiv

: det ( 'lu -- fdet ) 

    DUP ->matrix{{ a@  & a{{ &! 
    DUP ->pivot{   a@  & pivot{ &! 
    0 to npiv
    
    >R 1e 
    R> ->N @ 0 DO
	a{{ I I }} F@ F*
	pivot{ I } @ I = 0= IF npiv 1+ to npiv THEN
    LOOP

    npiv ?odd IF FNEGATE THEN ;


: deti0 ( 'lu -- fx )     \ det = fx * 10^nexp

    DUP ->matrix{{ a@  & a{{ &! 
    DUP ->pivot{   a@  & pivot{ &!
    0 to npiv  0 to nexp
    
    >R 1e
    R> ->N @ 0 DO
	a{{ I I }} F@ F*
	pivot{ I } @ I = 0= IF npiv 1+ to npiv THEN
	
	10e FOVER FABS F< IF
	    large-det
        ELSE
	    FDUP FABS 0.10e F< IF
		small-det
	    THEN
	THEN

    LOOP

    npiv ?odd IF FNEGATE THEN ;

[DEFINED] FDEPTH [IF]
: deti ( 'lu -- nexp ) ( F: -- r )  deti0 nexp ;
[ELSE]
: deti ( 'lu -- nexp r )  deti0 nexp -ROT ;
[THEN]

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{          [IF] include ttester [THEN]
[undefined] HILBERT-DET [IF] include hilbert [THEN]
[undefined] LUFACT      [IF] include lufact  [THEN]
BASE @ DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

\ test code, creates a finite segment of a Hilbert matrix of the specified
\ size and gets its determinant.  Uses the known form for the determinant
\ of these matrices to calculate the comparison value.

\ Dynamically allocated array space
FLOAT DMATRIX mat{{

LUMATRIX lmat
CR
TESTING DET
4 value N
t{ & mat{{ N N }}malloc ->   }t
t{ malloc-fail?         -> 0 }t
t{ mat{{ N  HILBERT     ->   }t
t{ lmat N lu-malloc     ->   }t
t{ mat{{ lmat lufact    ->   }t
t{ lmat det             -> N HILBERT-DET  r}t
t{ & mat{{ }}free       ->   }t
t{ lmat lu-free         ->   }t    

BASE !
[THEN]
