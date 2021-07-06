\ qm4.4th
\
\ Quantum Mechanics Demo 4: 
\ Properties of Eigenfunctions and Operators
\
\ Copyright (c) 2001--2018 Krishna Myneni
\ Provided under the GNU General Public License.
\
\ Please report bugs to: krishna.myneni@ccreweb.org
\
\ This demo illustrates several properties of eigenfunctions and
\ operators in quantum mechanics, using the radial eigenfunctions
\ for the hydrogen atom with zero angular momentum (l=0), phi_n(r),
\ as an example.
\
\ Various operators such as radial position, r, kinetic energy, T,
\ potential energy, V, and the Hamiltonian operator, H, are defined.
\ Using the defined eigenfunctions and operators, the student may
\
\   1) verify eigenfunctions are orthogonal
\   2) verify eigenfunctions are normalized
\   3) verify functions are actual eigenfunctions of H
\   4) determine eignvalues corresponding to the eigenfunctions
\   5) compute expectation values, <r>, <T>, <V>, <H> 
\   6) verify the Virial Theorem for the eigenstates: <T> = -<V>/2
\   7) compute probability of the electron being between r1 and r2
\ 
\ Examples of Usage:
\
\ a) Compute phi_1(r). The address of the wavefunction is returned on
\    the stack:
\
\    1 phi
\
\ b) Print the wavefunction computed in a):
\
\    psi.
\
\ c) Compute and output phi_1 to file ef1.dat:
\
\    >file ef1.dat 1 phi psi. console 
\
\ d) Compute and print then inner product of phi_1 and phi_1. 
\    A properly normalized wavefunction will give unity.
\
\    1 phi 1 phi ip f.
\
\    or
\
\    1 phi dup ip f.
\
\    Check normalization of remaining phi_n(r), n = 2--4.
\
\ e) Check orthogonality of phi_1 and phi_2. Two functions
\    are orthogonal if their inner product is zero.
\
\    1 phi 2 phi ip f.
\
\    Check orthogonality for other pairs, phi_i(r), phi_j(r),
\    i not equal to j.
\
\ f) Operate on phi_3 with r. The address of the result is returned
\    on the stack:
\
\    3 phi r
\
\ g) Operate on phi_3 with d/dr, i.e. compute first derivative
\    of phi_3; result returned on stack:
\
\    3 phi d/dr
\
\    Save phi_3(r) and dphi_3(r)/dr to files, and plot them together
\    on a graph. Verify the derivative calculation.
\
\ h) Compute and print radial probability density function,
\    |phi_1(r)|^2 :
\
\    1 phi dup prod r r psi.
\ 
\ i) Compute expectation value (average value) of r, <r>, in 
\    state phi_1 (units are Bohr radii):
\
\    1 phi dup r ip f.
\
\    Repeat for phi_n(r), n = 2--4.
\
\ j) Operate on phi_1(r) with Hamiltonian and print:
\
\    1 phi H psi.
\
\    How are the functions phi_1(r) and (H phi_1(r)) related to
\    each other? What is the eigenvalue of H, corresponding to
\    eigenfunction, phi_1(r)? Determine the eigenvalues of H
\    corresponding to phi_n(r), n=2--4.
\
\ k) Compute expectation value, <H>, in state phi_1(r)
\    (units are Rydbergs):
\
\    1 phi dup H ip f.
\
\    How are the expectation values of <H> in state phi_n(r)
\    related to the eigenvalues of H for phi_n(r)?
\
\ l) Compute the expectation values, <T>, and <V> for phi_n(r),
\    n=1,4. How are <T> and <V> related for the eigenfunctions?
\
\ m) Compute and print integral of r^2*phi_1*phi_1  from r=1.0 to
\    20.0 Bohr radii. This is the probability that an electron in
\    state 1 will be found between r= 1 and r=20.
\
\    1 phi dup prod 1e 20e integrate f. 
\
\
\ Notes:
\
\ 1. This demo uses the radial wavefunctions of the hydrogen atom, as
\    the example eigenfunctions. The radial functions are real (no 
\    imaginary component). Therefore, the code assumes only real 
\    eigenfunctions, and is limited in its application. For example, 
\    computations cannot be performed on arbitrary wavefunctions,
\    which are in general a complex superposition of the 
\    eigenfunctions. Such computations will be demonstrated in
\    subsequent demos.
\
\ 2. The program, H-atom.4th, computes radial eigenfunctions for
\    the hydrogen atom from a numerical solution of the radial wave
\    equation, for several n,l states. High accuracy energy
\    eigenvalues (8 significant digits) are computed using reduced
\    mass and relativistic corrections in that program.
\
\ Revisions:
\
\   2001-08-21 -- First version
\   2003-04-15 -- Replaced F>S with FROUND>S
\   2018-10-13 -- Revised.
\   2021-07-05 -- Revised to work on separate FP stack system.

