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

0 INVERT                        CONSTANT MAX-UINT
0 INVERT 1 RSHIFT               CONSTANT MAX-INT
0 INVERT 1 RSHIFT INVERT        CONSTANT MIN-INT

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
TESTING DO +LOOP with large and small increments

\ Contributed by Andrew Haley

MAX-UINT 8 RSHIFT 1+ CONSTANT USTEP
USTEP NEGATE CONSTANT -USTEP
MAX-INT 7 RSHIFT 1+ CONSTANT STEP
STEP NEGATE CONSTANT -STEP

VARIABLE BUMP

T{ : GD8 BUMP ! DO 1+ BUMP @ +LOOP ; -> }T

T{ 0 MAX-UINT 0 USTEP GD8 -> 256 }T
T{ 0 0 MAX-UINT -USTEP GD8 -> 256 }T

\ T{ 0 MAX-INT MIN-INT STEP GD8 -> 256 }T
\ T{ 0 MIN-INT MAX-INT -STEP GD8 -> 256 }T

\ Two's complement arithmetic, wraps around modulo wordsize
\ Only tested if the Forth system does wrap around, use of conditional
\ compilation deliberately avoided

MAX-INT 1+ MIN-INT = CONSTANT +WRAP?
MIN-INT 1- MAX-INT = CONSTANT -WRAP?
MAX-UINT 1+ 0=       CONSTANT +UWRAP?
0 1- MAX-UINT =      CONSTANT -UWRAP?

: GD9  ( n limit start step f result -- )
   >R IF GD8 ELSE 2DROP 2DROP R@ THEN -> R> }T
;

