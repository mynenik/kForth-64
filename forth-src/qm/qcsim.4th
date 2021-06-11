\ qcsim.4th
\
\ Quantum Circuit Simulation language for few qubit circuits.
\
\ Copyright (c) 2019, Krishna Myneni
\ Permission is granted to reuse this work, with attribution,
\ under the Creative Commons CC-BYSA license.
\
\ Notes:
\
\ 0. "n" refers to the number of qubits in the quantum circuit.
\    The quantum state vector of the circuit has 2^n dimensions in 
\    a complex state space.
\
\ 1. A quantum state for n qubits is a data structure containing the
\    following:
\
\      # of dimensions (2^n),  size = 1 cells
\      complex matrix, size = 2^n zfloats + 2 cells
\
\    The dimensions of the complex matrix are 2^n x 1 for a ket vector
\    and 1 x 2^n for bra vector.
\
\ 2. Quantum gates operating on n-qubit quantum states are represented
\    as a data structure containing the following:
\
\      # of dimensions (2^n), size = 1 cells
\      2^n x 2^n complex matrix, size = 2^(2n) zfloats + 2 cells  
\
\ 3. Executing the name of a bra, ket, or gate returns the address
\    of the first element in its complex matrix (see zmatrix.4th),
\    allowing it to be used in the same way as a zmatrix.
\
\ Special stack notation:
\
\   c  unsigned single cell value interpreted as a series
\      of n classical bits (where n must be specified).
\
\   q  pointer to an n-qubit quantum state vector (ket or bra), or
\      or to an n-qubit quantum gate, which may be stored in either the 
\      dynamic buffer (transient persistence) or to the reserved 
\      storage in a named child of one the following defining words:
\      KET  BRA  GATE
\
\ References:
\
\   1.  Quantum computation and Quantum Information, M. A. Nielsen
\       and I. L. Chuang, Cambridge University Press, 2000.
\      
\ Glossary:
\
\  2^      ( n -- m )  m = 2^n
\  ILOG2   ( u1 -- u2 ) floored log base 2 of integer
\  }}ZCLEAN  ( r nrows a -- ) threshold absolute values of zmatrix elements
\  DIM     ( a -- nrows ncols ) return dimensions of xzmatrix
\  QDIM    ( q -- 2^n ) return dimensionality of quantum state or gate
\  ALLOC_QBUF ( u -- a )  get transient memory for u bytes  
\  ALLOC_XZMAT ( nrows ncols -- a ) get transient memory for xzmatrix 
\  ALLOC_K ( 2^n -- q ) get transient memory for n-qubit ket vector
\  ALLOC_B ( 2^n -- q ) get transient memory for n-qubit bra vector
\  ALLOC_G ( 2^n -- q ) get transient memory for n-qubit gate
\
\  KET    ( n "name" -- ) create named n-qubit ket vector
\  BRA    ( n "name" -- ) create named n-qubit bra vector
\  GATE   ( n "name" -- ) create named n-qubit unitary gate
\
\  CBITS   ( c n -- caddr u ) return n-bit string for c 
\  C.      ( c -- )    print binary representation of c
\  Q.      ( q -- )    print a qubit state or gate matrix
\  Q!      ( z1 ... zm q -- )  store elements of q from stack
\  ->      ( q1 q2 -- ) copy qubit state or gate: q1->q2
\  QCLEAN? flag when true prints elements with value < minClean as zero
\
\  Q+      ( q1 q2 -- q3 ) add two q's
\  F*Q     ( r  q1 -- q2 ) Multiply q1 by a real scalar; return in q2
\  Z*Q     ( z  q1 -- q2 ) Multiply q1 by a complex scalar; return in q2
\  %*%     ( q1 q2 -- q3 ) Matrix multiplication of q1 and q2
\  %x%     ( q1 q2 -- q3 ) Kronecker outer product of q1 and q2
\  U_C     ( icntrl itarg qgate n -- qgate2 ) conditional n-qubit gate
\  U_SW    ( i j n -- qgate ) swap gate for qbits i and j in n-qubit gate
\  ADJOINT ( q1 -- q2 )    q2 = adjoint of q1 (q1 "dagger")
\
\  PROB      ( c q -- r )  return probability for measuring c for state q
\  ALL-PROB  ( q -- ) print all bit string probabilities for state q
\  SHOW-PROB ( q -- ) display bit string probabilities as text bar graph
\  }SAMPLES  ( q u a -- ) obtain u measurement samples for state q
\  P_OBS     ( u1 a1 u2 a2 -- ) compute observed bitstring probabilities.
\
\  Not yet implemented:
\
\  Q-      ( q1 q2 -- q3 ) subtract two q's
\  MEASURE  ( qin xtqc -- c ) execute quantum circuit with state qin
\                       and measure bit outputs c
\ Requires:
\   fsl/fsl-util.4th
\   fsl/complex.4th
\   fsl/extras/zmatrix.4th
\
\ Revisions:
\   2019-11-02 km  first version, one and two-qubit quantum circuits
\   2019-11-07 km  generic operators for quantum states and gates;
\                    simplified notation.
\   2019-11-08 km  implemented words U_C and U_SW to generate conditional
\                    two-qubit gates and swap gates for an n-qubit circuit;
\                    implemented F*Q and Z*Q and added 3-qubit QFT circuit
\                    example and a 3-qubit circuit exercise.
\   2019-11-11 km  fix comments; add MAXN and constants; use ilog2; begin
\                    implementation of measurement words.
\   2019-11-14 km  added SHOW-PROB , }SAMPLES , and related utilities;
\                    added SQRTX and SQRTY gates.
\   2019-11-20 km  added P_OBS to compute observed probabilities.
include ans-words.4th
include strings.4th
include fsl/fsl-util.4th
include fsl/complex.4th
include fsl/horner.4th
include fsl/extras/zmatrix.4th
include fsl/extras/noise.4th

