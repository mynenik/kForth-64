\ Conway's Game of Life, or Occam's Razor Dulled

\ The original ANS Forth version by Leo Wong (see bottom) 
\   has been modified slightly to allow it to run under 
\   kForth. Also, delays have been changed from 1000 ms to 
\   100 ms for faster update --- K. Myneni, 12-26-2001
\  
include ans-words
include strings
include ansi
\ MARKER Genesis
: CHARS ;

\ ANS Forth this life is remains and
1 CHARS CONSTANT /Char
: C+!  ( char c-addr -- )  DUP >R  C@ +  R> C! ;

\ the universal pattern
25 CONSTANT How-Deep
80 CONSTANT How-Wide
How-Wide How-Deep *  1-  \ 1- prevents scrolling on my screen
   CONSTANT Homes

\ world wrap
: World
   CREATE  ( -- )  Homes CHARS ALLOT
    DOES>  ( u -- c-addr )  SWAP Homes +  Homes MOD  CHARS + ;

World old
World new

\ biostatistics

\ begin hexadecimal numbering
HEX  \ hex xy : x holds life , y holds neighbors count

10 CONSTANT Alive  \ 0y = not alive

\ Conway's rules:
\ a life depends on the number of its next-door neighbors

\ it dies if it has fewer than 2 neighbors
: Lonely  ( char -- flag )  12 < ;

\ it dies if it has more than 3 neighbors
: Crowded  ( char -- flag )  13 > ;

: -Sustaining  ( char -- flag )
    DUP Lonely  SWAP Crowded  OR ;

\ it is born if it has exactly 3 neighbors
: Quickening  ( char -- flag )
    03 = ;

\ back to decimal
DECIMAL

\ compass points
: N  ( i -- j )  How-Wide - ;
: S  ( i -- j )  How-Wide + ;
: E  ( i -- j )  1+ ;
: W  ( i -- j )  1- ;

\ census
: Home+!  ( -1|1 i -- )  >R  Alive *  R> new C+! ;

: Neighbors+!  ( -1|0|1 i -- )
   2DUP N W new C+!  2DUP N new C+!  2DUP N E new C+!
   2DUP   W new C+!  (     i      )  2DUP   E new C+!
   2DUP S W new C+!  2DUP S new C+!       S E new C+! ;

: Bureau-of-Vital-Statistics ( -1|1 i -- )
   2DUP Home+!  Neighbors+! ;

\ mortal coils
CHAR ? CONSTANT Soul
    BL CONSTANT Body

\ at home
: Home  ( char i -- )  How-Wide /MOD AT-XY  EMIT ;

\ changes, changes
: Is-Born  ( i -- )
   Soul OVER Home
   1 SWAP Bureau-of-Vital-Statistics ;
: Dies  ( i -- )
   Body OVER Home
   -1 SWAP Bureau-of-Vital-Statistics ;

\ the one and the many
: One  ( c-addr -- i )
   0 old -  /Char / ;
: Everything  ( -- )
   0 old  Homes
   BEGIN  DUP
   WHILE  OVER C@  DUP Alive AND
      IF   -Sustaining IF  OVER One Dies     THEN
      ELSE  Quickening IF  OVER One Is-Born  THEN THEN
      1 /STRING
   REPEAT  2DROP
   How-Wide 1- How-Deep 1- AT-XY ;

\ in the beginning
: Void  ( -- )  
   0 old  Homes BLANK ;

\ spirit
: Voice  ( -- c-addr u )
   PAGE
   ." Say: "  0 new  DUP Homes ACCEPT ;

\ subtlety
: Serpent  ( -- )
   0 2 AT-XY  ." Press a key for knowledge."  KEY DROP
   0 2 AT-XY  ." Press space to re-start, Esc to escape life." ;

\ the primal state
: Innocence  ( -- )
   Homes 0
   DO  I new C@  Alive /  I Neighbors+!  LOOP ;

\ children become parents
: Passes  ( -- )  0 new  0 old  Homes  CMOVE ;

\ a garden
: Paradise  ( c-addr u -- )
   >R  How-Deep How-Wide *  How-Deep 2 MOD 0=  How-Wide AND -
   R@  -  2/  old
   R>  CMOVE
   0 old  Homes 0
   DO  COUNT BL <>
       DUP IF  Soul I Home  THEN
       Alive AND  I new C!
   LOOP  DROP
   Serpent
   Innocence Passes ;

: Creation  ( -- )  Void Voice Paradise ;

\ the human element

( 1000) 100 CONSTANT Ideas
: Dreams  ( -- )  Ideas MS ;

( 1000) 100 CONSTANT Images
: Meditation  ( -- )  Images MS ;

\ free will
: Action  ( -- char )
   KEY? DUP 
   IF  DROP KEY
       DUP BL = IF  Creation  THEN
   THEN ;

\ environmental dependence
27 CONSTANT Escape

\ history
: Goes-On  ( -- )
   BEGIN  Everything Passes
          Dreams Action Meditation
          Escape = UNTIL ;

\ a vision
: Life  ( -- )  Creation Goes-On ;

Life

\ 950724 + 970703 +

\ Copyright 1995 Leo Wong
\ hello@albany.net
\ http://www.albany.net/~hello/
