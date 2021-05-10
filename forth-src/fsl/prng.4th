\ Pseudo random number generator in ANS Forth
\
\         Forth Scientific Library Algorithm #57
\
\       Leaves a pseudo random number in the range (0,1)
\           on fp stack.

\   Based on GGUBS algorithm:  s' = 16807*s mod (2^32-1)
\   P. Bratley, B.L. Fox and L.E. Schrage, A guide to simulation
\   (Springer, Berlin, 1983).
\
\   To simplify transport to 16-bit machines the 32-bit
\   modular division is performed by synthetic division:
\   note that
\
\       bigdiv = divis * m1 + m2
\
\   so that ( [n] means "largest integer <= n" )
\
\       s' = s*m1 - [s*m1/b]*b = m1 * (s - [s/d]*d) - m2 * [s/d]
\
\   Environmental dependences:
\
\       1. assumes at least 32-bit DOUBLEs
\       2. needs FLOATING and DOUBLE wordsets
\
\
\
\ ---------------------------------------------------
\     (c) Copyright 1998  Julian V. Noble.          \
\       Permission is granted by the author to      \
\       use this software for any application pro-  \
\       vided this copyright notice is preserved.   \
\ ---------------------------------------------------
\
\ Revisions:
\    2007-11-28  km; ported to integrated stack systems (kForth);
\                    added automated test and base handling.

CR .( PRNG              V1            28 November  2007  JVN )
BASE @ DECIMAL

\ MARKER -rand

2VARIABLE     seed


2147483647e  FCONSTANT  bigdiv             \ 2^31-1
127773e      FCONSTANT  divis
16807e       FCONSTANT  m1
2836e        FCONSTANT  m2


: (rand)    ( adr -- fseed')
    dup >R 2@  D>F              ( fseed)
    divis FOVER FOVER           ( s d s d)
    F/  F>D  2>R                ( s d [s/d])
    2R@   D>F                   ( s d [s/d])
    F*   F-                     ( s-d*[s/d] = s mod d)
    m1   F*                     ( m1*[s mod d])
    2R> D>F  m2  F*  F-         ( fseed')
    FDUP  F>D                   ( fseed' seed')
    R> 2! ;                     \ save seed'

: prng      ( -- frandom#)
    seed  (rand)  bigdiv        (  -- fseed 2**31-1)
    FSWAP  FDUP  F0<            (  -- 2**31-1 fseed flag)
    IF   FOVER  F+   THEN   FSWAP  F/  ;

BASE !

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

: test  1 s>d  seed 2!  1000 0 DO  prng  FDROP  LOOP  seed 2@ ;

CR
TESTING PRNG
t{ test ->  522329230 s>d }t

BASE !

[THEN]