\ General utilities
[UNDEFINED] 4dup [IF] : 4dup 2over 2over ; [THEN]

8 constant MAXN   \ maximum number of qubits

1e 2e f/ fsqrt fconstant 1/sqrt2 
pi 2e f/ fconstant pi/2
1e  1e 1/sqrt2 z*f     zconstant z=sqrti   \ square root of  i
1e -1e 1/sqrt2 z*f     zconstant z=sqrt-i  \ square root of -i

: 2^ ( n -- m ) 1 swap lshift ;
: u2/ ( u -- u/2 ) 1 rshift ;

\ Implementation of ILOG2 by Rick C., comp.lang.forth, 2019-11-07
: ilog2 ( u1 -- u2 )  \ Find floored log base 2
  0 BEGIN swap u2/ dup WHILE swap 1+ REPEAT drop ;

: c. ( c -- | print binary form of c) 
   base @ binary swap . base ! ;

\ Return n-bit binary string for c
: cbits ( c n -- caddr u )
   base @ >r binary 
   >r s>d <# r>
   0 ?DO # LOOP #> 
   r> base ! ;

\ Initialization of pseudo random number generator ran0
37882569 idum !

true value qclean?
1e-12 fconstant minClean

\ Threshold the absolute values of the real and imaginary parts
\ of each element in a zmatrix. If a part of the element has 
\ absolute value less than the threshold, set that part to zero.
\ This is useful for suppressing numerical errors for printing.
: }}zclean ( r nrows a -- )
    tuck }}ncols * 0 ?DO  \ -- r a
      dup >r f@  f2dup fabs  \ -- r Re(z) r |Re(z)|  R: a
      f> IF fdrop 0e r@ f! ELSE fdrop THEN  \ -- r 
      r> float+ 
      dup >r f@ f2dup fabs   \ -- r Im(z) r |Im(z)|  R: a 
      f> IF fdrop 0e r@ f! ELSE fdrop THEN
      r> float+
    LOOP drop fdrop ;

\ An extended zmatrix structure. FSL matrices do not store the
\ number of rows in the header. To abstract the interface for
\ both quantum state vectors (ket and bra) and quantum gates,
\ we extend the zmatrix structure to store the number of rows
\ as well, while allowing the extended "xzmatrix" to be used 
\ transparently as a zmatrix

3 cells constant HDRSIZE

: xzmat-hdr! ( nrows ncols a -- )
    tuck cell+ complex over cell+ ! ! ! ;

: xzmat-size ( nrows ncols -- u ) * zfloats HDRSIZE + ;

: xzmatrix ( nrows  ncols "name" -- )
    create 2dup xzmat-size allot? xzmat-hdr!
    does> HDRSIZE + ;

