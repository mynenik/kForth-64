\ cg-test.4th
\
\  Test the precision and accuracy of the Clebsch-Gordan code (cg.4th)
\
\  K. Myneni, 2006-12-17
\
\  The values of the 3j symbols can be expressed as square-root fractions
\  of integers, from the product of powers of primes method described
\  in Appendix C of ref [2] from cg.4th. The prime number exponents
\  for the 3j symbols tested below are given in Table C-1, and were used
\  to compute the reference fractions, which are an *exact* representation
\  of the values.
\
\  Revisions:
\
\   2007-01-02  added more test cases  km
\   2007-01-04  added more half-integral argument test cases  km
\   2007-09-19  use ttester as the test harness instead of ftester  km
\   2010-05-01  specify paths in include statements  km

include ans-words
include strings
include fsl/fsl-util
include fsl/extras/cg
include ttester

1e-16 fdup rel-near f! abs-near f! \ tolerance for comparison
set-near

\ The following range of arguments are outside of what the
\   current cg.4th code can properly evaluate.

0 [IF]

t{  3j( 6 3 3   0  0  0 )   ->   1 100  3003 /sqrt  r}t  
t{  3j( 6 4 4   0  0  0 )   ->  -1  20  1287 /sqrt  r}t
t{  3j( 6 5 5   0  0  0 )   ->   1  80  7293 /sqrt  r}t
t{  3j( 6 6 4   0  0  0 )   ->   1  28  2431 /sqrt  r}t
t{  3j( 6 6 6   0  0  0 )   ->  -1 400 46189 /sqrt  r}t
t{  3j( 7 5 4   0  0  0 )   ->   1 280 21879 /sqrt  r}t
t{  3j( 7 6 5   0  0  0 )   ->  -1 420 46189 /sqrt  r}t
t{  3j( 8 4 4   0  0  0 )   ->   1 490 21879 /sqrt  r}t
t{  3j( 8 5 3   0  0  0 )   ->   1  56  2431 /sqrt  r}t
t{  3j( 8 5 5   0  0  0 )   ->  -1 490 46189 /sqrt  r}t
t{  3j( 8 6 2   0  0  0 )   ->   1  28  1105 /sqrt  r}t
t{  3j( 8 6 4   0  0  0 )   ->  -1 504 46189 /sqrt  r}t
t{  3j( 8 6 6   0  0  0 )   ->   1 350 46189 /sqrt  r}t
t{  3j( 9 5 4   0  0  0 )   ->  -1 882 46189 /sqrt  r}t
t{  3j( 9 6 3   0  0  0 )   ->  -1  84  4199 /sqrt  r}t
t{  3j( 9 6 5   0  0  0 )   ->   1 420 46189 /sqrt  r}t
t{  3j( 10 5 5  0  0  0 )   ->   1 756 46189 /sqrt  r}t
t{  3j( 10 6 4  0  0  0 )   ->   1  70  4199 /sqrt  r}t
t{  3j( 10 6 6  0  0  0 )   ->  -1 756 96577 /sqrt  r}t
[THEN]


Testing Wigner 3j symbols ( whole arguments )