include ans-words
include strings

[DEFINED] FDEPTH constant FPSTACK?
[UNDEFINED] a@  [IF] : a@ @ ; [THEN]
[UNDEFINED] s>f [IF] : s>f s>d d>f ; [THEN]
[UNDEFINED] fround>s [IF] : fround>s fround f>d d>s ; [THEN]

\
\ ---------------------------------------------------------------
\ Define the framework for storing wavefunctions and
\   performing arithmetic operations upon them.
\ ---------------------------------------------------------------

1 dfloats constant DSIZE
1024 1024 * constant PSIBUFSIZE		\ 1 MB
create psi_buf PSIBUFSIZE allot		\ allocate wavefunction buffer
variable psi_ptr psi_buf psi_ptr !	\ pointer in psi_buf

fvariable RMAX 50e RMAX f!  \ maximum radius in Bohr units for computations
variable nsteps
10000 nsteps !		\ default number of points for wavefunctions
fvariable rstep

: set_step_size ( -- ) RMAX f@ nsteps @ s>f f/ rstep f! ;

\ Return number of bytes required to store wavefunction
: psi_size ( -- n )
	nsteps @ dfloats ;

: psi_alloc ( -- a | reserve memory for wavefunction in psi_buf )
	\ return the address of start of wavefunction data
	psi_ptr a@ dup psi_size + 
	dup psi_buf PSIBUFSIZE + <
	if psi_ptr ! 
	else 2drop psi_buf dup psi_size + psi_ptr ! \ wraparound 
	then ; 

: @psi[] ( a n -- f | fetch the n^th element of wavefunction )
	\ n starts at 0 and can have maximum value of nsteps-1
	dfloats + f@ ;

: !psi[] ( f a n -- | store the n^th element of wavefunction )
	dfloats + f! ;

: psi. ( a -- | print the wavefunction value vs r )
	precision >r
	6 set-precision
	nsteps @ 0 DO
	  I s>f rstep f@ f* 
	  8 4 f.rd 2 spaces dup i @psi[] fs. cr
	LOOP drop 
	r> set-precision ; 	

: verify_address ( a -- a | abort if top item on stack is not an address )
	dup @ drop ; \ kForth will produce a VM error if item not an address

: verify_address_pair ( a1 a2 -- a1 a2 )
	2dup @ drop @ drop ;


\ ------------------------------------------------------------------ 
\ Eigenfunctions of the Hydrogen Atom Hamiltonian
\ ------------------------------------------------------------------

8 constant MAX_EF		\ maximum number of eigenfunctions
create efa MAX_EF cells allot	\ array of addresses to eigenfunctions

variable ne			\ number of eigenfunctions
4 ne !

2e fsqrt fconstant SQRT_TWO
3e fsqrt fconstant SQRT_THREE

