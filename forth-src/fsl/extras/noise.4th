\
\  noise.4th
\
\  Pseudo-random noise generation routines:
\
\    ran0	generates a random number between 0e and 1e with a
\		uniform distribution. Translated from Numerical Recipes
\		in C, by Press, et. al. 
\
\     gauss 	generates statistical noise with a normal distribution
\    		having mean of 0e and variance of 1e. Uses the output
\		of ran0 to generate a uniform deviate and
\ 		transforms this number into a normally distributed
\ 		deviate.
\
\     poisson-init  initialize the mean for a Poisson distribution
\
\     poisson-knuth generate a sample from a Poisson distribution.
\
\ Notes:
\
\ 1.  The formula for the inverse cumulative distribution function (CDF)
\     of a normal distribution is taken from Abramowitz and Stegun, p. 933.
\
\ 2.  Requires the FSL modules fsl-util.4th and  horner.4th
\
\
\ Copyright (c) 2001 Krishna Myneni
\ Original code for ran0 is Copyrighted by Numerical Recipes Software
\
\ Revisions:
\   2001-07-30  km; fixed gauss (flog -> fln)
\   2007-11-06  km; use FSL routine }Horner to simplify GAUSS
\   2010-10-26  km; revised for new names }FMEAN and }FVARIANCE in
\                     stats.4th; also use Private: and Public: to
\                     hide data.
\   2011-09-16  km; use Neal Bridges' anonymous modules
\   2012-02-19  km; use KM/DNW's modules library
\   2013-03-12  km; added Poisson random number generation:
\                     POISSON-INIT and POISSON-KNUTH

CR .( NOISE             V1.0e         12 March     2013   KM )
BEGIN-MODULE

BASE @ DECIMAL

Public:

variable idum

Private:

16807 constant IA
2147483647 constant IM
1e IM s>f f/ fconstant AM
127773 constant IQ
2836 constant IR
123459876 constant MASK

Public:

\ The word ran0 returns an observation from a uniform distribution
\   between 0. and 1.
\
\   Initialize the variable idum to any integer value prior to calling
\   ran0. Do not alter idum between calls for successive deviates in
\   a sequence.

: ran0 ( -- f )
    idum @ MASK xor dup idum !
    IQ / 
    dup IR * swap
    IQ * idum @ swap - IA *
    swap - idum !
    idum @ 0< IF  IM idum +!  THEN
    idum @ s>f AM f*
    idum @ MASK xor idum !	
;

Private:

variable iflag

3 FLOAT array C{
2.515517e  0.802853e  0.010328e  3 C{ }fput
4 FLOAT array D{
1e 1.432788e  0.189269e  0.001308e  4 D{ }fput

Public:

: gauss ( -- f | generate a pseudo-random number with a Gaussian distribution )

    false iflag !

    BEGIN  ran0  fdup  F0=  WHILE  fdrop  REPEAT

    fdup 0.5e F> dup iflag !
    IF  1e fswap F-  THEN			\ X

\ Compute the inverse of the CDF
\    
\ Equivalent FORTRAN code:
\
\ 	T = SQRT(LOG(1./X**2.))
\ 	XP = T - (C0+C1*T+C2*T**2.)/(1.+D1*T+D2*T**2.+D3*T**3.)
\ 	IF (IFLAG) XP = -XP

    fdup F* 1e fswap F/ fln fsqrt
    fdup C{ 2 }Horner  fover D{ 3 }Horner F/ F-
    iflag @ IF fnegate THEN
;


\ Generate an integer random number from a Poisson distribution,
\   with mean lambda. Initialize idum to seed the RNG.
Private:

fvariable lambda
fvariable lk
fvariable p

Public:

\ Execute POISSON-INIT before using Poisson RNGs.
: poisson-init ( flambda -- ) fdup lambda f! fnegate fexp lk f! ;

\ Knuth's algorithm for generating a Poisson random number;
\ see http://en.wikipedia.org/wiki/Poisson_distribution
: poisson-knuth ( -- u )
    1e 0 BEGIN  1+ >r ran0 f* fdup lk f@ f<= r> swap UNTIL
    >r fdrop r> 1-  
;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
[undefined] }fmean  [IF]  include fsl/extras/stats.4th    [THEN]
BASE @ DECIMAL


32768 constant Nsamples
Nsamples FLOAT array r{

21648 idum !  \ arbitrary seed for ran0

Defer generator

: sample  ( xt -- | sample random values from a specified distribution)
    IS generator
    Nsamples 0 DO generator  r{ I } F! LOOP ;

1e-2 rel-near F!
1e-2 abs-near F!
set-near

\ These tests only verify, roughly, the distributions of the random
\ samples --- they do not check for correlations between the samples.
\ Only the first two moments of the distributions, mean and variance,
\ are tested. Tests of higher order moments, skewness and kurtosis,
\ may also be useful.
\
\ For an ideal uniform distribution over the interval (0,1), it is
\ obvious that the mean will be 1/2, and it is not hard to verify, by
\ integration of the anlaytic expression for the variance of a
\ continuous probability density function, that the variance is 1/12. 

\ NOTE: Because we are using a finite sample size of the pseudo-random
\ numbers, there is some probability that the tests will fail, even when
\ the tolerances is set low (1e-2)! The probability of failure should
\ decrease with increased sample size.

CR
TESTING RAN0
t{ ' ran0 sample ->  }t
t{ Nsamples r{ }fmean     -> 0.5e r}t
t{ Nsamples r{ }fvariance -> 1e 12e F/ r}t

TESTING GAUSS
t{ ' gauss sample ->  }t
t{ Nsamples r{ }fmean     -> 0e r}t
t{ Nsamples r{ }fvariance -> 1e r}t

TESTING POISSON-KNUTH
: pgen poisson-knuth s>f ;
t{ 20e poisson-init ->  }t

t{ ' pgen sample ->  }t
t{ Nsamples r{ }fmean     -> 20e r}t
t{ Nsamples r{ }fvariance -> 20e r}t

BASE !
[THEN]
