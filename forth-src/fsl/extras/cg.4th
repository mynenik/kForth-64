\ cg.4th
\
\ Compute Wigner 3j symbols and Clebsch-Gordan coefficients
\
\ Copyright (c) 2006 Krishna Myneni
\ Provided under the GNU General Public License
\
\ The C-G coefficients are the superposition coefficients of coupled
\ angular momentum states in the basis of uncoupled product eigenstates
\ of the angular momentum operator. Hence, they may be computed from
\ definite integrals of products of spherical harmonic functions (eigen-
\ functions of the J^2 operator). However, explicit series expressions
\ for their calculation (obtained from group theory?) are used for practical
\ calculation. The C-G coefficients "are practically indispensable for
\ quantitative calculations of atomic structure and spectra"[2], as well as
\ other quantum mechanical problems involving angular momentum.
\
\
\ Requires:
\   ans-words.4th
\   strings.4th
\
\ Revisions:
\   2006-11-06  added 3j(  for natural input of integral and half-integral values  km
\   2006-12-15  added cg<  for natural input  "   "    km
\   2006-12-16  added example d) and References  km
\   2006-12-17  fixed evaluation of kmin and kmax, and loop step for
\                 sum over k in "3j"  km
\   2006-12-19  use FSL arrays for holding factorial table and 3j terms  km
\   2006-12-20  factor terms to avoid overflow in products of factorials km
\   2006-12-22  reordered args for "cg" and "cg<" to use conventional order  km
\   2006-12-23  fixed sign error introduced in "cg", and deleted entry
\                 for 13! in the factorial table, which was wrong  km
\   2006-12-20  further regrouping of factorial arithmetic in "3j" extends
\                 range of arguments to 3j, and reduces loss of precision
\                 (see new cg-test.4th) km
\   2009-08-12 km  fixed error in Note 2b).
\   2020-02-13 km  fix GCD for both symmetric and floored division.
\
\ Notes:
\
\ 1. Words which expect the angular momentum quantum numbers on the
\    stack, such as "3j" and "cg", require the quantum numbers to be
\    scaled by 2, in order to be able to specify integral and half-integral
\    values.
\
\    Words which parse the arguments, "3j(" and "cg<", can parse
\    half-integral spin strings, and therefore the 2x scale factor
\    is not applied when using these words. The examples below illustrate
\    how to use these words.
\    
\ 2. Examples of usage:
\
\      a) Find the Clebsch-Gordan coefficient relating the coupled angular
\         momentum state |j1=2, j2=1, j=3, m=2> to the uncoupled product
\         state |j1=2, m1=2>*|j2=1, m2=0>:
\
\         cg< 2 2 1 0 | 3 2 > f.   \ prints 0.57735, or sqrt(1/3)
\
\         Note that the uncoupled state quantum numbers are specified
\         first, in the order j1, m1, j2, m2, followed by a separator,
\         '|', followed by the coupled state quantum numbers in the
\         order j, m (j1 and j2 are implied for the coupled state).
\
\      b) Write the coupled state, |j1=2, j2=1, j=2, m=2>, as a
\         superposition of the uncoupled product states |j1=2, m1>|j2=1, m2>:
\
\         The complete set of product states |j1,m1>|j2,m2> are:
\
\         |2,-2>|1,-1>  |2,-2>|1, 0>  |2,-2>|1, 1>
\         |2,-1>|1,-1>  !2,-1>|1, 0>  |2,-1>|1, 1>
\         |2, 0>|1,-1>  |2, 0>|1, 0>  |2, 0>|1, 1>
\         |2, 1>|1,-1>  |2, 1>|1, 0>  |2, 1>|1, 1>
\         |2, 2>|1,-1>  |2, 2>|1, 0>  |2, 2>|1, 1>
\
\        Therefore, we must evaluate 15 C-G coefficients. This is
\        done using a loop over m1=-j1 to +j1 and m2=-j2 to +j2,
\        as follows.
\
\        : superpose
\             3 -2 DO  2 -1 DO  J . I .
\                               4 J 2* 2 I 2* 4 4 cg    f. cr
\             LOOP LOOP ;
\
\       superpose       \ prints the 15 superposition coefficients
\
\       The only nonzero C-G coefficients are those belonging to the product
\       states  |2, 1>|1, 1>  and  |2, 2>|1, 0>. The superposition is found
\       to be
\
\       |j1=2, j2=1, j=2, m=2> = -0.57735*|2, 1>|1, 1> + 0.816497*|2, 2>|1, 0> 
\
\       Note that the arguments to "cg" in "superpose" are
\
\             2*j1  2*m1  2*j2  2*m2  2*j  2*m
\
\    c) Angular momentum conservation requires m = m1 + m2. Therefore, for
\       example b), it is not necessary to evaluate all 15 C-G coefficients.
\       Those product states for which m1+m2 is not equal to m are guaranteed
\       to have zero superposition coefficients, and we could simply write:
\       
\       3 -2 DO I . 4 I 2* 2 2 I - 2* 4 4 cg   f. cr  LOOP
\
\       where the loop is over m1, and the arguments to cg now are
\       2*j1  2*j2  2*m1  2*(m-m1)  2*j  2*m
\
\    d) An atom in a excited state with angular momentum J'=1, m'=0, makes an
\       electric-dipole transition to a lower state with J=2. Find the 
\       relative probabilities of transitions to each of the different sublevels (m)
\       of the lower J=2 state.
\
\       In an electric dipole transition, a photon is emitted and carries off 1 unit
\       of angular momentum. Therefore, the final state of the system may be
\       represented as the product state
\
\                     |J m>|1 q>
\
\       where q = -1, 0, or 1, and m = m' - q (from conservation of angular momentum).
\       The superposition coefficient between the initial excited state and the final
\       (product) state is then:
\
\                     < J  m'-q  1 q | J' m' >
\
\       The relative probability of a transition from |J',m'> --> |J, m = m'-q> is the
\       square of the above amplitude.
\
\       For the lower level, J=2, and there are 5 sublevels, m = -2, -1, 0, 1, 2.
\       Transitions to m = -2 and m = 2 cannot satisfy m = m' - q. Therefore,
\       the probability of a transition to these sublevels is zero. The
\       relative probabilities for the remaining sublevels are given by:
\
\       cg< 2 -1  1  1 | 1 0 >  fdup f* f.   \  30%  |1,0> --> |2, m = -1>
\       cg< 2  0  1  0 | 1 0 >  fdup f* f.   \  40%  |1,0> --> |2, m =  0>  
\       cg< 2  1  1 -1 | 1 0 >  fdup f* f.   \  30%  |1,0> --> |2, m =  1>
\
\
\  References:
\
\    1. E. P. Wigner, in L.C. Biedenharn and H. van Dam, eds., Quantum Theory of
\       Angular Momentum (Academic Press, New York, 1965).
\
\    2. R. D. Cowan, The Theory of Atomic Structure and Spectra, (University of
\       California Press, Berkeley, 1981).
\
\ Requires:
\    ans-words
\    strings
\    fsl-util


