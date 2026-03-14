\ Additional tests on the the ANS Forth Core word set

\ This program was written by Gerry Jackson in 2007, with contributions from
\ others where indicated, and is in the public domain - it can be distributed
\ and/or modified in any way but please retain this notice.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\ The tests are not claimed to be comprehensive or correct 

\ ------------------------------------------------------------------------------
\ The tests are based on John Hayes test program for the core word set
\
\ This file provides some more tests on Core words where the original Hayes
\ tests are thought to be incomplete

\ Words tested in this file are:
\     DO I +LOOP RECURSE ELSE >IN IMMEDIATE FIND IF...BEGIN...REPEAT ALLOT DOES>
\ and
\     Parsing behaviour
\     Number prefixes # $ % and 'A' character input
\     Definition names
\     NONDEFERRED
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

VARIABLE SKIPPED-TESTS     0 SKIPPED-TESTS !
VARIABLE CORE-PLUS-ERRORS  0 CORE-PLUS-ERRORS !

:noname  ( c-addr u -- | Keep a cumulative error count )
  1 core-plus-errors +! error1 ;  error-xt !

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
\ COMMENT Skipping tests: DO +LOOP with large and small increments
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

T{ 0 MAX-INT MIN-INT STEP GD8 -> 256 }T
T{ 0 MIN-INT MAX-INT -STEP GD8 -> 256 }T

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