t{  3j( 0 0 0   0  0  0 )   ->   1   1     1 /sqrt  r}t
t{  3j( 1 1 0   0  0  0 )   ->  -1   1     3 /sqrt  r}t
t{  3j( 1 1 0   1 -1  0 )   ->   1   1     3 /sqrt  r}t
t{  3j( 1 1 1   1  0 -1 )   ->  -1   1     6 /sqrt  r}t
t{  3j( 2 1 1   0  0  0 )   ->   1   2    15 /sqrt  r}t
t{  3j( 2 1 1   0  1 -1 )   ->   1   1    30 /sqrt  r}t
t{  3j( 2 1 1   1  0 -1 )   ->  -1   1    10 /sqrt  r}t
t{  3j( 2 1 1   2 -1 -1 )   ->   1   1     5 /sqrt  r}t
t{  3j( 2 2 0   0  0  0 )   ->   1   1     5 /sqrt  r}t
t{  3j( 2 2 0   1 -1  0 )   ->  -1   1     5 /sqrt  r}t
t{  3j( 2 2 0   2 -2  0 )   ->   1   1     5 /sqrt  r}t
t{  3j( 2 2 1   1 -1  0 )   ->  -1   1    30 /sqrt  r}t
t{  3j( 2 2 1   1  0 -1 )   ->   1   1    10 /sqrt  r}t
t{  3j( 2 2 1   2 -2  0 )   ->   1   2    15 /sqrt  r}t
t{  3j( 2 2 1   2 -1 -1 )   ->  -1   1    15 /sqrt  r}t
t{  3j( 2 2 2   0  0  0 )   ->  -1   2    35 /sqrt  r}t
t{  3j( 2 2 2   1  0 -1 )   ->   1   1    70 /sqrt  r}t
t{  3j( 2 2 2   2 -1 -1 )   ->  -1   3    35 /sqrt  r}t
t{  3j( 2 2 2   2  0 -2 )   ->   1   2    35 /sqrt  r}t
t{  3j( 3 2 1   0  0  0 )   ->  -1   3    35 /sqrt  r}t
t{  3j( 3 2 1   0  1 -1 )   ->  -1   1    35 /sqrt  r}t
t{  3j( 3 2 1   1 -2  1 )   ->   1   1   105 /sqrt  r}t
t{  3j( 3 2 1   1 -1  0 )   ->   1   8   105 /sqrt  r}t
t{  3j( 3 2 1   1  0 -1 )   ->   1   2    35 /sqrt  r}t
t{  3j( 3 2 1   2 -2  0 )   ->  -1   1    21 /sqrt  r}t
t{  3j( 3 2 1   2 -1 -1 )   ->  -1   2    21 /sqrt  r}t
t{  3j( 3 2 1   3 -2 -1 )   ->   1   1     7 /sqrt  r}t
t{  3j( 3 2 2   0  1 -1 )   ->   1   2    35 /sqrt  r}t
t{  3j( 3 2 2   0  2 -2 )   ->   1   1    70 /sqrt  r}t
t{  3j( 3 2 2   1  0 -1 )   ->  -1   1    35 /sqrt  r}t
t{  3j( 3 2 2   1  1 -2 )   ->  -1   3    70 /sqrt  r}t
t{  3j( 3 2 2   2  0 -2 )   ->   1   1    14 /sqrt  r}t
t{  3j( 3 2 2   3 -1 -2 )   ->  -1   1    14 /sqrt  r}t
t{  3j( 3 3 0   0  0  0 )   ->  -1   1     7 /sqrt  r}t
t{  3j( 3 3 0   1 -1  0 )   ->   1   1     7 /sqrt  r}t
t{  3j( 3 3 0   2 -2  0 )   ->  -1   1     7 /sqrt  r}t
t{  3j( 3 3 0   3 -3  0 )   ->   1   1     7 /sqrt  r}t
t{  3j( 3 3 1   1 -1  0 )   ->   1   1    84 /sqrt  r}t
t{  3j( 3 3 1   1  0 -1 )   ->  -1   1    14 /sqrt  r}t
t{  3j( 3 3 1   2 -2  0 )   ->  -1   1    21 /sqrt  r}t
t{  3j( 3 3 1   2 -1 -1 )   ->   1   5    84 /sqrt  r}t
t{  3j( 3 3 1   3 -3  0 )   ->   1   3    28 /sqrt  r}t
t{  3j( 3 3 1   3 -2 -1 )   ->  -1   1    28 /sqrt  r}t
t{  3j( 3 3 2   0  0  0 )   ->   1   4   105 /sqrt  r}t
t{  3j( 3 3 2   1 -1  0 )   ->  -1   3   140 /sqrt  r}t
t{  3j( 3 3 2   1  0 -1 )   ->  -1   1   210 /sqrt  r}t
t{  3j( 3 3 2   1  1 -2 )   ->   1   2    35 /sqrt  r}t
t{  3j( 3 3 2   2 -2  0 )   ->   1   0     1 /sqrt  r}t
t{  3j( 3 3 2   2 -1 -1 )   ->   1   1    28 /sqrt  r}t
t{  3j( 3 3 2   2  0 -2 )   ->  -1   1    21 /sqrt  r}t
t{  3j( 3 3 2   3 -3  0 )   ->   1   5    84 /sqrt  r}t
t{  3j( 3 3 2   3 -2 -1 )   ->  -1   5    84 /sqrt  r}t
t{  3j( 3 3 2   3 -1 -2 )   ->   1   1    42 /sqrt  r}t
t{  3j( 3 3 3   1  0 -1 )   ->   1   1    42 /sqrt  r}t
t{  3j( 3 3 3   2  0 -2 )   ->  -1   1    42 /sqrt  r}t
t{  3j( 3 3 3   3 -1 -2 )   ->   1   1    21 /sqrt  r}t
t{  3j( 3 3 3   3  0 -3 )   ->  -1   1    42 /sqrt  r}t
t{  3j( 4 2 2   0  0  0 )   ->   1   2    35 /sqrt  r}t
t{  3j( 4 2 2   0  1 -1 )   ->   1   8   315 /sqrt  r}t
t{  3j( 4 2 2   0  2 -2 )   ->   1   1   630 /sqrt  r}t
t{  3j( 4 2 2   1  0 -1 )   ->  -1   1    21 /sqrt  r}t
t{  3j( 4 2 2   1  1 -2 )   ->  -1   1   126 /sqrt  r}t
t{  3j( 4 2 2   2 -1 -1 )   ->   1   4    63 /sqrt  r}t
t{  3j( 4 2 2   2  0 -2 )   ->   1   1    42 /sqrt  r}t
t{  3j( 4 2 2   3 -1 -2 )   ->  -1   1    18 /sqrt  r}t
t{  3j( 4 2 2   4 -2 -2 )   ->   1   1     9 /sqrt  r}t
t{  3j( 4 3 1   0  0  0 )   ->   1   4    63 /sqrt  r}t
t{  3j( 4 3 1   0  1 -1 )   ->   1   1    42 /sqrt  r}t
t{  3j( 4 3 1   1 -2  1 )   ->  -1   1    84 /sqrt  r}t
t{  3j( 4 3 1   1 -1  0 )   ->  -1   5    84 /sqrt  r}t
t{  3j( 4 3 1   1  0 -1 )   ->  -1   5   126 /sqrt  r}t
t{  3j( 4 3 1   2 -3  1 )   ->   1   1   252 /sqrt  r}t
t{  3j( 4 3 1   2 -2  0 )   ->   1   1    21 /sqrt  r}t
t{  3j( 4 3 1   2 -1 -1 )   ->   1   5    84 /sqrt  r}t
t{  3j( 4 3 1   3 -3  0 )   ->  -1   1    36 /sqrt  r}t
t{  3j( 4 3 1   3 -2 -1 )   ->  -1   1    12 /sqrt  r}t
t{  3j( 4 3 1   4 -3 -1 )   ->   1   1     9 /sqrt  r}t
t{  3j( 4 3 2   0  1 -1 )   ->  -1   5   126 /sqrt  r}t
t{  3j( 4 3 2   0  2 -2 )   ->  -1   1    63 /sqrt  r}t
t{  3j( 4 3 2   1 -3  2 )   ->  -1   1   210 /sqrt  r}t
t{  3j( 4 3 2   1 -2  1 )   ->  -1   7   180 /sqrt  r}t
t{  3j( 4 3 2   1 -1  0 )   ->  -1   1    84 /sqrt  r}t
t{  3j( 4 3 2   1  0 -1 )   ->   1   1    42 /sqrt  r}t
t{  3j( 4 3 2   1  1 -2 )   ->   1   2    63 /sqrt  r}t
t{  3j( 4 3 2   2 -3  1 )   ->   1   3   140 /sqrt  r}t
t{  3j( 4 3 2   2 -2  0 )   ->   1   4   105 /sqrt  r}t
t{  3j( 4 3 2   2 -1 -1 )   ->  -1   1   252 /sqrt  r}t
t{  3j( 4 3 2   2  0 -2 )   ->  -1   1    21 /sqrt  r}t
t{  3j( 4 3 2   3 -3  0 )   ->  -1   1    20 /sqrt  r}t
t{  3j( 4 3 2   3 -2 -1 )   ->  -1   1   180 /sqrt  r}t
t{  3j( 4 3 2   3 -1 -2 )   ->   1   1    18 /sqrt  r}t
t{  3j( 4 3 2   4 -3 -1 )   ->   1   1    15 /sqrt  r}t
t{  3j( 4 3 2   4 -2 -2 )   ->  -1   2    45 /sqrt  r}t
t{  3j( 4 3 3   0  0  0 )   ->  -1   2    77 /sqrt  r}t
t{  3j( 4 3 3   0  1 -1 )   ->   1   1  1386 /sqrt  r}t
t{  3j( 4 3 3   0  2 -2 )   ->   1   7   198 /sqrt  r}t
t{  3j( 4 3 3   0  3 -3 )   ->   1   1   154 /sqrt  r}t
t{  3j( 4 3 3   1  0 -1 )   ->   1   5   462 /sqrt  r}t
t{  3j( 4 3 3   1  1 -2 )   ->  -1  16   693 /sqrt  r}t
t{  3j( 4 3 3   1  2 -3 )   ->  -1   5   231 /sqrt  r}t
t{  3j( 4 3 3   2 -1 -1 )   ->  -1  20   693 /sqrt  r}t
t{  3j( 4 3 3   2  0 -2 )   ->   1   1   462 /sqrt  r}t
t{  3j( 4 3 3   2  1 -3 )   ->   1   3    77 /sqrt  r}t
t{  3j( 4 3 3   3 -1 -2 )   ->   1   1    99 /sqrt  r}t
t{  3j( 4 3 3   3  0 -3 )   ->  -1   1    22 /sqrt  r}t
t{  3j( 4 3 3   4 -2 -2 )   ->  -1   5    99 /sqrt  r}t
t{  3j( 4 3 3   4 -1 -3 )   ->   1   1    33 /sqrt  r}t
t{  3j( 4 4 0   0  0  0 )   ->   1   1     9 /sqrt  r}t
t{  3j( 4 4 0   1 -1  0 )   ->  -1   1     9 /sqrt  r}t
t{  3j( 4 4 0   2 -2  0 )   ->   1   1     9 /sqrt  r}t
t{  3j( 4 4 0   3 -3  0 )   ->  -1   1     9 /sqrt  r}t
t{  3j( 4 4 0   4 -4  0 )   ->   1   1     9 /sqrt  r}t
t{  3j( 4 4 1   1 -1  0 )   ->  -1   1   180 /sqrt  r}t
t{  3j( 4 4 1   1  0 -1 )   ->   1   1    18 /sqrt  r}t
t{  3j( 4 4 1   2 -2  0 )   ->   1   1    45 /sqrt  r}t
t{  3j( 4 4 1   2 -1 -1 )   ->  -1   1    20 /sqrt  r}t
t{  3j( 4 4 1   3 -3  0 )   ->  -1   1    20 /sqrt  r}t
t{  3j( 4 4 1   3 -2 -1 )   ->   1   7   180 /sqrt  r}t
t{  3j( 4 4 1   4 -4  0 )   ->   1   4    45 /sqrt  r}t
t{  3j( 4 4 1   4 -3 -1 )   ->  -1   1    45 /sqrt  r}t
t{  3j( 4 4 2   0  0  0 )   ->  -1  20   693 /sqrt  r}t
t{  3j( 4 4 2   1 -1  0 )   ->   1 289 13860 /sqrt  r}t
t{  3j( 4 4 2   1  0 -1 )   ->   1   1   462 /sqrt  r}t
t{  3j( 4 4 2   1  1 -2 )   ->  -1  10   231 /sqrt  r}t
t{  3j( 4 4 2   2 -2  0 )   ->  -1  16  3465 /sqrt  r}t
t{  3j( 4 4 2   2 -1 -1 )   ->  -1  27  1540 /sqrt  r}t
t{  3j( 4 4 2   2  0 -2 )   ->   1   3    77 /sqrt  r}t
t{  3j( 4 4 2   3 -3  0 )   ->  -1   7  1980 /sqrt  r}t
t{  3j( 4 4 2   3 -2 -1 )   ->   1   5   132 /sqrt  r}t
t{  3j( 4 4 2   3 -1 -2 )   ->  -1   3   110 /sqrt  r}t
t{  3j( 4 4 2   4 -4  0 )   ->   1  28   495 /sqrt  r}t
t{  3j( 4 4 2   4 -3 -1 )   ->  -1   7   165 /sqrt  r}t
t{  3j( 4 4 2   4 -2 -2 )   ->   1   2   165 /sqrt  r}t
t{  3j( 4 4 3   1 -1  0 )   ->   1   9   770 /sqrt  r}t
t{  3j( 4 4 3   1  0 -1 )   ->  -1   3   154 /sqrt  r}t
t{  3j( 4 4 3   2 -2  0 )   ->  -1 169  6930 /sqrt  r}t
t{  3j( 4 4 3   2 -1 -1 )   ->   1   4  1155 /sqrt  r}t
t{  3j( 4 4 3   2  0 -2 )   ->   1   5   462 /sqrt  r}t
t{  3j( 4 4 3   2  1 -3 )   ->  -1  25   693 /sqrt  r}t
t{  3j( 4 4 3   3 -3  0 )   ->   1   7   990 /sqrt  r}t
t{  3j( 4 4 3   3 -2 -1 )   ->   1   1   165 /sqrt  r}t
t{  3j( 4 4 3   3 -1 -2 )   ->  -1   1    33 /sqrt  r}t
t{  3j( 4 4 3   3  0 -3 )   ->   1   5   198 /sqrt  r}t
t{  3j( 4 4 3   4 -4  0 )   ->   1  14   495 /sqrt  r}t
t{  3j( 4 4 3   4 -3 -1 )   ->  -1   7   165 /sqrt  r}t
t{  3j( 4 4 3   4 -2 -2 )   ->   1   1    33 /sqrt  r}t
t{  3j( 4 4 3   4 -1 -3 )   ->  -1   1    99 /sqrt  r}t
t{  3j( 4 4 4   0  0  0 )   ->   1  18  1001 /sqrt  r}t
t{  3j( 4 4 4   1  0 -1 )   ->  -1   9  2002 /sqrt  r}t
t{  3j( 4 4 4   2 -1 -1 )   ->   1  20  1001 /sqrt  r}t
t{  3j( 4 4 4   2  0 -2 )   ->  -1  11  1638 /sqrt  r}t
t{  3j( 4 4 4   3 -1 -2 )   ->  -1   5  1287 /sqrt  r}t
t{  3j( 4 4 4   3  0 -3 )   ->   1   7   286 /sqrt  r}t
t{  3j( 4 4 4   4 -2 -2 )   ->   1   5   143 /sqrt  r}t
t{  3j( 4 4 4   4 -1 -3 )   ->  -1  35  1287 /sqrt  r}t
t{  3j( 4 4 4   4  0 -4 )   ->   1  14  1287 /sqrt  r}t
t{  3j( 5 3 2   0  0  0 )   ->  -1  10   231 /sqrt  r}t
t{  3j( 5 4 1   0  0  0 )   ->  -1   5    99 /sqrt  r}t
t{  3j( 5 4 3   0  0  0 )   ->   1  20  1001 /sqrt  r}t
t{  3j( 5 5 0   0  0  0 )   ->  -1   1    11 /sqrt  r}t
t{  3j( 5 5 2   0  0  0 )   ->   1  10   429 /sqrt  r}t 
t{  3j( 5 5 4   0  0  0 )   ->  -1   2   143 /sqrt  r}t
t{  3j( 6 4 2   0  0  0 )   ->   1   5   143 /sqrt  r}t
t{  3j( 6 5 1   0  0  0 )   ->   1   6   143 /sqrt  r}t
t{  3j( 6 5 3   0  0  0 )   ->  -1   7   429 /sqrt  r}t
t{  3j( 6 6 0   0  0  0 )   ->   1   1    13 /sqrt  r}t
t{  3j( 6 6 2   0  0  0 )   ->  -1  14   715 /sqrt  r}t
t{  3j( 7 4 3   0  0  0 )   ->  -1  35  1287 /sqrt  r}t
t{  3j( 7 5 2   0  0  0 )   ->  -1  21   715 /sqrt  r}t
t{  3j( 7 6 1   0  0  0 )   ->  -1   7   195 /sqrt  r}t
t{  3j( 7 6 3   0  0  0 )   ->   1 168 12155 /sqrt  r}t


