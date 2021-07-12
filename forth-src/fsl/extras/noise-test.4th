\ noise-test.4th
\
\ Generate random samples to check the probability distribution 
\   of the random numbers generated by ran0 and gauss in noise.4th. 
\
\ K. Myneni, 7-30-2001
\
\ Requires:
\   ans-words.4th
\   fsl-util.4th
\   horner.4th
\   noise.4th
\
\ Revisions:
\   2007-11-07  km; revised for new noise.4th (using FSL)

include ans-words
include fsl/fsl-util
include fsl/horner
include fsl/extras/noise

8192 3 FLOAT matrix samples{{

: go ( -- | generate the samples matrix)
    \ column 0 contains running index
    \ column 1 contains samples returned successively from ran0
    \ column 2 contains samples returned successively from gauss

    \ initialize IDUM

    time&date drop 30 * 24 * 3600 * swap 24 * 3600 * +
    swap 3600 * + swap 60 * + + 
    negate idum !

    8192 0 DO
	I s>f samples{{ I 0 }} F! 
	ran0  samples{{ I 1 }} F!
	gauss samples{{ I 2 }} F!
    LOOP ;

." The word 'go' generates the floating point matrix 'samples{{'" cr
." Column 0 is a running index" cr
." Column 1 are samples from a uniform distribution over the interval (0,1)" cr
." Column 2 are samples from a gaussian distribution (normal distribution)" cr
."   with zero mean and unit variance." cr cr
." You may write the samples matrix to a file called"
."   samples.dat by typing:" cr cr
." >file samples.dat 8192 3 samples{{ }}fprint console" cr cr

go

  





