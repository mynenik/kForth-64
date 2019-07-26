\ FILE:      benchpin.frt
\ LANGUAGE : ISO Forth
\ TITLE : The PI(N) recursion benchmark.
\ COPYRIGHT :  Albert van der Horst FIG Chapter Holland
\ This program may be copied and distributed freely as is.
\ Modified versions may be distributed if all following conditions
\ are satisfied:
\ 1. the copyright is retained,
\ 2. the modification is marked
\ 3. none of the modifications consist of :
\     1. gratitious de-ansification, like use of non-standard
\         comment symbols
\     2. lower casing
\     3. comment stripping
\  or 4. addition of system-specific words like source control
\         tools such as MARKER look-alikes

\ DESCRIPTION:
\  This (highly recursive) function calculates PI(n), i.e.
\  the number of primes less or equal to n.
\  It doesn't use a sieve, nor does it inspect numbers larger
\  than the square root of n for primeness.
\  It may be used for benchmarking, because it takes
\  considerable time for large numbers.
\  It is one of the few highly recursive algorithms that
\  actually calculate something sensible.

\ -------------------------------------------------
: RDROP 2R> SWAP DROP >R ; \ needed for kForth (KM)
\ -------------------------------------------------

\    -1 CONSTANT TRUE                 \ Comment out if present
\    0  CONSTANT FALSE                \ Comment out if present

\ ?PRIME tests whether the single precision number p is prime
\ Cases 0 1 are in fact illegal but return TRUE
: ?PRIME        ( p -- flag )
  >R
  R@ 4 U< IF RDROP TRUE EXIT THEN       \ Prevent silly infinite loop
  R@ 1 AND 0= IF RDROP FALSE EXIT THEN  \ Handle even numbers other than 2

  3 BEGIN
    R@ OVER /MOD SWAP
    0= IF RDROP 2DROP FALSE EXIT THEN
    OVER < IF RDROP DROP TRUE EXIT THEN
    2 +
    AGAIN
;

\ N2 are the amount of numbers <= N1 that are dismissed by the prime P,
\ i.e. it is divisible by P but not by a smaller prime.
\ Requires P<=N1
: DISMISS       ( N1 P -- N2 )
\   2DUP CR ." Dismissing " . .
    >R      R@ /
    DUP R@ < IF DROP RDROP 1 EXIT THEN       \ Only P itself
    DUP
    R> 2 ?DO
       I ?PRIME IF
          OVER I RECURSE -
       THEN
    LOOP
    SWAP DROP
;

\ Return PI(N2) i.e. the number of primes <= N1
: PI            ( N1 -- N2 )
   DUP >R
   1 -        \ Exclude 1
   R@ 2 / 1-   \ Multiples of 2 except 2 itself
   -           \ Exclude them
   3 BEGIN
      DUP DUP * R@ > 0= WHILE
      DUP ?PRIME IF
\        CR DUP . "IS PRIME" TYPE
         R@ OVER DISMISS 1-   \ Dismissals, except the prime itself.
         SWAP >R    -    R>   \ Exclude them
      THEN
   2 + REPEAT DROP
   RDROP
;

\ --------------------------------------------------

\ It can be tested by 

VARIABLE OLD
\ Find any errors in PI for arguments < N .
: FINDPROBLEMS        ( N -- )
  1 OLD !
  3 DO
     I PI DUP OLD @ - 0= 0=
     I ?PRIME 0= 0= <> IF
        DROP ." Wrong : " I . LEAVE
\     ELSE
\        ." Okay  : " I .        \ Comment out as desired.
     THEN
     OLD !
\      .S
  LOOP
;

