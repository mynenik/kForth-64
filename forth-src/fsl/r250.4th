\ r250d ranf r250d_init lcm_rand seed     R250 Pseudo-Random number generator

\ Forth Scientific Library Algorithm #23

\ algorithm from:
\ Kirkpatrick, S., and E. Stoll, 1981; A Very Fast Shift-Register
\ Sequence Random Number Generator, Journal of Computational Physics,
\ V. 40. p. 517
\
\ see also:
\ Maier, W.L., 1991; A Fast Pseudo Random Number Generator,
\                    Dr. Dobb's Journal, May, pp. 152 - 157

 
\ Uses the Linear Congruential Method,
\ the "minimal standard generator"
\ Park & Miller, 1988, Comm of the ACM, 31(10), pp. 1192-1201
\ for initialization


\ For a review of BOTH of these generators, see:
\ Carter, E.F, 1994; Generation and Application of Random Numbers,
\ Forth Dimensions, Vol. XVI, Numbers 1,2 May/June, July/August


\ This is an ANS Forth program requiring:
\      1. The Double-Number word set
\      2. The Floating-Point word set (for ranf)
\      3. The word '}' to dereference a one-dimensional array.
\      4. The words umd* umd/mod dxor dor and dand (see alternative note below)
\      5. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control visibility of internal code
\      6. The Programming-Tools wordset is need to control generator compilation
\         options (see note below).
\      7. The compilation of the test code is controlled by the VALUE TEST-CODE?
\         and the conditional compilation words in the Programming-Tools wordset

\ Note:
\ Assumes that double integers are (at least) 32 bits.  If regular integers
\ are (at least) 32 bits then umd* and umd/mod will not be needed if
\ lcm_rand is vectored to use lcm_rand32 (this will also be MUCH faster
\ than using lcm_rand16 for such systems).  The private word, vector_lcm attempts
\ to do this automatically at load time.
\
\ Alternatively, one can set the CONSTANT SINGLE-GENERATOR? to TRUE before loading,
\ in this case the generator lcm_randB will be used.  This will work with both 16
\ and 32 bit systems with a performance penalty of a little more than a factor of
\ 2.  This performance hit will have a small impact on the use of R250 (since
\ lcm_rand is only used to initialize R250), but could be a disadvantage when
\ using lcm_rand directly.  When compiling this way, umd* and umd/mod are not
\ needed. (all three lcm generator implementations give identical results).


\     (c) Copyright 1994  Everett F. Carter.     Permission is granted
\     by the author to use this software for any application provided
\     this copyright notice is preserved.

\ Revisions:
\    2009-06-03  km; revised the test code for automated tests;
\                    save base, switch to decimal, and restore base;
\                    change constant SINGLE-GENERATOR? to TRUE; add
\                    conditional definitions of 4dup and d> 
\    2011-09-16  km; use Neal Bridges' anonymous modules.
\    2012-02-19  km; use KM/DNW's modules library.

CR .( R250              V1.5c          19 February  2012   EFC )
BEGIN-MODULE

BASE @ DECIMAL

Public:

[UNDEFINED] 4dup [IF] : 4dup 2OVER 2OVER ; [THEN]
[UNDEFINED] d>   [IF] : d>   4dup d= >r d< r> or invert ;  [THEN]
[UNDEFINED] d0<  [IF] : d0<  0 0 d< ;  [THEN]

Private:

( FALSE) TRUE CONSTANT SINGLE-GENERATOR?

2147483647 s>d 2CONSTANT max32

SINGLE-GENERATOR? [IF]

\ multiply unsigned double by unsigned single, giving unsigned double result.
: mu* ( ud1 u--ud2 )  TUCK * >R  UM*  R> + ;

\ divide unsigned double by unsigned single, giving unsigned single result.
: um/ ( ud u--u )  UM/MOD NIP ;

\ divide unsigned double by unsigned single, giving unsigned double result.
: mu/ ( ud u--ud )  >R  0 R@  UM/MOD  R> SWAP >R  um/  R> ;

\ multiply unsigned single u1 by unsigned single u2, then divide by unsigned
\ single u3, giving unsigned double result.
: um*/ ( u1 u2 u3--ud )  >R UM*  R> mu/ ;

\ divide non-negative double +d1 by strictly positive double +d3,
\ giving double quotient d3.
\
\ The algorithm is described in "Long Divisors and Short Fractions
\ by Prof. Nathaniel Grossman, in Forth Dimensions Volume VI No. 3.
\
\ Grossman cites Abramowitz M and I A Stegun, Handbook of Mathematical
\ Functions, National Bureau of Standards Applied Mathematics Series, 55.
\ (Reprinted by Dover Publications) page 21 and Knuth, Seminumerical Algorithms
\ as his references.
: +d/ ( +d1 +d2--+d3 )  ?DUP IF  DUP 1+  0 1 ROT  um/
                                DUP >R  mu*
                                >R OVER SWAP R@ um*/ D-
                                2R> M*/  NIP 0
                          ELSE  mu/
                          THEN ;