Testing Wigner 3j symbols ( half integral arguments )

t{  3j( 1/2  1/2  0     1/2  -1/2   0   )  ->  1  1   2 /sqrt  r}t

t{  3j( 1    1/2  1/2   0     1/2  -1/2 )  ->  1  1   6 /sqrt  r}t
t{  3j( 1    1/2  1/2   1    -1/2  -1/2 )  -> -1  1   3 /sqrt  r}t

t{  3j( 3/2  1    1/2   1/2  -1     1/2 )  ->  1  1  12 /sqrt  r}t
t{  3j( 3/2  1    1/2   1/2   0    -1/2 )  ->  1  1   6 /sqrt  r}t
t{  3j( 3/2  1    1/2   3/2  -1    -1/2 )  -> -1  1   4 /sqrt  r}t

t{  3j( 3/2  3/2  0     1/2  -1/2   0   )  -> -1  1   4 /sqrt  r}t
t{  3j( 3/2  3/2  0     3/2  -3/2   0   )  ->  1  1   4 /sqrt  r}t

t{  3j( 3/2  3/2  1     1/2  -1/2   0   )  -> -1  1  60 /sqrt  r}t
t{  3j( 3/2  3/2  1     1/2   1/2  -1   )  ->  1  2  15 /sqrt  r}t
t{  3j( 3/2  3/2  1     3/2  -3/2   0   )  ->  1  3  20 /sqrt  r}t
t{  3j( 3/2  3/2  1     3/2  -1/2  -1   )  -> -1  1  10 /sqrt  r}t

