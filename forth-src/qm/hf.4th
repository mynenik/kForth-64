\ hf.4th
\
\ Module for performing Hartree-Fock calculations of
\ atomic radial functions.
\
\ Atomic units are assumed.
\
\ Copyright (c) 2012--2017 K. Myneni, http://ccreweb.org
\
\ Revisions:
\   2012-10-10  km  created.
\   2014-12-16  km  additional notes.  
\   2014-12-20  km  renamed this module from scf.4th to hf.4th.
\   2015-12-09  km  added word, ORTHOGONALITY
\   2017-07-26  km  added words, <R> and <VEL^2>, to compute
\                   expectation values of radial distance and
\                   square of velocity for an electron with a
\                   specified radial function, P(r).
\ Notes:
\
\  1. The exchange interaction term is presently not included.
\     At the present time, only the ground states of two-electron
\     atoms, e.g. He, Li+, etc. may be computed accurately within
\     the Hartree-Fock approximation.
\
\ References:
\
\  1. R. D. Cowan, The Theory of Atomic Structure and Spectra,
\     University of California Press, Berkeley 1981.
\

[undefined] fsquare [IF] 
: fsquare postpone fdup postpone f* ; immediate
[THEN]

Module: qm.hf

Also qm.schr1d

Begin-Module

0 ptr  r{
0 ptr  P{
FLOAT DARRAY  V{
FLOAT DARRAY  P'{
FLOAT DARRAY  P2{
FLOAT DARRAY  P2r{

variable Nmesh
fvariable Z

fvariable I1
fvariable I2

\ helper word; don't forget to free P2{ after use.
: compute-P2 ( -- )
    & P2{ Nmesh @ }malloc
    Nmesh @ 0 DO  P{ I } F@ fsquare P2{ I } F! LOOP
;

\ helper word; compute the radial integral of P2.
: integrate-P2 ( -- a )
    P2{ 0 } F@ r{ 0 } F@ F* 0.5e F*   
    Nmesh @ 1 DO
      r{ I }  F@   r{ I 1- } F@ F- 0.5e F*
      P2{ I } F@  P2{ I 1- } F@ F+ F* 
      F+
    LOOP
;

Public:

\ Compute the one-electron atom potential energy, given the
\ one-electron radial function, P(r) -- cf. equation 7.16 in
\ ref. [1]. Note that the energy does not include the nuclear
\ contribution, first term on the r.h.s. of 7.16. Also, the
\ units used here, a.u., are different from the expression of
\ 7.16 by a factor of 2.

: V_el ( 'r 'P n -- 'V )  
	Nmesh !
	to P{  to r{
	
	& V{   Nmesh @ }malloc
	& P2{  Nmesh @ }malloc
	& P2r{ Nmesh @ }malloc
	malloc-fail? ABORT" Unable to allocate arrays!"
	Nmesh @ 0 DO
	  P{ I } f@ fsquare fdup P2{ I } f!
	  r{ I } f@ f/ P2r{ I } f!
	LOOP

	\ Initialize integrals I1 and I2
	P2{ 0 } f@ r{ 0 } f@ f* 2e f/ I1 f! 
	0e
	1 Nmesh @ 1- DO
	  r{ I } f@ r{ I 1- } f@ f-
	  P2r{ I } f@  P2r{ I 1- } f@ f+ f* 2e f/
	  f+
	-1 +LOOP
	I2 f!

	I1 f@ r{ 0 } f@ f/  I2 f@ f+  V{ 0 } f!

	Nmesh @ 1 DO
	  r{ I } f@ r{ I 1- } f@ f- 2e f/   \ h2
	  P2{ I } f@ P2{ I 1- } f@ f+ fover f*  I1 f@ f+  I1 f!  \ h2
	  P2r{ I } f@  P2r{ I 1- } f@ f+ f* I2 f@ f- fnegate I2 f!
	  I1 f@ r{ I } f@ f/ I2 f@ f+ V{ I } f!
	LOOP

	& P2{ }free  & P2r{ }free

	V{   \ store this pointer and free its memory using
             \ FREE-V_EL after use
;

: free-V_el ( -- )  & V{ }free ;

Private:
0 ptr Vt{

Public:
\ Add nuclear potential for nucleus of charge Z to V(r),
\ cf. eqn. 7.16 ref. [1], first term on the r.h.s.
: add-V_nuc ( 'r 'V Z n -- )
    Nmesh ! s>f Z f! to Vt{ to r{
    Nmesh @ 0 DO
      Vt{ I } F@  Z F@ r{ I } F@ F/ F-
      Vt{ I } F!
    LOOP
;

\ Add effective potential term from orbital angular momentum
: add-V_l ( 'r 'V n l -- )
    dup IF
      dup 1+ * >r  \ l*(l+1)
      Nmesh ! to Vt{ to r{
      r> s>f
      Nmesh @ 0 DO
        fdup r{ I } F@ fsquare F/ Vt{ I } F+!
      LOOP
      fdrop
    ELSE
      2drop 2drop
    THEN  
;

\ Use trapezoid integration to return the radial integral of P^2(r)
\ across the mesh of r. This word is useful for checking the
\ normalization of P(r).

: radial-integral ( 'r 'P n -- a )
    Nmesh ! to P{  to r{
    compute-P2
    integrate-P2
    & P2{ }free
;

\ Replace P with its normalized version
: normalize ( 'r 'P n -- )
    radial-integral fsqrt  \ a
    Nmesh @ 0 DO P{ I } f@ fover f/ P{ I } f! LOOP
    fdrop ;

\ Compute the expectation value of the radial coordinate
\ for an orbital with radial function, P(r),assumed to be
\ normalized.

: <r> ( 'r 'P n -- <r> )
    Nmesh ! to P{ to r{
    compute-P2
    Nmesh @ 0 DO P2{ I } F@ r{ I } F@ F* P2{ I } F! LOOP
    integrate-P2
    & P2{ }free  
;

\ Compute the expectation value of the square of the
\ radial velocity for an orbital with radial function, P(r).
\ <v^2> is returned in atomic units (alpha^2 * c^2).
: <vel^2> ( 'r 'P n -- <v^2> )
    Nmesh ! to P{ to r{
    & P'{ Nmesh @ }malloc  \ 1st derivative of P{
    & P2{ Nmesh @ }malloc  \ 2nd derivative of P{
    P{  P'{  df/dr
    P'{ P2{  df/dr
    Nmesh @ 0 DO P2{ I } F@ P{ I } F@ F* P2{ I } F! LOOP
    integrate-P2 fnegate
    Nmesh @ 0 DO P{ I } F@ r{ I } F@ F/ P'{ I } F@ F* P2{ I } F! LOOP
    integrate-P2 2e F* F+
    Nmesh @ 0 DO P{ I } F@ r{ I } F@ F/ fsquare P2{ I } F! LOOP
    integrate-P2 -2e F* F+
    fabs  \ necessitated by ambiguity in sign for P(r).
    & P2{ }free
    & P'{ }free  
;

\ Use trapezoid integration to compute a perturbation correction
\ of electron with radial function P(r) in potential V(r).

: <V> ( 'r 'P 'V n -- deltaE )
    Nmesh ! to Vt{  to P{  to r{
    compute-P2
    Nmesh @ 0 DO  P2{ I } F@ Vt{ I } F@ F*  P2{ I } F!  LOOP
    integrate-P2
    & P2{ }free
;


Private:
0 ptr P_1{
0 ptr P_2{
fvariable r1
fvariable r2
fvariable dr1
fvariable dr2
fvariable r_gt

Public:

\ Return the integral of P_1*P_2 to check orthogonality of
\ two radial functions.
: orthogonality ( 'r 'P_1 'P_2 n -- p )
    Nmesh ! to P_2{ to P_1{ to r{
    & P2{ Nmesh @ }malloc
    Nmesh @ 0 DO  P_1{ I } F@ P_2{ I } F@ F* P2{ I } F! LOOP
    integrate-P2
    & P2{ }free
;

Private:
fvariable x
fvariable bb
fvariable aa
fvariable temp

Public:
\ Replace P_2 with a radial function which is a linear combination
\ of P_1 and P_2, and which is orthogonal to P_1.
: orthogonalize ( 'r 'P_1 'P_2 n -- )
    orthogonality x F!
    x F@ fsquare 2e F*  \ a
    x F@ 1e F-          \ b
    1e                  \ c
    solve_quadratic
    \ ." Complex roots: "
    \ zover zover
    \ z. 2 spaces z. cr
    real temp f! real temp f@ fmin
    fdup bb F!
    x F@ F* fnegate aa F!
    \ Compute the orthogonal function P_2'
    Nmesh @ 0 DO
      P_1{ I } F@ aa F@ f*
      P_2{ I } F@ bb F@ F*
      f+ P_2{ I } F!
    LOOP
;

\ Compute the Coulomb repulsion energy for two equivalent 
\ s-electrons, with radial functions given by P1 and P2 
\ (see eq. 6.27--6.28 in [1]); this is Slater integral F^0.
: F^0 ( 'r 'P_1 'P_2 n -- F0 )
    Nmesh ! to P_2{  to P_1{  to r{
    0e
    Nmesh @ 1 DO    \ loop over r2
      r{ I } F@ fdup r2 F!
      r{ I 1- } F@ F- dr2 F!
      0e
      Nmesh @ 1 DO  \ loop over r1
        r{ I } F@ fdup r{ I 1- } F@ F- dr1 F!
        r2 F@ fmax r_gt F!
	P_1{ I } F@ P_1{ I 1- } F@ F+ 2e F/ fsquare
	r_gt F@ F/ dr1 F@ F*
	F+
      LOOP
      P_2{ I } F@ P_2{ I 1- } F@ F+ 2e F/ fsquare F*
      dr2 F@ F*
      F+
    LOOP
;

\ Slater integral G^0
: G^0 ( 'r 'P_1 'P_2 n -- G0 )
    Nmesh ! to P_2{  to P_1{  to r{
    0e
    Nmesh @ 1 DO    \ loop over r2
      r{ I } F@ fdup r2 F!
      r{ I 1- } F@ F- dr2 F!
      0e
      Nmesh @ 1 DO  \ loop over r1
        r{ I } F@ fdup r{ I 1- } F@ F- dr1 F!
        r2 F@ fmax r_gt F!
	P_1{ I } F@ P_1{ I 1- } F@ F+ 2e F/ 
	P_2{ I } F@ P_2{ I 1- } F@ F+ 2e F/
	F*
	r_gt F@ F/ dr1 F@ F*
	F+
      LOOP
      P_1{ I } F@ P_1{ I 1- } F@ F+ 2e F/
      F*
      P_2{ I } F@ P_2{ I 1- } F@ F+ 2e F/
      F*
      dr2 F@ F*
      F+
    LOOP
;

End-Module

