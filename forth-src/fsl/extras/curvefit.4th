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
\  (fsl-util.4th), then define a fitting function which has the
\  following stack diagram:
\
\	( rx a -- ry )   or   ( a -- ) ( F: rx -- ry )
\
\  where rx is the x value at which the function is to be
\  evaluated and 'a' is the address of the array containing
\  the parameter values. The computed value for y is 
\  returned on the stack (or fpstack).
\
\  Input data (x, y) is passed to the fitter in two FSL arrays,
\  one containing the x values, the other containing the y values.
\  Starting parameters (best guess) for the fit, and reasonable
\  increments for the search, are also passed to the fitter.
\  A function parameter can be held fixed by setting its increment
\  to zero.   
\
\  Revised:
\
\  2003-12-17  fix problem with using zero parameter increment KM
\  2004-12-02  increased max curvature matrix size to 24x24  KM  
\  2006-03-17  modified original version to use FSL-style arrays 
\          and matrices  KM
\  2007-09-21  this file has been renamed from curvefit-fsl.4th
\          to curvefit.4th; the original curvefit.4th is now 
\          obsolete, since we have deprecated the matrix package,
\          matrix.4th  KM
\  2009-12-15  added error check in CURFIT to ensure that the
\          number of terms passed to the routine does not exceed
\          MAX_PARAMETERS  km
\  2023-11-14  Extensive revisions: set parameter uncertainty
\          to zero if parameter increment is zero; moved 
\          initialization stuff from CURFIT to INIT-CURVEFIT;
\          FLAMDA is renamed to LAMBDA, and initialized to 0.001
\          at the start of the fit by INIT-CURVEFIT; add default
\          tolerance for fractional change in chi-square for
\          CURFIT termination and SET-CHI-SQUARE-TOL for user
\          setting of this parameter; estimated parameter 
\          uncertainty array (sigmaa) and fitted curve array
\          (yfit) are now external inputs; fitting function
\          xt is passed to INIT-CURVEFIT; removed MAX_POINTS
\          and check on NPTS since relevant arrays are all external.
\
\  NOTES specific to this version of curvefit:
\
\  (1) INIT-CURVEFIT must be called first, prior to calling CURFIT.
\
\  (2) SET-CHI-SQUARE-TOL may be used to set a non-default
\      tolerance for the termination of CURFIT: when chi-square
\      increases by an amount less than the fraction tolerance,
\      CURFIT will not increase lambda and try again. The
\      selection of initial parameter increments is important!

CR .( CURVEFIT          V2.0          14 November 2023   KM )
BEGIN-MODULE

BASE @ DECIMAL

\ ------ Utilities for working with FSL arrays and matrices

: }}size@  ( a -- m | return number of columns in a matrix )
    2 CELLS - @ ;

: }}size!  ( m a -- | store the number of columns in the matrix, effectively resizing it )
    2 CELLS - ! ;
\ --------- End of array and matrix utilities

Public:

32 constant MAX_PARAMETERS

