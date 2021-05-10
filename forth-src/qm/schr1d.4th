\ schr1d.4th
\
\ Solve the eigenvalue problem for the radial Schroedinger 
\ equation, obtaining both a bound state eigenvalue and the 
\ corresponding eigenfunction, given the potential energy
\ function and an initial trial energy.
\
\ The one-dimensional radial Schroedinger equation may be
\ cast in the form,
\
\   P''(r) = 2*mu*(V(r) - E)*P(r)
\
\ The Numerov integration method can be used to solve this
\ equation for the unknowns, E and P(r) [1--4]. The discrete 
\ solutions for the eigenvalues, E, and the corresponding
\ radial eigenfunctions, P(r), may be found for a given 
\ potential energy function, V(r).
\
\ Q(r) is defined to be 2*mu*(V(r) - E), so that the equation 
\ to be solved, for both E and P(r), is,
\
\               P''(r) = Q(r)*P(r)
\
\ Units for the above equations are atomic units.
\
\ References:
\
\ 1. Anders Blom, 2002, "Computing algorithms for solving the 
\    Schroedinger and Poisson equations", available on the web at
\    http://www.teorfys.lu.se/personal/Anders.Blom/useful/scr.pdf
\
\ 2. Tao Pang, 1997, "An Introduction to Computational Physics",
\    Cambridge University Press, see program code3d.f.
\    Also on the web at 
\    http://www.physics.unlv.edu/~pang/comp/code3d.f
\
\ 3. R. J. LeRoy, 2007, "Level 8.0, A Computer Program for 
\    Solving the Radial Schroedinger Equation for Bound and 
\    Quasibound Levels", University of Waterloo, report CP-663. 
\    Software and manual available from the web at 
\    http://scienide2.uwaterloo.ca/~rleroy/level/
\    
\ 4. J. W. Cooley, 1961, "An Improved Eigenvalue Corrector Formula
\    for Solving the Schroedinger Equation for Central Fields",
\    Mathematics of Computation, 15, pp. 363--374.
\
\ Requires:
\
\   fsl/fsl-util
\   fsl/dynmem
\   fsl/extras/numerov
\   fsl/extras/array-utils0
\   fsl/extras/array-utils1
\   potential.4th
\
\ Revisions:
\   2010-10-18  km  first version; analytic potential functions
\                   not yet supported.
\   2010-10-19  km  revise comments.
\   2011-08-15  km  fixed SOLVE to avoid infinite loop condition
\                     by adding divide by two to energy increment
\                     when reversing direction away from zero crossing.
\   2012-10-13  km  added GET-P to copy contiguous radial function to 
\                     user array.
\   2014-12-12  km  completed modular version; now requires potential.4th.
\   2014-12-20  km  renamed GET-P to }GET-P; modified SETUP-MESH to
\                     return Nmesh; added UPDATE-VLIMS.
\   2014-12-27  km  added INIT-Qs, DF/DR, INIT-MATCHING-POINT, and
\                     UPDATE-MATCHING-POINT, and revised
\                     SOLVE and SCHR-INTEGRATE accordingly for
\                     a dynamically adjusted matching point for
\                     the inward and outward solutions.
\   2015-01-05  km  added check for convergence on slope difference
\                     in SOLVE, which also now returns error code 2
\                     when the energy converges at a value for
\                     which slope difference is above tolerance.
\   2015-02-11  km  remove the automatic adjustment of the mesh
\                     size to a power of 2. Added SETUP-FILE-MESH
\   2017-07-19  km  modified SCHR-INTEGRATE to not return error value,
\                     which was unused; use linear interpolation
\                     to estimate eigenvalue in SOLVE.
\
\ Copyright (c) 2010--2017 Krishna Myneni, http://ccreweb.org
\
\ This code may be used for any purpose, as long as the copyright
\ notice above is preserved.
\

[undefined] fsquare [IF] 
: fsquare postpone fdup postpone f* ; immediate
[THEN]

[undefined] fnip [IF]
: fnip    postpone fswap postpone fdrop ; immediate
[THEN]

: pad2 ( n1 -- n2 ) 
   2 BEGIN  1 LSHIFT 2DUP < UNTIL NIP ;

Module: qm.schr1d

Also qm.potential

Begin-Module

Private:

false value verbose?

\ Scale factors to convert raw distance and potential energy
\   data to atomic units.
fvariable rscale
fvariable Vscale
1e rscale F!
1e Vscale F!

fvariable Rmin
fvariable Rmax
fvariable Vmin
fvariable Vmax

