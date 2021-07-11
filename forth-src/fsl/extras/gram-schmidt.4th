\ gram-schmidt.4th
\
\ Construct new orthogonal basis from a set of M unnormalized,
\ non-orthogonal basis vectors using the Gram-Schmidt procedure.
\ In the process, also perform the QR decomposition of the 
\ N x M matrix (M <= N) containing input vectors as columns.
\
\ Copyright (c) 2019 Krishna Myneni <krishna.myneni@ccreweb.org>
\ This work may be used for any purpose provided the original
\ copyright notice is included in the derived work.
\
\ References:
\
\  1. A. Schlegel, "QR Decomposition with the Gram-Schmidt
\     Procedure", https://rpubs.com/aaronsc32/
\
\ Requires:
\   fsl/fsl-util.4th
\   fsl/dynmem.4th
\   fsl/extras/vector.4th
\
\ Glossary:
\
\   SETUP-GS ( N M 'A -- err )  Allocate auxiliary memory for GS.
\   GS       ( -- )     Perform Gram-Schmidt and QR decomposition.
\   FREE-GS  ( -- err ) Free auxiliary memory.
\
\ Usage:
\
\  1. Create and initialize a N by M matrix name{{ via standard
\     FSL matrix words.
\
\      N M FLOAT MATRIX name{{
\      etc.
\
\  2. Allocate memory for GS using SETUP-GS.
\
\       N M name{{ SETUP-GS
\
\  3. Perform orthogonalization and QR decomposition of name{{.
\
\       GS
\
\  4. Retrieve desired info from auxiliary matrices:
\       -- Orthogonal vectors are returned in name{{
\       -- Orthonormal vectors are in Q{{
\       -- R component matrix of QR decomposition is in R{{
\
\  5. Clean up memory.
\
\       FREE-GS 
\
\
\ Notes:
\   0. The direct Gram-Schmidt orthogonalization method,
\      implemented here, can become numerically unstable and
\      should be used with caution. Nevertheless, it is useful
\      pedagogically and for some computational tasks. This
\      code may also be used as a template for implementing
\      the Modified Gram-Schmidt algorithm (MGS), which has
\      better numerical stability.
\   1. The input matrix is modified.
\   2. SETUP-GS and FREE-GS return 0 on success.
\
CR .( GRAM-SCHMIDT      V1.0           13 Jan  2019 )

Begin-Module

BASE @
DECIMAL

0 value N
0 value M
0 ptr  A{{

Public:

DFLOAT DARRAY  A{
DFLOAT DARRAY  V{
DFLOAT DARRAY  P{
DFLOAT DMATRIX Q{{
DFLOAT DMATRIX R{{

\ Set up auxiliary vectors and matrices for GS;
\ err = 0 for success.
: setup-gs ( N M 'A -- err )
    to A{{  to M  to N
    & A{ N }malloc malloc-fail?
    & V{ N }malloc malloc-fail? or
    & P{ N }malloc malloc-fail? or
    & Q{{ N M }}malloc malloc-fail? or
    & R{{ M M }}malloc malloc-fail? or
;

\ Free the auxiliary vectors and matrices.
\ err = 0 for success.
: free-gs ( -- err )
    & R{{ }}free malloc-fail?
    & Q{{ }}free malloc-fail? or
    & P{ }free malloc-fail? or
    & V{ }free malloc-fail? or
    & A{ }free malloc-fail? or
;

: }}fzero ( N M 'A -- ) >r * floats r> 0 0 }} swap erase ; 

Public:

\ Gram-Schmidt orthogonalization of M vectors, each of
\ dimension N. The M vectors are stored as columns of
\ the real N x M matrix A{{ . The orthogonal vectors are
\ returned in A{{ and the orthonormalized vectors are 
\ stored in Q{{. The M x M matrix, R{{ , the remaining
\ component of the QR decomposition is also computed.
: gs ( -- )
    M 2 < IF  EXIT  THEN
    N M Q{{ }}fzero          \  Q{{ <- zero
    M M R{{ }}fzero          \  R{{ <- zero
    M N min to M             \  M <- Min(M, N)
    0 A{{ N A{     vget-col  \  A{ <- A{{ : 0 }}
    N A{ V{        vcopy     \  V{ <- A{
    N V{           vnorm     \  V{ <- V{ / |V{|
    N V{ 0 Q{{     vput-col  \  Q{{ : 0 }} <- V{
    N A{           vmag      \  |A{|
    R{{ 0 0 }} f!            \  R{{ 0 0 }} <- |A{|
    M 1 DO
      I A{{ N A{   vget-col  \  A{ <- A{{ : I }}
      N A{ V{      vcopy     \  V{ <- A{
      I 0 DO
        I Q{{ N P{ vget-col  \  P{ <- Q{{ : I }}
        N A{ P{    vdot      \  ( A{, P{ )
        fdup R{{ I J }} f!   \  R{{ I J }} <- (A{, P{)
        N P{       vscale    \  P{ <-- (A{, P{) * P{
        N V{ P{ V{ v-        \  V{ <- V{ - P{
      LOOP
      N V{ I A{{   vput-col  \  A{{ : I }} <- V{
      N V{         vnorm     \  V{ <- V{ / |V{|
      N V{ I Q{{   vput-col  \  Q{{ : I }} <- V{
      N V{ A{      vdot      \  ( V{, A{ )
      R{{ I I }} f!          \  R{{ I I }} <- (V{, A{)
    LOOP
;

BASE !

End-Module

TEST-CODE? [IF]
[undefined] T{ [IF] s" ttester.4th" included  [THEN]

base @
decimal

set-near
1e-15 rel-near f!

\ Example 1: Orthogonalize the two vectors { 3 1 } and { 2 2 }
\
\ See https://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process#Example

cr .( Example 1 ) cr

2 2 FLOAT MATRIX M1{{
3e M1{{ 0 0 }} f!
1e M1{{ 1 0 }} f!

2e M1{{ 0 1 }} f!
2e M1{{ 1 1 }} f!

2 2 M1{{ setup-gs ABORT" Error allocating arrays!"

TESTING gs
t{ gs -> }t

\ Validate orthognal vectors (not normalized)
t{ M1{{ 0 0 }} f@ ->  3e r}t
t{ M1{{ 1 0 }} f@ ->  1e r}t
t{ M1{{ 0 1 }} f@ -> -2e 5e f/ r}t
t{ M1{{ 1 1 }} f@ ->  6e 5e f/ r}t

\ Validate normalized orthognal vectors
10e fsqrt fconstant SQRT_10
t{ Q{{ 0 0 }} f@ ->  3e SQRT_10 f/ r}t 
t{ Q{{ 1 0 }} f@ ->  1e SQRT_10 f/ r}t
t{ Q{{ 0 1 }} f@ -> -1e SQRT_10 f/ r}t
t{ Q{{ 1 1 }} f@ ->  3e SQRT_10 f/ r}t

TESTING free-gs
t{ free-gs -> 0 }t

\ Example 2: Orthogonalize the three vectors,
\   { 2 2 1 }, { -2 1 2 }, { 18 0 0 }
\ See Ref. [1].

cr .( Example 2 ) cr

3 3 FLOAT MATRIX M2{{
 2e M2{{ 0 0 }} f!
 2e M2{{ 1 0 }} f!
 1e M2{{ 2 0 }} f!

-2e M2{{ 0 1 }} f!
 1e M2{{ 1 1 }} f!
 2e M2{{ 2 1 }} f!

18e M2{{ 0 2 }} f!
 0e M2{{ 1 2 }} f!
 0e M2{{ 2 2 }} f!

TESTING setup-gs
3 3 M2{{ setup-gs -> 0 }t

TESTING gs
t{ gs -> }t

\ Validate orthognal vectors
t{ M2{{ 0 0 }} f@ ->  2e r}t
t{ M2{{ 1 0 }} f@ ->  2e r}t
t{ M2{{ 2 0 }} f@ ->  1e r}t
t{ M2{{ 0 1 }} f@ -> -2e r}t
t{ M2{{ 1 1 }} f@ ->  1e r}t
t{ M2{{ 2 1 }} f@ ->  2e r}t
t{ M2{{ 0 2 }} f@ ->  2e r}t
t{ M2{{ 1 2 }} f@ -> -4e r}t
t{ M2{{ 2 2 }} f@ ->  4e r}t

\ Validate normalized orthognal vectors
1e 3e f/ fconstant 1/3
2e 3e f/ fconstant 2/3
t{ Q{{ 0 0 }} f@ ->  2/3 r}t 
t{ Q{{ 1 0 }} f@ ->  2/3 r}t
t{ Q{{ 2 0 }} f@ ->  1/3 r}t
t{ Q{{ 0 1 }} f@ ->  2/3 fnegate r}t
t{ Q{{ 1 1 }} f@ ->  1/3 r}t
t{ Q{{ 2 1 }} f@ ->  2/3 r}t
t{ Q{{ 0 2 }} f@ ->  1/3 r}t
t{ Q{{ 1 2 }} f@ ->  2/3 fnegate r}t
t{ Q{{ 2 2 }} f@ ->  2/3 r}t

\ Validate QR decomposition (Q validated above)
t{ R{{ 0 0 }} f@ ->   3e r}t
t{ R{{ 1 0 }} f@ ->   0e r}t
t{ R{{ 2 0 }} f@ ->   0e r}t
t{ R{{ 0 1 }} f@ ->   0e r}t
t{ R{{ 1 1 }} f@ ->   3e r}t
t{ R{{ 2 1 }} f@ ->   0e r}t
t{ R{{ 0 2 }} f@ ->  12e r}t
t{ R{{ 1 2 }} f@ -> -12e r}t
t{ R{{ 2 2 }} f@ ->   6e r}t

TESTING free-gs
t{ free-gs -> 0 }t

base !
[THEN]

