\ coreplus.4th
\ More tests on the the ANS Forth Core word set 

\ This program is free software; you can redistribute it and/or
\ modify it any way.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\ The tests are not claimed to be comprehensive or correct 

\ -----------------------------------------------------------------------------
\ Version 0.2  6 March 2009 { and } replaced with T{ and }T
\              Added extra RECURSE tests
\         0.1  20 April 2007 Created

\ -----------------------------------------------------------------------------
\ The tests are based on John Hayes test program for the core word set
\ and requires those files to have been loaded

\ This file provides some more tests on Core words where the original Hayes
\ tests are thought to be incomplete

\ Words tested in this file are:
\     DO +LOOP RECURSE
\
\     
\ -----------------------------------------------------------------------------
\ Assumptions and dependencies:
\     - ans-words    (for kForth)
\     - ttester
\ -----------------------------------------------------------------------------
include ans-words
include ttester

DECIMAL

Testing DO +LOOP with run-time increment, negative increment, infinite loop
\ Contributed by Reinhold Straub

VARIABLE iterations
VARIABLE increment
: gd7 ( limit start increment -- )
   increment !
   0 iterations !
   DO
      1 iterations +!
      I
      iterations @  6 = IF LEAVE THEN
      increment @
   +LOOP iterations @
;

T{  4  4 -1 gd7 -> 4 1 }T
T{  1  4 -1 gd7 -> 4 3 2 1 4 }T
T{  4  1 -1 gd7 -> 1 0 -1 -2 -3 -4 6 }T
T{  4  1  0 gd7 -> 1 1 1 1 1 1 6 }T
T{  0  0  0 gd7 -> 0 0 0 0 0 0 6 }T
T{  1  4  0 gd7 -> 4 4 4 4 4 4 6 }T
T{  1  4  1 gd7 -> 4 5 6 7 8 9 6 }T
T{  4  1  1 gd7 -> 1 2 3 3 }T
T{  4  4  1 gd7 -> 4 5 6 7 8 9 6 }T
T{  2 -1 -1 gd7 -> -1 -2 -3 -4 -5 -6 6 }T
T{ -1  2 -1 gd7 -> 2 1 0 -1 4 }T
T{  2 -1  0 gd7 -> -1 -1 -1 -1 -1 -1 6 }T
T{ -1  2  0 gd7 -> 2 2 2 2 2 2 6 }T
T{ -1  2  1 gd7 -> 2 3 4 5 6 7 6 }T
T{  2 -1  1 gd7 -> -1 0 1 3 }T
T{ -20 30 -10 gd7 -> 30 20 10 0 -10 -20 6 }T
T{ -20 31 -10 gd7 -> 31 21 11 1 -9 -19 6 }T
T{ -20 29 -10 gd7 -> 29 19 9 -1 -11 5 }T

\ ----------------------------------------------------------------------------
Testing RECURSE with :NONAME

T{ :NONAME ( n -- 0,1,..n ) DUP IF DUP >R 1- RECURSE R> THEN ;
   CONSTANT rn1 -> }T
T{ 0 rn1 EXECUTE -> 0 }T
T{ 4 rn1 EXECUTE -> 0 1 2 3 4 }T

Testing multiple RECURSE's in 1 definition

:NONAME  ( n -- n1 )
   1- DUP
   CASE 0 OF EXIT ENDOF
        1 OF 11 SWAP RECURSE ENDOF
        2 OF 22 SWAP RECURSE ENDOF
        3 OF 33 SWAP RECURSE ENDOF
        DROP ABS RECURSE EXIT
   endcase
; CONSTANT rn2

T{  1 rn2 EXECUTE -> 0 }T
T{  2 rn2 EXECUTE -> 11 0 }T
T{  4 rn2 EXECUTE -> 33 22 11 0 }T
T{ 25 rn2 EXECUTE -> 33 22 11 0 }T

\ -----------------------------------------------------------------------------

CR .( End of additional Core tests) CR

