\ stats.4th
\
\ Compute the mean and variance of a set of floating point numbers
\
\ Examples: See test code
\
\ Requires:
\   fsl-util.4th
\
\ Copyright (c) 1998, 2003 Krishna Myneni
\ Revisions:
\   1998-12-22
\   2003-11-06  km; added probability density function calculations:
\	            PGAUSS, AGAUSS, AREA_GAUSS
\   2007-11-09  km; revised for FSL compatibility
\   2010-10-26  km; renamed }mean and }variance to }fmean and
\                   }fvariance for consistency with array-utils
\                   naming convention; also use Private: and
\                   Public: to hide transient variables
\   2011-09-16  km; use Neal Bridges' anonymous modules.
\   2012-02-19  km; use KM/DNW's modules library
\   2013-03-12  km; fix stack comment for .STATS
\   2017-04-21  km; added }IMEAN and }IVARIANCE ; made .stats
\                   a private word and provided }ISTATS. and }FSTATS.
\   2023-12-05  km; replaced FDUP F* with FSQUARE

CR .( STATS             V1.1h          05 December  2023   KM )
BEGIN-MODULE

BASE @ 
DECIMAL

Private:

0 ptr arr{
fvariable mu
fvariable sigma2

: .stats ( -- )
    mu f@     ." Mean = " F. cr
    sigma2 f@ ." Variance = " F. cr
;

Public:
0 value Nsamples

: }imean ( u 'a -- fmu | mean of integer array )
    TO arr{ TO Nsamples
    0 Nsamples 0 ?DO  arr{ I } @ +  LOOP s>f Nsamples s>f F/
    fdup mu f! ;

: }ivariance ( u 'a -- fsigma2 | variance of integer array )
    }imean
    0e Nsamples 0 ?DO fover arr{ I } @ s>f F- fsquare F+ LOOP
    fswap fdrop 
    Nsamples 1- s>f F/ 
    fdup sigma2 F! ;   
 
: }fmean ( u 'a -- fmu | mean of floating point array )
    TO arr{ TO Nsamples
    0e Nsamples 0 ?DO  arr{ I } F@ F+  LOOP Nsamples s>f F/  
    fdup mu f! ;

: }fvariance ( u 'a -- fsigma2 | variance of floating point array )
    }fmean
    0e Nsamples 0 ?DO fover arr{ I } F@ F- fsquare F+ LOOP
    fswap fdrop 
    Nsamples 1- s>f F/ 
    fdup sigma2 F! ;

: }istats. ( u 'a -- | compute and print statistics for integer array )
    }ivariance  fdrop .stats ;

: }fstats. ( u 'a -- | compute and print statistics for fp array )
    }fvariance  fdrop .stats ;

2e fsqrt fconstant sqrt{2}
	
\ The words pgauss and agauss are translated from corresponding
\ Fortran functions in P.R. Bevington, Data Reduction and Error 
\ Analysis for the Physical Sciences, 1969, McGraw-Hill.

: pgauss ( fx fmu fsigma -- fpdf | evaluate gaussian probability density at fx)
    fdup F0= ABORT" PGAUSS: zero sigma value"
    2>r F- 2r@ F/ fsquare 2e F/ fnegate fexp
    0.3989422804e F* 2r> F/ ;

\ Evaluate area between the limits (mu - z*sigma) to (mu + z*sigma)
\   where z = |x-mu|/sigma, e.g. if mu = 0, the area is computed
\   between -x and +x.  

Private:

fvariable agauss_term
fvariable agauss_sum
fvariable agauss_denom

Public:

: agauss ( fx fmu fsigma -- farea )
    fdup  F0= ABORT" AGAUSS: zero sigma value"
    2>r F- 2r> F/ fabs			\ -- z
    fdup  0e F<= IF fdrop 0e exit THEN	\ -- z
    fdup  sqrt{2} F/			\ -- z term
    fdup  agauss_term F! agauss_sum F!	\ -- z
    fsquare 2e F/			\ -- y2		
       
       \ Accumulate sum of terms

    1e agauss_denom F!

    BEGIN
	fdup 2e F*					\ -- y2 2*y2
        agauss_denom F@ 2e F+ fdup agauss_denom F! F/	\ -- y2 2*y2/denom
	agauss_term F@ F* fdup				
	agauss_sum F@ F+ agauss_sum F!
	fdup agauss_term F!
	agauss_sum F@ F/ 1e-10 F<=
    UNTIL

    fnegate fexp agauss_sum F@ F* 1.128379167e F*
;
	 
\ Return area between x1 and x2 for Gaussian probability density function

Private:

fvariable agauss_mu
fvariable agauss_sigma

Public:

: area_gauss ( fx1 fx2 fmu fsigma -- farea )
    fdup F0= ABORT" AREA_GAUSS: zero sigma value" 
    agauss_sigma F! 
    agauss_mu F!			\ -- fx1 fx2
    agauss_mu F@  F-  fswap 
    agauss_mu F@  F-  fswap		\ -- fx1-fmu  fx2-fmu
    fover fover F* 0e F>  >r 
    fabs  0e  agauss_sigma F@  agauss  fswap
    fabs  0e  agauss_sigma F@  agauss
    r>
    IF    F- fabs		       \ (x1-mu) and (x2-mu) have same sign?
    ELSE  F+			       \ (x1-mu) and (x2-mu) have opposite sign
    THEN  2e F/   
;

BASE !
END-MODULE

TEST-CODE? [IF]   \ test code ==============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

1e-7 rel-near F!
1e-7 abs-near F!
set-near

(  
\ Test code for Gaussian probability functions

: test_gauss \ -- | print a table of values for mu = 0, sigma =1
    0e
    BEGIN
      cr
      fdup f. 2 spaces 
      fdup 0e 1e pgauss f. 2 spaces
      fdup 0e 1e agauss f. 2 spaces
      fdup fnegate fover 0e 1e area_gauss f.
      0.1e f+ 
      fdup 3e f>
    UNTIL
    fdrop cr ;
)

BASE !
[THEN]