\ Set up arrays for position and potential energy on
\ the fixed length mesh.
variable Nmesh   \ mesh size for integrator
fvariable h      \ step size on r_mesh{

Public:
FLOAT DARRAY r_mesh{
FLOAT DARRAY V_mesh{

Private:
FLOAT DARRAY Pl{
FLOAT DARRAY Pr{
FLOAT DARRAY P'{
FLOAT DARRAY Ql{
FLOAT DARRAY Qr{

: allocate-PQ ( -- flag )
    & Pl{ Nmesh @ }malloc
    & Pr{ Nmesh @ }malloc
    & P'{ Nmesh @ }malloc
    & Ql{ Nmesh @ }malloc
    & Qr{ Nmesh @ }malloc 
    malloc-fail? 
;

Public:

: set-Vlims ( Vmin Vmax -- ) Vmax F! Vmin F! ;
: update-Vlims ( -- )
    Nmesh @ V_mesh{ }fmin 
    Nmesh @ V_mesh{ }fmax set-Vlims
;

\ Set up a uniform mesh of radial coordinates. Nmesh is the 
\ number of points in the mesh.

: setup-uniform-rmesh ( Rmin Rmax Nmesh -- Nmesh )
    Nmesh !  Rmax F!  Rmin F!
    & r_mesh{ Nmesh @ }malloc
    malloc-fail? ABORT" setup-uniform-rmesh: Can't allocate mem!"
    Rmax F@ Rmin F@ F- Nmesh @ 1- s>f F/ h F!
    Rmin f@ Nmesh @ 0 DO  fdup r_mesh{ I } F! h F@ F+  LOOP fdrop
    allocate-PQ ABORT" setup-mesh: Can't allocate PQs!"
    Nmesh @
;

\ Set up the interpolated mesh for the potential
\ Nmesh is the number of points in the mesh, and
\ norder is the order of the interpolation polynomial
: setup-mesh ( Nmesh norder -- Nmesh )
   set-interpolation-order
   >r get-Rlims 
   r> setup-uniform-rmesh

   & V_mesh{ Nmesh @ }malloc
   malloc-fail? ABORT" setup-mesh: Can't allocate mem!"

   Nmesh @ 0 DO  r_mesh{ I } F@ InterpolateV  V_mesh{ I } F!  LOOP
   get-Vlims set-Vlims
;

\ Set up file data mesh, i.e., use input potential
\ provided by the module, qm.potential, which is
\ obtained directly from data read from a file.

: setup-file-mesh ( -- Nmesh )
    get-Npotnl dup 0< ABORT" setup-file-mesh: No potential data available!"
    Nmesh !
    & r_mesh{ Nmesh @ }malloc
    malloc-fail?
    & V_mesh{ Nmesh @ }malloc
    malloc-fail?
    or ABORT" setup-file-mesh: Can't allocate V_mesh{ !"
    Nmesh @ r_mesh{ }copy-r
    Nmesh @ V_mesh{ }copy-V
    allocate-PQ ABORT" setup-file-mesh: Can't allocate PQs!"
    get-Rlims Rmax f! Rmin f!
    Rmax F@ Rmin F@ F- Nmesh @ 1- s>f F/ h F!
    get-Vlims set-Vlims
    Nmesh @
;

    
Private:

fvariable mu   \ reduced mass in Schr. Eqn. (in atomic units)

variable  mi
variable  mo

: init-Qs ( E -- )
    \ Initialize Ql and Qr
    Nmesh @ 0 DO  V_mesh{ I } F@ fover F-   mu F@ 2e F* F* Ql{ I } F!  LOOP
    fdrop   \ -- 
    Nmesh @ 0 DO  Ql{ Nmesh @ I - 1- } F@   Qr{ I } F!  LOOP
;

: init-matching-point ( -- error )
    \ Find rightmost zero crossing of Ql{}; this will be the
    \   matching point for the outward and inward solutions
    0 
    1 Nmesh @ 1- DO  
      Ql{ I }    F@  0e F>  Ql{ I 1- } F@  0e F<=  and
      IF  drop I  leave THEN
    -1 +LOOP
    dup 0= IF drop 1 EXIT THEN  \ ERROR: Unable to find zero crossing!
    mo !
    Nmesh @ mo @ - 1- mi !   \ indices mo and mi correspond to same r
    0
;

\ Compute df/dr 
0 ptr f{
0 ptr f'{

Public:
: df/dr ( 'f 'fprime -- )
    to f'{ to f{
    f{ 1 } f@ f{ 0 } f@ f- h f@ f/  f'{ 0 } f!
    Nmesh @ 1- 1 DO
      f{ I 1+ } f@ f{ I 1- } f@ f- h f@ 2e f* f/  f'{ I } f!
    LOOP
    f{ Nmesh @ 1- } f@  f{ Nmesh @ 2 - } f@ f- h f@ f/
    f'{ Nmesh @ 2 - } f!
;

Private:
0 value idx_maxP
0 value idx_maxP'

: update-matching-point ( -- )
    \ Find r at which Pl{ } is a maximum
    0 to idx_maxP
    0e
    Nmesh @ 0 DO 
      Pl{ I } f@ fabs f2dup
      f< IF  I to idx_maxP fnip  ELSE  fdrop  THEN
    LOOP
    fdrop

    \ Find r at which dPl{ }/dr is a maximum slope
    Pl{ P'{ df/dr
    idx_maxP to idx_maxP'
    0e
    Nmesh @ idx_maxP DO
      P'{ I } f@ fabs f2dup 
      f< IF  I to idx_maxP' fnip  ELSE  fdrop  THEN
    LOOP
    fdrop
    idx_maxP' mo !
    Nmesh @ mo @ - 1- mi !
;
  
\ Normalize the integral of P(r)^2 using trapezoid integration
fvariable Pnorm
: normalize-Ps ( -- )
    Pl{ 0 } F@ fsquare 0.5e F*   
    mo @ 1 DO  Pl{ I } F@ fsquare F+  LOOP  
    Pl{ mo @ } F@ fsquare 0.5e F* F+ 
    Pr{ 0 } F@ fsquare 0.5e F*   
    mi @ 1 DO  Pr{ I } F@ fsquare F+  LOOP  
    Pr{ mi @ } F@ fsquare 0.5e F* F+
    F+ h F@ F*  fsqrt fdup Pnorm F!
    mo @ 2+ 0 DO  Pl{ I } F@ fover F/  Pl{ I } F!  LOOP
    mi @ 2+ 0 DO  Pr{ I } F@ fover F/  Pr{ I } F!  LOOP
    fdrop
;

\ Use Simpson's Rule
0 [IF]
: normalize-Ps ( -- )
    Pl{ 0 } F@ fsquare
    mo @ 1 DO  
      Pl{ I } F@ fsquare 
      I 2 mod IF 4e ELSE 2e THEN F* F+  
    LOOP  
    Pl{ mo @ } F@ fsquare F+ 

    Pr{ 0 } F@ fsquare
    mi @ 1 DO  
      Pr{ I } F@ fsquare 
      I 2 mod IF 4e ELSE 2e THEN F* F+  
    LOOP  
    Pr{ mi @ } F@ fsquare F+

    F+ h F@ F* 3e F/  fsqrt fdup Pnorm F!
    mo @ 2+ 0 DO  Pl{ I } F@ fover F/  Pl{ I } F!  LOOP
    mi @ 2+ 0 DO  Pr{ I } F@ fover F/  Pr{ I } F!  LOOP
    fdrop
;
[THEN]

\ Rescale Pl to equal Pr at the matching point
: match-Ps ( -- )
    Pr{ mi @ } F@  Pl{ mo @ } F@  F/  mo @ 2+ Pl{ }fscale ;

\ Join the inward solution, Pr, to the outward solution, Pl.
\ The contiguous radial function will be stored in Pl.
: join-lr ( -- )
    Nmesh @ mo @ 1+ DO  
      Pr{ Nmesh @ I - 1- } F@  Pl{ I } F!  
    LOOP  ;


Public:

: set-particle-mass ( m -- )  mu F! ;

\ Integrate the radial Schroedinger equation, inward and outward,
\   for a given energy, and return the difference in slopes at the
\   matching point.

: schr-integrate ( E -- delSlope )
    init-Qs

    verbose? IF  
      cr ." schr-integrate: mo = " mo ?  ."  mi = " mi ?  cr
    THEN

    \ Outward integration to one step past zero crossing
    Pl{  Ql{  mo @ 2+ h F@ numerov_integrate

    \ Inward integration to one step before zero crossing
    Pr{  Qr{  mi @ 2+ h F@ numerov_integrate

    match-Ps
    normalize-Ps

    \ Determine slope difference between outward and inward solutions
    Pl{ mo @ 1+ } F@  Pl{ mo @ 1- } F@ F- h F@ 2e F* F/   \ outward slope
    Pr{ mi @ 1- } F@  Pr{ mi @ 1+ } F@ F- h F@ 2e F* F/   \ inward  slope
    F- 
;


Private:

\ Given a trial energy eigenvalue, find the nearest actual eigenvalue
\   to within the absolute error, Etol.

fvariable dE
fvariable sd1
fvariable sd2
fvariable Etol
fvariable sdtol
( 1e-9) 1e-10 Etol F!   \ Default absolute error in eigenvalue (in Hartrees)
( 1e-3) 1e-4  sdtol F!   \ Default tolerance on slope error 

Public:

: set-verbose ( b -- ) to verbose? ;

\ Given the current trial value of E, and knowing that a zero
\ crossing has occurred in the slope difference, estimate the
\ location of the eigenvalue, from linear interpolation.
: estimate-E0 ( E -- E0 )
    sd1 f@ sd2 f@ fover f- f/ 1e f+
    dE  f@ f* f- 
; 

: solve ( E dE -- E' dE' nerror )
    dE F!
    \ Sanity check for starting value of E
    fdup Vmin F@ F<= IF  fdrop Vmin F@ dE F@ fabs 1.5e F* F+  THEN

    fdup init-Qs 
    init-matching-point IF 0e 1 EXIT THEN

    Nmesh @ Pl{ }fzero  Nmesh @ Pr{ }fzero

    \ Set initial values for Pl{ 0 }, Pl{ 1 }, Pr{ 0 }, and Pr{ 1 }
    0e   Pl{ 0 } F!   1e-6 Pl{ 1 } F!
    1e-6 Pr{ 0 } F!   2e-6 Pr{ 1 } F!
 
    verbose? IF 
      cr ." Max Error in E = " Etol F@ F. ." Eh"
    THEN

    \ Find the solution slope differences at E 
    fdup  schr-integrate  sd1 F!
    dE f@ F+  \ -- E+dE

    BEGIN
      fdup  schr-integrate  sd2 F!

      verbose? IF
        cr ." E = " fdup 15 f>string count s"  Eh" strcat type
        cr ."   Energy inc. (Eh)  = "  dE F@ F.
        cr ."   Matching r (a.u.) = "  r_mesh{ mo @ } F@ F.
        cr ."   Prev Slope Del  =   "  sd1 F@ F.
        cr ."   Curr Slope Del  =   "  sd2 F@ F.
      THEN

      \ Error > Tolerance ?
      dE  F@ fabs Etol  F@  F>
      sd2 F@ fabs sdtol F@  F> or 
    WHILE
      sd1 F@ sd2 F@ 
      f2dup F* F0< IF
        \ slope difference crossed zero; interpolate crossing
        \ point and reduce and reverse dE
        f2drop
        estimate-E0
        dE F@ -4e F/ dE F!
        sd1 F@ sd2 F@
      ELSE
        dE F@ fabs Etol F@ F< IF
          \ slope difference converged at non-zero value
          fdrop 2 EXIT 
        ELSE
	  \ slope difference greater than sdtol
          f2dup fabs fswap fabs fswap  \ -- E  |sd1|  |sd2|
          F<  IF    \ magnitude of slope difference increasing 
            dE F@ -2e F/ dE F! 
          THEN
        THEN
      THEN
      sd1 F! fdrop
      dE F@ F+  \ Apply correction to E
      update-matching-point
    REPEAT
    dE F@  0
;

\ For debug. Write the Pl{r} and Pr{r} solutions to a file.
\ col 1 = r, col 2 = Pl, col 3 = Pr, col 4 = P (contiguous
\ solution).
: write-soln ( -- )
   s" soln.dat" delete-file drop
   s" >file soln.dat" evaluate
   Nmesh @ 0 DO
     r_mesh{ I } F@ F. 2 spaces  Pl{ I } F@ fdup F. 2 spaces
     Pr{ Nmesh @ I - 1- } F@ fdup F. 2 spaces
     I mo @ > IF  fswap THEN  fdrop F. cr
   LOOP
   console
;

Private:

0 ptr Pdest{

Public:

\ Copy the continguous radial function into user array, which
\ must be allocated by the user with sufficient memory

: }get-P ( 'P -- )
    to Pdest{
    Nmesh @ 0 DO
      Pl{ I } F@  Pr{ Nmesh @ I - 1- } F@
      I mo @ > IF  fswap THEN  fdrop  Pdest{ I } F!
    LOOP
;

\ Clean up remaining dynamically allocated memory
: end-solve ( -- )
    & Qr{ }free
    & Ql{ }free
    & P'{ }free
    & Pr{ }free
    & Pl{ }free
    & V_mesh{ }free
    & r_mesh{ }free
;

End-Module

