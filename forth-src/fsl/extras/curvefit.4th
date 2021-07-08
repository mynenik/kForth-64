\
\ curvefit.4th
\
\ Nonlinear least-squares curve fitting routine from P.R. Bevington,
\   "Data Reduction and Error Analysis for the Physical Sciences",
\   translated to kForth by K. Myneni, 9-21-1998
\
\ kForth requires the following files:
\
\	ans-words.4th
\	fsl-util.4th
\	dynmem.4th
\	gaussj.4th
\
\ Usage:
\
\  First include the source file for the array and matrix words
\  (fsl-util.4th), then the source file containing the definition of
\  the fitting function,
\
\	functn
\
\  The stack diagram for functn is
\
\	fx a -- fy
\
\  where fx is the x value at which the function is to be
\  evaluated and 'a' is the address of the array containing the parameter
\  values. The computed value for y is returned on the stack.
\
\  Read in the data to two 1D matrices, one containing the x values,
\  the other containing the y values. 
\
\  Next, set the values of the array 'a' to the buest guess
\  initial parameters. Also initialize an array, deltaa, which
\  contains the initial increments for the corresponding parameters.
\  The fit convergence time will depend on the magnitude of the
\  parameter increments. A parameter can be held fixed for the
\  curve fit by setting its increment to zero.
\
\  Finally, execute curfit. 
\
\  Revised:
\
\	2003-12-17  fix problem with using zero parameter increment.  KM
\       2004-12-02  increased max curvature matrix size to 24x24  KM  
\       2006-03-17  modified original version to use FSL-style arrays and matrices  KM
\       2007-09-21  this file has been renamed from curvefit-fsl.4th
\                     to curvefit.4th; the original curvefit.4th is
\                     now obsolete, since we have deprecated the
\                     matrix package, matrix.4th  KM
\       2009-12-15  added error check in CURFIT to ensure that the
\                     number of terms passed to the routine does not exceed
\                     MAX_PARAMETERS  km
\
\  NOTES specific to this version of curvefit:
\
\  (1) There is no provision in FSL array structure for storing the length of the 
\        array. An error check is performed by CURFIT to ensure that the local arrays 
\        have been declared large enough to accomodate the number of points and
\        number of parameters for the fit. If not, the user may edit this file to
\        change the constants MAX_POINTS and/or MAX_PARAMETERS.
\
\  (2) The argument list for CURFIT was modified as a result of (1). The values of
\        NPTS, the number of points, and NTERMS, the number of fitting parameters
\        are now arguments to CURFIT.

CR .( CURVEFIT          V1.0b         15 December 2009   KM )

\ ------ Utilities for working with FSL arrays and matrices

: }}size@  ( a -- m | return number of columns in a matrix )
    2 CELLS - @ ;

: }}size!  ( m a -- | store the number of columns in the matrix, effectively resizing it )
    2 CELLS - ! ;
\ --------- End of array and matrix utilities

32 constant MAX_PARAMETERS
16384 constant MAX_POINTS

