\ kiss.4th
\
\ 32 and 64-bit variants of the KISS pseudo-random numbers
\ generator of G. Marsaglia [1].
\
\ The 32-bit implementation here is a slight variant of 
\ the code posted to comp.lang.forth by Marcel Hendrix 
\ on 29 Jan 2003 and 11 June 2016 [2].
\
\ The 64-bit version is translated from a posting by
\ Marsaglia to thecodingforums.com [3]. There is a test
\ to ensure that it is generating the intended sequence.
\
\ References:
\
\   1. G. Marsaglia and A. Zaman, The  KISS  generator, 
\      Technical report, Department of Statistics, 
\      Florida State University, Tallahassee, FL, USA, 1993
\
\   2. M. Hendrix, messages on usenet news group comp.lang.forth,
\      https://groups.google.com/d/msg/comp.lang.forth/5GJqpXjEW6k/SMJT5fcfCAAJ
\      https://groups.google.com/d/msg/comp.lang.forth/5GJqpXjEW6k/o1tID0PWAgAJ
\
\   3. G. Marsaglia, posting to
\      https://www.thecodingforums.com/threads/64-bit-kiss-rngs.673657/
\
\ Notes:
\
\ 1. Marsaglia gives a PASS/FAIL test for the 64-bit KISS in 
\    ref. [3]. The equivalent Forth test is KISS64-TEST
\
\ Requires ans-words.4th (kForth only)

1 CELLS 8 = constant 64-bit?

variable kiss.x
variable kiss.y
variable kiss.z
variable kiss.c

64-bit? [IF]
1234567890987654321 constant KISS.x_DEF
362436362436362436  constant KISS.y_DEF
1066149217761810    constant KISS.z_DEF
123456123456123456  constant KISS.c_DEF
6906969069          constant KISS_LCG_M
1234567             constant KISS_LCG_A
43                  constant KISS_SHIFT3
[ELSE]
123456789           constant KISS.x_DEF
362436069           constant KISS.y_DEF
871119182           constant KISS.z_DEF
129281              constant KISS.c_DEF
69069               constant KISS_LCG_M
12345               constant KISS_LCG_A
5                   constant KISS_SHIFT3 
[THEN]

: reset-KISS ( -- )
    KISS.x_DEF   KISS.x !
    KISS.y_DEF   KISS.y !
    KISS.z_DEF   KISS.z !
    KISS.c_DEF   KISS.c ! ; 


64-bit? [IF]
\ 64-bit version
: s() ( ux -- u )  63 rshift ;

: ran-KISS ( -- u)
   kiss.x @ 58 lshift kiss.c @ + \ t
   kiss.x @ 6  rshift kiss.c !
   kiss.x @ s() over s()  \ t s(x) s(t)
   2dup = IF drop  \ t s(x) 
   ELSE  2drop kiss.x @ over + s() negate 1+ \ t 1-s(x+t)
   THEN  \ t cinc
   kiss.c +! kiss.x +!
   kiss.y @ DUP  13 LSHIFT XOR
            DUP  17 RSHIFT XOR
            DUP  KISS_SHIFT3 LSHIFT XOR kiss.y !
   kiss.z @ KISS_LCG_M * KISS_LCG_A + kiss.z !
   kiss.x @ kiss.y @ + kiss.z @ +
;
 
variable rr
: kiss64-test ( -- )
    cr ." Testing 64-bit RAN-KISS ... "
    reset-KISS 
    100000000 0 DO 
      ran-kiss rr ! 
    LOOP
    rr @ 1666297717051644203 = IF
      ." PASSED."
    ELSE
      ." FAILED!"
    THEN cr ;
    
 
[ELSE]
\ 32-bit version
: ran-KISS ( -- u )
        333333314 kiss.x @ UM* kiss.c @ ( U>D) 0 D+
        ( lo hi) dup kiss.c ! + dup kiss.x !
        kiss.c @ U< IF  1 kiss.x +!  1 kiss.c +! THEN
        kiss.x @ INVERT 1+ kiss.x !
        kiss.y @ DUP 13 LSHIFT XOR
                 DUP 17 RSHIFT XOR
                 DUP KISS_SHIFT3 LSHIFT XOR kiss.y !
        kiss.z @ KISS_LCG_M *  KISS_LCG_A +  kiss.z !
        kiss.x @ kiss.y @ + kiss.z @ + ;  
[THEN]

reset-KISS

