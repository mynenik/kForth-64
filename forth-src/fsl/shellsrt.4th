\ Shell-Metzger in-place descending sort of floating array
\   see, e. g., Press et al, Numerical Recipes, Cambridge (1986)

\ usage:  build array containing N or more fp values  A{
\         N A{ }shellsort

\ Forth Scientific Library Algorithm #15

\ ANS compliant, requiring
\     FLOATING-POINT wordset
\     array defining and referencing words as in fsl_util.*
\     The compilation of the test code is controlled by the VALUE TEST-CODE?
\     and the conditional compilation words in the Programming-Tools wordset.

\ Note:  code relies on consecutive storage of array elements
\     testing code uses FSIN , PRECISION and SET-PRECISION 
\       from FLOATING EXT wordset
\       and % , s>f , set-width and }fprint from fsl_util.*

\ (c) Copyright 1994 Charles G. Montgomery.  Permission is granted by the
\ author to use this software for any purpose provided this copyright
\ notice is preserved.

\ Adapted for kForth; 10/26/03  Krishna Myneni
\ Use under kForth requires:
\
\	ans-words.4th
\	fsl-util.4th
\

.( SHELLSORT         v1.3b          28 October 1994   cgm ) CR    

0 ptr astart  \ storage for base address used in array access
0 ptr a1
0 ptr a2

: }shellsort    ( nsize &array -- )

    0 } TO astart
    DUP
    BEGIN       ( nsize mspacing )
      2/ DUP    
    WHILE       ( n m )
      2DUP - 0
      DO        ( n m )
       0 I DO   ( n m )

\ compare Ith and (I+M)th elements 
              DUP I + DUP               ( n m l l )
              FLOATS   astart + F@        
              I FLOATS astart + F@      ( n m l Al Ai )
              F<                \ reverse this to get ascending sort

\ switch them if necessary
              IF  DROP LEAVE            ( n m )
              THEN                      ( n m l )
              FLOATS   astart + DUP to a1 F@  
              I FLOATS astart + DUP to a2 F@  ( n m Al Ai &Al &Ai)
              a1 F! a2 F!

              DUP NEGATE                ( n m -m )
            +LOOP
      LOOP
    REPEAT   2DROP
;

TEST-CODE? [IF]     \ test code =============================================

33 FLOAT ARRAY Test{

: fillTest{  ( -- )  33 0 DO  I S>F 0.7e F/ FSIN Test{ I } F!  LOOP  ;

   \ PRECISION  3 SET-PRECISION  print-width @ 10 print-width !

   fillTest{
   cr .( UNSORTED values: ) cr  
   33  Test{ }fprint cr
   cr .( SORTED values: ) cr
   33  Test{ }shellsort
   33  Test{ }fprint cr

   \ print-width ! SET-PRECISION

[THEN]

\ end of file