MAX_PARAMETERS MAX_PARAMETERS  FLOAT matrix  alpha{{  \ curvature matrix
MAX_PARAMETERS MAX_PARAMETERS  FLOAT matrix  alph2{{  \ modified curv. matrix and inverse
               MAX_PARAMETERS  FLOAT array   beta{    \ derivs of chi0^2 w.r.t. params
               MAX_PARAMETERS  FLOAT array   bet2{
               MAX_PARAMETERS  FLOAT array   deriv{   \ derivs of f(x) w.r.t. params

Private:

DEFER functn
0  ptr  xa{	\ address of x array (npts)
0  ptr  ya{	\ address of y array (npts)
0  ptr  yfit{   \ address of yfit array (npts)
0  ptr  aa{	\ address of parameter array (nterms)
0  ptr  adel{	\ address of parameter increment array (nterms)
0  ptr  asig{   \ address of parameter uncertainty array (nterms)

\ Default fractional tolerance on chi square for fit termination
1E-5 fconstant DEF_TOL_CHI_SQUARE
fvariable tol_chi_square

Public:

variable npts
variable nterms
variable nfree
fvariable lambda
fvariable chisq1
fvariable chisqr

\ Arguments to INIT-CURVEFIT are the following:
\
\   x       array for x values                       input
\   y       array for y values                       input
\   yfit    array for receiving computed fit curve   output
\   a       parameter array                          input/output
\   deltaa  parameter increment array                input
\   sigmaa  estimated parameter uncertainty array    output
\   nterms  number of parameters                     input
\   npts    number of points: (x,y) pairs            input
\   xtfunc  execution token for fitting function     input
\
\ The calling code must set up all of the above arrays and
\ define the fitting function prior to calling INIT-CURVEFIT

: init-curvefit ( x y yfit a deltaa sigmaa nterms npts xtfunc -- )
    IS functn
    npts ! nterms !
    TO asig{
    TO adel{
    TO aa{
    TO yfit{
    TO ya{ 
    TO xa{
    nterms @ MAX_PARAMETERS > ABORT" Too many parameters for CURFIT"
    npts @ nterms @ - nfree !

    \ Set up sizes of alpha{{ and alph2{{ matrices
    nterms @ alpha{{ }}size!
    nterms @ alph2{{ }}size!

    0.001e lambda f!
    DEF_TOL_CHI_SQUARE tol_chi_square f!
;

\ Provide user setting of non-default fractional 
\ chi-square tolerance for termination of CURFIT.
: set-chi-square-tol ( F: r -- )
    fdup F0> IF tol_chi_square f! ELSE fdrop THEN ;
    
\ Evaluate reduced chi-square for fit to data

: fchisq ( -- chi-square)
    0.0e0
    nfree @ 0> IF
      npts @ 0 DO		\ Accumulate chi-square
        ya{ I } F@  yfit{ I } F@  F- fsquare F+
      LOOP
      nfree @ s>f F/	\ divide by nfree 	  
    THEN ;

\ Non-analytical derivative routine
fvariable aj
fvariable delta

: fderiv ( n -- | evaluate derivative of function at x_n )
    xa{ SWAP } F@
    nterms @ 0 DO
      aa{ I } F@ aj F!
      adel{ I } F@  FDUP F0= IF  
        FDROP 0.0e0 \ derivative taken to be zero if parameter inc is zero
      ELSE
        delta F!
        aj F@ delta F@ F+  aa{ I } F!
        FDUP aa{ functn
        aj F@ delta F@ F-
        aa{ I } F!
        FOVER aa{ functn
        F- delta F@ F/ 2.0e0 F/
        aj F@ aa{ I } F!
      THEN
      deriv{ I } F!	
    LOOP
    FDROP
;	  

: curfit ( F: -- chisqr )   \ See Note (2)
    \ Initialize alpha matrix and beta array to zero.
    nterms @ 0 DO
      0.0e0 beta{ I } F!
      I 1+ 0 DO  0.0e0 alpha{{ J I }} F!  LOOP
    LOOP

    \ Compute new derivs and curvature matrix elements. 
    npts @ 0 DO
      I fderiv
      nterms @ 0 DO
        ya{ J } F@   xa{ J } F@  aa{ functn  F-
        deriv{ I } F@ F* beta{ I } F+!
        I 1+ 0 DO
          deriv{ J } F@  deriv{ I } F@ F* alpha{{ J I }} F+!
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
      xa{ I } F@  aa{ functn  yfit{ I } F!
    LOOP

    fchisq  chisq1 F!

    \ Compute modified curvature matrix and invert it
    \ to find new parameters

    BEGIN
      nterms @ 0 DO
        nterms @ 0 DO
          alpha{{ J I }} F@  
          alpha{{ J J }} F@  alpha{{ I I }} F@ F* 
          FDUP F0= IF F2DROP 0.0e0 ELSE FSQRT F/ THEN
          alph2{{ J I }} F!
        LOOP
        lambda F@ 1.0e0 F+  alph2{{ I I }} F!
      LOOP

      alph2{{ nterms @ mat^-1  ABORT" Singular Matrix!"

      nterms @ 0 DO
        aa{ I } F@  bet2{ I } F!
        nterms @ 0 DO  
          beta{ I } F@  alph2{{ J I }} F@  F*
          alpha{{ J J }} F@  alpha{{ I I }} F@ F* 
          FDUP F0= IF F2DROP 0.0e0 ELSE FSQRT F/ THEN 
          bet2{ J } F+!
        LOOP
      LOOP

      \ If chi-square increased, increase lambda and try again

      npts @ 0 DO
        xa{ I } F@ bet2{ functn  yfit{ I } F!
      LOOP
      fchisq chisqr F!	
      chisq1 F@ chisqr F@ f2dup F< >r
      F- FABS chisq1 F@ F/ tol_chi_square F@ F> r> and
    WHILE
      lambda F@ 10.0e0 F* lambda F!
    REPEAT

    \ Evaluate parameters and uncertainties

    nterms @ 0 DO
      bet2{ I } F@  aa{ I } F!
      adel{ I } F@ F0= IF
        0.0e0
      ELSE 
        alph2{{ I I }} F@  alpha{{ I I }} F@ F/ FSQRT
      THEN
      asig{ I } F!
    LOOP

    lambda F@ 10.0e0 F/ lambda F!
    chisqr F@			\ return chi-square on stack
;

BASE !
END-MODULE