\ Return the dimensions of an xzmatrix
: dim ( a -- nrows ncols ) HDRSIZE - dup @ swap cell+ @ ;
: }}nrows ( a -- nrows )   HDRSIZE - @ ;

\ Dynamic buffer for transient, unnamed quantum states and gates
1024 2048 * constant QBUF_SIZE
create qbuf QBUF_SIZE allot
variable qptr   qbuf qptr !
 
\ Allocate usize bytes and in dynamic buffer;
\ Return start address of newly allocated region.
: alloc_qbuf ( usize -- a | allocate size bytes and return address)
    dup QBUF_SIZE >= Abort" Object too big for dynamic buffer!"
    dup QBUF_SIZE 2/ 2/ >= IF 
      ." WARNING: QBUF_SIZE should be increased!" 
    THEN
    >r qptr a@ dup r@ + dup qbuf QBUF_SIZE + >=
    IF 2drop qbuf dup r> +          \ wraparound 
    ELSE r> drop THEN
    qptr ! ;

\ allocate an xzmatrix in the dynamic buffer;
\ return address is to start of matrix data
: alloc_xzmat ( nrows ncols -- a ) 
    2dup xzmat-size alloc_qbuf 
    dup >r xzmat-hdr! r> HDRSIZE + ;

\ allocate an n-qubit ket vector in the dynamic buffer
: alloc_k ( 2^n -- q ) 1 alloc_xzmat ;

\ allocate an n-qubit bra vector in the dynamic buffer
: alloc_b ( 2^n -- q ) 1 swap alloc_xzmat ;

\ allocate space for an n-qubit gate in the dynamic buffer
: alloc_g ( 2^n -- q ) dup alloc_xzmat ;

\ Adjoint of quantum state vector or gate
: adjoint ( q -- qd )
    dup dim swap alloc_xzmat >r
    dup }}nrows swap r@ }}ztranspose
    r@ dup }}nrows swap }}zconjg r> ;
    
\ Return dimensionality of quantum state or gate
: qdim ( q -- 2^n ) dim max ;

\ Copy ket, bra, or gate: q1 -> q2
: -> ( q1 q2 -- )
    2dup >r dim r>  dim d= invert Abort" Object size mismatch!"
    dup dim * zfloats move ;

\ Print a state vector or a gate
: q. ( q -- )
    qclean? IF  
      dup dim alloc_xzmat dup >r ->
      minClean r@ }}nrows r@ }}zclean
      r>
    THEN  
    dup }}nrows swap }}zprint ;

\ Store qubit state vector or gate matrix elements from stack
: q! ( z1 ... zm q -- )
    dup >r dim *   \ -- z1 ... zm nelem
    r> dup dim 1- swap 1- swap }}
    swap 0 ?DO  dup >r z! r> zfloat-  LOOP drop ;

\ Add two states or two gates
: q+ ( q1 q2 -- q3 )
    dup dim alloc_xzmat >r
    >r dup }}nrows swap r> 
    r@ }}z+ r> ;

0 [IF]
\ Subtract two states or two gates
: q- ( q1 q2 -- q3 )
    dup dim alloc_xzmat >r
    >r dup }}nrows swap r> 
    r@ }}z- r> ;
[THEN]

\ Scale q by a real number
: f*q ( r q1 -- q2 )  
    dup dim alloc_xzmat dup >r ->
    r@  dup qdim swap }}f*z r> ;

\ Scale q by a complex number
: z*q ( z q1 -- q2 )  
    dup dim alloc_xzmat dup >r ->
    r@  dup qdim swap }}z*z r> ;

\ Probabilities for measuring bit patterns for a given state

\ Probability of measuring classical bits c given ket q
: prob ( c q -- r )
    dup >r qdim 1- and r> swap 0 }} z@ |z|^2 ;