\ In this example, we use the known radial eigenfunctions
\ for the hydrogen atom, phi_nl, for l = 0, c.f. R.D. Cowan,
\ The Theory of Atomic Structure and Spectra 
\ (University of California Press, 1981).
	 
: phi_10 ( r -- f | return 2*exp[-r] )
	fnegate fexp 2e f* ;

: phi_20 ( r -- f | return [2^-.5]*exp[-r/2]*[1-r/2] )
	2e f/ fnegate fdup 
	1e f+ fswap fexp f* SQRT_TWO f/ ;

: phi_30 ( r -- f | return [2/27^.5]*exp[-r/3]*[1 - 2r/3 + 2r^2/27] )
	3e f/ fnegate fdup fdup fdup
	f* 2e f* 3e f/ fswap 2e f* f+ 1e f+
	fswap fexp f* 2e f* 3e f/ SQRT_THREE f/ ;

: phi_40 ( r -- f | return [1/4]*exp[-r/4]*[1-3r/4+r^2/8-r^3/192] )
	4e f/ fnegate fdup fdup fdup
	fdup fdup f* f* 3e f/ fswap fdup f* 2e f* f+
	fswap 3e f* f+ 1e f+ fswap fexp f* 4e f/ ;
	

\ Set up addresses to the eigenfunctions

' phi_10 efa !
' phi_20 efa 1 cells + !
' phi_30 efa 2 cells + !
' phi_40 efa 3 cells + !

: @efa[] ( n -- xt | return the xt of the n^th eigenfunction )
	1- cells efa + a@ ;

variable ntemp

\ Return the n^th eigenfunction over the range r=0 to RMAX
: phi ( n -- a )
	dup ne @ > IF 
	  ." Invalid eigenfunction number." cr abort
	THEN
	ntemp !
	psi_alloc dup 	\ reserve memory for the data
	set_step_size
	nsteps @ 0 DO
	  dup
	  I s>f rstep f@ f* ntemp @ @efa[] execute
[ FPSTACK? invert ] [IF] rot [THEN] 
	  f! DSIZE +	  
	LOOP
	drop ;

	
\ ---------------------------------------------------------------
\ Define arithmetic operations on wavefunctions
\ ---------------------------------------------------------------

variable wf_a1
variable wf_a2
variable wf_a3
fvariable temp

\ Return a wavefunction scaled by a constant, r
: c* ( a1 r -- a2 )
	temp f!
	verify_address wf_a1 !
	psi_alloc wf_a2 !
	nsteps @ 0 DO
	  wf_a1 a@ I @psi[] temp f@ f*
	  wf_a2 a@ I !psi[]
	LOOP 
	wf_a2 a@ ;		

\ Return sum of two wavefunctions
: add ( a1 a2 -- a3 )
	psi_alloc wf_a3 ! 
	verify_address_pair wf_a2 ! wf_a1 !
	nsteps @ 0 DO
	  wf_a1 a@ I @psi[] 
	  wf_a2 a@ I @psi[] f+
	  wf_a3 a@ I !psi[]
	LOOP
	wf_a3 a@ ;

\ Return product of two wavefunctions
: prod ( a1 a2 -- a3 )
	psi_alloc wf_a3 ! 
	verify_address_pair wf_a2 ! wf_a1 !
	nsteps @ 0 DO
	  wf_a1 a@ I @psi[]
	  wf_a2 a@ I @psi[] f*
	  wf_a3 a@ I !psi[]
	LOOP
	wf_a3 a@ ;	

: r_index ( r -- u | return index corresponding to r )
	RMAX f@ f/ nsteps @ s>f f* fround>s 
	nsteps @ min 0 max ;

fvariable r1
fvariable r2

\ Return the volume integral of wavefunction a, between r1 to r2
: integrate ( a r1 r2 -- rint )
	r2 f! r1 f! 
	verify_address wf_a1 !
	set_step_size

	0e
	r2 f@ r_index r1 f@ r_index DO
	  wf_a1 a@ I @psi[]
	  I dup * s>f f* f+
	LOOP
	rstep f@ fdup fdup f* f* f* 
