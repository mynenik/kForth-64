\ shanks         Nonlinear transformation of series      ACM Algorithm #215
\        Forth Scientific Library Algorithm #55
\
\ This algorithm is useful in tranforming a slowly convergent 
\ (and sometimes slowly divergent) series in order to get a more
\ rapidly converging sequence so that certain types of iterative
\ equations can be solved more rapidly.
\ See the test example for further explanation.

\ This procedure replaces elements S[nmin] through S[nmax-2*kmax] of
\ the array S by the e[kmax] transform of the sequence S. (the
\ elements S[nmax-2*kmax+1] through S[nmax-1] are destroyed).  The
\ parameter kmax therefore can range from 1 to nmax/2.
\ The number of valid elements in the transformed S array is returned.

\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\      2. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.
\      3. The immediate words '&' to get addresses
\         and '&!' to set array pointers ( 'DARRAY' ).


\ See:
\ Shanks, D., 1955; Nonlinear transformations of divergent and slowly
\                   convergent series, J. Math. Phys. V34, pp. 1-42
\ also,
\ Wynn, P., 1956; On a device for computing the em(Sn) Transformation,
\                 Mathematical Tables and other Aids to Computation,
\                 V. 10, No. 54, pp. 91 - 96

\ and,
\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

\ Revisions:
\    2007-11-29  km; revised test code for automated tests and
\                    added base handling.
\    2011-09-16  km; use Neal Bridges' anonymous modules.
\    2012-02-19  km; use KM/DNW's modules library
CR .( SHANKS            V1.0b          19 February  2012   EFC )
BEGIN-MODULE

BASE @ DECIMAL

Public:

1.0E23 FCONSTANT FLOAT-MAX

Private:

FVARIABLE T0
FVARIABLE T1
FLOAT DARRAY S{             \ pointer to the passed array

: shanks-inner ( j limk -- )

          0 ?DO
              DUP I - >R

              S{ R@ } F@  S{ R@ 1- } F@ F-  FDUP T1 F!
              F0= IF
                      S{ R@ } F@ FLOAT-MAX F= IF     T0 F@
                                                ELSE   FLOAT-MAX THEN
                                                T1 F!
                 ELSE  1.0e0 T1 F@ F/ T0 F@ F+ T1 F!   THEN

              R> 1-

              S{ OVER } F@   T0 F!
              >R T1 F@          S{ R> } F!

         LOOP

       DROP
;

Public:

: shanks ( &s nmin nmax kmax -- nmax' )
        >R >R >R
        & S{ &!
        R> R> R>
        
        2*
        OVER OVER - 0< ABORT" SHANKS kmax too large relative to nmax "
        DUP 2 <        ABORT" SHANKS kmax must be at least 1 "

        ROT ROT 1+
        DUP 3 PICK - >R        \ save new array upper bound

             OVER  DO
                         0.0E0 T0 F!
                         I OVER -
                         DUP 3 PICK > IF DROP OVER THEN

                         I SWAP shanks-inner

                    LOOP
        2DROP
        R>
;

BASE !
END-MODULE

TEST-CODE? [IF]     \ test code =====================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

1e-6 rel-near F!
1e-6 abs-near F!
set-near

9 FLOAT ARRAY s{


CR
TESTING SHANKS

\ In this (simple) example we are seeking the smallest zero of the
\ Lagurerre polynomial L2(x) = x^2 - 4 x + 2 by solving the iterative
\ scheme:  S[n+1] = 0.25 ( S[n]^2 + 2 )      where S[0] = 0
\          S[infinity] should be the value we seek.

0.5857864375e  FCONSTANT  LPROOT

: init-s1
    0.0E0
    0.50E0
    0.5625E0
    0.5791015625E0
    0.5838396549E0
    0.5852171856E0
    0.5856197886E0
    7 s{ }fput
;

: s-test1 ( kmax -- r )   \ kmax can range from 1 to 3 in this example
                          \ because nmax = 6
    init-s1
    >R s{  0 6 R> shanks
    1- s{ SWAP } F@  ;

\ The last value of S above is the SHANKS estimate of the zero

t{  1 s-test1  ->  LPROOT   r}t
t{  2 s-test1  ->  LPROOT   r}t 
t{  3 s-test1  ->  LPROOT   r}t


\ In this example we are seeking the limit of the slowly converging
\ series ln(2) = 1 - 1/2 + 1/3 - 1/4 + 1/5 - 1/6 + 1/7 - 1/8 + 1/9 + ...

2.0e0 fln  FCONSTANT  LN2

: init-s2                      \ set up the first 9 values of S,
                               \ the partial sums of the above formula
      1.0E0         s{ 0 } F!

      9 1 DO 1.0E0 I 1+ S>F F/
             I 2 MOD IF FNEGATE THEN
             s{ I 1- } F@ F+
             s{ I } F!
          LOOP 
;


: s-test2 ( kmax -- r )   \ kmax can range from 1 to 4 in this example
                          \ because nmax = 9
    init-s2
    >R  s{  0 8 R> shanks
    1- s{ SWAP } F@  ;

\ The last value of S above is the SHANKS estimate of the ln(2)

t{  3 s-test2  ->  LN2   r}t
t{  4 s-test2  ->  LN2   r}t

\ Another example from Shanks's Paper      added by lgw
\ Pi = 4 - 4/3 + 4/5 - 4/7 + 4/9 + ..... 
  
: init-s3                     \ set up the first 9 values of S
    4.0E0
    2.66666666667E0
    3.46666666667E0
    2.89523809524E0
    3.33968253968E0
    2.97604617604E0
    3.28373848373E0
    3.01707181706E0
    3.25236593471E0
    9 s{ }fput
;

: s-test3 ( kmax -- r )   \ kmax can range from 1 to 4 in this example
                          \ because nmax = 8
    init-s3
    >R s{  0 8 R> shanks
    1- s{ SWAP } F@  ;

\ The last value of S above is the SHANKS estimate of pi.

t{  3 s-test3  ->  PI   r}t
t{  4 s-test3  ->  PI   r}t

BASE !

[THEN]

