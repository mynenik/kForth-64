\ big-extras.4th
\
\   Additional definitions for big number arithmetic
\   using FSL #47 big.4th
\
\ K. Myneni, 2026-8-01
\
\ Revisions:
\  2028-08-12 km, revise BIG_S^N to handle 0 and negative
\    arguments.

\ Move a big number from src address to destination
: big-move ( addr1 addr2 -- )
  OVER @ ABS 1+ CELLS    \ Number of address units in the number
  MOVE ;

\ "big factorial"  
: big! ( n -- addr )
   big-here 1 big, 1 big,  \ addr of new big 1
   swap abs 1+ 200 min
   1 do dup I BIG*S loop ;

\ Raise single length signed integer to a positive
\ integer power and return the result as a big number
: big_s^n ( n1 n2+ -- addr)
   dup 0= IF
     2drop big-here 1 big, 1 big, EXIT  \ big 1
   THEN
   dup 0< IF
     2drop -24 throw
   THEN               ( n1 n2+)
   over 0= IF
     2drop big-here 1 big, 0 big, EXIT  \ big 0
   THEN
   2dup 2 mod 0<> swap 0< and >r  ( n1 n2+) ( R: bsign)
   swap abs dup >r    ( n2+ |n1|) ( R: |n1| bsign)
   1 big,  big,       ( n2+)      ( R: |n1| bsign)
   big-here 2 cells - swap r> swap ( addr |n1| n2+) ( R: bsign) 
   1 ?DO 2dup big*s LOOP drop
   r> IF dup bignegate THEN ;