\ T{ 0 0 0  USTEP +UWRAP? 256 GD9
\ T{ 0 0 0 -USTEP -UWRAP?   1 GD9
\ T{ 0 MIN-INT MAX-INT  STEP +WRAP? 1 GD9
\ T{ 0 MAX-INT MIN-INT -STEP -WRAP? 1 GD9

\ ------------------------------------------------------------------------------
TESTING DO +LOOP with maximum and minimum increments

: (-MI) MAX-INT DUP NEGATE + 0= IF MAX-INT NEGATE ELSE -32767 THEN ;
(-MI) CONSTANT -MAX-INT

\ T{ 0 1 0 MAX-INT GD8  -> 1 }T
\ T{ 0 -MAX-INT NEGATE -MAX-INT OVER GD8  -> 2 }T

\ T{ 0 MAX-INT  0 MAX-INT GD8  -> 1 }T
\ T{ 0 MAX-INT  1 MAX-INT GD8  -> 1 }T
\ T{ 0 MAX-INT -1 MAX-INT GD8  -> 2 }T
\ T{ 0 MAX-INT DUP 1- MAX-INT GD8  -> 1 }T

\ T{ 0 MIN-INT 1+   0 MIN-INT GD8  -> 1 }T
\ T{ 0 MIN-INT 1+  -1 MIN-INT GD8  -> 1 }T
\ T{ 0 MIN-INT 1+   1 MIN-INT GD8  -> 2 }T
\ T{ 0 MIN-INT 1+ DUP MIN-INT GD8  -> 1 }T

\ ------------------------------------------------------------------------------
TESTING +LOOP setting I to an arbitrary value

\ The specification for +LOOP permits the loop index I to be set to any value
\ including a value outside the range given to the corresponding  DO.

\ SET-I is a helper to set I in a DO ... +LOOP to a given value
\ n2 is the value of I in a DO ... +LOOP
\ n3 is a test value
\ If n2=n3 then return n1-n2 else return 1
: SET-I  ( n1 n2 n3 -- n1-n2 | 1 )
   OVER = IF - ELSE 2DROP 1 THEN
;

: -SET-I ( n1 n2 n3 -- n1-n2 | -1 )
   SET-I DUP 1 = IF NEGATE THEN
;

: PL1 20 1 DO I 18 I 3 SET-I +LOOP ;
\ T{ PL1 -> 1 2 3 18 19 }T
: PL2 20 1 DO I 20 I 2 SET-I +LOOP ;
\ T{ PL2 -> 1 2 }T
: PL3 20 5 DO I 19 I 2 SET-I DUP 1 = IF DROP 0 I 6 SET-I THEN +LOOP ;
\ T{ PL3 -> 5 6 0 1 2 19 }T
: PL4 20 1 DO I MAX-INT I 4 SET-I +LOOP ;
\ T{ PL4 -> 1 2 3 4 }T
: PL5 -20 -1 DO I -19 I -3 -SET-I +LOOP ;
\ T{ PL5 -> -1 -2 -3 -19 -20 }T
: PL6 -20 -1 DO I -21 I -4 -SET-I +LOOP ;
\ T{ PL6 -> -1 -2 -3 -4 }T
: PL7 -20 -1 DO I MIN-INT I -5 -SET-I +LOOP ;
\ T{ PL7 -> -1 -2 -3 -4 -5 }T
: PL8 -20 -5 DO I -20 I -2 -SET-I DUP -1 = IF DROP 0 I -6 -SET-I THEN +LOOP ;
\ T{ PL8 -> -5 -6 0 -1 -2 -20 }T

\ ------------------------------------------------------------------------------
TESTING multiple RECURSEs in one colon definition

: ACK ( m n -- u )    \ Ackermann function, from Rosetta Code
   OVER 0= IF  NIP 1+ EXIT  THEN       \ ack(0, n) = n+1
   SWAP 1- SWAP                        ( -- m-1 n )
   DUP  0= IF  1+  RECURSE EXIT  THEN  \ ack(m, 0) = ack(m-1, 1)
   1- OVER 1+ SWAP RECURSE RECURSE     \ ack(m, n) = ack(m-1, ack(m,n-1))
;

T{ 0 0 ACK ->  1 }T
T{ 3 0 ACK ->  5 }T
T{ 2 4 ACK -> 11 }T

\ ------------------------------------------------------------------------------
TESTING multiple ELSE's in an IF statement
\ Discussed on comp.lang.forth and accepted as valid ANS Forth

: MELSE IF 1 ELSE 2 ELSE 3 ELSE 4 ELSE 5 THEN ;
T{ 0 MELSE -> 2 4 }T
T{ -1 MELSE -> 1 3 5 }T

\ ------------------------------------------------------------------------------
TESTING IMMEDIATE with CONSTANT  VARIABLE and CREATE [ ... DOES> ]

T{ 123 CONSTANT IW1 IMMEDIATE IW1 -> 123 }T
T{ : IW2 IW1 LITERAL ; IW2 -> 123 }T
T{ VARIABLE IW3 IMMEDIATE 234 IW3 ! IW3 @ -> 234 }T
T{ : IW4 IW3 [ @ ] LITERAL ; IW4 -> 234 }T
T{ :NONAME [ 345 ] IW3 [ ! ] ; DROP IW3 @ -> 345 }T
\ T{ CREATE IW5 456 , IMMEDIATE -> }T
\ T{ :NONAME IW5 [ @ IW3 ! ] ; DROP IW3 @ -> 456 }T
\ T{ : IW6 CREATE , IMMEDIATE DOES> @ 1+ ; -> }T
\ T{ 111 IW6 IW7 IW7 -> 112 }T
\ T{ : IW8 IW7 LITERAL 1+ ; IW8 -> 113 }T
\ T{ : IW9 CREATE , DOES> @ 2 + IMMEDIATE ; -> }T
: FIND-IW BL WORD FIND NIP ;  ( -- 0 | 1 | -1 )
\ T{ 222 IW9 IW10 FIND-IW IW10 -> -1 }T   \ IW10 is not immediate
\ T{ IW10 FIND-IW IW10 -> 224 1 }T        \ IW10 becomes immediate

\ ------------------------------------------------------------------------------
TESTING that IMMEDIATE doesn't toggle a flag

VARIABLE IT1 0 IT1 !
: IT2 1234 IT1 ! ; IMMEDIATE IMMEDIATE
T{ : IT3 IT2 ; IT1 @ -> 1234 }T

\ ------------------------------------------------------------------------------

COMMENT Skipping RECURSE tests with :NONAME
0 [IF]
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
[THEN]

\ -----------------------------------------------------------------------------

CR .( End of additional Core tests) CR

