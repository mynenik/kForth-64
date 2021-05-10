
\ Forth Scientific Library Algorithm #59

\ ANS Forth Program.
\ Requiring the Double-Number word set (namely M*/).
\ Requiring .( ?DO \ from the Core Extensions word set.

\ (c) Copyright 1994 Gordon R Charlton.  Permission is granted by
\ the author to use this software for any application provided this
\ copyright notice is preserved.

\ Revisions:
\   2007-10-23  km; replaced test code with automated tests
\   2007-10-27  km; save base, switch to decimal, and restore base

cr
.( Permutations & Combinations. Version FSL1.0  27th October 1994) cr
.(         Gordon Charlton - gordon@charlton.demon.co.uk) cr
cr

BASE @ DECIMAL

: mu* ( ud1 u--ud2)  TUCK * >R  UM*  R> + ;
\
\ multiply unsigned double d1 by unsigned single u giving unsigned double ud2.


: perms ( u1 u2--ud)  1 S>D 2SWAP
                       SWAP 1+ DUP ROT -
                       ?DO  I mu*  LOOP ;
\
\ return nPr, where u1=n u2=r. All arguments are unsigned, result is double.
\
\ This is an iterative version of the recurrence;
\      r=0 --> nPr = 1
\      r>0 --> nPr = nP(r-1)(n-r+1)


VARIABLE temp  \ private to combs

: combs ( u1 u2--ud)  1 S>D 2SWAP
                       2DUP - MIN
                       SWAP temp !
                       1+ 1 ?DO  temp @  I M*/
                                 -1 temp +!
                            LOOP ;
\
\ return nCr, where u1=n u2=r. All arguments are unsigned, result is double.
\
\ This is an iterative version of the recurrence;
\      r=0 --> nCr = 1
\      r>0 --> nCr = nC(r-1)(n-r+1)/r
\
\ This recurrance was chosen in favour of the more common
\      nCr = n!/(n-r)! r!
\ to avoid excessively large intermediate results. Use of integer maths
\ necessitates that the multiplication be done before the division, to avoid
\ truncation errors, hence the use of M*/, which has a triple length
\ intermediate result. Advantage is taken of the symmetry of the function
\ to minimise the number of iterations.

BASE !
\ end of Permutations & Combinations.

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

CR
TESTING PERMS  COMBS
t{  7 0 perms  ->     1 s>d }t
t{  7 3 perms  ->   210 s>d }t
t{  7 5 perms  ->  2520 s>d }t
t{  7 7 perms  ->  5040 s>d }t

t{  7 0 combs  ->     1 s>d }t
t{  7 3 combs  ->    35 s>d }t
t{  7 5 combs  ->    21 s>d }t
t{  7 7 combs  ->     1 s>d }t

BASE !
[THEN]


