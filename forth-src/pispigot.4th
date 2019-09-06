\ pispigot.4th 
\
\ Print pi to arbitrary number of digits
\
\ Obtained from: http://wiki.forthfreak.net/index.cgi?PiSpigot
\
\ Great Computer Language Shootout
\ http://shootout.alioth.debian.org/
\ contributed by Albert van der Horst, Ian Osgood
\ modified to run under kForth by K. Myneni, 27Jan06; rev 28Jan06

\ ==== kForth requires ===================
include ans-words
: ptr  create 1 cells ?allot ! does> a@ ;
\ =======================================

\ read NUM from last command line argument
\ 0. argc @ 1- arg >number 2drop drop constant NUM

1000 constant NUM  \ set number of digits here

\
\ Arbitrary precision arithmetic
\ A p-number consists of a count plus count cells, 2-complement small-endian
\

\ Shorthand.
: p>size ( pn -- size ) POSTPONE @ ; IMMEDIATE
: p>last ( pn -- msb ) DUP p>size CELLS + ;
: [I] POSTPONE I POSTPONE CELLS POSTPONE + ; IMMEDIATE

\ Give sign of p
: p0< ( p -- flag ) p>last @ 0< ;

\ Copy a p-number to another buffer
: pcopy ( src dst -- ) OVER p>size 1+ CELLS MOVE ;

\ Check for overflow, extend the p-number if needed
: ?carry ( carry p -- ) 2DUP p0< <> IF 1 OVER +!  p>last ! ELSE 2DROP THEN ;

\ In-place multiply by an unsigned integer
0 value n
0 ptr p
: p* ( { n p -- } ) to p  to n
  p p0<  0 0 ( sign dcarry )
  p p>size 1+ 1 DO
    p [I] @       ( digit )
    n UM* D+ SWAP ( carry digit )
    p [I] ! 0
  LOOP
  ROT n UM* D+ DROP  p ?carry ;

\ Ensure two p-numbers are the same size before adding
0 value n
0 ptr p
0 value sign
: extend  OVER p0< ( { p n sign -- } ) to sign to n to p
  p p>size 1+  n p +!  p p>size 1+ SWAP DO sign p [i] ! LOOP ;
: ?extend ( p1 p2 -- p1 p2 )
  OVER p>size OVER p>size - ?DUP IF
    DUP 0< IF >R OVER R> NEGATE
    ELSE OVER SWAP
    THEN extend
  THEN ;

\ In-place addition of another p-number
0 ptr src
0 ptr p
: p+  ?extend ( { src p -- } ) to p to src 
  src p0< p p0<  0 0 ( sign sign dcarry )
  p p>size 1+ 1 DO
    p   [I] @ 0 D+
    src [I] @ 0 D+ SWAP
    p   [I] ! 0
  LOOP
  DROP + + p ?carry ; \ add signs, check for overflow
 
\ In-place subtraction of another p-number
0 ptr src
0 ptr p
: p-  ?extend ( { src p -- } ) to p to src 
  src p0< p p0<  0 0 ( sign sign dcarry )
  p p>size 1+ 1 DO
    p   [I] @ 0 D+
    src [I] @ 0 D- SWAP
    p   [I] ! s>d
  LOOP
  DROP + + p ?carry ; \ add signs, check for overflow

\
\ pi-spigot specific computation
\

\ approximate upper limit on size required (1000 -> 1166)
NUM 6 5 */ 2+ CELLS constant SIZE

\ Current z transformation

CREATE aq SIZE ALLOT  1 1 aq 2!
CREATE ar SIZE ALLOT  0 1 ar 2!
    \ "as" identical zero and remains so
CREATE at SIZE ALLOT  1 1 at 2!

\ Generate non zero parts of next matrix ( -- q r t )
VARIABLE K
: generate   1 K +!   K @  DUP 2* 1+  DUP 2* SWAP ;

\ temporary p-number buffer 
CREATE HERE 1024 1024 * CELLS ALLOT  ( comment this line for ANS Forth )   

\ Multiply z from the left
: compose< ( bq br bt -- )
  DUP at p*  ar p*  aq HERE pcopy  HERE p*  HERE ar p+  aq p* ;

\ Multiply z from the right
: compose> ( bt br bq -- )
  DUP aq p*  ar p*  at HERE pcopy  HERE p*  HERE ar p-  at p* ;

\ Calculate z at point 3, leaving integer part and fractional part.
\ Division is by multiple subtraction until the fractional part is
\ negative.
: z(3)  ( -- n pfract ) HERE  aq OVER pcopy  3 OVER p*  ar OVER p+
  0 BEGIN SWAP at OVER p-  DUP p0< 0= WHILE SWAP 1+ REPEAT ;

\ Calculate z at point 4, based on the result for point 3
\ and decide whether the integer parts are the same.
: z(4)same? ( pfract -- flag ) aq OVER p+  p0< ;

: pidigit ( -- nextdigit)
    BEGIN z(3) z(4)same? 0= WHILE DROP generate compose< REPEAT
    1   OVER 10 *   10   compose> ;

: printcount ( n -- ) 9 emit [char] : emit 1 U.R CR ;

\ ( digits - remaining)
: printdigit   pidigit [CHAR] 0 + EMIT
    DUP 10 MOD 0= IF printcount ELSE DROP THEN ;

\ Spigot n digits with formatting ( n --)
: spigot  DUP 1+ 1 DO I printdigit LOOP
    DUP 10 MOD IF 10 2DUP MOD - SPACES printcount ELSE DROP THEN ;

NUM spigot bye