t{  3j( 2    3/2  1/2   0     1/2  -1/2 )  -> -1  1  10 /sqrt  r}t
t{  3j( 2    3/2  1/2   1    -3/2   1/2 )  ->  1  1  20 /sqrt  r}t
t{  3j( 2    3/2  1/2   1    -1/2  -1/2 )  ->  1  3  20 /sqrt  r}t
t{  3j( 2    3/2  1/2   2    -3/2  -1/2 )  -> -1  1   5 /sqrt  r}t

t{  3j( 2    3/2  3/2   0     1/2  -1/2 )  ->  1  1  20 /sqrt  r}t
t{  3j( 2    3/2  3/2   0     3/2  -3/2 )  ->  1  1  20 /sqrt  r}t
t{  3j( 2    3/2  3/2   1     1/2  -3/2 )  -> -1  1  10 /sqrt  r}t
t{  3j( 2    3/2  3/2   2    -1/2  -3/2 )  ->  1  1  10 /sqrt  r}t

t{  3j( 5/2  3/2  1     1/2  -3/2   1   )  ->  1  1  60 /sqrt  r}t
t{  3j( 5/2  3/2  1     1/2  -1/2   0   )  ->  1  1  10 /sqrt  r}t
t{  3j( 5/2  3/2  1     1/2   1/2  -1   )  ->  1  1  20 /sqrt  r}t
t{  3j( 5/2  3/2  1     3/2  -3/2   0   )  -> -1  1  15 /sqrt  r}t
t{  3j( 5/2  3/2  1     3/2  -1/2  -1   )  -> -1  1  10 /sqrt  r}t
t{  3j( 5/2  3/2  1     5/2  -3/2  -1   )  ->  1  1   6 /sqrt  r}t

