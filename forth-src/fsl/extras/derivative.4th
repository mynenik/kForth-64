\
\ derivative.4th
\
\ Compute the numerical derivative of a series of data values
\
\ Krishna Myneni, 30 Dec 1989
\ Revisions:
\	1990-08-30  km; Translated from QuickBasic to VAX FORTRAN
\       1991-10-02  km; Modified for Microsoft Fortran 5.0
\	2001-03-30  km; Translated to kForth
\       2007-06-02  km; use FSL-style array instead of kForth matrix package
\       2007-11-07  km; update comments
\
\ Requires:
\   fsl-util.4th

\ der_m is the n x 2 input matrix with column 0 containing
\   x values and column 1 containing y values. The y values
\   are replaced with the corresponding value of the derivative
\

0 ptr der{{
0 value Npts

fvariable dx1
fvariable dx2
fvariable last_y

\ derivative returns an integer error code with the following meaning:
\	0 = no error, derivative computed successfully;
\	1 = two points have same x value, derivative not computed.

: derivative ( 'mat npts  -- ierr)

    to Npts  to der{{

    \ Compute derivative at first pt with just two points.

    der{{ 1 0 }} F@  der{{ 0 0 }} F@  F- fdup dx1 F! \ x(1) - x(0)
    F0= IF 1 EXIT THEN	\ exit if dx = 0 between first two pts
    der{{ 1 1 }} F@	        \ y(2)
    der{{ 0 1 }} F@	        \ y(1)
    fdup last_y F!
    F- dx1 F@ F/  der{{ 0 1 }} F!

    \ Calculate derivative with average of forward and backward slopes.

    Npts 1- 1 DO
	der{{ I 1+ 0 }} F@   der{{ I 0 }} F@  F-  dx1 F! \ dx1 = x(i+1) - x(i)
	der{{ I 0 }} F@	  der{{ I 1- 0 }} F@  F-  dx2 F! \ dx2 = x(i) - x(i-1)
	
	dx1 F@ F0=  dx2 F@ F0=  or
	IF 1 unloop EXIT  THEN

	last_y F@  der{{ I 1 }} F@	       \ y(i-1)  y(i)
	fdup last_y F!  fswap F- dx2 F@ F/
	der{{ I 1+ 1 }} F@  last_y F@  F-      \ y(i+1) - y(i)
	dx1 F@ F/  F+ 2e F/  der{{ I 1 }} F!

    LOOP
    
    \ Compute derivate at last pt. using two pts.

    der{{ Npts 1- 0 }} F@  der{{ Npts 2 - 0 }} F@  F- fdup dx1 F!
    F0= IF 1 EXIT then	\ exit if dx = 0 between last two pts

    der{{ Npts 1- 1 }} F@  last_y F@ F-  dx1 F@ F/  der{{ Npts 1- 1 }} F!	

    0  \  Derivative computed successfully.
;

