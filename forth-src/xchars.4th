\ xchars.4th
\
\ Words from the optional xchar wordset in Forth 2012.
\ ( see http://forth-standard.org/standard/xchar )
\
\ The words below are standard words in the reference
\ implementation form, from the documentation, adapted
\ for kForth.
\
\ Glossary
\
\   CHAR    ( "name" -- xchar )
\   [CHAR]  ( "name" -- rt:xchar )
\   X-SIZE  ( xc-addr u1 -- u2 )
\   XC-SIZE ( xchar -- u )
\   XC!+    ( xchar xc-addr -- xcaddr' )
\   XC!+?   ( xchar xc-addr1 u1 -- xc-addr2 u2 flag )
\   XC@+    ( xc-addr1 -- xc-addr2 xchar )
\   XCHAR-  ( xc-addr1 -- xc-addr2 )
\   XCHAR+  ( xc-addr1 -- xc-addr2 )
\   XEMIT   ( xchar -- )
\   XKEY    ( -- xchar )
\   XC-LEN  ( xc-addr u1 -- u2 )
\ 
\ Revisions:
\   2017-05-09  created using reference implementation
\   2019-11-27  added: CHAR  [CHAR] XCHAR-
\
BASE @

[undefined] U>= [IF]
: U>= ( u1 u2 -- flag ) 2DUP = >R  U> R>  OR ; 
[THEN]

HEX

\ Return the number of pchars used to encode the first xchar
\ stored in the string xc-addr u1.

: X-SIZE ( xc-addr u1 -- u2 )
   0= IF DROP 0 EXIT THEN
   \ length of UTF-8 char starting at u8-addr (accesses only u8-addr)
   C@
   DUP 80 U< IF DROP 1 EXIT THEN
   DUP c0 U< IF ( -77 THROW ) abort THEN
   DUP e0 U< IF DROP 2 EXIT THEN
   DUP f0 U< IF DROP 3 EXIT THEN
   DUP f8 U< IF DROP 4 EXIT THEN
   DUP fc U< IF DROP 5 EXIT THEN
   DUP fe U< IF DROP 6 EXIT THEN
   ( -77 throw ) abort ;

\ Return the number of pchars used to encode xchar.

: XC-SIZE ( xchar -- u )
   DUP 80 U< IF DROP 1 EXIT THEN \ special case ASCII
   800 2 >R
   BEGIN 2DUP U>= 
   WHILE 5 LSHIFT R> 1+ >R 
         DUP 0= IF 2DROP R> EXIT THEN 
   REPEAT 
   2DROP R>
;

\ Store xchar at xc-addr and return the next memory location

: XC!+ ( xchar xc-addr -- xc-addr' )
   OVER 80 U< IF TUCK C! CHAR+ EXIT THEN \ special case ASCII
   >R 0 SWAP 3F
   BEGIN 2DUP U> WHILE
     2/ >R DUP 3F AND 80 OR SWAP 6 RSHIFT R>
   REPEAT 
   7F XOR 2* OR R>
   BEGIN OVER 80 U< 0= WHILE 
     TUCK C! CHAR+ 
   REPEAT NIP
;

\ Store xchar at xc-addr1 u1. xc-addr2 u2 is the remaining string.
\ If xchar did fit into the buffer, flag is true, otherwise flag
\ is false, and xc-addr2 u2 equal xc-addr1 u1.
\ XC!+? is safe for buffer overflows.

: XC!+? ( xchar xc-addr1 u1 -- xc-addr2 u2 flag )
   >R OVER XC-SIZE R@ OVER U< IF ( xchar xc-addr1 len r: u1 )
     \ not enough space
     DROP NIP R> FALSE
   ELSE
     >R XC!+ R> R> SWAP - TRUE
   THEN ;

\ Fetch xchar at xc-addr1. xc-addr2 points to the first
\ memory location after the retrieved xchar. 

: XC@+ ( xc-addr1 -- xc-addr2 xchar )
   COUNT DUP 80 U< IF EXIT THEN \ special case ASCII
   7F AND 40 >R
   BEGIN DUP R@ AND WHILE R@ XOR
     6 LSHIFT R> 5 LSHIFT >R >R COUNT
     3F AND R> OR
   REPEAT R> DROP
;

\ Backward-compatible CHAR which works for xchars
: CHAR ( "name" -- xchar )  BL WORD COUNT DROP XC@+ NIP ;

\ Backward-compatible [CHAR] which works for xchars
: [CHAR] ( "name" -- rt:xchar )  CHAR POSTPONE LITERAL ; IMMEDIATE

\ Backup to address of previous xchar 
: XCHAR- ( xc-addr1 -- xc-addr2 )
    BEGIN 1 CHARS - DUP C@ C0 AND 80 <> UNTIL ;

\ Add size of xchar stored at xc-addr1 to this address, giving xc-addr2.

: XCHAR+ ( xc-addr1 -- xc-addr2 ) XC@+ DROP ;

\ Print an xchar on the terminal.

: XEMIT ( xchar -- )
   DUP 80 U< IF EMIT EXIT THEN \ special case ASCII
   0 SWAP 3F
   BEGIN 2DUP U> WHILE
     2/ >R DUP 3F AND 80 OR SWAP 6 RSHIFT R>
   REPEAT 7F XOR 2* OR
   BEGIN DUP 80 U< 0= WHILE EMIT REPEAT DROP
;

\ Read an xchar from the terminal. Discard all input events
\ up to the completion of the xchar.

: XKEY ( -- xchar )
   KEY DUP 80 U< IF EXIT THEN \ special case ASCII
   7F AND 40 >R
   BEGIN DUP R@ AND WHILE R@ XOR
     6 LSHIFT R> 5 LSHIFT >R >R KEY
     3F AND R> OR
   REPEAT R> DROP ;

\ ------- Non-Standard Words ---------

\ Return the length in code points of an xchar string

: XC-LEN ( xc-addr u1 -- u2 )
    0 >r 2dup + >r drop
    begin xchar+ dup r@ < while r> r> 1+ >r >r repeat
    drop r> drop r> 1+ ;

BASE !
\ =============================
false [IF]
[undefined] T{ [IF] s" ttester.4th" included  [THEN]
BASE @
HEX

TESTING XC!+?
T{ ffff PAD 4 XC!+? -> PAD 3 + 1 TRUE }T

TESTING XC-SIZE
T{      0 XC-SIZE -> 1 }T
T{     7f XC-SIZE -> 1 }T
T{     80 XC-SIZE -> 2 }T
T{    7ff XC-SIZE -> 2 }T
T{    800 XC-SIZE -> 3 }T
T{   ffff XC-SIZE -> 3 }T
T{  10000 XC-SIZE -> 4 }T
T{ 1fffff XC-SIZE -> 4 }T

BASE !
[THEN]
