\ random.4th
\
\ Assorted simple pseudo-random number generators
\ for 32-bit and 64-bit Forth systems.
\
\ Requires ans-words.4th
\
\ References
\  1. https://en.wikipedia.org/wiki/Linear_congruential_generator
\  2. https://nuclear.llnl.gov/CNP/rng/rngman/node4.html
\  3. See ranqd1 in Numerical Recipes, ch. 7, 2nd ed.; the
\       given test values for seed of 0 may be reproduced
\       from RANDOM under kForth-32.
base @
decimal
 
1 CELLS 8 = constant 64-bit?

64-bit? [IF]
c" 28629335555777941757" number? 2drop 
                     constant  LCG_MUL   \ [2]
3037000493           constant  LCG_ADD   \ [2]
hex ff80000000000000 constant  ROL9_MASK
decimal
55                   constant  ROL9_RS
[ELSE]
1664525              constant  LCG_MUL   \ [3]
1013904223           constant  LCG_ADD   \ [3]
hex ff800000         constant  ROL9_MASK
decimal
23                   constant  ROL9_RS
[THEN]
decimal

variable seed

\ from old versions of glibc [1]
: random-aphwb  ( -- u ) seed @ 69069 * 1+ dup seed ! ;

: random  ( -- u ) LCG_MUL seed @ * LCG_ADD + dup seed ! ;

: rol9 ( u1 -- u2 | rotate u1 left by 9 bits )
    dup ROL9_MASK and ROL9_RS rshift swap 9 lshift or ;     

: random2 ( -- u ) LCG_MUL seed @ * LCG_ADD + rol9 dup seed ! ;

: random2p ( -- u )
[ 64-bit? ] [IF]
    random2 255 and 56 lshift
    random2 255 and 48 lshift or
    random2 255 and 40 lshift or
    random2 255 and 32 lshift or
    random2 255 and 24 lshift or
[ELSE]
    random2 255 and 24 lshift
[THEN]
    random2 255 and 16 lshift or
    random2 255 and  8 lshift or
    random2 255 and or ;


base !
