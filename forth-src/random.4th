\ random.4th
\
\ Assorted simple random number generators
\
\ Needs to be updated for 64-bit systems -- km, 2020-01-26

base @ 
hex
ff800000 constant ROL9MASK
decimal

variable seed

: random  ( -- u ) seed @ 107465 * 234567 + dup seed ! ;

: rol9 ( u1 -- u2 | rotate u1 left by 9 bits )
    dup ROL9MASK and 23 rshift swap 9 lshift or ;     

: random2 ( -- u ) seed @ 107465 * 234567 + rol9 dup seed ! ;

: random2p ( -- u )
	   random2 255 and 24 lshift
	   random2 255 and 16 lshift or
	   random2 255 and  8 lshift or
	   random2 255 and or ;

: random-aphwb  ( -- u ) seed @ 69069 * 1+ dup seed ! ;

base !
