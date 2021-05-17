\ sigfig-example.fs
\
\ Illustrate use of SET-PRECISION and FS. to display only
\ the meaningful digits in a calculation of the error
\ function, erf(x).
\
\ Requires:
\   fsl-util.fs
\   erf.fs
\
\ K. Myneni, 2011-02-09
\
\ Revisions:
\   2011-02-10  km  revised the words SIG-FIG and ERF1; SIG-FIG
\                     should now be generally applicable.
\  
\ ERF1 has the following maximum relative error in each of the
\   following ranges. We will use this information to output
\   the function with a proper number of significant digits.
\
\                         Max Rel. Error
\  ----------------------------------
\             x  <  -6.0   1.0e-16
\   -6.0  <=  x  <  -5.5   3.3e-16
\   -5.5  <=  x  <  -4.0   3.9e-10
\   -4.0  <=  x  <  -2.5   2.8e-6
\   -2.5  <=  x  <  -0.5   2.4e-5
\   -0.5  <=  x  <   0.1   5.9e-4
\    0.1  <=  x  <   2.0   1.8e-4
\    2.0  <=  x  <   2.5   1.4e-5
\    2.5  <=  x  <   3.1   2.8e-6
\    3.1  <=  x  <   3.8   1.5e-7
\    3.8  <=  x  <   4.0   1.7e-9
\    4.0  <=  x  <   4.4   3.9e-10
\    4.4  <=  x  <   5.0   1.5e-11
\    5.0  <=  x  <   5.5   6.4e-12
\    5.5  <=  x  <   6.0   6.2e-14
\    6.0  <=  x            1.0e-16

[undefined] f>s [IF] : f>s f>d d>s ; [THEN]

15 constant Nintervals
Nintervals    FLOAT ARRAY x{
Nintervals 1+ FLOAT ARRAY err{

-6.0e  -5.5e  -4.0e
-2.5e  -0.5e   0.1e
 2.0e   2.5e   3.1e
 3.8e   4.0e   4.4e
 5.0e   5.5e   6.0e 

Nintervals x{ }fput

 1.0e-16  3.3e-16  3.9e-10
 2.8e-6   2.4e-5   5.9e-4
 1.8e-4   1.4e-5   2.8e-6
 1.5e-7   1.7e-9   3.9e-10
 1.5e-11  6.4e-12  6.2e-14
 1.0e-16

Nintervals 1+ err{ }fput

\ Return the maximum relative error in ERF1 for a given argument
: lookup-err ( F: x -- relerr )
    Nintervals 0 DO
      fdup x{ I } f@ f< IF
        fdrop err{ I } f@ unloop EXIT
      THEN
    LOOP
    fdrop err{ Nintervals } f@
;

\ Return the number of significant figures for the specified 
\ result and absolute error; we need a ceiling function!
: sig-fig ( F: result abserr -- ) ( -- u )
    flog fnegate fswap fabs flog f+ 
    1e f+   \ really should use FCEIL
    f>s ;

\ Compute Erf(x) using the word ERF1 and output the result
\   to the proper number of significant figures
: erf1. ( F: r -- )
    fdup  erf1
    fswap lookup-err   \ F: erf(x) relerr
    fover f* fabs      \ F: erf(x) abserr
    f2dup sig-fig set-precision
    fdrop fs. ;