: upow ( u1 u2 -- u | u = u1^u2 )
    DUP 0= IF  2DROP 1
    ELSE  1 -ROT  0  DO  TUCK * SWAP  LOOP   DROP
    THEN
;

: gcd ( n1 n2 -- gcd | find greatest common divisor)
    ?DUP IF SWAP OVER MOD RECURSE THEN ABS ;

: simplify-fraction ( num denom -- num' denom' | simplify)
    2DUP gcd DUP >R / SWAP R> / SWAP ;    

: /sqrt ( isign inum idenom -- f | f = isign*sqrt[inum/idenom])
    ROT >R >R s>f r> s>f f/ fsqrt R> 0< IF FNEGATE THEN ;


: }izero ( n a -- | fill integer array of size n with zeros)
    SWAP 0 ?DO  0 OVER I } ! LOOP DROP ;

: }iput ( m_1 ... m_n n a -- | store m_1 ... m_n into array of size n )
    SWAP DUP 0 ?DO  1- 2DUP 2>R } ! 2R>  LOOP  2DROP ;

: }imax ( n a -- max | return the maximum value of an integer array of size n)
    DUP 0 } @ ROT 1 ?DO  OVER I } @ max  LOOP NIP ;
    
9 INTEGER ARRAY primes{
2 3 5 7 11 13 17 19 23  9 primes{ }iput

\ Return integer product from array of prime exponents
: }prime-product ( n array -- iprod | n is array size)
    1
    ROT 0 ?DO
	OVER I } @ DUP IF primes{ I } @ SWAP upow * ELSE DROP THEN
    LOOP NIP ;


