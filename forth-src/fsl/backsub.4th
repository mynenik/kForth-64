\ backsub      Solves for linear systems via LU factorization

\ Forth Scientific Library Algorithm #35

\              Solves Ax = b     (A in LU form)

\ Presumes that the matrix has been converted in LU form (using LUFACT)
\ before being called.

\ This code is an ANS Forth program requiring:
\      1. The Floating-Point word set ** This version assumes an integrated data/fp stack **
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      3. Uses the words 'FLOAT' and Array to create floating point arrays.
\      4. The word '}' to dereference a one-dimensional array.
\      5. Uses the words 'DARRAY' and '&!' to set array pointers.
\      6. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset


\ see,
\ Baker, L., 1989; C Tools for Scientists and Engineers,
\ McGraw-Hill, New York, 324 pages,   ISBN 0-07-003355-2


\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.

\ Revisions:
\   2005-01-22  cgm; defective test code commented out
\   2007-09-14  km;  replaced test code with automated tests 
\   2007-10-27  km;  save base, switch to decimal, and restore base
\   2010-04-30  km;  uncommented Private:
\   2011-09-16  km;  use Neal Bridges' anonymous modules interface 
\   2012-02-19  km;  use KM/DNW's modules library
\   2021-05-16  km;  updated for use with separate fp stack
\ =====================================================================
\ The is the kForth version, which requires the following files:
\
\  ans-words.4th
\  fsl-util.4th
\  dynmem.4th
\  struct.4th       \ The Gforth structures package is used
\  lufact.4th       \   in place of the FSL structures package.
\
\ ======================================================================

CR .( BACKSUB           V1.2g          16 May       2021   EFC )
BEGIN-MODULE
BASE @ DECIMAL

Private:

FLOAT  DARRAY b{
FLOAT  DMATRIX a{{
INTEGER DARRAY pivot{

FLOAT DARRAY sx{
FLOAT DARRAY sy{

FVARIABLE temp

: sdot ( k n first -- t )       \ based upon a standard BLAS routine

     0e temp F!
     ?DO
       a{{ I 2 PICK }} F@ b{ I } F@ F* temp F@ F+ temp F!
     LOOP

     DROP  temp F@
;

: backsub-init ( 'lu 'b -- n )

    & b{ &!
    DUP ->pivot{ a@   & pivot{  &!
    DUP ->matrix{{ a@ & a{{     &!
    ->N @

;


: solve-Ly=b ( n --  )

       -1 SWAP
       0 DO
            b{ pivot{ I } @ } DUP F@ temp F!

            b{ I } SWAP >R F@ R> F!

            DUP 0< IF  temp F@ F0= 0= IF  DROP I THEN
                    ELSE
                        I OVER ?DO
                                    temp F@ a{{ J I }} F@ b{ I } F@ F* F- temp F!  
                                LOOP
                    THEN
            temp F@ b{ I } F!
         LOOP

         DROP
;

: solve-Ux=y ( n -- )

        0 OVER 1- DO
                     b{ I } F@  temp F!
                     I OVER 1- < IF
                                   DUP I 1+ DO
                                              temp F@ a{{ J I }} F@ b{ I } F@ F* F- temp F!
                                   LOOP
                                 THEN                      

                     temp F@ a{{ I I }} F@ F/   b{ I } F!
                  -1 +LOOP
         DROP
;


: solve-UTy=b ( n -- )

    -1 SWAP
     0 DO
            b{ I } F@  temp F!

            DUP 0 < IF   temp F@ F0= 0= IF DROP I THEN
                    ELSE
                        I OVER ?DO
                                  temp F@ a{{ I J }} F@ b{ I } F@ F* F- temp F!
                        LOOP
                    THEN
            temp F@ a{{ I I }} F@ F/   b{ I } F!
     LOOP
   DROP

;

: solve-LTx=y ( n -- )

     0 OVER 1- DO
                 b{ I } F@  temp F! 

                 I OVER 1- < IF
                        DUP I 1+ DO
                                  temp F@ a{{ I J }} F@ b{ I } F@ F* F- temp F!
                        LOOP
                 THEN
                 temp F@ b{ I } F!                
            -1 +LOOP
     DROP
;

Public:

: backsub ( 'lu 'b  -- )

    backsub-init

    DUP

    solve-Ly=b
    
    solve-Ux=y
    
;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] LUFACT  [IF] include fsl/lufact  [THEN]
[undefined] T{      [IF] include ttester [THEN]
[undefined] CompareArrays [IF] include fsl/fsl-test-utils [THEN]
BASE @ DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

3 3 FLOAT matrix mat{{
3 3 FLOAT matrix lmat{{
  3 FLOAT array  x{
  3 FLOAT array  sol{
  3 INTEGER array piv{

LUMATRIX lub
CR
TESTING problem 1   
1e  0e  5e 
3e  2e  4e
1e  1e  6e
3 3 mat{{ }}fput

0e  4e  2e   3 x{ }fput
0e  2e  0e   3 sol{ }fput

t{ lub lmat{{ piv{ 3 lumatrix-init  ->  }t
t{ mat{{ lub lufact                 ->  }t
t{ lub x{ backsub                   ->  }t
3 CompareArrays x{ sol{

TESTING problem 2
 2e  3e  -1e
 4e  4e  -3e
-2e  3e  -1e
3 3 mat{{ }}fput

5e  3e  1e  3 x{ }fput
1e  2e  3e  3 sol{ }fput

t{ lub lmat{{ piv{ 3 lumatrix-init  ->  }t
t{ mat{{ lub lufact                 ->  }t
t{ lub x{ backsub                   ->  }t
3 CompareArrays x{ sol{



\ : backsubt-test ( -- )         \ solves the same problem in transposed form


\         CR ." --------------problem 1------------------ " CR

\         init-vals1
\         mat{{ 3 transpose

\         lub lmat{{ piv{ 3 LUMATRIX-INIT


\         ." A: " CR        
\         3 3 mat{{ }}fprint
\         CR ." B: " 3 x{ }fprint
\         CR

\         mat{{ lub lufact


\         CR
\         3 3 lmat{{ }}fprint

\         lub x{ backsub-t
      
\         CR ." solution (should be 0 2 0 ): "
\         3 x{ }fprint


\         CR ." --------------problem 2----------------- " CR

\         init-vals2
\         mat{{ 3 transpose

\         lub lmat{{ piv{ 3 LUMATRIX-INIT
        
\         ." A: " CR        
\         3 3 mat{{ }}fprint
\         CR ." B: " 3 x{ }fprint
\         CR

\         mat{{ lub lufact


\         CR
\         3 3 lmat{{ }}fprint

\         lub x{ backsub-t
      
\         CR ." solution (should be 1 2 3 ): "
\         3 x{ }fprint

\  CR

\ ;
BASE !
[THEN]


