\ func_Ngauss.4th
\
\  N overlapping Gaussian peaks
\
\  y = B + SUM_i{ A_i*exp(-(x-mu_i)^2/(2*sig_i^2)) }
\
\  Parameter array is ordered as follows
\
\	0    B      baseline
\	1    A_1
\	2    mu_1
\	3    sig_1
\	4    A_2
\	5    mu_2
\	6    sig_2
\       7    A_3
\       :     :
\       :     :
\
\ Notes:
\
\ 1. Make sure to set the value Npeaks to the number of peaks to be
\      fitted prior to calling functn


0 value Npeaks
0 ptr   params{
fvariable fx
0 value idx

: functn ( fx 'a -- fy )
    TO params{  fx F!
    params{ 0 } F@
    Npeaks 0 ?DO
	I 3 * 1+ TO idx           \ index of first param for each peak
	params{ idx 1+ } F@ fx F@ F- FDUP F*
	params{ idx 2+ } F@ FDUP F* 2e F* F/
	FNEGATE FEXP
	params{ idx } F@ F*
	F+
    LOOP
;