13 INTEGER ARRAY fac_table{
1  1  2  6  24  120  720  5040  40320  362880
3628800 39916800 479001600
13 fac_table{ }iput

: fac ( n -- m | m is n factorial )
    DUP 12 > ABORT" greater than 12!"
    fac_table{ SWAP } @ ;

: prod ( n1 n2 -- m | m = PI_n1^n2; n1 < n2 )
    2DUP > IF SWAP THEN 1 -ROT 1+ SWAP ?DO I * LOOP ;

: fac/ ( a b -- num denom | simplify expression a!/b! to an ordinary fraction)
    2DUP = IF 2DROP 1 1
    ELSE
	2DUP < IF  SWAP 1+ SWAP prod 1 SWAP  ELSE  1+ SWAP prod 1  THEN
    THEN ; 
    
6 INTEGER ARRAY 3j_terms{

: j1' ( -- j1' ) s" 3j_terms{ 0 } @" evaluate ; immediate nondeferred
: j2' ( -- j2' ) s" 3j_terms{ 1 } @" evaluate ; immediate nondeferred
: j3' ( -- j3' ) s" 3j_terms{ 2 } @" evaluate ; immediate nondeferred
: m1' ( -- m1' ) s" 3j_terms{ 3 } @" evaluate ; immediate nondeferred
: m2' ( -- m2' ) s" 3j_terms{ 4 } @" evaluate ; immediate nondeferred
: m3' ( -- m3' ) s" 3j_terms{ 5 } @" evaluate ; immediate nondeferred


: check-triangle-relations ( -- flag )
    m1' abs j1' <=			\      j1 >= |m1| >= 0
    m2' abs j2' <= and		        \ and  j2 >= |m2| >= 0
    m3' abs j3' <= and		        \ and  j3 >= |m3| >= 0
    j1' j2' + j3' + 1 and 0= and  	\ and  j1+j2+j3 is an integer 
    m1' m2' + m3' + 0= and  	        \ and  m1+m2+m3 = 0
    j1' j2' - m3' - 1 and 0= and	\ and  j1-j2-m3 is an integer
    j1' j2' + j3' >= and		\ and  j1+j2 >= j3
    j2' j3' + j1' >= and		\ and  j2+j3 >= j1
    j3' j1' + j2' >= and 		\ and  j3+j1 >= j2
;

variable 3j-sign
variable kmax
variable kmin

