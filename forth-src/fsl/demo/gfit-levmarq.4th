\ gfit-levmarq.4th
\
\ Fit a double Gaussian function to data using the FSL Levenberg-Marquardt 
\ fitting routines (see levmarq.4th). 
\
\ The fitting function is:
\
\	y = A*exp{-(x-mu1)^2/(2*sigma1^2)} + B*exp{-(x-mu2)^2/(2*sigma2^2)} + C
\
\ The parameters are stored in the array a{ in the following sequence:
\
\	A, mu1, sigma1, B, mu2, sigma2, C
\
\ Copyright (c) 2004 Krishna Myneni, Provided under the GNU General Public 
\   License
\
\ Revisions:
\
\   2004-01-03  created
\   2007-11-03  renamed to gfit-levmarq.4th
\   2021-07-09  updated file paths, replaced DEFINES with IS

include ans-words
include fsl/fsl-util
include fsl/dynmem
include fsl/gaussj
include fsl/levmarq

\ Define the fitting function. Computes the y value and the derivatives dy/da.
\ Derivatives are computed from analytic expressions.

0 ptr arr{
0 ptr dyda{
fvariable fx

: f2gauss ( fx 'a 'dyda -- fy )
	to dyda{
	to arr{
	fdup fx f!
	arr{ 1 } f@ f- fsquare
	arr{ 2 } f@ fsquare 2e f* f/
	fnegate fexp
	fdup dyda{ 0 } f!
	arr{ 0 } f@ f*
	fx f@
	arr{ 4 } f@ f- fsquare
	arr{ 5 } f@ fsquare 2e f* f/
	fnegate fexp
	fdup dyda{ 3 } f!
	arr{ 3 } f@ f*
	f+
	arr{ 6 } f@ f+
	arr{ 0 } f@ arr{ 2 } f@ fsquare f/ fx f@ arr{ 1 } f@ f- f*
	dyda{ 0 } f@ f* dyda{ 1 } f!
	arr{ 3 } f@ arr{ 5 } f@ fsquare f/ fx f@ arr{ 4 } f@ f- f*
	dyda{ 3 } f@ f* dyda{ 4 } f!
	dyda{ 1 } f@ fx f@ arr{ 1 } f@ f- f* arr{ 2 } f@ f/ 
	dyda{ 2 } f!
	dyda{ 4 } f@ fx f@ arr{ 4 } f@ f- f* arr{ 5 } f@ f/
	dyda{ 5 } f!
	1e dyda{ 6 } f! ;

& f2gauss IS MrqFitter
	

FLOAT DARRAY  x{
FLOAT DARRAY  y{

0 value npts	\ number of data points
7 value npar	\ number of parameters

: put_data ( y1 ... yn -- )
	& x{ npts }malloc
	& y{ npts }malloc

	npts 0 do
	  s>f y{ npts i - 1- } F!
	  i 1+ s>f x{ i } F!	\ x is a running index
	loop

;

include wfms01-1.dat	\ put the data from the file onto the stack
513 to npts 		\ number of data points in the file
put_data		\ move the data from the stack to the y matrix


npar FLOAT ARRAY  a{

\ Setup initial values for the function parameters
\   ( see func_2gauss.4th for meaning of parameters) 

20000e  a{ 0 }  F!	\ A
206e    a{ 1 }  F!	\ mu1
100e    a{ 2 }  F!	\ sigma1
15000e  a{ 3 }  F!	\ B
390e    a{ 4 }  F!	\ mu2
100e    a{ 5 }  F!	\ sigma2
-15000e a{ 6 }  F!	\ C

FLOAT DARRAY  sig{
INTEGER DARRAY  lista{
FLOAT DMATRIX covar{{
FLOAT DMATRIX alpha{{

: init ( -- | Initialize the curve-fitting routine )
	\ allocate auxiliary matrices

	& sig{ npts }malloc
	& lista{ npar }malloc
	& covar{{ npar npar }}malloc
	& alpha{{ npar npar }}malloc

	npts 0 DO 1e sig{ i } F! LOOP
	npar 0 DO i lista{ i } ! LOOP	\ fit all parameters
	x{ y{ sig{ npts a{ npar lista{ npar covar{{ alpha{{   setup-marquardt
;

init


: params. ( -- | display the current values of the parameters )
	cr npar 0 DO a{ i } f@ f. cr loop ;

: iterate ( -- | perform one iteration of curvefit and display results )
	mrqminimize ABORT" singular matrix"
	params. 
	CR ." reduced chi-squared = " chisq f@ npts npar - s>f f/ f. ;


: genfit ( -- | display the fitted data values )
	\ You can redirect the output to a file to plot it with another program
	\   e.g. '>file fit.dat genfit console'
	npts 0 do
	  i s>f a{ dyda{ f2gauss  \ compute the fitted y value
	  i 1+ . 2 spaces f. cr   \ print the x and y values
	loop ; 

cr cr
.( Initial Parameters are: ) cr params. cr cr
.( Type 'iterate' to execute mrqminimize once and print the results.) cr
.( Continue to 'iterate' until chi-square converges.) cr cr
.( When the fit converges, you may write the fitted data to a file) cr
.(   by typing, '>file fit.dat genfit console') cr cr