\ Store the probabilities for each possible bit string;
\ Return the sum of all probabilities (use as check for
\ r = 1).
MAXN 2^ float array p{
variable nprob

: set-p ( q -- r)
    dup dim = Abort" Not a state vector!"
    dup qdim
    dup MAXN 2^ > Abort" Maximum dimension exceeded!"
    dup nprob !
    0 ?DO 
      I over prob    
      p{ I } f!
    LOOP  drop
    0e nprob @ 0 ?DO  p{ I } f@ f+  LOOP ;

\ Print the probabilities for measuring all 2^n classical
\ outputs for ket q
fvariable tprob

: all-prob ( q -- )
    dup set-p tprob f!
    qdim  \ -- 2^n
    dup 0 ?DO
      dup I swap 
      2 spaces ilog2 cbits type 2 spaces
      p{ I } f@ 
      qclean? IF
        fdup minClean f< IF fdrop 0e THEN
      THEN 
      6 4 f.rd cr
    LOOP  >r
    tprob f@  r> ilog2 10 + 4 f.rd 
;

\ Display a text bar graph of the bit string probabilities
\ for a given quantum state
: show-prob ( q -- )
    dup set-p fdrop
    qdim  \ -- 2^n
    dup 0 ?DO
      dup I swap
      2 spaces ilog2 cbits type space
      p{ I } f@ 100e f* fround>s
      0 ?DO [char] * emit LOOP cr
    LOOP  drop
;

\ Utilties for sampling bit strings
\ Map ranges in unit interval to correspond to probabilities
\ for each bit string
MAXN 2^ float array rngmap{
: set-rngmap ( q -- )
    dup set-p 
    1e f- fabs minClean f> Abort" Total probability is not unity!"
    p{ 0 } f@  rngmap{ 0 } f!
    qdim 1 ?DO
      rngmap{ I 1- } f@ p{ I } f@ f+
      rngmap{ I } f!
    LOOP ;

\ Return the measured bits for the current probability
\ distribution (set-rngmap should have been called prior)
\ for the quantum state.
: rng>bits ( r -- c )
    nprob @ 0 ?DO
      fdup rngmap{ I } f@ f< IF fdrop I unloop EXIT THEN
    LOOP
    true Abort" Random trial is out of range!" ;

\ Obtain u measurements of n-qubit state vector q and return
\ the measurements in an integer array
: }samples ( q u a -- )
    rot set-rngmap
    swap 0 ?DO  \ -- a
      ran0 rng>bits over !
      cell+
    LOOP  drop ;

\ Compute the observed probabilities for u1 samples 
\ stored in an integer array a1 for a quantum state of
\ dimension u2. The observed probabilities are stored in
\ floating point array a2.
variable a_obs
variable udim
: P_obs ( u1 a1 u2 a2 -- )
    a_obs ! dup udim !
    0 ?DO  \ loop over u2 probabilities
      over 0 ?DO  \ loop over u1 samples
        dup I } @ J = IF
          a_obs a@ J } dup >r f@ 1e f+  r> f!
        THEN
      LOOP
    LOOP  drop
    s>f
    udim @ 0 ?DO 
      a_obs a@ I } dup >r 
      f@ fover f/ r> f!  
    LOOP  fdrop ;

\ Create a named, uninitialized n-qubit ket state vector.
: ket ( n "name" -- )  2^ 1 xzmatrix ;

\ Create named dual n-qubit bra state vector.
: bra ( n "name" -- ) 1 swap 2^ xzmatrix ;

\ Create a named, uninitialized n-qubit unitary transformation
: gate ( n "name" -- ) 2^ dup xzmatrix ;

\ Create a special 1x1 xzmatrix to use for building up
\ multi-qubit gates or state vectors with the outer product
0 gate one
z=1 one z!

0 [IF]
\ Return flag indicating whether or not matrix object is unitary
: unitary? ( q -- flag )
    dup adjoint %*% identity? ;
[THEN]

\ Product of bra and ket vectors
: b*k ( q1 q2 -- z )
    2>r z=0 2r> 
    dup qdim 0 ?DO  \ -- q1 q2
      2>r 2r@ drop z@ 2r@ nip z@ z* z+
      2r> zfloat+ swap zfloat+ swap
    LOOP  2drop ;

\ Generic object matrix multiplication
: %*% ( q1 q2 -- q3|z )
    2dup >r dim r> dim >r <> Abort" Object sizes not compatible!"
    r>  \ -- q1 q2 nrow1 ncol2
    2dup 1 1 D= IF 
      2drop b*k
    ELSE
      alloc_xzmat \ -- a1 a2 a3
      >r >r   dup }}nrows swap 
      r>      dup }}nrows swap 
      r@ }}zmul r>
    THEN ;
 