T{ 0 0 0  USTEP +UWRAP? 256 GD9
T{ 0 0 0 -USTEP -UWRAP?   1 GD9
T{ 0 MIN-INT MAX-INT  STEP +WRAP? 1 GD9
T{ 0 MAX-INT MIN-INT -STEP -WRAP? 1 GD9

\ ------------------------------------------------------------------------------
TESTING DO +LOOP with maximum and minimum increments

: (-MI) MAX-INT DUP NEGATE + 0= IF MAX-INT NEGATE ELSE -32767 THEN ;
(-MI) CONSTANT -MAX-INT

T{ 0 1 0 MAX-INT GD8  -> 1 }T
T{ 0 -MAX-INT NEGATE -MAX-INT OVER GD8  -> 2 }T

T{ 0 MAX-INT  0 MAX-INT GD8  -> 1 }T
T{ 0 MAX-INT  1 MAX-INT GD8  -> 1 }T
T{ 0 MAX-INT -1 MAX-INT GD8  -> 2 }T
T{ 0 MAX-INT DUP 1- MAX-INT GD8  -> 1 }T

T{ 0 MIN-INT 1+   0 MIN-INT GD8  -> 1 }T
T{ 0 MIN-INT 1+  -1 MIN-INT GD8  -> 1 }T
T{ 0 MIN-INT 1+   1 MIN-INT GD8  -> 2 }T
T{ 0 MIN-INT 1+ DUP MIN-INT GD8  -> 1 }T

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
T{ PL1 -> 1 2 3 18 19 }T
: PL2 20 1 DO I 20 I 2 SET-I +LOOP ;
T{ PL2 -> 1 2 }T
: PL3 20 5 DO I 19 I 2 SET-I DUP 1 = IF DROP 0 I 6 SET-I THEN +LOOP ;
T{ PL3 -> 5 6 0 1 2 19 }T
: PL4 20 1 DO I MAX-INT I 4 SET-I +LOOP ;
T{ PL4 -> 1 2 3 4 }T
: PL5 -20 -1 DO I -19 I -3 -SET-I +LOOP ;
T{ PL5 -> -1 -2 -3 -19 -20 }T
: PL6 -20 -1 DO I -21 I -4 -SET-I +LOOP ;
T{ PL6 -> -1 -2 -3 -4 }T
: PL7 -20 -1 DO I MIN-INT I -5 -SET-I +LOOP ;
T{ PL7 -> -1 -2 -3 -4 -5 }T
: PL8 -20 -5 DO I -20 I -2 -SET-I DUP -1 = IF DROP 0 I -6 -SET-I THEN +LOOP ;
T{ PL8 -> -5 -6 0 -1 -2 -20 }T

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

\ -----------------------------------------------------------------------------
TESTING multiple ELSE's in an IF statement
\ Discussed on comp.lang.forth and accepted as valid ANS Forth

: MELSE IF 1 ELSE 2 ELSE 3 ELSE 4 ELSE 5 THEN ;
T{ 0 MELSE -> 2 4 }T
T{ -1 MELSE -> 1 3 5 }T

\ ------------------------------------------------------------------------------
COMMENT Skipping tests: manipulation of >IN in interpreter mode
0 [IF]
TESTING manipulation of >IN in interpreter mode

T{ 12345 DEPTH OVER 9 < 34 AND + 3 + >IN ! -> 12345 2345 345 45 5 }T
T{ 14145 8115 ?DUP 0= 34 AND >IN +! TUCK MOD 14 >IN ! GCD CALCULATION -> 15 }T
[THEN]

2 SKIPPED-TESTS +!
\ ------------------------------------------------------------------------------
TESTING IMMEDIATE / NONDEFERRED with CONSTANT  VARIABLE and CREATE [ ... DOES> ]

T{ 123 CONSTANT IW1 IMMEDIATE IW1 -> 123 }T
T{ : IW2 IW1 LITERAL ; IW2 -> 123 }T
T{ VARIABLE IW3 IMMEDIATE NONDEFERRED 234 IW3 ! IW3 @ -> 234 }T
T{ : IW4 IW3 [ @ ] LITERAL ; IW4 -> 234 }T
T{ :NONAME [ 345 ] IW3 [ ! ] ; DROP IW3 @ -> 345 }T

T{ CREATE IW5 1 CELLS ALLOT? 456 SWAP ! IMMEDIATE -> }T
T{ :NONAME IW5 [ @ IW3 ! ] ; DROP IW3 @ -> 456 }T
T{ : IW6 CREATE 1 CELLS ALLOT? ! IMMEDIATE NONDEFERRED DOES> @ 1+ ; -> }T
T{ 111 IW6 IW7 IW7 -> 112 }T
T{ : IW8 IW7 LITERAL 1+ ; IW8 -> 113 }T
T{ : IW9 CREATE 1 CELLS ALLOT? ! DOES> @ 2 + IMMEDIATE NONDEFERRED ; -> }T
: FIND-IW BL WORD FIND NIP ;  ( -- 0 | 1 | -1 )
T{ 222 IW9 IW10 FIND-IW IW10 -> -1 }T   \ IW10 is not immediate
T{ IW10 FIND-IW IW10 -> 224 1 }T        \ IW10 becomes immediate

\ ------------------------------------------------------------------------------
TESTING that IMMEDIATE doesn't toggle a flag

VARIABLE IT1 0 IT1 !
: IT2 1234 IT1 ! ; IMMEDIATE IMMEDIATE
T{ : IT3 IT2 ; IT1 @ -> 1234 }T

\ ------------------------------------------------------------------------------
TESTING parsing behaviour of S" ." and (
\ which should parse to just beyond the terminating character no space needed

T{ : GC5 S" A string"2DROP ; GC5 -> }T
T{ ( A comment)1234 -> 1234 }T
T{ : PB1 CR ." You should see 2345: "." 2345"( A comment) CR ; PB1 -> }T

\ ------------------------------------------------------------------------------
TESTING number prefixes # $ %
COMMENT Skipping tests: 'c' character input
\ Adapted from the Forth 200X Draft 14.5 document

VARIABLE OLD-BASE
DECIMAL BASE @ OLD-BASE !
T{ #1289 -> 1289 }T
T{ #-1289 -> -1289 }T
T{ $12eF -> 4847 }T
T{ $-12eF -> -4847 }T
T{ %10010110 -> 150 }T
T{ %-10010110 -> -150 }T
\ T{ 'z' -> 122 }T
\ T{ 'Z' -> 90 }T
\ Check BASE is unchanged
T{ BASE @ OLD-BASE @ = -> TRUE }T

\ Repeat in Hex mode
16 OLD-BASE ! 16 BASE !
T{ #1289 -> 509 }T
T{ #-1289 -> -509 }T
T{ $12eF -> 12EF }T
T{ $-12eF -> -12EF }T
T{ %10010110 -> 96 }T
T{ %-10010110 -> -96 }T
\ T{ 'z' -> 7a }T
\ T{ 'Z' -> 5a }T
\ Check BASE is unchanged
T{ BASE @ OLD-BASE @ = -> TRUE }T   \ 2

DECIMAL
\ Check number prefixes in compile mode
T{ : nmp  #8327 $-2cbe %011010111 ( ''') ; nmp -> 8327 -11454 215 ( 39) }T

4 SKIPPED-TESTS +!
\ ------------------------------------------------------------------------------
TESTING definition names
\ should support {1..31} graphical characters
: !"#$%&'()*+,-./0123456789:;<=>? 1 ;
T{ !"#$%&'()*+,-./0123456789:;<=>? -> 1 }T
: @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^ 2 ;
T{ @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^ -> 2 }T
: _`abcdefghijklmnopqrstuvwxyz{|} 3 ;
T{ _`abcdefghijklmnopqrstuvwxyz{|} -> 3 }T
: _`abcdefghijklmnopqrstuvwxyz{|~ 4 ;     \ Last character different
T{ _`abcdefghijklmnopqrstuvwxyz{|~ -> 4 }T
T{ _`abcdefghijklmnopqrstuvwxyz{|} -> 3 }T

\ ------------------------------------------------------------------------------
TESTING FIND with a zero length string and a non-existent word

CREATE EMPTYSTRING 1 CELLS ALLOT \ 0 C,
: EMPTYSTRING-FIND-CHECK ( c-addr 0 | xt 1 | xt -1 -- t|f )
    DUP IF ." FIND returns a TRUE value for an empty string!" CR THEN
    0= SWAP EMPTYSTRING = = ;
T{ EMPTYSTRING FIND EMPTYSTRING-FIND-CHECK -> TRUE }T

CREATE NON-EXISTENT-WORD 16 CHARS ALLOT  \ Same as in exceptiontest.fth
T{ c" $$QWEQWEQWERT$$" NON-EXISTENT-WORD 16 MOVE -> }T
T{ NON-EXISTENT-WORD FIND -> NON-EXISTENT-WORD 0 }T

\ -----------------------------------------------------------------------------

CR .( Error Count: ) CORE-PLUS-ERRORS ? CR
CR .( Tests Skipped [see comments above]: ) SKIPPED-TESTS ?
CR .( End of additional Core tests) CR

