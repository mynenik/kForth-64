\ h2XJ0.4th
\
\ Find the vibrational level energies, E(v, J=0), and dissociation 
\ energy, D0, of the H_2 molecule in its ground electronic state 
\ (X 1Sigma_g^+), by solving the radial Schroedinger equation with
\ theoretical inter-atomic potential(s) [1].
\
\ Notes:
\
\ 1. The potential energy curve given in [1] is a high-precision
\    potential in the clamped nuclei approximation (Born-Oppenheimer
\    approximation) or B-O potential. Corrections due to nuclear
\    motion, relativistic effects, and QED effects have been computed
\    [2--4,7] and may be added to the potential from [1] to improve the
\    quantitative comparison to experimental values [5].
\
\ 2. The computed vibrational energy levels of H_2 match to better 
\    than 5.5 cm^-1 of the experimental values. With respect to the
\    B-O calculations described in Fig. 1 of ref. [9], the value of
\    D0 matches to within 1e-4 cm^-1 of other high-precision
\    calculations, and the difference in energy between the
\    v = 0 and v = 1 levels, Delta_01, matches to within
\    4e-4 cm^-1.
\
\ References:
\
\ 1. K. Pachucki, "Born-Oppenheimer potential for H_2," 
\    Phys. Rev. A 82, 032509 (2010).
\
\ 2. W. Kolos and L. Wolniewicz, "Accurate Adiabatic Treatment of
\    the Ground State of the Hydrogen Molecule," J. Chem. Phys.
\    41, 3663 (1964).
\
\ 3. L. Wolniewicz, "Relativistic energies of the ground state of
\    the hydrogen molecule," J. Chem. Phys. 99, 1851 (1993).
\
\ 4. L. Wolniewicz, "Nonadiabatic energies of the ground state of
\    the hydrogen molecule," J. Chem. Phys. 103, 1792 (1995).
\
\ 5. I. Dabrowski, Canadian J. Phys. 62, 1639 (1984).
\
\ 6. R. J. LeRoy, 2007, "Level 8.0, A Computer Program for 
\    Solving the Radial Schroedinger Equation for Bound and 
\    Quasibound Levels", University of Waterloo, report CP-663. 
\    Software and manual available from the web at 
\    http://sienide2.uwaterloo.ca/~rleroy/level/
\
\ 7. M. Puchalski, J. Komasa, and K. Pachucki, "Relativistic
\    corrections for the ground electronic state of molecular
\    hydrogen," Phys. Rev. A 95, 052506 (2017).
\
\ 8. S. Sturm, et al., Nature 506, 467 (2014).
\
\ 9. M. L. Niu, et al., J. Mol. Spectr. 300, 44--54 (2014).
\
\ Revisions:
\   2010-10-19 km  first version; misses the v=14 level;
\                  fix typos in comments.
\   2010-10-21 km  revise notes.
\   2014-12-12 km  uses modular versions of schr1d and potential.
\   2015-01-31 km  removed note 3; the program finds all bound
\                  vibrational levels, including v=14, with the
\                  most recent versions of schr1d. Increased the
\                  output precision of PRINT-ENERGY.
\   2017-07-07  km additional references and revised comments; 
\                  added relativistic reference potential energy
\                  in comment for use with potential curve from
\                  ref. 7; updated m_p from ref. 8.
\   2017-07-25  km fp number formatting and output words removed
\                  to strings.4th, and renamed.
\   2020-09-28  km updated conversion factor from Hartrees to cm^-1
\
\ Copyright (c) 2010--2020 Krishna Myneni, krishna.myneni@ccreweb.org
\
\ This code may be used for any purpose as long as the copyright
\ notice above is preserved.
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

Also qm.potential
Also qm.schr1d

219474.6313705e fconstant  cm^-1/Eh  \ Hartree to wavenumber conversion
0.5291772083e   fconstant  A/a0  \ Bohr radius to Angstroms conversion
1e              fconstant  m_e   \ mass of electron in atomic units
\ 1836.15267247e  fconstant  m_p \ mass of proton in a.u. (obsolete)
1836.15267377e  fconstant  m_p   \ updated from ref. 8.


\ Read the theoretical Born-Oppenheimer potential [1], V(R), for 
\ the ground electronic state of H2 [H(1s) + H(1s) in the symmetric 
\ configuration]
variable np
s" H2-potnl-pac2010.dat" read-potnl np !
\ s" H2-potnl-pkp2017.dat" read-potnl np !
\ s" H2-potnl-pkp2017_rel.dat" read-potnl np !

\ Use minimum 1024 point interpolated potential, with 9th order
\ polynomial interpolation
variable Nmesh
8192 9 setup-mesh Nmesh !

\ Set the effective mass of the particle in the potential well
\ m_p 2e F/ set-particle-mass  ( reduced mass in the B-O approx. )
m_p m_e F+ 2e F/  set-particle-mass  \ reduced mass of H_2

-1e    fconstant V_inf   \ potential energy in Hartrees at R=infinity
                         \ (this is the energy of two separated H atoms)
\ -1.00001331283862e+00 fconstant V_inf  ( relativistic version )

\ Convert energy in Hartrees to cm^-1 and print with uncertainty value
: print-energy ( E dE -- )
    cm^-1/Eh F* fswap V_inf F- cm^-1/Eh F*
    12 4 f.rd ."   +/- " 8 6 f.rd ;

32 constant MAX-LEVELS
MAX-LEVELS FLOAT ARRAY Ev{
0 value v
0.001e fconstant start_dE  \ initial energy increment for solve
fvariable offset_E  \ offset for next trial energy
0e offset_E f!

fvariable Vmin
get-Vlims fdrop Vmin f!

: next-trial-E ( F: E -- E' ) offset_E F@ F+ ;

: find-levels ( -- ) 
    cr ." Vibrational Level Energies in cm^-1 relative to"
    cr ." V(inf) = " V_inf cm^-1/Eh F* 14 4 f.rd ."  cm^-1" 
    MAX-LEVELS Ev{ }fzero

    \ Find the energy of the lowest level (v=0)
    0 to v
\ true set-verbose
    Vmin F@ start_dE solve ABORT" find-levels: Unable to find the lowest level!" 
    f2dup cr v 4 .R 2 spaces print-energy fdrop
    fdup Ev{ v } F!
    fdup Vmin F@ F- offset_E F! 
    BEGIN
      next-trial-E start_dE solve
      0= IF   \ F: -- E' dE'
	fover Ev{ v } F@ start_dE F~ IF  \ We found the previous level, increase offset
           cr ." Previous level found."
	   offset_E F@ 1.2e F* offset_E F! fdrop
	ELSE 
          v 1+ to v  
          f2dup cr v 4 .R 2 spaces print-energy fdrop
          \ The following energy increment works well to determine
          \   the trial value for the next eigenvalue
          fdup Ev{ v } F! 
          fdup Ev{ v 1- } F@ F- 2e F/ offset_E F!
        THEN
      ELSE
        fdrop
      THEN
      \ 5 spaces offset_E f@ f. 
      fdup V_inf F>
    UNTIL
    fdrop
    \ Dissociation energy, D0
    V_inf Ev{ 0 } F@ F- cm^-1/Eh F* 
    cr ." D0 (cm^-1) = " 14 5 f.rd 
    Ev{ 1 } f@ Ev{ 0 } f@ f- cm^-1/Eh f*
    cr ." Delta_01 (cm^-1) = " 14 5 f.rd
    end-solve
;
    
\ find-levels





