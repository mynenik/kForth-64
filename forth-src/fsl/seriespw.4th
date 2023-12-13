\ seriespwr        Exponentiation of series                 ACM Algorithm #158
\ This routine calculates the FIRST N+1 coefficients of the series g(x)
\ that results from raising an Nth degree polynomial f(x) by the power P

\ Forth Scientific Library Algorithm #16

\ If one sets P = 0, it is treated as a special case. The algorithm gives Ln( f(x) )
\ for P = 0, NOT the mathematical result f(x)^0 = 1

\ The series coefficients are such that a[0] = 1 for f(x),
\ f(x) = 1 + \sum_i=1^N a[i] x^i                         Note N+1 coefficients.

\ This remarkable algorithm can be used to make some very useful function
\ transformations simply by manipulating the coefficients of a polynomial
\ expansion of the function:
\ if f(x) = exp(x) and P = -1.0, then result g(x) = exp(-x)     (see test 3)
\ if f(x) = exp(x) and P = ln(2), then the result g(x) = 2^x    (see test 1)
\ if f(x) = exp(x) and P = 0.0, then the result g(x) = x

\ This is an ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. The word S>F to convert an integer to float.
\      3. The words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      4. The words 'DARRAY' and '&!' to alias arrays.
\      5. The immediate word '&' to get the address of an array
\         at either compile or run time.
\      6. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset.
\      7. The test code uses the immediate word '%' which takes the next token
\         and converts it to a floating-point literal
\         : %   BL WORD  COUNT  >FLOAT  0= ABORT" NAN"
\               STATE @  IF POSTPONE FLITERAL  THEN  ; IMMEDIATE
\      8. The test code uses the words 'factorial' and '}horner'

\ Note: the code does not use more than four fp stack cells (iForth vsn 1.05).


\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York.
\ ISBN 0-89791-017-6

\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.
\
\     2011-09-16  km; use Neal Bridges' anonymous modules.
 

CR .( SERIESPWR         V1.3b          16 September 2011   EFC )
BEGIN-MODULE

BASE @
DECIMAL

Private:

FLOAT DARRAY a{
FLOAT DARRAY b{

Public:

: seriespwr ( p &a &b n -- )    \ ( &a &b n -- , F: p -- )
      >R
      & b{ &!             \ point to array b
      & a{ &!             \ point to array a
      ( R>)

      FDUP F0= IF   a{ 1 } F@  0.0e0 b{ 0 } F!
               ELSE a{ 1 } F@ FOVER F*  a{ 0 } F@ b{ 0 } F! THEN
      b{ 1 } F!

      R> 1+ 2 DO
              0.0e0
              I 1 DO
                       FOVER
                       J I - S>F F*
                       I S>F F-
                       b{ I } F@ F*
                       a{ J I - } F@ F*
                       F+
                  LOOP

              I S>F F/
              FOVER a{ I } F@ FSWAP
              FDUP F0= IF FDROP ELSE F* THEN
              F+
              b{ I } F!
      LOOP
                                  
      FDROP
;

BASE !
END-MODULE

TEST-CODE? [IF]     \ test code =============================================

[undefined] T{        [IF] s" ttester.4th" included [THEN]
[undefined] factorial [IF] s" factorl.4th" included [THEN]
[undefined] }Horner   [IF] s" horner.4th"  included [THEN]  
BASE @
DECIMAL

100 FLOAT ARRAY a{
100 FLOAT ARRAY res{

: clear_a ( -- )
     8 1 DO 0e a{ I } F! LOOP
     1.0e a{ 0 } F!
;

: e^x ( -- )             \ set the coefficients for e^x
     clear_a
     8 1 DO 1.0e I factorial D>F F/   a{ I } F! LOOP
;

: test_init ( --  )
     clear_a
     1.0e  a{ 0 } F!
     2.0e  a{ 1 } F!
     3.0e  a{ 2 } F!
     0.5e  a{ 3 } F!
;

: series_testn ( -- ) ( f: p -- )
    test_init
    a{  res{ 6 seriespwr
    CR
    ." A:  "  7 a{ }fprint CR
    ." B:  "  7 res{ }fprint CR
;


: series_test0 ( -- )                \ takes sum x^n and generates it log
   8 0 DO 1.0e a{ I } F! LOOP
   0.0e  a{  res{ 6  seriespwr

   CR
   ." P = 0.0 " CR
   ." A:  "  7 a{ }fprint CR
   ." B: " 7 res{ }fprint CR
   ." B should be: 0 1 1/2 1/3 1/4 1/5 1/6 " CR
;

: series_test1 ( -- )             \ generates 2^x by raising e^x by log(2)
    e^x
    0.693147181e a{  res{ 6  seriespwr

   CR
   ." P = 0.693147181 " CR
   ." A:  "  7 a{ }fprint CR
   ." B: " 7 res{ }fprint CR
   ." B should be: 1 0.69314781 0.240226507 0.055504109 0.009618129 " CR
   ."              0.001333356 0.000154035 " CR
   
;

\ Note:
\ Squaring a 3rd order polynomial results in a 6th order polynomial
\ so we take the 3rd order one and put zeros in the high coefficients
\ and treat it as 6th order, otherwise seriespwr will not generate
\ the high order coefficients.

: series_test2 ( -- )               \ squares a polynomial
    CR
    ." P = 2.0 "
    2.0e series_testn
    ." B should be: 1.0 4.0 10.0 13.0 11.0 3.0 0.25 " CR
;

: series_test3 ( -- )               \ generates e^-x from e^x
    e^x
    -1.0e a{  res{ 6  seriespwr

    CR
    ." P = -1.0 " CR
    ." A:  "  7 a{ }fprint CR
    ." B: " 7 res{ }fprint CR
    ." B should be: 1.0 -1.0 0.5 -0.16666667 0.041666667 -0.00833333 " CR
    ."              0.00138889 " CR
;


: series_tests ( -- )
        series_test0
        series_test1
        series_test2
        series_test3
;

\ What happens with  f(x) = 1+x, P = -1  ?
\ g(x) = 1/(1+x) exactly, but how good will the series approximation be?

: set[1+x] ( -- )
     clear_a
     1e   a{ 0 } F!
     1e   a{ 1 } F! ;


: test_(1+x)^-1 ( -- )
   set[1+x]
   -1e a{  res{ 6  seriespwr
   CR
   ." P = -1.0 " CR
   ." A:  "  7 a{ }fprint CR
   ." B: " 7 res{ }fprint CR
   ." B should be: 1.0 -1.0 1.0 -1.0 1.0 -1.0 1.0 " CR ;

: test_1/(1+x)
	test_(1+x)^-1
	CR ."  x   Approximation     Exact          Error (%) "
	10 0 DO  CR ." 0." I 1 .R 4 SPACES 
		 I S>F 10e F/ FDUP res{ 6 }Horner FDUP F. 5 SPACES
		 1e FROT 1e F+ F/ FDUP F. 6 SPACES
		 FOVER F- FABS 100e F* FSWAP F/ F.
	   LOOP ;

\ test_1/(1+x)'s table looks like this:
\ x   Approximation     Exact          Error (%) 
\ 0.0    1.000000      1.000000       0.000000 
\ 0.1    0.909091      0.909091       9.999999E-6 
\ 0.2    0.833344      0.833333       0.001280 
\ 0.3    0.769399      0.769231       0.021865 
\ 0.4    0.715456      0.714286       0.163572 
\ 0.5    0.671875      0.666667       0.775194 
\ 0.6    0.642496      0.625000       2.723130 
\ 0.7    0.636679      0.588235       7.608812 
\ 0.8    0.672064      0.555556       17.335915 
\ 0.9    0.778051      0.526316       32.354590 

BASE !
[THEN]