\ multiply unsigned double by unsigned double, giving double result.
: ud* ( ud ud--ud )  DUP IF  2SWAP  THEN  DROP  mu* ;


\ divide non-negative double +d1 by strictly positive double +d3,
\ giving double remainder d3 and double quotient d4.
: +d/mod ( +d1 +d2--+d3 +d4 )  4DUP  +d/  2DUP  2>R  ud*  D-  2R> ;

[THEN]

Public:

2VARIABLE seed               1234 s>d  seed 2!

Defer lcm_rand

\ Linear Congruential Method, the "minimal standard generator"
\ Park & Miller, 1988, Comm of the ACM, 31(10), pp. 1192-1201

SINGLE-GENERATOR? [IF]

\ the following implementation works for both 16 and 32 bit systems
: lcm_randB  ( -- d )  seed 2@ 127773 s>d +d/mod
                         2>R
                         16807 mu*
                         2R>
                         2836 mu* D-
                         2DUP D0< IF max32 D+ THEN
                         2DUP seed 2!
;

use( lcm_randB is lcm_rand

[ELSE]

\ for a cell size of at least 16 bits and a double size of at least 32 bits
: lcm_rand16  ( -- d )   seed 2@ 16807 s>d umd*
                         max32 umd/mod
                         2DROP
                         2DUP seed 2!
;



\ the following implementation gives identical results and will
\ run faster than lcm_rand16 for a system with a cell size of at least 32 bits
: lcm_rand32  ( -- d )   seed 2@ 127773 UM/MOD
                         >R
                         16807 UM*
                         R>
                         2836 UM* D-
                         DUP 0< IF max32 D+ THEN
                         2DUP seed 2!
;

Private:

\ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
\ WARNING!!!!!! MAKE SURE THIS IS SET APPROPRIATELY FOR YOUR MACHINE/COMPILER !!


: vector_lcm
           1 CELLS 4 < IF     \ for 16 BIT INTS
            		 USE( lcm_rand16
                       ELSE   \ for 32 BIT (or larger) INTS
                         USE( lcm_rand32
                       THEN
          is lcm_rand
;

vector_lcm

\ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

[THEN]

Private:

\ R250 code -- 31 bit version
\ Kirkpatrick & Stoll, 1981; Jour. Computational Physics,
\ 40, p. 517

2VARIABLE dmask
2VARIABLE dmsb

VARIABLE front_index
VARIABLE back_index

250 DOUBLE ARRAY r250d_buffer{

Public:

: r250d_init ( d -- )
      seed 2!   0 front_index !   103 back_index !

      \ initialize the buffer with random values
      250 0 DO lcm_rand r250d_buffer{ I } 2! LOOP


      250 0 [ HEX ]
          DO
              lcm_rand 020000000 s>d d>
              IF r250d_buffer{ i } DUP >R 2@ 040000000 s>d dor R> 2! THEN
         LOOP

     040000000 s>d dmsb 2!
     07fffffff s>d dmask 2!

    [ DECIMAL ]

    31 0 DO
         r250d_buffer{ I 7 * 3 + } DUP >R
         2@ dmask 2@ dand
            dmsb  2@ dor
        R> 2!

        dmask DUP >R 2@ D2/ R> 2!
        dmsb  DUP >R 2@ D2/ R> 2!
   LOOP
;

: r250d   ( -- d )             \ 32 bit positive (i.e. 31 bit) number

      r250d_buffer{ back_index @  } 2@

      r250d_buffer{ front_index @ } DUP >R 2@    dxor

      2DUP    R> 2!            \ save new value at front index location

      1 front_index +!
      front_index @ 249 > IF 0 front_index ! THEN

      1 back_index +!
      back_index @ 249 > IF 0 back_index ! THEN

;

: ranf ( --, f: -- x)             \ generate a random value from 0.0 to 1.0

        r250d D>F max32 D>F F/

;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester  [THEN]
BASE @ DECIMAL

\ test the LCM generator
: lcm_test   ( -- d )
             1 s>d  seed 2!        \ set initial seed value
             1 s>d                 \ push a temporary value
             10000 0 DO 2DROP lcm_rand LOOP
                    \  ." final value: " D.
                    \  ." should be 1043618065" CR
;

CR
TESTING  LCM_RAND
t{  lcm_test  ->   1043618065 s>d  }t

\ test the R250 generator
: r250_test  ( -- d )
             1 s>d r250d_init
             1 s>d
             10000 0 DO 2DROP r250d LOOP
                     \ ." final value: " D.
                     \ ." should be 267771767" CR
;

CR 
TESTING  R250D
t{  r250_test  ->  267771767 s>d  }t

BASE !
[THEN]






