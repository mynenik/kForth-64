\ polyfit.4th   
\                                                               
\  Polynomial fitting routine in Forth                          
\
\ Adapted from the routine polfit in P.R. Bevington,
\ "Data Reduction and Error Analysis for the Physical Sciences"
\
\ Requires the following modules:
\
\       ans-words.4th
\       fsl-util.4th
\       dynmem.4th
\       determ.4th
\
\ Revisions:
\              
\	10-02-98 Adapted for LabForth KM             
\	03-29-99 Adapted for kForth KM  
\       01-01-02 Cleaned up the code (no functional changes)  KM
\       2007-06-12  merged polfit from xypolyfit.4th to this module as polfit2;
\                     factor common code, and use FSL-style arrays and modules.
\       2007-09-18  use determ.4th instead of FSL dets.4th for determinant calc.;
\                   added polfit1, and use [DEFINED] statement to check for
\                   xyplot environment; fixed problem with order of args in polfit  KM
\       2009-10-28  updated data structure members for xyplot interface  km

0  value  Nterms     \ number of terms (order - 1)               
0  value  Nmax                                                   
0  value  Npts

fvariable chisq                                                 
fvariable xterm                                                 
fvariable yterm                                                 
fvariable delta                                                 
                                                                
\ Floating point matrices used by polfit                        
                                                                
