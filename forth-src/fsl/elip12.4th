\ elip12     Complete Elliptic Integrals        ACM Algorithms #55 and # 56

\ Forth Scientific Library Algorithm #28

\ Evaluates the Complete Elliptic Integral of the first kind,
\     K[k] = int_0^{\pi/2} 1/Sqrt{ 1 - k^2 Sin^2(v)} dv
\ and of the second kind,
\     E[k] = int_0^{\pi/2}   Sqrt{ 1 - k^2 Sin^2(v)} dv

\ Note:
\       Uses the MODULUS k  (the parameter m = k^2).
\       These algorithms are not suitable for k = 1, and the accuracy
\         breaks down very near k = 1 ( 0.999999 )
\       These evaluations are by polynomial expansions, the accuracy is
\         controlled by the polynomial coefficients to about 7 places.
 
\ This is an ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code. ( see fsl_util file )
\      3. Uses the words 'FLOAT' and Array to create floating point arrays.
\      4. The word '}' to dereference a one-dimensional array.
\      5. Uses the word '}Horner' (FSL #3) for fast polynomial evaluation.
\      6. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset
\


\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ Revisions:
\   2011-01-25  km  added BASE handling and automated test code.
\   2011-09-16  km  use Neal Bridges' anonymous module interface.
\   2012-02-19  km  use KM/DNW's modules library

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

CR .( ELIP12     V1.1c                 19 February  2012   EFC )

BEGIN-MODULE

BASE @
DECIMAL

Private:

4 FLOAT ARRAY K-Coefs1{
4 FLOAT ARRAY K-Coefs2{
3 FLOAT ARRAY E-Coefs1{
4 FLOAT ARRAY E-Coefs2{

  0.5E0         K-Coefs1{ 0 } F!
  0.12475074E0  K-Coefs1{ 1 } F!
  0.060118519E0 K-Coefs1{ 2 } F! 
  0.010944912E0 K-Coefs1{ 3 } F!

  1.3862944E0   K-Coefs2{ 0 } F!
  0.097932891E0 K-Coefs2{ 1 } F!
  0.054544409E0 K-Coefs2{ 2 } F!
  0.032024666E0 K-Coefs2{ 3 } F!

  0.24969795E0  E-Coefs1{ 0 } F!
  0.08150224E0  E-Coefs1{ 1 } F!
  0.01382999E0  E-Coefs1{ 2 } F!

  1.0E0         E-Coefs2{ 0 } F!
  0.44479204E0  E-Coefs2{ 1 } F!
  0.085099193E0 E-Coefs2{ 2 } F!
  0.040905094E0 E-Coefs2{ 3 } F!

Public:

: K[k] ( -- ) ( F: k -- K[k] )                  \ ACM Algorithm #55

       FSQUARE 1.0E0 FSWAP F-

       FDUP K-Coefs2{ 3 }Horner
       FSWAP FDUP K-Coefs1{ 3 }Horner
       FSWAP FLN F*
       F-       
;


: E[k] ( -- ) ( F: k -- K[k] )                  \ ACM Algorithm #56

       FSQUARE 1.0E0 FSWAP F-

       FDUP E-Coefs2{ 3 }Horner
       FSWAP FDUP E-Coefs1{ 2 }Horner
       FOVER F* FSWAP FLN F*
       F-       
;

END-MODULE
BASE !

TEST-CODE? [IF]   \ test code ==========================================
[undefined] T{ [IF] s" ttester" included [THEN]
BASE @
DECIMAL

\ convert a modulus angle in degrees to the  modulus
: modulus   PI F* 180.0E0 F/ FCOS FSQUARE 1.0E0 FSWAP F- FSQRT ;

\ test driver,  calculates the complete elliptic integral of the first
\ and second kind compare with Abramowitz & Stegun,
\ Handbook of Mathematical Functions, Table 17.1

1e-15 abs-near f!
4e-7 rel-near f!
set-near

cr
TESTING E[k]  K[k]
t{  0.0e0         E[k]  ->  1.57079633e0  r}t
t{  0.0e0         K[k]  ->  1.57079633e0  r}t
t{  0.66332495e0  E[k]  ->  1.38025877e0  r}t
t{  0.66332495e0  K[k]  ->  1.80632756e0  r}t
t{  0.86602539e0  E[k]  ->  1.21105603e0  r}t
t{  0.86602539e0  K[k]  ->  2.15651565e0  r}t
t{  0.97979589e0  E[k]  ->  1.05050223e0  r}t
t{  0.97979589e0  K[k]  ->  3.01611249e0  r}t

0 [IF]  \ ---- original test code ----
: EK_test ( -- )
        CR
        ."  m     k         E(k) exact  K(k) exact      E(k)   K(k) " CR

       ." 0.0  0.0         1.57079633  1.57079633     "
       0.0E0 FDUP E[k] F.  K[k] F. CR

      ." 0.44 0.66332495  1.38025877  1.80632756     "
      0.66332495E0 FDUP E[k] F.  K[k] F. CR

      ." 0.75 0.86602539  1.21105603  2.15651565     "
      0.86602539E0  FDUP E[k] F.  K[k] F. CR

      ." 0.96 0.97979589  1.05050223  3.01611249     "
      0.97979589E0 FDUP E[k] F.  K[k] F. CR
;
[THEN]  \ ---- end original test code ----

BASE !
[THEN]




