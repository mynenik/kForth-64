\ gfit-curvefit.4th
\
\ Example of nonlinear curve fitting to data.
\
\ The fitting function is the sum of two Gaussian peaks and a flat baseline:
\
\	y = B + A1*exp{-(x-mu1)^2/(2*sigma1^2)} + A2*exp{-(x-mu2)^2/(2*sigma2^2)}
\
\ See the file func_Ngauss.4th for correct parameter ordering.
\
\ Copyright (c) 2006 Krishna Myneni, Provided under the GNU General Public 
\   License
\
\ Revisions:
\
\   2006-03-17  km; modified from gfit-fsl.4th 
\   2007-09-21  km; renamed this file to gfit.4th (original gfit.4th
\                   which used the original kForth matrix package
\                   is obsolete); also, curvefit-fsl.4th has been
\                   renamed to curvefit.4th and the original 
\                   curvefit.4th has been obsoleted.
\   2007-11-03  km; renamed this file to gfit-curvefit.4th
\   2007-11-21  km; use the generic N-gaussian function evaluator,
\                   func_Ngauss.4th, and modified parameter ordering
\                   accordingly
\   2016-06-04  km; update path for fitting function.

include ans-words
include fsl/fsl-util
include fsl/dynmem
include fsl/gaussj


\ Define the fitting function.

include fsl/extras/func_Ngauss
2 to Npeaks

include fsl/extras/curvefit   ( functn must be defined prior to loading curvefit)

FLOAT DARRAY  x{
FLOAT DARRAY  y{

0 value np	\ number of data points

: put_data ( y1 ... yn -- )
    & x{ np }malloc
    & y{ np }malloc

    np 0 DO  s>f y{ np 1- I - } F!  LOOP
    np 0 DO  I 1+ s>f x{ I } F!	 LOOP  \ x is a running index, starting at 1
;

include wfms01-1.dat	\ put the data from the file onto the stack
513 to np               \ number of data points in the file
put_data		\ move the data from the stack to the y matrix


7 value npar	\ number of fitting parameters

npar FLOAT ARRAY  a{
npar FLOAT ARRAY  deltaa{

\ Setup initial values for the function parameters:

-15000e ( B) 20000e ( A1) 206e ( mu1) 100e ( sigma1) 15000e ( A2) 390e ( mu2) 100e ( sigma2)
npar a{ }fput

\ Setup the initial parameter increments, i.e. the amount each parameter may be
\ varied to try to improve the fit. Any function parameter may be fixed to its
\ initial value by setting its corresponding increment to 0e.

1e ( dB) 1e ( dA1) 0.1e ( dmu1) 0.1e ( dsigma1) 1e ( dA2) 0.1e ( dmu2) 0.1e ( dsigma2)
npar deltaa{ }fput

: params. ( -- | display the current values of the parameters )
    cr npar 0 DO a{ I } F@ F. cr loop ;

: iterate ( -- | perform one iteration of curvefit and display results )
    x{ y{ a{ deltaa{ npar np curfit
    ." Fitted Parameters:" cr params. cr 
    CR ." reduced chi-squared = " F. ;


: genfit ( -- | display the fitted data values )
    \ You can redirect the output to a file to plot it with another program
    \   e.g. '>file fit.dat genfit console'
    np 0 do
	I s>f a{ functn         \ compute the fitted y value
	I 1+ . 2 spaces F. cr   \ print the x and y values
    loop ; 

cr cr
.( Initial Parameters are: ) cr params. cr cr
.( Type 'iterate' to execute curfit once and print the results.) cr
.( Continue to 'iterate' until chi-square converges.) cr cr
.( When the fit converges, you may write the fitted data to a file) cr
.(   by typing, '>file fit.dat genfit console') cr cr


