\ invm      Inverts a matrix in LU form
\
\ Forth Scientific Library Algorithm #36

\ invm ( 'lu 'a{{ -- )
\         Inverts the LU matrix at 'lu and returns the inverse in the
\         matrix a{{

\ Presumes that the matrix has been converted in LU form (using LUFACT)
\ before being called.

\ This code is ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      3. Uses the words 'FLOAT' and 'DARRAY' to create floating point arrays
\         plus 'INTEGER' to create integer arrays.
\      4. The word '}' to dereference a one-dimensional array, and '}}' to
\         dereference two dimensional arrays.
\      5. Uses the words 'DARRAY' and '&!' to set array pointers.
\      6. Uses the FSL word BACKSUB to perform back substituion on the
\         internally formed subproblems.
\      7. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset
\      8. The test code uses 'HILBERT' and 'HILBERT-DET' for generating the test


\ see,
\ Baker, L., 1989; C Tools for Scientists and Engineers,
\ McGraw-Hill, New York, 324 pages,   ISBN 0-07-003355-2


\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.

\ Revisions:
\   2007-09-14  km; replaced test code with automated tests
\   2007-10-27  km; save base, switch to decimal, and restore base
\   2011-09-16  km; use Neal Bridges' anonymous modules
\   2012-02-19  km; use KM/DNW's modules library
\   2021-05-16  km; update file paths in test code
CR .( INVM              V1.2e          16 May       2021   EFC )

BEGIN-MODULE

BASE @ DECIMAL

Private:


FLOAT DARRAY b{     \ scratch space

0 ptr LU            \ pointer to users LU data structure
0 ptr a{{

: invm-init ( 'lu 'a{{ -- n )

    to a{{  to LU 

    LU ->N @  & b{ OVER }malloc
    malloc-fail? ABORT" INVM-INIT malloc failure "
;

Public:

: invm ( 'lu 'a{{ -- )

    invm-init

    DUP 0 DO
	DUP 0 DO 0.0E0 b{ I } F! LOOP
	1.0E0 b{ I } F!

	LU b{ backsub

	DUP 0 DO b{ I } F@ a{{ J I }} F! LOOP
    LOOP
    DROP

    & b{ }free
;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code =============================================
[undefined] T{           [IF] include ttester  [THEN]
[undefined] CompareMatrices [IF] include fsl/fsl-test-utils [THEN]
[undefined] LUFACT       [IF] include fsl/lufact  [THEN]
[undefined] BACKSUB      [IF] include fsl/backsub [THEN]
BASE @ DECIMAL

1e-13 abs-near F!   ( tolerance of 1e-14 causes failed test )
1e-13 rel-near F!
set-near

\ test code, creates a finite segment of a Hilbert matrix of the specified
\ size and inverts it.  Uses the known form for the inverse of these
\ matrices to calculate the comparison value.

\ Dynamically allocated array space
FLOAT DMATRIX mat{{
FLOAT DMATRIX mat-ref{{
FLOAT DMATRIX lmat{{
INTEGER DARRAY piv{

LUMATRIX lui

CR
TESTING INVM
4 value N
t{ & mat{{ N N }}malloc  ->   }t
t{ malloc-fail?          -> 0 }t
t{ mat{{ N hilbert       ->   }t
t{ & lmat{{ N N }}malloc ->   }t
t{ malloc-fail?          -> 0 }t
t{ & piv{ N }malloc      ->   }t
t{ malloc-fail?          -> 0 }t
t{ lui lmat{{ piv{ N lumatrix-init  ->  }t
t{ mat{{ lui lufact      ->   }t
t{ lui mat{{ invm        ->   }t

t{ & mat-ref{{ N N }}malloc ->  }t
t{ mat-ref{{ N hilbert-inv  ->  }t
N N CompareMatrices mat{{  mat-ref{{

t{ & mat{{ }}free  ->  }t
t{ & lmat{{ }}free ->  }t
t{ & piv{ }free    ->  }t

BASE !
[THEN]