\ Kronecker outer products of quantum states and gates.
: %x% ( q1 q2 -- q3 )
    2dup >r dim r> dim    \ -- q1 q2 nrows1 ncols1 nrows2 ncols2
    >r swap >r * r> r> *  \ -- q1 q2 nrows1*nrows2 ncols1*ncols2
    alloc_xzmat >r        \ -- q1 q2  r: q3
    >r dup }}nrows swap
    r> dup }}nrows swap
    r@ }}zkron r> ;

\ Predefined single and two-qubit states and their adjoints
1 ket |0>   z=1 z=0 |0> q! 
1 ket |1>   z=0 z=1 |1> q! 

1 bra <0|  |0> adjoint <0| ->
1 bra <1|  |1> adjoint <1| ->

\ Compose two-qubit states out of Kronecker products of 1-qubit states
2 ket |00>   |0> |0> %x%  |00> ->
2 ket |01>   |0> |1> %x%  |01> ->
2 ket |10>   |1> |0> %x%  |10> ->
2 ket |11>   |1> |1> %x%  |11> ->

2 bra <00|   |00> adjoint <00| ->
2 bra <01|   |01> adjoint <01| ->
2 bra <10|   |10> adjoint <10| ->
2 bra <11|   |11> adjoint <11| ->

\ Non-unitary operators P0, P1, P01, P10
1 gate P0   |0> <0| %*% P0  ->  \ projection operator |0><0|
1 gate P1   |1> <1| %*% P1  ->  \ projection operator |1><1|
1 gate P01  |0> <1| %*% P01 ->
1 gate P10  |1> <0| %*% P10 ->

\ Single qubit operators and gates: I1, X, Y, Z, S, T, H
1 gate I1  P0 P1 q+ I1 ->
1 gate X   z=0 z=1 z=1 z=0  X q!
1 gate Y   z=0 z=i znegate z=i z=0 Y q!
1 gate Z   z=1 z=0 z=0 z=1 znegate Z q!
1 gate S   z=1 z=0 z=0 z=i  S q!
1 gate T   z=1 z=0 z=0 pi 4e f/ fsincos fswap T q!
1 gate H   X Z q+ H ->  1/sqrt2 H f*q H ->
1 gate SQRTX z=1 z=i z=i z=1 SQRTX q!
  z=sqrti conjg 1/sqrt2 z*f  SQRTX z*q SQRTX ->
1 gate SQRTY z=1 z=1 znegate z=1 z=1 SQRTY q!
  1/sqrt2 SQRTY f*q SQRTY ->

0 [IF]
: RX ( rtheta -- q )
;

: RY ( rtheta -- q )
;

: RZ ( rtheta -- q )
;
[THEN]

\ Conditional 2-qubit unitary gate:
\   n is number of qubits in circuit; n >=2
\   icontrol is index of control qubit: 0 -- n-1
\   itarget  is index of target  qubit: 0 -- n-1, itarget <> icontrol
\   q1 is the one-qubit gate to be used in conditional 2-qubit gate
variable cntrl
variable targ
variable qtemp

: U_c ( icontrol itarget q1 n -- q2 )
    dup 2 < Abort" ** Circuit must have minimum of 2 qubits!"
    >r qtemp ! targ ! cntrl ! r>
    cntrl @ over >= >r targ @ over >= r> or
    Abort" ** Control or target qubits are out of range!"
    cntrl @ targ @ = 
    Abort" ** Control and target cannot be same qubits!"
    one dup  \ -- n q=1 q=1
    rot 0 ?DO
       cntrl @ I = IF
          >r >r  P0 r> %x%  P1 r> %x%
       ELSE
         targ @ I = IF
           >r >r I1 r> %x%  qtemp a@ r> %x% 
         ELSE
           >r >r I1 r> %x%  I1 r> %x%
         THEN
      THEN
    LOOP
    q+ 
;

\ SWAP gate for qubits i and j in an n-qubit circuit
\ implemented using CNOT gates.
variable qtemp

: U_sw ( i j n -- q )
   dup 2 < Abort" ** Circuit must have minimum of 2 qubits!"
   X swap 
   4dup U_c qtemp !
   2>r swap 2r> U_c
   qtemp a@ tuck >r 
   %*% r> %*% ;
   
