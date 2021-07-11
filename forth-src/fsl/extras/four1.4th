\ four1.4th
\
\ Compute Fourier transform of array of complex values
\
\ This implementation is based on the routine four1() from Numerical Recipes 
\ in C, 2nd ed., by W.H. Press, S. A. Teukolsky, W. T. Vetterling, and
\ B. P. Flannery, Cambridge University Press, 1992.
\
\ Copyright (c) 2001,2006, 2009 Krishna Myneni
\ Original code Copyright (c) Numerical Recipes Software
\
\ Notes:
\
\  (0) The input array is an array of type FLOAT; thus, this routine will
\      perform a double precision FFT on most Forth systems.
\
\  (1) The number of values in the input array must be a power of 2.
\
\  (2) The transformed data is ordered in the manner described in Press, et.
\       al.
\
\ Requires:
\
\   ans-words.4th  (for kforth only)
\   fsl-util.4th
\   complex.4th
\
\ Revisions:
\   2000-08-16  km; added inverse FFT routine
\   2006-04-29  km; revised the Copyright statement and Notes.
\   2007-10-23  km; revised to use FSL arrays; renamed to }four1
\   2007-10-31  km; revised to use complex library (calculations simplify
\                   greatly); re-ordered arguments for consistency with fft
\                   word from fft-x86
\   2009-10-30  km; defined complex constant z=1, which is no longer
\                   provided by complex.4th
zvariable w
zvariable wp
1e 0e zconstant z=1

0 ptr data{
0 value isign
0 value Nvals
0 value N
0 value jj
0 value mm
0 value mmax
variable istep    

: }four1 ( nn isign 'a -- | replace 'a with its FFT or inverse FFT )
    TO data{ TO isign  2* TO Nvals
    0 TO jj

    Nvals 0 DO
	jj  I > IF		\ exchange two complex numbers
	    data{ I } z@  data{ JJ } z@   data{ I } z!  data{ JJ } z!
	THEN
	
	Nvals 2/ TO mm

	BEGIN
	    mm 2 >=  jj mm >= and
	WHILE
		jj mm -  TO jj
		mm 2/ TO mm
	REPEAT

	mm jj + TO jj
    2 +LOOP

    2 TO mmax

    BEGIN
	Nvals mmax >
    WHILE
	    mmax 2* istep !
	    6.28318530717959e0 mmax s>f F/
	    isign 0< IF fnegate THEN fdup 
	    0.5e F* fsin fdup F* -2e F*
	    fswap fsin wp z!

	    z=1 w z!

	    mmax 0 DO
		Nvals I DO
		    I mmax + TO jj
		    data{ jj } z@  w z@ z*
		    zdup data{ I } z@ zswap z-  data{ jj } z!
		    data{ I } z@ z+ data{ I } z!
		istep @ +LOOP

		w z@ zdup wp z@ z* z+ w z!
	    2 +LOOP
	  
	    istep @ TO mmax
    REPEAT
;
