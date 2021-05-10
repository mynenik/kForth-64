\ DFourier                      Direct Fourier Transforms

\ Forth Scientific Library Algorithm #37

\ Perform the Direct Fourier Transform on an array using various algorithms.
\ DFT-T   -- uses table lookup
\ DFT-1   -- uses modified first-order Goertzel with reverse order input
\ DFT-2   -- uses modified second-order Goertzel with reverse order input
\ DFT-2F  -- uses second-order Goertzel with forward order input

\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\   XX 2. The immediate word '%' which takes the next token
\         and converts it to a floating-point literal (for the test code).
\      3. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\   XX 4. The test code uses the word 'zpow' to raise a complex number
\         to a real power, 'Z/' to divide one complex number by another
\         and 'Z*' to multiply two complex numbers.
\      4. The test code uses the word 'Z^N' to raise a complex number
\         to an integer power, 'Z/' to divide one complex number by another
\         and 'Z*' to multiply two complex numbers -- these words are
\         provided by FSL #60, complex.x.
\ see:
\ Burrus, C.S. and T.W. Parks, 1985; DFT/FFT and Convolution
\ Algorithms, Theory and Implementation, John Wiley and Sons, New York,
\ 233 pages, ISBN 0-471-81932-8

\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.
\
\ Revisions:
\   2011-01-17  km  ported to unified or separate fp stack systems; 
\                   minor additional factoring of words; replace manual 
\                   test code with automated test code, using FSL #60 
\                   for complex number arithmetic.
\   2011-01-20  km  completed analytic FT for example 1, version 1.3
\   2011-09-16  km  use Neal Bridges' anonymous module interface
\   2012-02-19  km  use KM/DNW's modules library
\   2021-05-10  km  updated paths to FSL files for test code.
CR .( DFourier          V1.3b          19 February  2012   EFC, KM )
BEGIN-MODULE
BASE @
DECIMAL

Public:
[undefined] 2PI [IF]  2e PI F* FCONSTANT 2PI  [THEN]

Private:

FLOAT DARRAY fx{
FLOAT DARRAY fy{
FLOAT DARRAY a{
FLOAT DARRAY b{

FLOAT DARRAY c{
FLOAT DARRAY s{

FVARIABLE cosine                \ scratch variables used by all but DFT-T
FVARIABLE sine

FVARIABLE cos2                   \ scratch variables used by DFT-2 and DFT-2F
FVARIABLE a2
FVARIABLE b2
FVARIABLE 2pi/n   \ sign set by dir 

0 VALUE n
0 VALUE js
1 VALUE dir                    \  1 for forward transform, -1 for inverse

\ Setup direction and number of points for transform
: set-dir-n ( n dir -- )
    TO dir  TO n
    2PI n S>F F/
    dir 0< IF FNEGATE THEN
    2pi/n F! 
;

: fac ( k -- sin[k*2pi/n] cos[k*2pi/n] )  \ ( k -- ) ( F: -- sin[] cos[] ) 
    S>F 2pi/n F@ F* FSINCOS ;
 
\ Build the DFT look-up table; SET-DIR-N *must* be executed 
\ prior to DFT1-TABLE-INIT
: dft1-table-init ( n -- )                 
       0 DO  I fac  c{ I } F!  s{ I } F!  LOOP
;

Public:

: DFT-T ( &x &y &a &b n di -- )            \ Direct Fourier Transform with
     set-dir-n                             \ table look-up
     &  b{ &!     &  a{ &!
     & fy{ &!     & fx{ &!

     & c{ n }malloc
     & s{ n }malloc

     n dft1-table-init

     n 0 DO
	     fx{ 0 } F@  fy{ 0 } F@

             0 to js
             n 1 DO
                      js J + to js
                      n 1- js < IF js n - to js THEN

                      c{ js } F@ fy{ I } F@ F*
                      s{ js } F@ fx{ I } F@ F* F-  F+
                      FSWAP
                      c{ js } F@ fx{ I } F@ F*
                      s{ js } F@ fy{ I } F@ F* F+  F+
                      FSWAP
             LOOP

             b{ I } F!  a{ I } F!    
     LOOP

     & c{ }free
     & s{ }free    
;

: DFT-1 ( &x &y &a &b n di -- )             \ Direct Fourier Transform using
     set-dir-n                              \ Goertzel's first order algorithm
     &  b{ &!     &  a{ &!
     & fy{ &!     & fx{ &!

     n 1- to js
     n 0 DO
          I fac  cosine F!  sine F!                 
          fx{ js } F@    fy{ js } F@

          js 1- 0 DO
            F2DUP
            sine F@ F* FSWAP
            cosine F@ F* F+
            fx{ js I - 1- } F@ F+
            FROT FROT
            cosine F@ F*
            FSWAP  sine F@ F* F-
            fy{ js I - 1- } F@ F+
          LOOP
                     
          F2DUP
          sine F@ F* FSWAP
          cosine F@ F* F+
          fx{ 0 } F@ F+     a{ I } F!

          cosine F@ F* FSWAP
          sine F@ F* F-
          fy{ 0 } F@ F+     b{ I } F!                     
     LOOP
;

: DFT-2 ( &x &y &a &b n di -- )             \ Direct Fourier Transform using
     set-dir-n                              \ Goertzel's second order algorithm,
                                            \ with reverse order input
     &  b{ &!     &  a{ &!
     & fy{ &!     & fx{ &!

     n 1- to js
     n 0 DO
        I fac  FDUP cosine F!   2.0E0 F* cos2 F!  sine   F!
                                       
        fy{ js } F@    fx{ js } F@
        0.0E0 a2 F!    0.0E0 b2 F!
                      
        js 1- 0 DO
           FDUP cos2 F@ F* a2 F@ F-
           fx{ js I - 1- } F@ F+
           FSWAP a2 F!
           FSWAP
           FDUP cos2 F@ F* b2 F@ F-
           fy{ js I - 1- } F@ F+
           FSWAP b2 F!
           FSWAP
        LOOP
                     
        F2DUP  cosine F@ F* a2 F@ F-
        FSWAP  sine F@ F* F+
        fx{ 0 } F@ F+     a{ I } F!

        sine F@ F* FSWAP
        cosine F@ F* b2 F@ F- FSWAP
        F-
        fy{ 0 } F@ F+     b{ I } F!                     
     LOOP
;

: DFT-2F ( &x &y &a &b n di -- )            \ Direct Fourier Transform using
     set-dir-n                              \ Goertzel's second order algorithm,
                                            \ with forward order input
     &  b{ &!     &  a{ &!
     & fy{ &!     & fx{ &!

     n  0 DO
        I fac  FDUP cosine F!  2.0E0 F* cos2 F!  sine F!
                                       
        fy{ 0 } F@    fx{ 0 } F@
        0.0E0 a2 F!   0.0E0 b2 F!
                      
        n  1 DO
           FDUP cos2 F@ F* a2 F@ F-
           fx{ I } F@ F+
           FSWAP a2 F!
           FSWAP
           FDUP cos2 F@ F* b2 F@ F-
           fy{ I } F@ F+
           FSWAP b2 F!
           FSWAP
        LOOP
                     
        F2DUP  cosine F@ F* a2 F@ F-
        FSWAP  sine F@ F* F-
        a{ I } F!

        sine F@ F* FSWAP
        cosine F@ F* F+ b2 F@ F- 
        b{ I } F!                     
     LOOP
;


END-MODULE
BASE !

TEST-CODE? [IF]     \ test code =============================================
[undefined] PARSE_ARGS [IF] s" strings.4th" included  [THEN]
[undefined] T{  [IF]  s" ttester.4th" included [THEN]
[undefined]  [IF] s" fsl/fsl-test-utils.4th" included [THEN]
[undefined] zvariable [IF] s" fsl/complex.4th" included [THEN]

BASE @
DECIMAL

1e 0e zconstant 1+0i
0e 1e zconstant 0+1i

19 FLOAT ARRAY xx{
19 FLOAT ARRAY yy{
19 FLOAT ARRAY aa{
19 FLOAT ARRAY bb{

\ Example 1: Two-tone test signal
\
\   s_k = a1*cos(2pi*f1*k/n) + i*a2*sin(2pi*f2*k/n)
\
\   for k = 0, 1, ..., n-1
\
3.0E0 fconstant f1  \ frequency 1
1.0E0 fconstant f2  \ frequency 2
1.0E0 fconstant a1  \ amplitude 1
0.4E0 fconstant a2  \ amplitude 2
: dftest1-init ( n -- )
       >R 2PI R@ S>F F/
       R> 0 DO
             I S>F FOVER F* FDUP
             f1 F* FCOS a1 F*  xx{ I } F!
             f2 F* FSIN a2 F*  yy{ I } F!
       LOOP
       FDROP
;

\ Analytic Fourier spectrum of finite duration two-tone signal:
\
\   Let, T(x) = ( exp(i*2pi*x) - 1 ) / x
\
\   Then, the Fourier transform of s(t) is given by,
\
\   S(f) = (-i/(4*pi))*[ a1*( T(f1-f) + T(-(f1+f)) ) 
\                      + a2*( T(f2-f) - T(-(f2+f)) ) ]
\        
\ The above expression should give the same answer as the DFT at
\ discrete frequencies, apart from an overall normalization factor.

: T(x) ( F: x -- z)
    fdup fabs 1e-10 f<  
    IF fdrop 0+1i         \ take proper limit for |x| -> 0
    ELSE fdup 2pi f* fsincos fswap 1+0i z- frot z/f 
    THEN ;


fvariable freq

: S(f) ( f -- z )
    freq f!
    f1 freq f@ f-         T(x)
    f1 freq f@ f+ fnegate T(x)  z+  a1 z*f
    f2 freq f@ f-         T(x)
    f2 freq f@ f+ fnegate T(x)  z-  a2 z*f
    z+  0e -4e pi f* 1/f z*    
;

0 value np
fvariable 2pi*np
: two-tone-actual-ft ( n -- )
    to np  
    np S>F 2pi F* 2pi*np F!     \ normalization factor

    np 2/ 1+ 0 DO  I S>F S(f)   \ positive frequencies
       2pi*np F@ z*f
       yy{ I } F!  xx{ I } F!
    LOOP

    np np 2/ 1+ DO              \ negative frequencies
      I np - S>F S(f) 2pi*np F@ z*f
      yy{ I } F!  xx{ I } F!
    LOOP
;
       

\ Example 2: A chirp test signal
0.9E0  0.3E0  zconstant  z1
: dftest2-init ( n -- )       
    0 DO  z1  I z^n   yy{ I } F!  xx{ I } F!  LOOP
;

\ Analytic Fourier transform of chirp signal
ZVARIABLE w
ZVARIABLE dc

: chirp-actual-ft ( n -- )
       >R 2PI R@ S>F F/
       FDUP FCOS FSWAP FSIN FNEGATE  w z!
       1+0i  z1 R@ z^n  z- dc z!
       
       R> 0 DO
             dc z@                             \ numerator
             w z@ I z^n  z1  z* 1+0i zswap z-  \ denominator
	     z/   yy{ I } F!  xx{ I } F!
       LOOP
;

DEFER DFT                      \ execution vector for DFT

: dft-test ( -- ) 
    \ Example 1
    t{  19 dftest1-init  ->  }t
    t{  xx{  yy{  aa{  bb{  19  1  DFT  ->  }t
    t{  19 two-tone-actual-ft  ->  }t
    s" 19 CompareArrays aa{  xx{" evaluate
    s" 19 CompareArrays bb{  yy{" evaluate
    \ Example 2
    t{  19 dftest2-init  ->  }t
    t{  xx{  yy{  aa{  bb{  19  1  DFT  ->  }t
    t{  19 chirp-actual-ft  ->  }t
    s" 19 CompareArrays aa{  xx{" evaluate
    s" 19 CompareArrays bb{  yy{" evaluate
;

1e-13 rel-near f!
1e-13 abs-near f!
set-near

CR
TESTING DFT-T
& DFT-T  IS  DFT
dft-test

TESTING DFT-1
& DFT-1  IS  DFT
dft-test

TESTING DFT-2
& DFT-2  IS  DFT
dft-test

TESTING DFT-2F
& DFT-2F  IS  DFT
dft-test

\ Original Test Code
0 [IF]
: dfourier-test1 ( -- )

    CR
    19 dftest1-init
    ." Initial array: " CR 19 xx{ }fprint CR
                           19 yy{ }fprint CR
                        
    xx{ yy{ aa{ bb{ 19 1 DFT-T

    ." Transformed array (table method) : " CR 
    19 aa{ }fprint CR
    19 bb{ }fprint CR

    xx{ yy{ aa{ bb{ 19 1 DFT-1

     ." transformed array (1st order method): " CR
     19 aa{ }fprint CR
     19 bb{ }fprint CR

    xx{ yy{ aa{ bb{ 19 1 DFT-2

     ." transformed array (2nd order method): " CR
     19 aa{ }fprint CR
     19 bb{ }fprint CR

    xx{ yy{ aa{ bb{ 19 1 DFT-2F

     ." transformed array (2nd order forward method): " CR
     19 aa{ }fprint CR
     19 bb{ }fprint CR
;

DEFER DFT                      \ execution vector for DFT
& DFT-T IS DFT                 \ initialize to use DFT-T
                               \ also try DFT-1, DFT-2, and DFT-2F
: dfourier-test2 ( -- )
        CR
        19 dftest2-init
        xx{  yy{ aa{ bb{ 19 1 DFT

        ." Transformed array: " CR 19 aa{ }fprint CR
                                   19 bb{ }fprint CR
        19 chirp-actual-ft

        ." Analytic value : "   CR 19 xx{ }fprint CR
                                   19 yy{ }fprint CR
;

[THEN]  \ end original test code

BASE !
[THEN]