FLOAT DMATRIX  apfit{{
FLOAT DARRAY   sumx{                                    
FLOAT DARRAY   sumy{

0 ptr params{     \ holds address of parameter array

: }fzero ( 'array n -- | zero the n-element float array)
    FLOATS erase ;


\ Common code for versions of polfit is factored in polfit0; the
\ arrays sumx{ and sumy{ and the fvariable chisq must be set up
\ prior to calling polfit0

: polfit0 ( -- fdet | perform fitting and return determinant )
    Nterms 0 DO
	Nterms 0 DO  sumx{ I J + } F@  apfit{{ J I }} F!  LOOP
    LOOP

    apfit{{ Nterms determ  fdup delta F!
    F0= IF  0e EXIT  THEN

    Nterms 0 DO
	Nterms 0 DO
	    Nterms 0 DO  sumx{ I J + } F@  apfit{{ J I }} F!  LOOP
	    sumy{ I } F@  apfit{{ I J }} F!
	LOOP
	apfit{{ Nterms determ  delta F@ F/  params{ I } F!
    LOOP

\ Calculate chi-squared

    Nterms 0 DO
	chisq F@ params{ I } F@ sumy{ I } F@ F* 2e F* F- chisq F!
	Nterms 0 DO
	    sumx{ J I + } F@  params{ I } F@ F*  params{ J } F@ F*
	    chisq F@ F+ chisq F!
	LOOP
    LOOP
    
    chisq F@  Npts Nterms - s>f  F/ ;


\ The specialized variants below, polfit, polfit1, and polfit2,
\   allow for data to be passed to the polynomial fitter in
\   several ways:
\
\   a) separate x and y floating point arrays (polfit)
\   b) a 2 column matrix (polfit1)
\   c) through an xyplot dataset information structure (polfit2).
\

0  ptr  xd{
0  ptr  yd{

\ x = address of fmatrix containing x values                    
\ y = address of fmatrix containing y values                    
\ a = address of fmatrix for receiving fitted parameters        
\ n = order of fitting polynomial                               
\ np = number of points

: polfit ( 'x 'y 'a  n  np -- chi-square | perform polynomial fit )     
    to Npts  1+ to Nterms  to params{  to yd{  to xd{
    & apfit{{ Nterms Nterms }}malloc
    & sumy{ Nterms }malloc                              
    Nterms 2* 1- to Nmax                                       
    & sumx{ Nmax }malloc

    sumx{ Nmax }fzero  sumy{ Nterms }fzero  params{ Nterms }fzero
    0e chisq F!

    Npts 0 DO
	yd{ I } F@  xd{ I } F@  \ fy fx
	1e
	Nmax 0 DO  fdup sumx{ I } F@ F+ sumx{ I } F! fover F*  LOOP  xterm F!

	fover
	Nterms 0 DO  fdup sumy{ I } F@ F+ sumy{ I } F! fover F*  LOOP  yterm F!

	fover fdup F* chisq F@ F+ chisq F!
	fdrop fdrop
    LOOP

    polfit0

    \ cleanup
    & sumx{ }free  & sumy{ }free  & apfit{{ }}free
;


0 ptr xyd{{

: polfit1 ( 'xy 'a  n  np -- chi-square | perform polynomial fit )     
    to Npts  1+ to Nterms  to params{  to xyd{{ 
    & apfit{{ Nterms Nterms }}malloc
    & sumy{ Nterms }malloc                              
    Nterms 2* 1- to Nmax                                       
    & sumx{ Nmax }malloc

    sumx{ Nmax }fzero  sumy{ Nterms }fzero  params{ Nterms }fzero
    0e chisq F!
    
    Npts 0 DO
	xyd{{ I 1 }} F@  xyd{{ I 0 }} F@  \ fy fx
	1e
	Nmax 0 DO  fdup sumx{ I } F@ F+ sumx{ I } F! fover F*  LOOP  xterm F!

	fover
	Nterms 0 DO  fdup sumy{ I } F@ F+ sumy{ I } F! fover F*  LOOP  yterm F!

	fover fdup F* chisq F@ F+ chisq F!
	fdrop fdrop
    LOOP

    polfit0

    \ cleanup
    & sumx{ }free  & sumy{ }free  & apfit{{ }}free
;


\ polfit2 is for use under XYPLOT only
[DEFINED] DatasetInfo [IF]

0 ptr pDS

\ ds = address of dataset info structure                    
\ a = address of fmatrix for receiving fitted parameters        
\ n = order of fitting polynomial                               
                                                                
: polfit2 ( ds 'a n -- chi-square | perform polynomial fit )     
    1+ to Nterms                                                 
    to params{  to pDS                                                    
    & apfit{{ Nterms Nterms }}malloc
    & sumy{ Nterms }malloc                              
    Nterms 2* 1- to Nmax                                       
    & sumx{ Nmax }malloc                                    
    pDS DatasetInfo->Npts @ to Npts
    
    sumx{ Nmax }fzero  sumy{ Nterms }fzero  params{ Nterms }fzero
    0e chisq F!
    
    Npts 0 DO
	I pDS @xy	\ fetch the i^th point
	fswap		\ fy fx
	1e
	Nmax 0 DO  fdup sumx{ I } F@ F+ sumx{ I } F! fover F*  LOOP  xterm F!

	fover
	Nterms 0 DO  fdup sumy{ I } F@ F+ sumy{ I } F! fover F*  LOOP  yterm F!

	fover fdup F* chisq F@ F+ chisq F!
	fdrop fdrop
    LOOP

    polfit0

    \ cleanup 
    & sumx{ }free  & sumy{ }free  & apfit{{ }}free
;
[THEN]

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

10 constant NP  ( number of points )

\ Initialize x and y arrays with data for y = x^2

NP FLOAT array x{ 0e  1e  2e  3e  4e  5e  6e  7e  8e  9e  NP x{ }fput
NP FLOAT array y{ 0e  1e  4e  9e 16e 25e 36e 49e 64e 81e  NP y{ }fput

NP x{ }fprint
NP y{ }fprint
\ Array for fitted polynomial coefficients.

4 FLOAT array coeffs{

t{ x{ y{ coeffs{ 2 NP polfit -> 0e  r}t
t{ coeffs{ 0 } F@            -> 0e  r}t
t{ coeffs{ 1 } F@            -> 0e  r}t
t{ coeffs{ 2 } F@            -> 1e  r}t

[THEN]