t{  3j( 5/2  2    1/2   1/2  -1     1/2 )  -> -1  1  15 /sqrt  r}t
t{  3j( 5/2  2    1/2   1/2   0    -1/2 )  -> -1  1  10 /sqrt  r}t
t{  3j( 5/2  2    1/2   3/2  -2     1/2 )  ->  1  1  30 /sqrt  r}t
t{  3j( 5/2  2    1/2   3/2  -1    -1/2 )  ->  1  2  15 /sqrt  r}t
t{  3j( 5/2  2    1/2   5/2  -2    -1/2 )  -> -1  1   6 /sqrt  r}t

t{  3j( 5/2  2    3/2   1/2  -2     3/2 )  -> -1  1  35 /sqrt  r}t
t{  3j( 5/2  2    3/2   1/2  -1     1/2 )  -> -1  5  84 /sqrt  r}t
t{  3j( 5/2  2    3/2   1/2   0    -1/2 )  ->  1  1  70 /sqrt  r}t
t{  3j( 5/2  2    3/2   1/2   1    -3/2 )  ->  1  9 140 /sqrt  r}t
t{  3j( 5/2  2    3/2   3/2  -2     1/2 )  ->  1  8 105 /sqrt  r}t
t{  3j( 5/2  2    3/2   3/2  -1    -1/2 )  ->  1  1 210 /sqrt  r}t
t{  3j( 5/2  2    3/2   3/2   0    -3/2 )  -> -1  3  35 /sqrt  r}t
t{  3j( 5/2  2    3/2   5/2  -2    -1/2 )  -> -1  2  21 /sqrt  r}t
t{  3j( 5/2  2    3/2   5/2  -1    -3/2 )  ->  1  1  14 /sqrt  r}t

