\ iso_1s2_hf.4th
\
\ Use the Hartree-Fock (HF) approximation to calculate the
\ ground state radial functions, binding energies, one-
\ electron ionization energies, average radii of the 1s
\ orbital, and average electron speed in the 1s orbital
\ for the isoelectronic sequence of atoms with a 1s(2) 
\ electron configuration, over the range Z = 2 to 10:
\
\   He, Li1+, Be2+, B3+, C4+, N5+, O6+, F7+, Ne8+
\
\ Notes:
\
\   1. The mesh size used by default (65,536) and the
\      selection of Rmax as a function of Z gives an
\      accuracy, within the HF theory, of 7 significant
\      digits and a maximum error of less than 1e-5 a.u.
\      in the calculation of the total binding energy.
\
\   2. Comparison to experimental values of binding and
\      ionization energies may be found at ref. 3. With
\      the exception of He, which has a discrepancy of 1.4%
\      with experiment, all other atoms have a discrepancy
\      of less than 1%. Correlation corrections are
\      important for the lighter atoms, while relativistic
\      corrections become important for higher Z. 
\
\ References:
\
\   1. R. D. Cowan, The Theory of Atomic Structure and Spectra,
\      Univ. of California Press, Berkeley 1981.
\
\   2. C. Froese-Fischer, et. al., Program HF.f from the Atomic
\      Structure Package (ATSP), 
\      http://nlte.nist.gov/cgi-bin/MCHF/download.pl?d=ATSP
\
\   3. NIST Atomic Spectral Database, 
\      http://www.nist.gov/pml/data/asd.cfm
\
\   4. C. C. J. Roothaan and A. W. Weiss, "Correlated Orbitals
\      for the Ground State of Heliumlike Systems," Reviews of
\      Modern Physics vol. 32, pp. 194--205 (1960); see Table
\      V, column 2.
\
\ Revisions:
\   2017-07-26  km; first complete version.
\   2024-08-11  km; fix to run under 64-bit kForth also
include ans-words
include modules
1 cells 4 = [IF]
include syscalls
include mc
include asm-x86
include fpu-x86
[THEN]
include strings
include fsl/fsl-util
include fsl/dynmem
include fsl/complex
include fsl/quadratic
include fsl/polrat
1 cells 4 = [IF]
include fsl/extras/numerov_x86
[ELSE]
include fsl/extras/numerov
[THEN]
include fsl/extras/find
include fsl/extras/read_xyfile
include fsl/extras/array-utils0
include fsl/extras/array-utils1
include qm/potential
include qm/schr1d
include qm/hf

Also qm.schr1d
Also qm.hf

: print-energy ( E -- )  11 7 f.rd  ;

0 value Z
1e 137.035999139e f/ fconstant alpha  \ fine-structure constant
1e    fconstant  m_e   \ mass of electron in atomic units
m_e   fconstant  mu    \ no reduced mass correction
1e-12 fconstant  R_min

\ Rmax is a function of Z. For a uniform mesh size
\ of 65,536, an approximate relationship to achieve
\ integration accuracy of 7 digits over Z = 2 to 10 is
\
\   Rmax(Z) = 12 - Z

: Rmax ( Z -- r )  12 - negate s>f ;

variable Nmesh