;

\ Return the inner product of wavefunctions a1 and a2
: ip ( a1 a2 -- rprod )
	verify_address_pair prod 0e RMAX f@ integrate ;


\ ---------------------------------------------------------------
\ Define operators that act on the wavefunctions to produce
\	new functions.
\ ---------------------------------------------------------------

\ Apply the position operator, r, to a wavefunction and return
\ new function
: r ( a1 -- a2 )
	verify_address wf_a1 !
	psi_alloc wf_a2 !
	nsteps @ 0 DO 
	  wf_a1 a@ I @psi[] rstep f@ I s>f f* f*
	  wf_a2 a@ I !psi[]
	LOOP
	wf_a2 a@ ;

\ Apply the operator, 1/r, to a wavefunction and return result
: 1/r ( a1 -- a2 )
	verify_address wf_a1 !
	psi_alloc wf_a2 !
	nsteps @ 0 DO
	  wf_a1 a@ I @psi[] rstep f@ I s>f f* 
	  fdup f0= 
	  IF fswap fdrop 	\ avoid singularity at r=0 
	  ELSE f/
	  THEN
	  wf_a2 a@ I !psi[]
	LOOP
	wf_a2 a@ ;

\ Derivative operators

\ Apply the derivative operator to a wavefunction and return result
\ a1 is the address of psi
\ a2 is the address of d(psi)/dr
: d/dr ( a1 -- a2 )
	verify_address wf_a1 !
	psi_alloc wf_a2 !

	\ Compute forward slope at first point

	wf_a1 a@ 1 @psi[] wf_a1 a@ 0 @psi[] f- rstep f@ f/ 
	wf_a2 a@ 0 !psi[]

	\ Compute derivative at interior points by averaging
	\   forward and backward slopes

	nsteps @ 1- 1 DO
	  wf_a1 a@ dup I    @psi[] 
[ FPSTACK? invert ] [IF] rot [THEN]
          I 1- @psi[] f-  
	  wf_a1 a@ dup I 1+ @psi[] 
[ FPSTACK? invert ] [IF] rot [THEN]
          I    @psi[] f-
	  f+ rstep f@ f/ 2e f/
	  wf_a2 a@ I !psi[]
	LOOP
	  
	\ Compute backward slope at last point	  	  	  

	wf_a1 a@ dup nsteps @ 1- @psi[] 
[ FPSTACK? invert ] [IF] rot [THEN]
        nsteps @ 2- @psi[] f- 
	rstep f@ f/ wf_a2 a@ nsteps @ 1- !psi[]

	wf_a2 a@ ;

\ Apply the second derivative operator to a wavefunction
: d2/dr2 ( a1 -- a2 ) d/dr d/dr ;

\ Define the Hamiltonian operator for the hydrogen atom
\
\ The Hamiltonian operator defined below is for the case of a 
\ central potential (V = V(r)) and with zero angular momentum :
\
\	H = T + V(r)
\
\ where K and V are the kinetic energy and potential energy
\ operators for the hydrogen atom,
\
\    T = -d2/dr2 - (2/r)d/dr
\
\    V(r) = -2/r
\
\ For the above expressions, the energy units are Rydbergs and 
\ distance units are Bohr radii:
\
\	1 Rydberg = 13.6058 eV
\	1 Bohr radius = 0.529177 Angstroms

\ Apply the kinetic energy operator to a wavefunction
: T ( a1 -- a2 )
	d/dr dup d/dr swap 1/r 2e0 c* add -1e0 c*
;

\ Apply the H-atom potential energy operator to a wavefunction
: V ( a1 -- a2 )  1/r -2e0 c* ;	

\ Apply the H operator to a wavefunction
: H ( a1 -- a2 )  dup T swap V add ;


