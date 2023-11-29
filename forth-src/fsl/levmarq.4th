\ A nonlinear fitting toolkit. Implementing the Levenberg-Marquardt method.

\ setup-marquardt ( 'x 'y 'sig ndata  'a ma  'lista mfit  'covar 'alpha -- )
\ Levenberg-Marquardt method, attempting to reduce the value chisq of a fit 
\ between a set of points x[1..ndata], y[1..ndata] with individual standard 
\ deviations sig[1..ndata], and a nonlinear function dependent on coefficients
\ a[1..ma]. The array lista[1..ma] numbers the parameters a such that the 
\ first mfit elements correspond to values actually being adjusted; the 
\ remaining ma-mfit parameters are held fixed at their input value. The 
\ program returns current best-fit values for the ma fit parameters a, and
\ chisq. During most iterations the [1..mfit, 1..ma] elements of the 
\ array covar[1..ma, 1..ma] and the array alpha[1..ma, 1..ma] are used as 
\ working space. The program must be supplied with a routine MrqFitter 
\ ( 'a 'dyda ) ( F: x -- yfit ) that evaluates the fitting function yfit, and 
\ its derivatives dyda[1..ma] with respect to the fitting parameters a at x. 
\ On the call to setup-marquardt, provide an initial guess for the 
\ parameters a . Now start calling mrqminimize . 

\ mrqminimize ( -- bad? )
\ First call setup-marquardt . If mrqminimize succeeds chisq becomes smaller 
\ and alamda decreases by a factor of 10. If a step fails alamda grows by a 
\ factor of 10. You must call repeatedly until convergence is achieved. 
\ When mrqminimize indicates convergence, make one final call with 
\ alamda = 0.0, so that covar returns the covariance matrix, and alpha the 
\ curvature matrix. Finally call exit-marquardt to clean up memory. 
\ Note: the boolean returned does not indicate successful convergence, but
\ reports TRUE in case of a fatal error. You may want to call exit-marquardt
\ when a fatal error happens (probably a singular matrix in gaussj).

\ exit-marquardt ( -- )
\ Call exit-marquardt to clean up memory after using setup-marquardt and/or
\ mrqminimize .

\ MrqFitter ( 'a 'dyda -- ) ( F: x -- yfit )
\ A vectored word that evaluates the fitting function yfit, and its 
\ derivatives dyda[1..ma] with respect to the fitting parameters a at x. 

\         Flowchart of the Nonlinear Fitting Process:
\         ===========================================
\   0    Set a to ma guessed/fixed values and call setup-marquardt
\   1    call mrqminimize and check that alamda and chisq decrease.
\          if not, or error, goto 3
\          if true, continue 1 until chisq is satisfactory
\   2    Make alamda = 0 and call mrqminimize one more time. Now covar contains
\ 	 covariance and alpha the curvature (a and chisq become valid).
\   3    do exit-marquardt

\ This is an ANS Forth program requiring:
\	1. The Floating-Point word sets
\	2. Uses FSL words from fsl_util.xxx 
\	3. Uses : F0=  ( -- bool ) ( F: r -- )  0e 0e F~ ;
\		: F> FSWAP F< ;
\		: F2DUP ( F: r1 r2 -- r1 r2 r1 r2 ) FOVER FOVER ;
\	        : 1/F  ( F: r -- 1/r ) 1e FSWAP F/ ;
\		: F+! ( addr -- ) ( F: r -- )  DUP F@ F+ F! ;
\		: FSQUARE ( F: r1 -- r2 ) FDUP F* ;
\		: F1+ ( F: r -- r ) 1e F+ ;

\ Note: the code uses 8 fp stack cells (iForth vsn 1.05) when executing
\       the test words.

\ See: 'Numerical recipes in Pascal, The Art of Scientific Computing',
\ William H. Press, Brian P. Flannery, Saul A. Teukolsky and William
\ T. Vetterling, Chapter 14 (14.4): Modeling of Data, Nonlinear Models.
\ 1989; Cambridge University Press, Cambridge, ISBN 0-521-37516-9

\ (c) Copyright 1995 Marcel Hendrix.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

\    2003-11-25  km; adapted for kForth.
\    2011-09-16  km; set BASE to decimal and restore; use Neal Bridges'
\                    anonymous modules.
\    2012-02-19  km; use KM/DNW's modules library
\    2021-07-09  km; update for separate fp stack also.
CR .( MARQUARDT         V1.0c          09 July       2021     MH )
BEGIN-MODULE

BASE @ DECIMAL

\ ======== kForth Requires ===================
\  ans-words.4th
\  fsl-util.4th
\  dynmem.4th
\  gaussj.4th
\
: F1+ ( F: r -- r ) 1e F+ ;
\ ========= end of kForth requirements ======


Private:

  FLOAT DARRAY  x{		\ inputs x y and individual standard deviations
  FLOAT DARRAY  y{
  FLOAT DARRAY  sig{		0 VALUE ndata

  FLOAT DARRAY  a{		0 VALUE ma
  FLOAT DARRAY  dyda{

  FLOAT DARRAY  lista{		0 VALUE mfit

  FLOAT DMATRIX covar{{		\ (ma x ma) covariances
  FLOAT DMATRIX alpha{{		\ (ma x ma) curvatures

  FLOAT DARRAY  MrqminBeta{	\ these 4 are scratch space.
  FLOAT DARRAY  atry{	
  FLOAT DARRAY  da{
  FLOAT DMATRIX oneda{{

  FVARIABLE MrqminOchisq 	\ scratch


Public:

FVARIABLE alamda
FVARIABLE chisq 

DEFER MrqFitter ( fx 'a 'dyda -- fy )

Private:


\ Given the covariance matrix covar[1..ma, 1..ma] of a fit for mfit of ma
\ total parameters, and their ordering lista[1..ma], repack the covariance 
\ matrix to the true order of the parameters. Elements associated with fixed
\ parameters will be zero. 
fvariable temp
: covsrt ( -- )
	\ zero the elements below the diagonal
	ma 1- 0 ?DO  ma I 1+ ?DO  0e covar{{ I J }} F!  LOOP LOOP

	\ pack off-diagonal elements of fit into correct locations below 
	\ diagonal
        mfit 1- 0 ?DO	
          mfit  I 1+ ?DO
            covar{{ I J }} F@  
            covar{{ lista{ J } @  lista{ I } @
            2DUP < IF  SWAP  THEN   }} F!
          LOOP
        LOOP

	\ Temporarily store diagonal elements in top row and zero the diagonal 
	covar{{ 0 0 }} F@ ( -- "swap" )
	ma 0 DO  
          covar{{ I I }} DUP F@ 
          temp f! 0e 
[ fp-stack? invert ] [IF] ROT [THEN]
          F! temp f@ covar{{ 0 I }} F!  
        LOOP

	\ Sort elements into proper order on diagonal 
	( -- swap) covar{{ lista{ 0 } @ DUP }} F!
	mfit 1 DO  covar{{ 0 I }} F@  covar{{ lista{ I } @ DUP }} F!  LOOP

	\ Fill above diagonal by symmetry 
	ma 1 DO  I 0 DO  covar{{ J I }} F@  covar{{ I J }} F!  LOOP LOOP ;


\ Used by mrqminize to evaluate the linearized fitting matrix. 
\ alpha[1..mfit, 1..mfit], and vector beta[1..mfit]
\ Called as   a{ alpha{{ MrqminBeta{ mrqcof  ||   atry{ covar{{ da{ mrqcof
0 ptr beta{
0 ptr alpha2{{
0 ptr a2{
: mrqcof ( 'a 'alpha 'mbeta -- )
	( LOCALS| beta{ alpha{{ a{ |)
	TO beta{  TO alpha2{{  TO a2{
	mfit 0 DO \ init symmetric alpha and beta
		  I 1+ 0 DO  0e alpha2{{ J I }} F!  LOOP
		  0e beta{ I } F!
	LOOP
	0e ( chi2)
	ndata 0 DO \ summation loop over all data
		   sig{ I } F@ FSQUARE 1/F ( -- chi2 s2)
		   y{ I } F@
		   x{ I } F@ a2{ dyda{ MrqFitter ( -- ... ymod)
		   F- ( chi2 s2 dy)
		   mfit 0 DO
			     FOVER dyda{ lista{ I } @ } F@ F* ( .. wt)
			     I 1+ 0 DO
				       FDUP dyda{ lista{ I } @ } F@ F*
				       alpha2{{ J I }} F+!
		 	     LOOP ( -- chi2 s2 dy wt)
			     FOVER F* beta{ I } F+!
		   LOOP ( -- chi2 s2 dy)
		   FSQUARE F* F+ ( -- chi2)
	LOOP
	chisq F!
	mfit 1 DO  I 0 DO  alpha2{{ J I }} F@ alpha2{{ I J }} F!  LOOP LOOP ;

0 VALUE kk
: init-marquardt ( -- )

	mfit ( LOCALS| kk |) TO kk

	ma 0 DO 
		 0  mfit 0 DO lista{ I } @ J = 1 AND + LOOP
		 DUP 0= IF  DROP I lista{ kk } !  1 kk + TO kk
		      ELSE  1 > ABORT" lista :: improper permutation (1)"
		      THEN
	   LOOP  kk ma <> ABORT" lista :: improper permutation (2)" 

	0.001e alamda F!  
	a{ alpha{{ MrqminBeta{ mrqcof   chisq F@ MrqminOchisq F!
	a{ atry{ ma }fcopy ;
  
Public: 

: setup-marquardt ( 'x 'y 'sig ndata  'a ma  'lista mfit  'covar 'alpha -- )
	0e chisq F!  
	& alpha{{ &!   & covar{{ &!  
	TO mfit  & lista{ &!
	TO ma    & a{ &!
	TO ndata & sig{ &!  & y{ &!  & x{ &!
	&       dyda{ ma }malloc malloc-fail? 
	& MrqminBeta{ ma }malloc malloc-fail? OR
	&       atry{ ma }malloc malloc-fail? OR
	& oneda{{ ma  1 }}malloc malloc-fail? OR 
	& da{ ma }malloc malloc-fail? OR ABORT" mrqminimize :: out of memory"
	init-marquardt ;

: exit-marquardt ( -- )
	&         da{   }free  
	&      oneda{{ }}free  
	&       atry{   }free  
	& MrqminBeta{   }free   
	&       dyda{   }free ;


0 [IF] Experimental; substitute for gaussj . It was slower, not better at all.

FLOAT DMATRIX dummy{{

: mgaussj ( 'a 'b n m -- bad? )
	1 <> ABORT" mgaussj assumes m = 1" >R 
	& dummy{{ R@ 1 }}malloc malloc-fail? IF 2DROP 2DROP TRUE EXIT THEN
	2DUP dummy{{ SWAP R@ DUP 10  1e-9 solve F2DROP 
	  NIP IF R> 3DROP & dummy{{ }}free TRUE EXIT THEN
	dummy{{ SWAP ( b) R@ 1 }}fcopy
	R> mat^-1  	\ solve doesn't return the matrix inverse...
	& dummy{{ }}free ;

[THEN]


: mrqminimize ( -- bad? )
	alpha{{ covar{{ mfit DUP }}fcopy 

	alamda F@ F1+
	mfit 0 DO  
		  FDUP alpha{{ I DUP }} F@ F*  covar{{ I DUP }} F! 
		  MrqminBeta{ I } F@  oneda{{ I 0 }} F!
	     LOOP
	FDROP

	covar{{ oneda{{ mfit 1 gaussj IF TRUE EXIT THEN  \ singular?
	mfit 0 DO oneda{{ I 0 }} F@  da{ I } F! LOOP

	alamda	F@ F0= IF covsrt FALSE EXIT THEN

	mfit 0 DO     a{ lista{ I } @ } F@  da{ I } F@ F+
		   atry{ lista{ I } @ } F!
	     LOOP
	atry{ covar{{ da{ mrqcof 
	chisq F@  MrqminOchisq F@ 
	 F< IF
		alamda DUP F@ 0.1e F* 
[ fp-stack? invert ] [IF] ROT [THEN] 
                F!
		chisq F@  MrqminOchisq F!
		covar{{ alpha{{ mfit mfit }}fcopy   
		mfit 0 DO  
			   atry{ lista{ I } @ } F@  a{ lista{ I } @ } F!
			   da{ I } F@  MrqminBeta{ I } F!
		     LOOP
	  ELSE	alamda DUP F@ 10e F* 
[ fp-stack? invert ] [IF] ROT [THEN]
                F!  MrqminOchisq F@ chisq F!
	  THEN 

	FALSE ;

BASE !
END-MODULE

TEST-CODE? [IF]

\ Setup code for the vectors MrqFitter MRQ-SETUP MRQ-STOP? and MRQ-RESULTS

10 VALUE #datapoints	\ number of data points
 3 VALUE #funcs		\ number of functions to fit data
 3 VALUE #params/f	\ parameters per function

  FLOAT DARRAY x{
  FLOAT DARRAY y{
  FLOAT DARRAY sig{
  FLOAT DARRAY a{
INTEGER DARRAY lista{

FLOAT DMATRIX covar{{
FLOAT DMATRIX alpha{{

DEFER MRQ-SETUP    ( -- )
DEFER MRQ-STOP?    ( iter -- stop? )
DEFER MRQ-RESULTS  ( -- )

0 VALUE iter
: FIND-COEFFS ( -- )
	1 ( LOCALS| iter |) TO iter

	MRQ-SETUP

	BEGIN
	  mrqminimize IF exit-marquardt TRUE ABORT" singular matrix" THEN
	  chisq F@ 1e-18 F<  
	  iter DUP 1+ TO iter MRQ-STOP?  OR
	UNTIL

	MRQ-RESULTS ;

\ Evaluates and computes derivative of a set of #funcs Gaussian functions
\ of the form  f(x) = B * exp -( (x-E)/G )^2.
\ The parameters B,E,G are stored sequentially in a{ .
\ The derivatives dy/dB, dy/dE and dy/dG are stored sequentially in dyda{ .
0 VALUE ix
0 ptr dyda{
0 ptr arr{
FVARIABLE a
FVARIABLE b
FVARIABLE c
: fgauss ( fx 'a 'dyda -- fy )
	0 ( LOCALS| ix dyda{ a{ |) TO ix  TO dyda{  TO arr{
	0e a F!  0e b F!  0e c F!
	0e ( -- x y)
	#funcs 0
	  DO	
		I #params/f * TO ix
		FOVER arr{ ix 1+ } F@ F-  arr{ ix 2+ } F@ F/ ( arg) FDUP a F!
		FSQUARE FNEGATE FEXP ( ex) FDUP b F!
		a F@ F* F2* arr{ ix } F@ F* ( fac) c F!  ( -- x y)
		arr{ ix } F@ b F@ F* F+ ( -- x y')
		b F@ dyda{ ix } F!
		c F@ arr{ ix 2+ } F@ F/ FDUP dyda{ ix 1+ } F!
		a F@ F* dyda{ ix 2+ } F!
 	LOOP 
	FSWAP ( -- x ) FDROP ;

	& fgauss IS MrqFitter



FVARIABLE spread	\ actual value does NOT influence the number of 
			\ iterations, but it affects covar{{ .
			\ Too small a value prevents convergence abruptly.

: UNSURE ( -- )  1e-2  spread F! ;	
: SURE   ( -- )  1e-10 spread F! ;  SURE

20 VALUE scaled

: gscale ( i -- fdelta )
	scaled * S>F  #datapoints S>F F/ ;

\ Assume the user sets up #datapoints.
\ Experiment with: #datapoints (up to 800 was tried)
\                  scaled      (up to 80 was tried). 

: GAUSS-SETUP
\	400 TO #datapoints
	3 TO #funcs
	3 TO #params/f

	&     x{ #datapoints }malloc malloc-fail?
	&     y{ #datapoints }malloc malloc-fail? OR
	&   sig{ #datapoints }malloc malloc-fail? OR
	&     a{ #funcs #params/f * }malloc malloc-fail? OR
	& lista{ #funcs #params/f * }malloc malloc-fail? OR
	& covar{{ #funcs #params/f * DUP }}malloc malloc-fail? OR
	& alpha{{ #funcs #params/f * DUP }}malloc malloc-fail? OR 
	ABORT" FIND-COEFFS :: not enough core"

	#datapoints 0 DO spread F@ sig{ I } F!  LOOP 

	#datapoints 0 DO  I gscale   x{ I } F!  LOOP 
 	
	#datapoints 0 DO I gscale 2.5e F- 1.5e F/ FSQUARE FNEGATE FEXP 3.3e F*
			 I gscale 1.3e F- 2.1e F/ FSQUARE FNEGATE FEXP 6.6e F*  F-
			 I gscale 6.5e F- 7.5e F/ FSQUARE FNEGATE FEXP 2.2e F*  F+
			 y{ I } F!
	            LOOP 
	
	CR ." The encoded function F(x) = " CR
	CR ."     3.3 exp -((x-2.5)/1.5)^2 "
	CR ."   - 6.6 exp -((x-1.3)/2.1)^2 "
	CR ."   + 2.2 exp -((x-6.5)/7.5)^2 " CR

	2e a{ 0 } F!   3e a{ 1 } F!	1e a{ 2 } F!  
	3e a{ 3 } F!   1e a{ 4 } F! 	2e a{ 5 } F!
	1e a{ 6 } F!   2e a{ 7 } F!	3e a{ 8 } F!

	#funcs #params/f * 0 DO I lista{ I } ! LOOP 

	x{ y{ sig{ #datapoints  
	a{ #funcs #params/f *  lista{ #funcs #params/f *  
	covar{{ alpha{{ setup-marquardt ( alamda <- 0.001)
	
	mrqminimize ABORT" singular matrix" ;

	& GAUSS-SETUP IS MRQ-SETUP


: GAUSS? ( iter -- stop? )
	CR ." iter = " . 
	." chisq = " chisq F@ F. ." alamda = " alamda F@ F.
	KEY? DUP IF KEY DROP THEN ;

	& GAUSS? IS MRQ-STOP?


: F.NICE ( r -- )
	FDUP F0< 0= IF SPACE THEN  F. SPACE ;

: .GAUSS
	chisq F@  0e alamda F! 		\ get the results
	mrqminimize IF exit-marquardt 
		       TRUE ABORT" singular matrix"  
	          THEN
	chisq F!

	exit-marquardt 

	CR CR ." Results, spread      : " spread F@ F.
	   CR ."          chi squared : " chisq F@ F. 
	   CR ." Parameters: "
	#funcs 0 DO CR  #params/f 0 DO a{ J #params/f * I + } F@ F.NICE 
				  LOOP 
	       LOOP 

	CR ." Expected: " 
	CR ."  3.300000   2.500000   1.500000  "
	CR ." -6.600000   1.300000   2.100000  "
	CR ."  2.200000   6.500000   7.500000  " 

	print-width @ >R  #funcs #params/f * print-width !	
	 CR ." --more--" KEY DROP
	 CR ." Covariance matrix: " 
	 CR #funcs #params/f * DUP covar{{ }}fprint CR 
 	 CR ." --more--" KEY DROP
	 CR ." Curvature matrix: "  
	 CR #funcs #params/f * DUP alpha{{ }}fprint 
	R> print-width ! ;

	& .GAUSS IS MRQ-RESULTS

CR .( Try:  UNSURE 20 TO scaled  30 TO #datapoints  FIND-COEFFS )


0 [IF] An example run.

UNSURE 20 TO scaled  30 TO #datapoints  FIND-COEFFS 

The encoded function F(x) = 

    3.3 exp -((x-2.5)/1.5)^2 
  - 6.6 exp -((x-1.3)/2.1)^2 
  + 2.2 exp -((x-6.5)/7.5)^2 

iter = 1 chisq = 2.446145E6 alamda = 1.000000E-1 
iter = 2 chisq = 1.584755E6 alamda = 1.000000E-2 
iter = 3 chisq = 1.026331E6 alamda = 1.000000E-3 
iter = 4 chisq = 5.921613E5 alamda = 1.000000E-4 
iter = 5 chisq = 5.921613E5 alamda = 1.000000E-3 
iter = 6 chisq = 5.921613E5 alamda = 1.000000E-2 
iter = 7 chisq = 5.921613E5 alamda = 1.000000E-1 
iter = 8 chisq = 4.071527E5 alamda = 1.000000E-2 
iter = 9 chisq = 4.071527E5 alamda = 1.000000E-1 
iter = 10 chisq = 1.128088E5 alamda = 1.000000E-2 
iter = 11 chisq = 1.128088E5 alamda = 1.000000E-1 
iter = 12 chisq = 3.368427E4 alamda = 1.000000E-2 
iter = 13 chisq = 1.300483E4 alamda = 1.000000E-3 
iter = 14 chisq = 2.870931E2 alamda = 1.000000E-4 
iter = 15 chisq = 2.543948E1 alamda = 1.000000E-5 
iter = 16 chisq = 2.231272E1 alamda = 1.000000E-6 
iter = 17 chisq = 2.096454E-4 alamda = 1.000000E-7 
iter = 18 chisq = 1.309434E-13 alamda = 1.000000E-8 
iter = 19 chisq = 5.843253E-22 alamda = 1.000000E-9 

Results, spread      : 0.010000 
         chi squared : 5.843253E-22 
Parameters: 
 3.300000   2.500000   1.500000  
-6.600000   1.300000  -2.100000  
 2.200000   6.500000   7.500000  
Expected: 
 3.300000   2.500000   1.500000  
-6.600000   1.300000   2.100000  
 2.200000   6.500000   7.500000  

--more--
Covariance matrix: 
  1.938826E-0001  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  7.574291E-0004  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  1.988668E-0003  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  1.240128E-0001  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  4.810466E-0003  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  6.332869E-0004  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  6.680120E-0005  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  3.640873E-0003  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  2.783365E-0003

--more--
Curvature matrix: 
  2.819820E+0004  1.273911E+0001  3.099252E+0004  2.609057E+0004 -6.248443E+0004  5.098517E+0004  2.969631E+0004 -8.920526E+0003  4.896951E+0003
  1.273911E+0001  1.363671E+0005  2.520325E+0002 -3.060407E+0004 -9.412342E+0004  7.123669E+0004  1.391698E+0004  3.065423E+0003 -5.079796E+0003
  3.099252E+0004  2.520325E+0002  1.018292E+0005  4.544711E+0004 -2.443262E+0004  9.597476E+0004  6.323771E+0004 -1.722452E+0004  9.923394E+0003
  2.609057E+0004 -3.060407E+0004  4.544711E+0004  3.723782E+0004 -1.439339E+0004  4.693130E+0004  3.174655E+0004 -1.140830E+0004  7.493222E+0003
 -6.248443E+0004 -9.412342E+0004 -2.443262E+0004 -1.439339E+0004  2.949967E+0005 -1.030917E+0005 -5.758105E+0004  9.350724E+0003 -5.146021E+0002
  5.098517E+0004  7.123669E+0004  9.597476E+0004  4.693130E+0004 -1.030917E+0005  1.759290E+0005  8.565761E+0004 -2.131631E+0004  1.108229E+0004
  2.969631E+0004  1.391698E+0004  6.323771E+0004  3.174655E+0004 -5.758105E+0004  8.565761E+0004  1.361689E+0005  3.092711E+0003  1.705476E+0004
 -8.920526E+0003  3.065423E+0003 -1.722452E+0004 -1.140830E+0004  9.350724E+0003 -2.131631E+0004  3.092711E+0003  1.000546E+0004  2.374715E+0003
  4.896951E+0003 -5.079796E+0003  9.923394E+0003  7.493222E+0003 -5.146021E+0002  1.108229E+0004  1.705476E+0004  2.374715E+0003  5.999577E+0003

[THEN]


[THEN]

				( * End of File * )