FLOAT DARRAY V1{   \ Hartree potential energy from 1-electron
FLOAT DARRAY P1{   \ radial function for 1s (n=1, l=0) subshell

: alloc-aux-arrays ( -- )
   & V1{ Nmesh @ }malloc
   & P1{ Nmesh @ }malloc
   malloc-fail? ABORT" setup-mesh: Can't allocate mem!"
;

: free-aux-arrays ( -- )
   & P1{ }free
   & V1{ }free
;

\ true to verbose?

\ Given an initial guess for the energy, an initial energy
\ increment, and the central potential from all of the other 
\ electrons, add the nuclear potential for nuclear charge Z,
\ and solve for the 1-electron solution, returning the energy,
\ energy uncertainty, and error code (from schr1d's SOLVE)
: solve_1el ( E_t dE_t 'V -- E dE error )
    V_mesh{ Nmesh @ }fcopy
    r_mesh{ V_mesh{ Z Nmesh @ add-V_nuc
    update-Vlims
    solve
;

\ Find the one-electron ground-state energy
: one-electron-gs ( -- E dE error )
    Nmesh @ V_mesh{ }fzero
    -100e 1e V_mesh{ solve_1el
;

fvariable dE    \ initial energy increment for schr1d's SOLVE
fvariable E1    \ energy of electron 1 in nuclear + 2nd el field

\ Perform one iteration of the self-consistent field
\ calculation, for two "s" electrons. This can be done
\ using iteration with one electron, since the two
\ equivalent "s" electrons must converge to have the 
\ same energy and radial function.
: scf-iter-1s2 ( -- error )
    \ Check normalization of radial function P1(r)
    \ r_mesh{ P1{ Nmesh @ radial-integral  ." I(P1^2) = " f. cr

    \ Compute potential energy function of the electron field
    r_mesh{ P1{ Nmesh @  V_el  V1{ Nmesh @ }fcopy  free-V_el
    E1 f@ dE f@ V1{  solve_1el
    ?dup IF >r f2drop r> EXIT THEN  \ Error occurred in SOLVE
    fdrop E1 f!
    P1{ }get-P
    0  \ no error
;


\ Maximum number of iterations for scf convergence
20 value MAX_SCF_ITER
5e-9 fconstant Etol    \ convergence tolerance for scf 
variable n_iter
fvariable E1_last

: scf ( -- error )
    0 n_iter !
    E1 f@ E1_last f!
    \ E1 f@ f. cr
    BEGIN
       scf-iter-1s2
       1 n_iter +!
       ?dup IF EXIT THEN
       \ ." Iter " n_iter @ 2 .r ." : " 2 spaces
       \ ." E1|E2 = " E1 f@ print-energy  cr
       n_iter @ MAX_SCF_ITER > IF 10 EXIT THEN  
       E1 f@ E1_last f@ f- fabs
       fdup ( 4e) 10e f/ dE f! 
       Etol f<
       E1 f@ E1_last f!
       \ dE f@ f. cr
    UNTIL
    0
;

fvariable  E_1el   \ energy of the one-electron atom
fvariable  E_cou   \ energy of electron-electron Coulomb interaction
fvariable  E_tbe   \ total binding energy of atom
fvariable  E_ion   \ energy of ionization (for one electron)

\ The expressions for Coulomb energy and binding energy
\ are specific to the 1s(2) electron configuration --
\ they are not generally applicable.

: Coulomb-energy ( -- )
    r_mesh{ P1{ V1{ Nmesh @ <V>   E_cou f! 
    \ r_mesh{ P1{ P1{ Nmesh @ F^0  E_cou f! ( alternate slower method )
;

: binding-energy ( -- )
    E1 f@ 2e f* E_cou f@ f- fnegate E_tbe f!  \ eq. 8.12 [1].
;

: ionization-energy ( -- )  E_1el f@ E_tbe f@ f+ E_ion f! ;

\ Matrix row is indexed by Z, and the columns contain
\ E_1el, E1, E_cou, E_tbe, and E_ion
10 4 FLOAT matrix E_1s2{{ 

: store-energies ( Z -- )
    >r
    E_1el f@ E1 f@ E_cou f@ E_tbe f@ E_ion f@ 5
    r> E_1s2{{ }}frow-put
;

: print-energies ( E_tbe E_ion -- )
    fswap print-energy 2 spaces print-energy
;

\ Compute and display binding and ionization energies of 
\ 1s(2) electron configuration in atom/ions for a fixed 
\ range of Z.

s" He Li(1+) Be(2+) B(3+) C(4+) N(5+) O(6+) F(7+) Ne(8+)" 2constant $Atoms
2variable $A
$Atoms $A 2!

: next-atom-name ( -- a u )
    $A cell+ a@ $A @ parse_token 2swap $A 2!
    s"       " 2dup 2>r 
    2dup blank 
    drop swap cmove 2r> ;

: iso_1s2 ( -- )
    mu set-particle-mass

    11 2 DO        \ Z: 2 --> 10
       I to Z
       R_min  Z Rmax 65536 setup-uniform-rmesh Nmesh !
       & V_mesh{ Nmesh @ }malloc
       alloc-aux-arrays \ V1{ P1{
       one-electron-gs
       ?dup IF 
	 drop f2drop 
         ." Cannot find 1-electron ground-state"
         LEAVE
       THEN
       fdrop E_1el f!
       \ Initialize the first electron radial function to the 
       \ one-electron radial function, and set its binding energy.
       P1{ }get-P 
       E_1el f@ E1 f!
       0.2e dE f!
       scf
       ?dup IF ." SCF Error " . LEAVE THEN
       Coulomb-energy
       binding-energy
       ionization-energy
       \ I store-energies
       Z 4 .R 3 spaces
       next-atom-name type 2 spaces 
       E_tbe f@ E_ion f@ print-energies 2 spaces
       r_mesh{ P1{ Nmesh @ <r>     7 4 f.rd 2 spaces
       r_mesh{ P1{ Nmesh @ <vel^2> fsqrt alpha f* 7 4 f.rd cr
       end-solve
       free-aux-arrays
   LOOP
;

cr .( All energies and distances are in atomic units. )
cr .( Isoelectronic sequence for electron configuration 1s2: ) cr
cr .(    Z   Atom         B.E.         I.E.       <r>      v/c)
cr .( ----------------------------------------------------------)
cr

iso_1s2