MAX_PARAMETERS MAX_PARAMETERS  FLOAT matrix  alpha{{
MAX_PARAMETERS MAX_PARAMETERS  FLOAT matrix  alph2{{
               MAX_PARAMETERS  FLOAT array   beta{
               MAX_PARAMETERS  FLOAT array   bet2{
               MAX_PARAMETERS  FLOAT array   deriv{
               MAX_PARAMETERS  FLOAT array   sigmaa{
               MAX_POINTS      FLOAT array   yfit{			\ array of fit data


0  ptr  xa{		\ address of x array (npts x 1)
0  ptr  ya{		\ address of y array (npts x 1)
0  ptr  aa{		\ address of parameter array (nterms x 1)
0  ptr  adel{		\  "       "    of increment array (nterms x 1)

variable npts
variable nterms
variable nfree
fvariable flamda 0.001e flamda f!
fvariable chisq1
fvariable chisqr

fvariable aj
fvariable delta

\ Evaluate reduced chi-square for fit to data

: fchisq ( -- chi-square)
	0e
	nfree @ 0>
	IF
	  npts @ 0 DO		\ Accumulate chi-square
	    ya{ I } F@  yfit{ I } F@  F- FDUP F* F+
	  LOOP

	  nfree @ s>f F/		\ divide by nfree 	  
	THEN	  
;



\ non-analytical derivative routine

: fderiv ( n -- | evaluate derivative of function at x_n )
	xa{ SWAP } F@
	nterms @ 0 DO
	  aa{ I } F@ aj F!
	  adel{ I } F@  FDUP 
	  F0= IF  FDROP 0e deriv{ I } F!	\ set derivative to zero if parameter inc is zero
	  ELSE
	    delta F!
            aj F@ delta F@ F+  aa{ I } F!
	    FDUP aa{ functn
	    aj F@ delta F@ F-
	    aa{ I } F!
	    FOVER aa{ functn
	    F- delta F@ F/ 2e F/  deriv{ I } F!
	    aj F@ aa{ I } F!
	  THEN
	LOOP
	FDROP
;	  


: curfit ( x y a deltaa nterms npts -- chisqr )   \ See Note (2)
        npts ! nterms !
	TO adel{  \ store address of increment array
	TO aa{    \ store address of parameter array
	TO ya{    \ store address of y array
	TO xa{    \ "          "  of x array
	
	npts @ MAX_POINTS > ABORT" Too may points for CURFIT"
	nterms @ MAX_PARAMETERS > ABORT" Too many parameters for CURFIT"
	npts @ nterms @ - nfree !

\ Set up sizes of alpha{{, alph2{{, beta{, b2{, deriv{, sigmaa{, and yfit{ matrices

	nterms @ alpha{{ }}size!
	nterms @ alph2{{ }}size!

\ Evaluate alpha and beta matrices

	nterms @ 0 DO
	  0e beta{ I } F!
	  I 1+ 0 DO  0e alpha{{ J I }} F!  LOOP
	LOOP

	npts @ 0 DO
	  I fderiv			\ call fderiv
	  nterms @ 0 DO
	    beta{ I } F@  ya{ J } F@  xa{ J } F@		
	    aa{ functn		\ call functn with x(j) and aa
	    F- 
	    deriv{ I } F@ F* F+ beta{ I } F!
	    
	    I 1+ 0 DO
	      alpha{{ J I }} F@	 deriv{ J } F@  deriv{ I } F@
	      F* F+ alpha{{ J I }} F!
	    LOOP
	  LOOP
	LOOP

	nterms @ 0 DO
	  I 1+ 0 DO
	    alpha{{ J I }} F@  alpha{{ I J }} F!
	  LOOP
	LOOP

\ Evaluate chi square at starting point

	npts @ 0 DO
	  xa{ I } F@  aa{ functn  
	  yfit{ I } F!
	LOOP

	fchisq	chisq1 F!		\ call fchisq

\ Invert modified curvature matrix to find new parameters

	BEGIN
	  nterms @ 0 DO
	    nterms @ 0 DO
	      alpha{{ J I }} F@  alpha{{ J J }} F@  alpha{{ I I }} F@
	      F* FDUP F0= IF FDROP FDROP 0e ELSE FSQRT F/ THEN
	      alph2{{ J I }} F!
	    LOOP
	    flamda F@ 1e F+  alph2{{ I I }} F!
	  LOOP

	  \ alph2{{ matinv  FDROP			\ call matinv

	  alph2{{ nterms @ mat^-1  ABORT" Singular Matrix!"

	  nterms @ 0 DO
	    aa{ I } F@  bet2{ I } F!
	    nterms @ 0 DO
	      bet2{ J } F@  beta{ I } F@  alph2{{ J I }} F@  F*
	      alpha{{ J J }} F@  alpha{{ I I }} F@ F* 
	      FDUP F0= IF FDROP FDROP 0e ELSE FSQRT F/ THEN 
	      F+ bet2{ J } F!
	    LOOP
	  LOOP

\ ." executed loop" cr

\ If chi-square increased, increase flamda and try again

	  npts @ 0 DO
	    xa{ I } F@ bet2{ functn  yfit{ I } F!
	  LOOP
	  fchisq chisqr F!	
	  chisq1 F@ chisqr F@ F<
	WHILE
	  flamda F@ 10e F* flamda F!
	REPEAT

\ Evaluate parameters and uncertainties


	nterms @ 0 DO
	  bet2{ I } F@  aa{ I } F!
	  alph2{{ I I }} F@  alpha{{ I I }} F@ F/ FSQRT  sigmaa{ I } F!
	LOOP

	flamda F@ 10e F/ flamda F!

	chisqr F@			\ return chi-square on stack
;
