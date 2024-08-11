\ he-scf.4th
\
\ Use the Hartree-Fock method to perform a self-consistent field
\ calculation for the ground state orbitals of the He atom, and,
\ from these, find the ground state energy and the one electron
\ ionization energy.
\
\ Notes:
\
\ 1. Non-relativistic Hartree-Fock calculation of the He ground
\    state energy should give -2.861680 in atomic units (Eh) [1,2],
\    without reduced mass correction.
\
\ 2. Experimental values of relevant parameters [3]:
\
\        He I ionization energy    (Eh) = 0.90357
\        He I total binding energy (Eh) = 2.90338
\        He II binding energy      (Eh) = 1.99982
\
\ 3. Correlation and relativistic corrections are not computed.
\    The correlation between the two 1s electrons is the
\    largest source of discrepancy between the HF calculation
\    and the experimental value.
\
\ Revisions:
\   2012-10-03 km  first version
\   2014-12-16 km  fixed reduced masses and method of computing
\                  Coulomb repulsion energy.
\   2014-12-19 km  verified that without reduced mass correction,
\                  we obtain same result as other published HF
\                  results, e.g. ref. [1], to about 5 significant digits.
\   2014-12-20 km  removed unneeded dependency on module, pnl.4th;
\                  update starting energy on each scf cycle.
\   2015-11-15 km  revised comments, added ref. to ATSP.
\   2017-07-05 km  changed Rmin to 1e-12; increased mesh size to
\                  65536. These changes give 7 significant digits
\                  for the binding energy (in the HF approximation).
\   2017-07-18 km  updated Rmax for improved accuracy; factored
\                  code for consistency with iso_1s2_hf.4th.
\   2017-07-20 km  removed redundant calculation for 2nd "s" electron;
\                  adjust dE on each SCF iteration for faster
\                  convergence.
\   2017-07-25 km  fp number formatting and output words moved
\                  to strings.4th and renamed.
\   2024-08-11 km  fix to run under 64-bit kForth also.
\
\ Copyright (c) 2012--2024 Krishna Myneni, http://ccreweb.org
\
\ This code may be used for any purpose as long as the copyright
\ notice above is preserved.
\
\ References:
\
\   1. R. D. Cowan, The Theory of Atomic Structure and Spectra,
\      Univ. of California Press, Berkeley 1981; see p. 221, Table 8-2.
\
\   2. C. Froese-Fischer, et. al., Program HF.f from the Atomic
\      Structure Package (ATSP), 
\      http://nlte.nist.gov/cgi-bin/MCHF/download.pl?d=ATSP
\
\   3. NIST Atomic Spectral Database, 
\      http://www.nist.gov/pml/data/asd.cfm

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

: print-energy ( E -- ) 12 9 f.rd  ;

2 constant Z
1e              fconstant  m_e   \ mass of electron in atomic units
7294.2995365e   fconstant  m_alpha \ mass of alpha particle (He nucleus)

\ Reduced mass for one electron and He nucleus
 m_e fconstant mu1 ( no reduced mass correction )
\ m_e m_alpha f*  m_e m_alpha f+ f/ fconstant mu1

\ Reduced mass for electron in He+ potential
 m_e fconstant mu2  ( no reduced mass correction )
\ m_alpha m_e f+  m_e f*  m_alpha m_e 2e f* f+ f/ fconstant mu2

1e-12 fconstant R_min
9e    fconstant R_max

variable Nmesh
R_min R_max 65536 setup-uniform-rmesh Nmesh !

FLOAT DARRAY V1{
FLOAT DARRAY P1{

: alloc-aux-arrays ( -- )
   & V1{ Nmesh @ }malloc
   & P1{ Nmesh @ }malloc
   malloc-fail? ABORT" setup-mesh: Can't allocate mem!"
;

: free-aux-arrays ( -- )
   & P1{ }free
   & V1{ }free
;

\ Write solutions for evaluation
: write-he-soln ( -- )      
    s" >file he-scf.dat" evaluate
    Nmesh @ 0 DO
      r_mesh{ I } f@ f. 2 spaces
      V1{ I }     f@ f. 2 spaces
      P1{ I }     f@ f. 2 spaces cr
    LOOP
    console
;

fvariable  dE
fvariable  E1      \ energy of electron 1 in nuclear + 2nd el field
fvariable  E_1el   \ energy of the one-electron atom
fvariable  E_ion   \ energy of ionization (for one electron)
fvariable  E_cou   \ energy of electron-electron Coulomb interaction
fvariable  E_tbe   \ total binding energy of atom

\ true to verbose?

\ Given an initial guess for the energy, an initial energy
\ increment, and the central potential from all of the other
\ electrons, add the nuclear potential for nuclear charge Z,
\ and solve for the 1-electron solution, returning the energy,
\ energy uncertainty, and the error code returned by SOLVE.
: solve_1el ( E_t dE_t 'V -- E dE error )
    V_mesh{ Nmesh @ }fcopy
    r_mesh{ V_mesh{ Z Nmesh @ add-V_nuc
    update-Vlims
    solve
;

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
       ." Iter " n_iter @ 2 .r ." : " 2 spaces
       ." E1|E2 = " E1 f@ print-energy  cr
       n_iter @ MAX_SCF_ITER > IF 10 EXIT THEN  
       E1 f@ E1_last f@ f- fabs
       fdup ( 4e) 10e f/ dE f! 
       Etol f< 
       key? IF  key 27 = ELSE 0 THEN or
       E1 f@ E1_last f!
       \ dE f@ f. cr
    UNTIL
    0
;

\ Find the ground state energy and the ionization energy
\   of the helium atom.
: he-scf ( n -- )
    & V_mesh{ Nmesh @ }malloc
    alloc-aux-arrays
    \ Find the one-electron energy in the nuclear potential
    mu1 set-particle-mass
    Nmesh @ V_mesh{ }fzero
    0.1e dE f!
    -2e dE f@ V_mesh{ solve_1el 
    ABORT" Unable to solve for radial function."
    fdrop E_1el f!

    cr ." He+ ion ground state energy = " E_1el f@ print-energy cr

    cr ." Atom: He I"
    cr ." Electron configuration: 1s(2)"
    cr ." Term: 1S" cr
    cr ." Starting SCF calculation ..." cr

    \ Initialize the first electron radial function to the 
    \ one-electron radial function, and set its binding energy.
    P1{ }get-P 
    E_1el f@ E1 f!
    mu2 set-particle-mass

    scf ?dup IF 
      ." SCF Error " . cr
    ELSE
      \ Compute the Coulomb repulsion energy,
      \ the total binding energy, and ionization energy.
      r_mesh{ P1{ V1{ Nmesh @ <V>    E_cou f!
      \ r_mesh{ P1{ P2{ Nmesh @ F^0  E_cou f!
      E1 f@ fdup f+ E_cou f@ f- fnegate E_tbe f!
      E_1el f@ E_tbe f@ f+ E_ion f!
      ."   Coulomb Repulsion Energy = "  E_cou f@ print-energy cr
      ."   Total Binding Energy     = "  E_tbe f@ print-energy cr
      ."   Ionization Energy        = "  E_ion f@ print-energy cr
    THEN
  
\ Uncomment the line below, if you want to write the radial
\ function solutions to a file:
\
\    write-he-soln

    end-solve
    free-aux-arrays
;

cr .( All energies are in atomic units. ) cr
ms@ 
he-scf
ms@ swap - 
cr .( Elapsed: ) . .(  ms ) cr