\ Two qubit gates: I2, U2CN, U2CNR, U2CZ, U2SW

2 gate I2     I1 dup %x%   I2 ->
2 gate U2CX   1 0 X 2 U_c  U2CX ->  \ CNOT gate: q0=target, q1=control
2 gate U2CXR  0 1 X 2 U_c  U2CXR -> \ CNOT gate: q0=control, q1=target
2 gate U2CZ   1 0 Z 2 U_c  U2CZ ->  \ CZ   gate: q0=target, q1=control
2 gate U2SW   0 1   2 U_sw U2SW ->  \ SWAP gate for q0 and q1

\ Examples:
\
\ 1) Simple one-qubit quantum circuit. Input state is |0>.
\ 
\    q0 |0> ---[H]---
\
\    Compute output state and probabilities for 0 and 1.
\
\    1 ket |a>         \ make a 1-qubit ket state called '|a>' 
\    H |0> %*% |a> ->  \ compute and store output state
\    <0| |a> %*% z.    \ print complex probability amplitude <0|a>
\    0 |a> prob f.    \ print probability of measuring c=0 for |a>
\    1 |a> prob f.    \ print probability of measuring c=1 for |a>
\
\ 2) Two-qubit quantum circuit with only single qubit gates
\
\    q1 |0> ---[H]---
\    
\    q0 |0> ---[X]---
\
\    2 ket |ba>
\    H |0> %*%  X |0> %*%  %x% |ba> ->  \ compute output state for circuit
\    H X %x% |00> %*% |ba> ->  \ alternate way to compute output state
\    <10| |ba> %*% |z|^2 f. \ print probability of measuring c=10 (binary)
\    |ba> all-prob    \ display probabilities for measuring all bit strings
\
\ 3) Two-qubit quantum circuit to generate entangled qubits.
\               :      
\    q1 ---[H]-----*-----
\               :  |
\    q0 ---[X]----[CX]---
\               :
\               1
\
\ Define the quantum circuit operations on an input state of 2 qubits to
\ transform it into the output state.
\
\    : qc3 ( qin[2] -- qout[2] )
\        H X %x%  \ compose the 2-qubit gate prior to 1; note the order.
\        swap %*%      \ apply to input state to give quantum state at 1
\        U2CX swap %*% \ apply CNOT gate to give output state
\    ;
\
\    |00> qc q.  \ print output state for input |00>
\    |01> qc q.  \   "                   "      |01>
\    |10> qc q.  \   "                   "      |10>
\    |11> qc q.  \   "                   "      |11>
\
\
\ 4) Three-Qubit Quantum Fourier Transform
\
\    Compose a 3-qubit gate for the circuit below.
\
\                  :         :
\  q2 ---[H]---[S]---[T]----------------x----
\               |  :  |      :          |
\  q1 ----------*-----|--[H]---[S]------|----
\                  :  |      :  |       |
\  q0 ----------------*---------*--[H]--x----
\                  :         :
\                  1         2

2 gate U2CS01   0 1 S 2 U_c  U2CS01 ->   \ Controlled-phase gate

3 gate U3QFT  \ 3-qubit gate for full circuit
  H I1 %x% 
  U2CS01          swap %*%     \ 2-qubit gate at 1 for q1,q2                     
  I1 %x%                       \ transform to 3-qubit gate
  0 2 T 3 U_c     swap %*%
  I1 H %x% I1 %x% swap %*%     \ 3-qubit gate at 2
  I1 U2CS01 %x%   swap %*%
  I2 H %x%        swap %*%
  0 2 3 U_sw      swap %*%
  U3QFT  ->

\ 5) Exercise: 
\
\    Compose the following implementation of the 3-qubit Toffoli gate.
\
\ q2 ------------------*------------------*---------*---------*--[T]--
\                      |                  |         |         |
\ q1 --------*---------|--------*---------|--[Td]-[CX]-[Td]-[CX]-[S]--
\            |         |        |         |
\ q0 --[H]-[CX]-[Td]-[CX]-[T]-[CX]-[Td]-[CX]-[T]-[H]------------------
\
\  The Td gate is defined below. Use the word U_c to define the 
\  conditional NOT gates [CX] between the appropriate qubits.
\  You may want to define other intermediate gates to help compose 
\  the gate for the entire circuit.

1 gate Td  T adjoint Td ->

