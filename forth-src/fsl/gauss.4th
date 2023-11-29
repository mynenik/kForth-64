\ Gauss       The Gaussian (Normal) probablity function   ACM Algorithm #209
\ Calulates, z = 1/sqrt( 2 pi ) \int_-\infty^x exp( - 0.5 u^2 ) du
\ by means of polynomial approximations.   Accurate to 6 places.

\ Forth Scientific Library Algorithm #42

\ This is an ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      3. Uses the words 'FLOAT' and ARRAY to create floating point arrays.
\      4. The word '}' to dereference a one-dimensional array.
\      5. Uses the FSL word '}Horner' for fast polynomial evaluation.
\      6. The compilation of the test code is controlled by VALUE TEST-CODE?
\         and the conditional compilation words in the
\         Programming-Tools wordset.

\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.
\
\ Revisions:
\   2007-11-11  km; revised test code; save and restore base
\   2011-09-16  km; use Neal Bridges' anonymous modules
\   2012-02-19  km; use KM/DNW's modules library
CR .( GAUSS             V1.0c          19 February  2012  EFC )

BEGIN-MODULE

BASE @ DECIMAL

Private:

15 FLOAT ARRAY big{
 9 FLOAT ARRAY small{

    0.999936657524E0
    0.000535310849E0
   -0.002141268741E0
    0.005353579108E0
   -0.009279453341E0
    0.011630447319E0
   -0.010557625006E0
    0.006549791214E0
   -0.002034254874E0
   -0.000794620820E0
    0.001390604284E0
   -0.000676904986E0
   -0.000019538132E0
    0.000152529290E0
   -0.000045255659E0
15 big{ }fput

    0.797884560593E0
   -0.531923007300E0
    0.319152932694E0
   -0.151968751364E0
    0.059054035624E0
   -0.019198292004E0
    0.005198775019E0
   -0.001075204047E0
    0.000124818987E0
9 small{ }fput

: gauss-small-y ( y -- z )

       FDUP FSQUARE
       small{ 8 }Horner
       F* 2.0E0 F*
;

: gauss-mid-y ( y -- z )
      2.0E0 F-
      big{ 14 }Horner
;

Public:


: gauss ( x -- gauss{x} )

        FDUP F0= IF
                    F0< >R 0.0E0
                 ELSE

                    FDUP F0< >R          \ push flag for sign of x
                    FABS 2.0E0 F/

                    FDUP 1.0E0 F<  IF
                                      gauss-small-y
                                   ELSE
                                      FDUP 4.85E0 F< IF
                                                      gauss-mid-y
                                                     ELSE
                                                      FDROP 1.0E0
                                                     THEN
                                   THEN
                                   
                 THEN


      R> IF ( x < 0 )    FNEGATE THEN

      1.0E0 F+ 2.0E0 F/

;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ========================================
[undefined] T{      [IF]  include ttester.4th  [THEN]    
BASE @ DECIMAL

1e-6 rel-near F!
1e-6 abs-near F!
set-near

CR
TESTING GAUSS    
t{  5.0E0 gauss  ->  1.0e r}t
t{ -1.5E0 gauss  ->  0.0668072e r}t
t{ -0.5E0 gauss  ->  0.308538e  r}t
t{  0.5E0 gauss  ->  0.691462e  r}t

BASE !
[THEN]
