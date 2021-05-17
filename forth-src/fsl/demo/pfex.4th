\ pfex.4th
\
\ Annotated example of using the polynomial fitting routine
\ under kforth.
\
\ K. Myneni, 5-10-2000
\
\ Requires:
\
\	ans-words.4th
\       fsl-util.4th
\       dynmem.4th
\       determ.4th
\	polyfit.4th
\
\ Revisions:
\       01-01-2002  cleaned up code  KM
\       09-18-2007  use new polyfit.4th module, with FSL-style arrays  KM
\       05/16/2021  update file paths.  KM
\
\ First load the necessary source files

include ans-words
include fsl/fsl-util
include fsl/dynmem
include fsl/extras/determ
include fsl/extras/polyfit


\ First create the x and y arrays (floating pt) to hold
\   the data to be fitted.

10 constant NP  ( the number of points we will fit)

NP FLOAT array x{
NP FLOAT array y{

\ Let's manually put in NP (10) values into the x and y arrays now.
\   I will use the data for y = x^2

0e  1e  2e  3e  4e  5e  6e  7e  8e  9e  NP x{ }fput
0e  1e  4e  9e 16e 25e 36e 49e 64e 81e  NP y{ }fput

\ You can verify that the x and y matrices have the correct
\   data in them by printing them out, e.g.
\
\	10 x{ }fprint
\	10 y{ }fprint


\ We also need an array to hold the fitted polynomial coefficients.

4 FLOAT array coeffs{


\ Now fit the data to a 2nd order polynomial, and print 
\   chi-square and the coefficients

x{ y{ coeffs{ 2 NP polfit

cr
." Chi-square = " f. cr
." The coefficients are: " cr   3 coeffs{ }fprint


