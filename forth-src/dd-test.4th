\ dd-test.4th
\
\ Compute and print the Golden Ratio [1] to 32 significant digits,
\   using the ddarith library and several computing methods.
\
\ K. Myneni, 2020-09-27
\
\ 1. http://en.wikipedia.org/wiki/Golden_ratio

include ans-words
include ddarith
include dd_io

DECIMAL

1e 0e ddconstant DD1.0
2e 0e ddconstant DD2.0
3e 0e ddconstant DD3.0
5e 0e ddconstant DD5.0

DD3.0 DD2.0 dd/  ddconstant DD3/2

\ 1. Soln. of quadratic eqn: phi = (1 + sqrt(5))/2
: phi-qu ( F: -- x xx )
    DD5.0 ddsqrt DD1.0 dd+ DD2.0 dd/ ;


\ 2. Trigonometric eqn: phi = 2*cos(pi/5)
0 [IF]
: phi-tr ( F: -- x xx )
   DDPI DD5.0 dd/ ddcos DD2.0 dd* ;  \ no ddcos available at present
;
[THEN]

\ 3. Continued square root: phi = sqrt(1 + sqrt(1 + sqrt(1 + ...
: phi-cs ( nterms -- ) ( F: -- x xx )
    >r DD2.0 ddsqrt
    r> 0 ?DO  DD1.0 dd+ ddsqrt  LOOP ;

\ 4. Continued fraction: phi = 1 + 1/(1 + 1/(1 + 1/... 
: phi-cf ( nterms -- ) ( F: -- x xx )
    >r DD3/2
    r> 0 ?DO  DD1.0 ddswap dd/ DD1.0 dd+  LOOP ;

32 set-precision

cr
cr .( Double Double Arithmetic Demo -- Golden Ratio Calculation to 32 digits )
cr 
cr .( 1. phi = {1 + sqrt[5]}/2 ) 
cr phi-qu  ddfs. cr

0 [IF]
cr .( 2. phi = 2*cos[pi/5] )
cr phi-tr  ddfs. cr
[THEN]

cr .( 3. phi = sqrt[1 + sqrt[1 + sqrt[1 + ... )
cr 100 phi-cs  ddfs. cr

cr .( 4. phi = 1 + 1/(1 + 1/(1 + 1/... )
cr 100 phi-cf  ddfs. cr