t{  3j( 5/2  5/2  0     1/2  -1/2   0   )  ->  1  1   6 /sqrt  r}t
t{  3j( 5/2  5/2  0     3/2  -3/2   0   )  -> -1  1   6 /sqrt  r}t
t{  3j( 5/2  5/2  0     5/2  -5/2   0   )  ->  1  1   6 /sqrt  r}t

t{  3j( 5/2  5/2  1     1/2  -1/2   0   )  ->  1  1 210 /sqrt  r}t
t{  3j( 5/2  5/2  1     1/2   1/2  -1   )  -> -1  3  35 /sqrt  r}t
t{  3j( 5/2  5/2  1     3/2  -3/2   0   )  -> -1  3  70 /sqrt  r}t
t{  3j( 5/2  5/2  1     3/2  -1/2  -1   )  ->  1  8 105 /sqrt  r}t
t{  3j( 5/2  5/2  1     5/2  -5/2   0   )  ->  1  5  42 /sqrt  r}t
t{  3j( 5/2  5/2  1     5/2  -3/2  -1   )  -> -1  1  21 /sqrt  r}t

t{  3j( 5/2  5/2  2     1/2  -1/2   0   )  -> -1  4 105 /sqrt  r}t
t{  3j( 5/2  5/2  2     3/2  -3/2   0   )  ->  1  1 420 /sqrt  r}t
t{  3j( 5/2  5/2  2     3/2  -1/2  -1   )  ->  1  1  35 /sqrt  r}t
t{  3j( 5/2  5/2  2     3/2   1/2  -2   )  -> -1  9 140 /sqrt  r}t
t{  3j( 5/2  5/2  2     5/2  -5/2   0   )  ->  1  5  84 /sqrt  r}t
t{  3j( 5/2  5/2  2     5/2  -3/2  -1   )  -> -1  1  14 /sqrt  r}t
t{  3j( 5/2  5/2  2     5/2  -1/2  -2   )  ->  1  1  28 /sqrt  r}t

