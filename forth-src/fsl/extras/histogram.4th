\ histogram.4th
\
\  Bin a series of values from a FLOAT ARRAY to 
\  create a histogram. 
\
\  Copyright (c) 1998 Krishna Myneni
\
\  This code may be used for any purpose, as long as the
\  copyright notice above is preserved.
\
\  Revisions: 
\    2002-01-01  km
\    2010-10-21  km  rewrite for FSL arrays, making use of
\                    array utilities.
\    2011-09-16  km  use Neal Bridges' anonymous modules.
\    2012-02-19  km  use KM/DNW's modules library.
\
\  Requires:
\   fsl-util.4th
\   dynmem.4th
\   array-utils0.4th
\   array-utils1.4th
\
\  Usage:
\
\  To create a histogram of the values in a FLOAT array of
\  u values, with a bin width specified by rwidth,
\
\	rwidth u arrayname }fhistogram
\
\  The histogram counts are stored in the dynamically allocated
\  integer array hist_counts{ .
\
\  A horizontal text plot of the histogram can be made by typing 
\
\	show-histogram
\
\  Free the histogram when it is no longer needed:
\
\       free-histogram

BEGIN-MODULE

BASE @
DECIMAL

Private:

FLOAT DARRAY hist_values{

fvariable hmax		\ max of data
fvariable hmin		\ min of data
fvariable hwidth	\ bin width

Public:

INTEGER DARRAY hist_counts{
variable nbins		\ number of bins

\ Bin the data in a FLOAT ARRAY with the specified bin width	
: }fhistogram ( fwidth u 'A -- )
	& hist_values{  &!  >r  hwidth f! 
	r@ hist_values{ }fmax hmax f!
	r@ hist_values{ }fmin hmin f!   
        r>

	\ Number of bins needed? Allocate array to hold counts.
	hmax F@ hmin F@ F- hwidth F@ F/  ftrunc>s 1+ nbins !
        & hist_counts{ nbins @ }malloc
	malloc-fail? ABORT" }fhistogram: Unable to allocate mem!"

	nbins @ hist_counts{ }izero	\ clear histogram counts

	0 ?DO
	  hist_values{ I } F@ hmin F@ F- 
          hwidth F@ F/ ftrunc>s >r	 \ bin number
	  1 hist_counts{ r> } +!         \ increment the bin count
	LOOP
;

Private:

variable hist_disp_scale

Public:

: show-histogram ( -- )
   \ Determine a scale factor for the counts
   \ nbins @ hist_counts{ }imax
   
   cr ." xx.xxexxx 0    5    10   15   20   25   30   35   40   45   50"
   cr ."           |____|____|____|____|____|____|____|____|____|____|_" cr
   nbins @ 0 ?DO  
      hist_counts{ I } @
      ."           |" 0 ?do 42 emit loop cr
   LOOP ;

\ Clean up 
: free-histogram ( -- )
    & hist_counts{ }free 
;


BASE !
END-MODULE
	  	
TEST-CODE? [IF]  \ ----------------------------------------
[undefined] ran0 [IF]
false to TEST-CODE? 
  s" fsl/horner"       included
  s" fsl/extras/noise" included  
[THEN]
BASE @
DECIMAL

512 constant NS
NS FLOAT ARRAY gnoise{
: gen-noise  NS 0 DO  gauss gnoise{ I } F!  LOOP ;

gen-noise
0.2e NS gnoise{ }fhistogram
cr cr
show-histogram
free-histogram

BASE !
[THEN]






