\ mmul.4th
\
\ Double precision floating point matrix multiplication.
\
\ Krishna Myneni
\
\ Usage: a1 a2 a3 nr1 nc1 nc2 df_mmul
\
\ Requires:
\   ans-words.4th
\   modules.4th
\   fsl/fsl-util.4th
\
\ Revisions:
\   2017-05-17  km; created.
\   2017-05-18  km; precompute row offsets for a1 and a2;
\                   additional test case for product of
\                   3x4 with 4x4; made into FSL-style module.
\   2017-05-19  km; fixed declaration of floating point arrays
\                   in test code -- previously declared as
\                   double integer.
\   2017-05-20  km; replacing >R DFLOAT+ R> with SWAP DFLOAT+ SWAP
\                   in DF_MUL_R1C2, suggested by Stephen Pelc,
\                   reduces execution time by 16% for large matrices
\                   under kforth-fast.
\   2017-05-21  km; added SET_MMUL_PARAMS to be able to use DF_R1C2>A1A2
\                   and DF_MUL_R1C2 independently of DF_MMUL.
\   2021-05-09  km; added separate stack versions of words.
\   2023-12-05  km; fix comment for DF_MMUL.
\
\ Notes:
\   0. Matrix data is assumed to be stored in row order
\

CR .( MMUL               V1.3         09 May  2021 )

BEGIN-MODULE

BASE @
DECIMAL

variable nc1
variable nc2
variable a1
variable a2
variable roffs1
variable roffs2

Public:

\ Convert row of a1 and column of a2 to
\ corresponding addresses
: df_r1c2>a1a2 ( row1 col2 -- arow1 acol2 )
    dfloats a2 a@ + >r
    roffs1 @ * a1 a@ + r>   \ -- arow1 acol2
;

\ Multiply row of a1 with col of a2, element by element,
\ and accumulate the sum.
[DEFINED] FDEPTH [IF]
: df_mul_r1c2 ( row1 col2 -- ) ( F: -- rsum )
    df_r1c2>a1a2
    0e
    nc1 @ 0 DO  
      2dup f@ f@ f* f+
      roffs2 @ + 
      swap dfloat+ swap
    LOOP
    2drop ;
[ELSE]
: df_mul_r1c2 ( row1 col2 -- rsum )
    df_r1c2>a1a2
    2>r 0e 2r>  \ rsum a1 a2
    nc1 @ 0 DO  
      2dup 2>r >r f@ r> f@ f* f+
      2r> roffs2 @ + 
      swap dfloat+ swap
    LOOP
    2drop ;
[THEN]

: set_mmul_params ( a1 a2 a3 nr1 nc1 nc2 -- a3 nr1 )
    nc2 ! nc1 ! 2>r a2 ! a1 !
    \ offsets to next row for a1 and a2
    nc1 @ dfloats roffs1 !
    nc2 @ dfloats roffs2 !
    2r> ;

\ Multiply two double-precision matrices with data beginning at
\ a1 and a2, and store at a3. Proper memory allocation is
\ assumed, as are the dimensions for a2, i.e. nr2 = nc1 is
\ assumed.
[DEFINED] FDEPTH [IF]
: df_mmul ( a1 a2 a3 nr1 nc1 nc2 -- )
    set_mmul_params
    0 DO
      nc2 @ 0 DO
        J I df_mul_r1c2 dup f!
        dfloat+
      LOOP
    LOOP
    drop ;
[ELSE]
: df_mmul ( a1 a2 a3 nr1 nc1 nc2 -- )
    set_mmul_params
    0 DO
      nc2 @ 0 DO
        J I df_mul_r1c2 2 pick f!
        dfloat+
      LOOP
    LOOP
    drop ;
[THEN]

BASE !

END-MODULE

TEST-CODE? [IF]
[undefined] T{ [IF] s" ttester.4th" included  [THEN]

base @
decimal

\ Allot and initialize three 2x2 matrices

2 2 dfloat matrix a{{
2 2 dfloat matrix b{{
2 2 dfloat matrix c{{

cr

t{ 1e a{{ 0 0 }} f! ->  }t
t{ 2e a{{ 0 1 }} f! ->  }t
t{ 3e a{{ 1 0 }} f! ->  }t
t{ 4e a{{ 1 1 }} f! ->  }t

t{ 5e b{{ 0 0 }} f! ->  }t
t{ 6e b{{ 0 1 }} f! ->  }t
t{ 7e b{{ 1 0 }} f! ->  }t
t{ 8e b{{ 1 1 }} f! ->  }t

TESTING df_mmul

set-near
1e-16 rel-near f!

t{ a{{ 0 0 }} b{{ 0 0 }} c{{ 0 0 }} 2 2 2 df_mmul -> }t
t{ c{{ 0 0 }} f@  ->  19e r}t
t{ c{{ 0 1 }} f@  ->  22e r}t
t{ c{{ 1 0 }} f@  ->  43e r}t
t{ c{{ 1 1 }} f@  ->  50e r}t

\ Compute the product of a 3x4 matrix with a 4x4 matrix
3 4 dfloat matrix d{{
4 4 dfloat matrix e{{
3 4 dfloat matrix f{{

t{ 1e         0.5e      0.25e        2e 
   1e 3e f/   0.75e     5e 6e f/     3e
   2e 3e f/   5e 4e f/  6e 7e f/     11e 12e f/
   3 4 d{{ }}fput  ->  }t

t{ 10e       9e         8e         7e
   6e        5e         4e         3e
   2e        1e         0.5e       0.25e
   1e 8e f/  1e 16e f/  1e 3e f/   2e 3e f/ 
   4 4 e{{ }}fput  ->  }t

t{ d{{ 0 0 }} e{{ 0 0 }} f{{ 0 0 }} 3 4 4 df_mmul  -> }t
t{ f{{ 0 0 }} f@  ->  10e 3e f+ 0.5e f+ 0.25e f+  r}t
t{ f{{ 0 1 }} f@  ->  9e 2.5e f+ 0.25e f+ 0.125e f+  r}t
t{ f{{ 0 2 }} f@  ->  8e 2e f+ 0.125e f+ 2e 3e f/ f+  r}t
t{ f{{ 0 3 }} f@  ->  7e 1.5e f+ 1e 16e f/ f+ 4e 3e f/ f+  r}t
t{ f{{ 1 0 }} f@  ->  10e 3e f/ 4.5e f+ 5e 3e f/ f+ 3e 8e f/ f+  r}t
t{ f{{ 1 1 }} f@  ->  3e 3.75e f+ 5e 6e f/ f+ 3e 16e f/ f+  r}t
t{ f{{ 1 2 }} f@  ->  8e 3e f/ 3e f+ 5e 12e f/ f+ 1e f+  r}t
t{ f{{ 1 3 }} f@  ->  7e 3e f/ 2.25e f+ 5e 24e f/ f+ 2e f+ r}t
t{ f{{ 2 0 }} f@  ->  20e 3e f/ 7.5e f+ 12e 7e f/ f+ 11e 96e f/ f+  r}t
t{ f{{ 2 1 }} f@  ->  6e 6.25e f+ 6e 7e f/ f+ 11e 192e f/ f+  r}t
t{ f{{ 2 2 }} f@  ->  16e 3e f/ 5e f+ 3e 7e f/ f+ 11e 36e f/ f+  r}t
t{ f{{ 2 3 }} f@  ->  14e 3e f/ 3.75e f+ 3e 14e f/ f+ 11e 18e f/ f+  r}t

base !
[THEN]

