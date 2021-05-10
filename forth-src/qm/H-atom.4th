\ H-atom.4th
\
\ Find the non-relativistic radial functions and energies
\ of the 1s--4s and the 2p--4p states of the hydrogen atom,
\ by direct numerical integration of the Schroedinger eqn.
\
\ Compute the first-order relativistic corrections using
\ the non-relativistic energies and wavefunctions. Spin-orbit
\ coupling, which results in "fine structure" of the energy
\ levels, is not computed by this program, nor are the Lamb
\ shifts.
\
\ Copyright (c) 2014--2017 Krishna Myneni, http://ccreweb.org
\
\ This code may be used for any purpose as long as the source
\ is attributed.
\
\ Notes:
\   1. The numerically computed energies are accurate, with respect
\      to the theoretical model, to 8 or 9 digits, for the
\      non-relativistic and relativistic energies.
\
\   2. The reduced mass of the 1-electron atom is used by default,
\      since the hydrogen atom is a two-body problem. When comparing
\      the results of this program with textbook energies, radial
\      functions, or expectation values <r>, beware that theoretical
\      results sometimes assume an idealized atom with an infinite
\      nuclear mass. The regular electron mass, 1 in atomic units,
\      may be used instead of the reduced mass, for comparing to the 
\      idealized atom results.
\
\   3. Higher n and l states may also be computed. You will have to
\      adjust R_max, and possibly the size of the mesh. Also, the initial
\      trial energy and energy increment passed to SOLVE must be chosen
\      carefully, or the energy level may be missed. I have not tried
\      to compute l=2 or higher states.
\
\   4. Comparison of the computed energy levels may be made to the
\      accepted energy levels provided by the NIST Atomic Spectral
\      Database (ref. 5). Adding the measured Lamb shift from
\      ref. 4 (0.272618 cm^-1)to the computed relativistic ground state
\      (1s) energy gives numerical agreement to one part in 10^8
\      between the calculated and the accepted values.
\
\ Revisions:
\   2014-12-22  km  first version.
\   2014-12-24  km  fix output formatting.
\   2014-12-27  km  optional code added to write analytic solutions
\                     to file for comparison with numerical solutions.
\   2015-02-11  km  use numerov_x86.4th for faster performance.
\   2017-06-22  km  set R_min to 0.0e0 and R_max to 80.0e0;
\                   and use mesh size of 65536; program
\                   computes expectation values <1/r>, <1/r^2>,
\                   and <1/r^3>.
\   2017-06-26  km  added first-order relativistic corrections for
\                   kinetic energy and Darwin terms.
\   2017-06-27  km  revised calc. of R(0) = limit( r->0 ) P_nl(r)/r
\   2017-06-29  km  use Simpson's integration for computing
\                   expectation values; vastly increase grid size
\                   to reach accuracy at the 1e-3 cm^-1 level.
\   2017-07-23  km  fp number formatting and output words removed
\                   (now in strings.4th)
\
\ References:
\
\   1. R. D. Cowan, The Theory of Atomic Structure and Spectra,
\      Univ. of California Press, Berkeley 1981.
\
\   2. C. E. Burkhardt and J. J. Leventhal, Topics in Atomic Physics,
\      Springer, New York 2006.
\
\   3. J. D. Garcia and J. E. Mack, Energy Level and Line Tables for
\      One-Electron Atomic Spectra, Journal of the Optical Society of
\      America, vol. 55, pp. 654--671 (1965).
\
\   4. M. Weitz, A. Huber, F. Schmidt-Kaler, D. Leibfried, W. Vassen,
\      C. Zimmermann, K. Pachucki, and T. W. Hansch, Precision
\      measurement of the 1S ground-state Lamb shift in atomic
\      hydrogen and deuterium by frequency comparison, Physical
\      Review A, vol. 52, pp. 2664--2681 (1995).
\
\   5. NIST Atomic Spectral Database:
\      http://physics.nist.gov/PhysRefData/ASD/levels_form.html
\      

include ans-words
include modules
1 cells 4 = [IF]
include syscalls
include mc
include asm
include fpu-x86
[THEN]
include strings
include fsl/fsl-util
include fsl/dynmem
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