t{  3j( 3    3/2  3/2   0     1/2  -1/2 )  ->  1  9 140 /sqrt  r}t
t{  3j( 3    3/2  3/2   0     3/2  -3/2 )  ->  1  1 140 /sqrt  r}t
t{  3j( 3    3/2  3/2   1    -1/2  -1/2 )  -> -1  3  35 /sqrt  r}t
t{  3j( 3    3/2  3/2   1     1/2  -3/2 )  -> -1  1  35 /sqrt  r}t
t{  3j( 3    3/2  3/2   2    -1/2  -3/2 )  ->  1  1  14 /sqrt  r}t
t{  3j( 3    3/2  3/2   3    -3/2  -3/2 )  -> -1  1   7 /sqrt  r}t

t{  3j( 3    5/2  1/2   0     1/2  -1/2 )  ->  1  1  14 /sqrt  r}t
t{  3j( 3    5/2  1/2   1    -3/2   1/2 )  -> -1  1  21 /sqrt  r}t
t{  3j( 3    5/2  1/2   1    -1/2  -1/2 )  -> -1  2  21 /sqrt  r}t
t{  3j( 3    5/2  1/2   2    -5/2   1/2 )  ->  1  1  42 /sqrt  r}t
t{  3j( 3    5/2  1/2   2    -3/2  -1/2 )  ->  1  5  42 /sqrt  r}t
t{  3j( 3    5/2  1/2   3    -5/2  -1/2 )  -> -1  1   7 /sqrt  r}t