9 INTEGER ARRAY termsA{ 
9 INTEGER ARRAY termsB{

: factor-terms ( -- | factor terms from square root expression if they appear twice in termsA)
    1 1 1 1 1 1 1 1 1  9 termsB{ }iput
    8 0 DO
	I termsA{ I } @ DUP 1 <> IF
	    9 I 1+ DO
		termsA{ I } @ 2DUP = IF
		    DROP 2DUP OVER termsB{ SWAP } !
		    1 termsA{ ROT } !
		    1 termsA{ I } !
		    LEAVE
		ELSE
		    DROP
		THEN
	    LOOP
	THEN
	2DROP
    LOOP
;
		
	
: 3j  ( 2j1  2j2  2j3  2m1  2m2  2m3 -- f | compute the 3j symbol value)
    6 3j_terms{ }iput
    check-triangle-relations
    IF
	\ Compute 3-j symbol
	j1' j2' - m3' - 2/ 1 and 3j-sign !
	
	j1' j2' + j3' - 2/
	j1' j2' - j3' + 2/
	j2' j3' + j1' - 2/
	j1' m1' -       2/
	j1' m1' +       2/
	j2' m2' -       2/
	j2' m2' +       2/
	j3' m3' -       2/
	j3' m3' +       2/
	9 termsA{ }iput

	factor-terms
	
	1
	9 termsA{ }imax
	9 0 DO termsA{ I } @ OVER = IF 1 termsA{ I } ! LEAVE THEN  LOOP
	j1' j2' + j3' + 2+ 2/ fac/ /sqrt
	
	1  9 0 DO termsA{ I } @ DUP 1 > IF fac * ELSE DROP THEN LOOP s>f fsqrt f*

	1  9 0 DO termsB{ I } @ DUP 1 > IF fac * ELSE DROP THEN LOOP s>f f*
  
	j1' j2' + j3' -
	j1' m1' -        MIN
	j2' m2' +        MIN  kmax !
	
	0
	j2' j3' - m1' -  MAX
	j1' j3' - m2' +  MAX  kmin !

	0e
	kmax @ kmin @ >= IF 
	
	    \ Compute sum over k'

	    kmax @ 1+ kmin @ ?DO
		1e
		i 2/ fac
		j1' j2' + j3' - i - 2/ fac *
		j1' m1' - i -       2/ fac *
		j2' m2' + i -       2/ fac *
		j3' j2' - m1' + i + 2/ fac *
		j3' j1' - m2' - i + 2/ fac *
		s>f
		f/
		i 2/ 1 and IF fnegate THEN f+
	    2 +LOOP
	THEN
	f*
	3j-sign @ IF fnegate THEN
	  
    ELSE
	0e
    THEN ;



\ Compute the 3j symbol from the product of primes formula, given the
\   prime exponents (see Appendix C of ref [2]). The exact integral
\   numerator and denominators for the fraction are first computed and
\   stored.

variable num
variable denom
9 INTEGER ARRAY  num_terms{
9 INTEGER ARRAY  denom_terms{

: 3jp ( isign iexp1 iexp2 ... iexpn n -- f | isign is +1 or -1) 
    9 num_terms{ }izero   9 denom_terms{ }izero
    1 SWAP DO
	DUP 0< IF ABS denom_terms{ ELSE num_terms{ THEN  I 1- } !
    -1 +LOOP
    9 num_terms{ }prime-product
    9 denom_terms{ }prime-product
    simplify-fraction
    2DUP denom ! num ! /sqrt ; 



: cg ( 2j1  2m1  2j2  2m2  2j  2m -- f )
    rot swap 2>r rot 2r>  negate 3j
    j3' 1+ s>f fsqrt f*
    j1' j2' - m3' + 2/ 1 and IF fnegate THEN ;
    
    
\ Convert a string representing an integral or half-integral spin
\   into a scaled integer. The string contains an integer or fractional
\   half integer, e.g. " -3/2", "1/2", "3", ...
: $>j ( a u -- n )
    2dup s" /2" search IF  nip - 0 ELSE  2drop 1 THEN >r evaluate r> lshift ;   

: 3j( ( "..." -- f | parse arguments to 3j and compute)
    [char] ) word count parse_line
    6 <> ABORT" Incorrect number of arguments!"
    $>j >r $>j >r $>j >r $>j >r $>j >r $>j
    r> r> r> r> r> 
    3j ;

: cg< ( " ... " -- f | parse arguments to cg and compute)
    [char] | word count parse_line
    4 <> ABORT" Incorrect number of arguments for uncoupled state!"
    $>j >r $>j >r $>j >r $>j 
    r> r> r>
    [char] > word count parse_line
    2 <> ABORT" Incorrect number of arguments for coupled state!"
    $>j >r $>j r>
    cg
;