Also qm.schr1d

: print-energy ( E -- )  12 9 f.rd ;

1 constant Z
219474.6313705e fconstant  cm^-1/Eh  \ Hartree to cm^-1 conversion
1e              fconstant  m_e   \ mass of electron in atomic units
1836.15267247e  fconstant  m_p   \ mass of proton in atomic units

1e 137.035999139e f/ fconstant alpha  \ fine structure constant

false [IF]
\ No reduced mass, for comparison to other progs such as hf.
m_e fconstant mu
[ELSE]
\ Reduced mass for one electron and H nucleus
m_e m_p f*  m_e m_p f+ f/ fconstant mu
[THEN]
mu set-particle-mass

 0e  fconstant R_min
( 120e) 80e   fconstant R_max

variable Nmesh
R_min R_max  65536 8 * setup-uniform-rmesh Nmesh !
& V_mesh{ Nmesh @ }malloc

4 constant n_max

FLOAT DARRAY V_nuc{
FLOAT DARRAY  P{
FLOAT DMATRIX P_ns{{
FLOAT DMATRIX P_np{{

: setup-auxiliary-arrays ( -- )
   & V_nuc{ Nmesh @ }malloc
   & P{ Nmesh @ }malloc
   & P_ns{{ Nmesh @ n_max }}malloc
   & P_np{{ Nmesh @ n_max 1- }}malloc
   malloc-fail? ABORT" setup-mesh: Can't allocate mem!"
;

setup-auxiliary-arrays

\ Write a radial function matrix to a file
0 ptr M{{
0 value M_ncols

: write-rfn ( 'M ncols caddr u -- )
    s" >file " 2swap strcat evaluate
    to M_ncols
    to M{{
    Nmesh @ 0 DO
      r_mesh{ I } f@ fs. 2 spaces
      M_ncols 0 DO
        M{{ J I }} f@ fs. 2 spaces
      LOOP
      cr
    LOOP
    console
;

\ Write solutions for evaluation
: write-H-soln ( -- )      
    P_ns{{ n_max     s" H-atom-s.dat" write-rfn
    P_np{{ n_max 1-  s" H-atom-p.dat" write-rfn
;

\ Compute the one-electron effective potential, for an electron with
\ angular momentum, l.
: setup-V ( l -- )
    >r

    \ Compute the nuclear potential, -Z/r
    Z s>f fnegate
    Nmesh @ 1 DO  
      fdup 
      r_mesh{ I } f@
      f/ V_nuc{ I } f!
    LOOP
    fdrop

    \ Add to it the centrifugal potential, l*(l+1)/(2*mu*r^2)
    r> dup 1+ * s>f 2e f/ mu f/
    Nmesh @ 1 DO  
      fdup
      r_mesh{ I } f@ fsquare f/
      V_nuc{ I } f@ f+ V_mesh{ I } f!
    LOOP
    fdrop

    V_mesh{ 1 } f@  V_mesh{ 0 } f!  \ set finite value at r=0
    update-Vlims         
;


\ Compute the expectation value of r (average value) for
\ the current radial function, P(r); cf. eq. 3.24 [1].
\ Use Simpson's integration.
fvariable h
fvariable flast

: <r> ( -- <r> )
    r_mesh{ 1 } f@ r_mesh{ 0 } f@ f- h f!
    0e
    Nmesh @ 1- 1 DO
      P{ I } f@ fsquare r_mesh{ I } f@ f*
      I 2 mod IF 4e ELSE 2e THEN f*
      f+
    LOOP
    P{ Nmesh @ 1- } f@ fsquare r_mesh{ Nmesh @ 1- } f@ f* f+
    h f@ f* 3e f/ 
;

: <1/r> ( -- <1/r> )
    r_mesh{ 1 } f@ r_mesh{ 0 } f@ f- h f!
    0e
    Nmesh @ 1- 1 DO
      P{ I } f@ fsquare r_mesh{ I } f@ f/ 
      I 2 mod IF 4e ELSE 2e THEN f*
      f+
    LOOP
    P{ Nmesh @ 1- } f@ fsquare r_mesh{ Nmesh @ 1- } f@ f/ f+
    h f@ f* 3e f/
;

: <r^-2> ( -- <r^-2> )
    r_mesh{ 1 } f@ r_mesh{ 0 } f@ f- h f!
    0e
    Nmesh @ 1- 1 DO
      P{ I } f@ fsquare r_mesh{ I } f@ fsquare f/ 
      I 2 mod IF 4e ELSE 2e THEN f*
      f+
    LOOP
    P{ Nmesh @ 1- } f@ fsquare r_mesh{ Nmesh @ 1- } f@ fsquare f/ f+
    h f@ f* 3e f/
;

\ Compute the expectation value of 1/r^3 for the current P(r);
\ this is needed for calculation of fine-structure corrections.
: <r^-3> ( -- <r^-3> )
    r_mesh{ 1 } f@ r_mesh{ 0 } f@ f- h f!
    P{ 0 } f@ fsquare 
    r_mesh{ 0 } f@
    fdup f0= IF fdrop r_mesh{ 1 } f@ 10e f/ THEN
    fdup fdup f* f* f/
    fdup flast f!
    2e f/
    Nmesh @ 1 DO
      flast f@ 
      P{ I } f@ fsquare r_mesh{ I } f@ fdup fdup f* f* f/
      fdup flast f!
      f+ 2e f/ h f@ f*
      f+
    LOOP
;


: hsep ." |" ;
: sep  ." -------------------" ;
: sep2 ." ------------" ;
: tline sep  hsep  sep2 hsep sep2 hsep sep2 hsep sep2 ;

0.04e fconstant dE
5 FLOAT array Es{      \ energies of s-states
5 FLOAT array Ep{      \ energies of p-states
5 FLOAT array Es_tot{  \ relativistic energies of s-states
5 FLOAT array Ep_tot{  \ relativistic energies of p-states (no f.s.)
5 FLOAT array r^-1_s{  \ expectation values of r^-1 for s-states
5 FLOAT array r^-1_p{  \   "                     "  for p-states
5 FLOAT array r^-2_s{  \ expectation values of r^-2 for s-states
5 FLOAT array r^-2_p{  \   "                     "  for p-states
5 FLOAT array dEs{
5 FLOAT array dEp{

0 ptr E{
0 ptr E_tot{
0 ptr dE{
0 ptr r^-1{
0 ptr r^-2{
0 ptr P_nl{{
0 value l
0 value id

: select-arrays ( l -- )
    CASE
      0 OF  Es_tot{ Es{ dEs{ r^-1_s{ r^-2_s{ P_ns{{ [char] s  ENDOF
      1 OF  Ep_tot{ Ep{ dEp{ r^-1_p{ r^-2_p{ P_np{{ [char] p  ENDOF
    ENDCASE
    to id to P_nl{{ to r^-2{ to r^-1{ to dE{ to E{ to E_tot{
;

\ First-order relativistic correction for n, l states, using
\ quantities obtained from the numerical solution of the
\ non-relativistic energies and wavefunctions.

\ Obtain limit r->0 of P_nl(r)/r using quadratic fit near r=0
: R_nl(0) ( n l -- R_nl[0] )
   dup IF 2drop 0e
   ELSE
     select-arrays
     1- >r
     P_nl{{ 1 r@ }} f@ 18e f*
     P_nl{{ 2 r@ }} f@ -9e f* f+
     P_nl{{ 3 r> }} f@  2e f* f+  
     r_mesh{ 1 } f@ 6e f* f/
   THEN
;

\ First-order relativistic correction to the kinetic energy;
\ see ref. 2, sec. 7.5, eqn. 7.24 (converted to atomic units).
: E_T ( n l -- E_T )
   select-arrays
   1- >r
   E{ r@ } f@ fsquare
   E{ r@ } f@ 2e f* r^-1{ r@ } f@ f* f+
   r^-2{ r@ } f@ f+
   alpha fsquare f* 2e f/ fnegate
   r> drop ;

\ First-order Darwin correction ( only applies to l=0 states )
\ see ref. 2, eqn. 7.39 (converted to atomic units).
: E_D ( n l -- E_D )
   R_nl(0) fsquare  alpha fsquare f* 8e f/ ;

\ First-order relativistic correction (without spin-orbit coupling)
: E_rel ( n l -- E_rel )
   2dup 2>r  E_T  2r> E_D f+ ;

\ Given the n^th bound energy level, compute a trial energy for
\ searching for the next level.
: offset-E ( E n -- E' )  >r fdup 2e r> 1+ s>f f** 4e fmin f/ f- ;
: offset-dE ( dE n -- dE' ) >r 4e r> s>f f** f/ ;

\ Find the bound energy levels, and corresponding radial functions
\ for a given orbital angular momentum.
: find-levels ( l -- )
    to l 
    l select-arrays
    l setup-V    \ effective potential for electron
    -0.5e dE        
    n_max l DO
      solve  ABORT" Unable to solve for radial function."
      dE{ I } f! E{ I } f!
      2 spaces I 1+ 1 .R id EMIT 
      2 spaces E{ I } f@ print-energy 
      P{ }get-P 
      <r>
      space hsep 11 7 f.rd
      <1/r>  fdup r^-1{ I } f!
      space hsep 11 7 f.rd
      <r^-2> fdup r^-2{ I } f!
      space hsep 11 7 f.rd
      <r^-3>
      space hsep 11 7 f.rd
      cr
      Nmesh @ 0 DO  P{ I } f@ P_nl{{ I J }} f!  LOOP
      E{ I } f@  I offset-E   dE I offset-dE
    LOOP
    f2drop
;

\ Show relativistic corrections
: show-rel-corr ( l -- )
    to l
    l select-arrays
    n_max l DO
      2 spaces I 1+ 1 .R id EMIT
      2 spaces E{ I } f@ print-energy
      space
      PRECISION 
      4 SET-PRECISION
      I 1+ l E_T 
      hsep space fs.
      I 1+ l E_D 
      hsep space fs. space
      hsep space I 1+ l E_rel fdup 2>r fs.
      SET-PRECISION 2r>
      hsep space E{ I } f@ f+ fdup E_tot{ I } f! print-energy
      cr
    LOOP  
;

ms@
cr .( Mesh size = ) Nmesh ?
cr .( Energies and distances are in atomic units. )
cr
cr .(   nl       E             <r>        <1/r>        <1/r^2>      <1/r^3> )
cr tline
cr
0 find-levels  \ Find the l = 0 bound states.
tline cr
1 find-levels  \ Find the l = 1 bound states.
tline cr

cr .( First-order Relativistic Corrections: )
cr
cr .(   nl       E            E_T           E_D         E_rel       E_tot )
cr tline
cr
0 show-rel-corr
tline cr
1 show-rel-corr
tline cr


false [IF]   \ Diagnostics

\ Write the numerical Pnl solutions to files
write-H-soln

\ Compute the analytic 1s, 2s, and 2p radial functions for H, 
\ over the same mesh, for diagnostics.
2e fsqrt fconstant sqrt_2
6e fsqrt fconstant sqrt_6

: P1s ( r -- P[r] ) fdup fnegate fexp f* 2e f* ;
: P2s ( r -- P[r] ) 
     fdup 2e f/ fnegate fdup 
     1e f+ fswap fexp f* fswap f*
     sqrt_2 f/ ;
: P2p ( r -- P[r] ) fdup fdup -2e f/ fexp f* f* 2e f/ sqrt_6 f/ ;
     
Nmesh @ 3 FLOAT MATRIX P_an{{

: analytic_rfn ( -- )
    Nmesh @ 0 DO
      r_mesh{ I } f@  
      fdup  P1s  P_an{{ I 0 }} f!
      fdup  P2s  P_an{{ I 1 }} f!
            P2p  P_an{{ I 2 }} f!
    LOOP      
;
analytic_rfn

\ Write the analytic solutions.
P_an{{ 3     s" H-atom-analytic.dat" write-rfn

[THEN]

end-solve
& P_np{{ }}free
& P_ns{{ }}free
& P{ }free
& V_nuc{ }free

ms@ swap -
cr .( Elapsed: ) . .(  ms) cr