t{  3j( 3    5/2  3/2   0     1/2  -1/2 )  -> -1  1  35 /sqrt  r}t
t{  3j( 3    5/2  3/2   0     3/2  -3/2 )  -> -1  3  70 /sqrt  r}t
t{  3j( 3    5/2  3/2   1    -5/2   3/2 )  -> -1  1  56 /sqrt  r}t
t{  3j( 3    5/2  3/2   1    -3/2   1/2 )  -> -1  7 120 /sqrt  r}t
t{  3j( 3    5/2  3/2   1    -1/2  -1/2 )  ->  1  1 420 /sqrt  r}t
t{  3j( 3    5/2  3/2   1     1/2  -3/2 )  ->  1  9 140 /sqrt  r}t
t{  3j( 3    5/2  3/2   2    -5/2   1/2 )  ->  1  5  84 /sqrt  r}t
t{  3j( 3    5/2  3/2   2    -3/2  -1/2 )  ->  1  1  84 /sqrt  r}t
t{  3j( 3    5/2  3/2   2    -1/2  -3/2 )  -> -1  1  14 /sqrt  r}t
t{  3j( 3    5/2  3/2   3    -5/2  -1/2 )  -> -1  5  56 /sqrt  r}t
t{  3j( 3    5/2  3/2   3    -3/2  -3/2 )  ->  1  3  56 /sqrt  r}t

t{  3j( 3    5/2  5/2   0     1/2  -1/2 )  -> -1  4 315 /sqrt  r}t
t{  3j( 3    5/2  5/2   0     3/2  -3/2 )  ->  1  7 180 /sqrt  r}t
t{  3j( 3    5/2  5/2   0     5/2  -5/2 )  ->  1  5 252 /sqrt  r}t
t{  3j( 3    5/2  5/2   1    -1/2  -1/2 )  ->  1  4 105 /sqrt  r}t
t{  3j( 3    5/2  5/2   1     1/2  -3/2 )  -> -1  1 210 /sqrt  r}t
t{  3j( 3    5/2  5/2   1     3/2  -5/2 )  -> -1  1  21 /sqrt  r}t
t{  3j( 3    5/2  5/2   2    -1/2  -3/2 )  -> -1  1  84 /sqrt  r}t
t{  3j( 3    5/2  5/2   2     1/2  -5/2 )  ->  1  5  84 /sqrt  r}t
t{  3j( 3    5/2  5/2   3    -3/2  -3/2 )  ->  1  4  63 /sqrt  r}t
t{  3j( 3    5/2  5/2   3    -1/2  -5/2 )  -> -1  5 126 /sqrt  r}t

t{  3j( 7/2  2    3/2   1/2  -2     3/2 )  ->  1  1 280 /sqrt  r}t
t{  3j( 7/2  2    3/2   1/2  -1     1/2 )  ->  1  3  70 /sqrt  r}t
t{  3j( 7/2  2    3/2   1/2   0    -1/2 )  ->  1  9 140 /sqrt  r}t
t{  3j( 7/2  2    3/2   1/2   1    -3/2 )  ->  1  1  70 /sqrt  r}t
t{  3j( 7/2  2    3/2   3/2  -2     1/2 )  -> -1  1  56 /sqrt  r}t
t{  3j( 7/2  2    3/2   3/2  -1    -1/2 )  -> -1  1  14 /sqrt  r}t
t{  3j( 7/2  2    3/2   3/2   0    -3/2 )  -> -1  1  28 /sqrt  r}t
t{  3j( 7/2  2    3/2   5/2  -2    -1/2 )  ->  1  3  56 /sqrt  r}t
t{  3j( 7/2  2    3/2   5/2  -1    -3/2 )  ->  1  1  14 /sqrt  r}t
t{  3j( 7/2  2    3/2   7/2  -2    -3/2 )  -> -1  1   8 /sqrt  r}t

t{  3j( 7/2  5/2  1     1/2  -3/2   1   )  -> -1  1  56 /sqrt  r}t
t{  3j( 7/2  5/2  1     1/2  -1/2   0   )  -> -1  1  14 /sqrt  r}t
t{  3j( 7/2  5/2  1     1/2   1/2  -1   )  -> -1  1  28 /sqrt  r}t
t{  3j( 7/2  5/2  1     3/2  -5/2   1   )  ->  1  1 168 /sqrt  r}t
t{  3j( 7/2  5/2  1     3/2  -3/2   0   )  ->  1  5  84 /sqrt  r}t
t{  3j( 7/2  5/2  1     3/2  -1/2  -1   )  ->  1  5  84 /sqrt  r}t
t{  3j( 7/2  5/2  1     5/2  -5/2   0   )  -> -1  1  28 /sqrt  r}t
t{  3j( 7/2  5/2  1     5/2  -3/2  -1   )  -> -1  5  56 /sqrt  r}t
t{  3j( 7/2  5/2  1     7/2  -5/2  -1   )  ->  1  1   8 /sqrt  r}t



