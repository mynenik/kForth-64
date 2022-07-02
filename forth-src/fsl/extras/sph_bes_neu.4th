\ sph_bes_neu.4th
\
\ Spherical Bessel and Neumann functions for large index range
\
\ Use recurrence relations to compute the spherical Bessel and 
\ Neumann functions, j_l(x) and n_l(x), for l over the range
\ 0 to 999. The relative accuracy of j_l(x) and n_l(x) is 
\ better than 5e-16 for x <= 100, for l=0 to 100 -- see test
\ code below.
\
\ The computed function values for different l's are stored in
\ arrays rbes{ and rneu{ with l as the index. 
\ 
\ The recursive algorithm implemented here is the one from Ref. 1.
\ The computed functions have standard normalization, e.g.
\
\   j_0(x) = sin(x)/x
\   j_1(x) = sin(x)/x^2 - cos(x)/x
\   j_2(x) = (3/x^3 - 1/x)*sin(x) - (3/x^2)*cos(x)
\   ...
\   n_0(x) = -cos(x)/x
\   n_1(x) = -cos(x)/x^2 - sin(x)/x
\   n_2(x) = -(3/x^3 - 1/x)*cos(x) -(3/x^2)*sin(x)
\
\ Forth version by Krishna Myneni, 2022-07-02
\
\ References
\   1. E. Gillman and H. R. Fiebig, "Accurate recursive generation
\      of spherical Bessel and Neumann functions for a large range
\      of indices," Computers in Physics vol. 2, p. 62 (1988).
\
\ Notes:
\   1. The floating point words FSIN and FCOS are used separately
\      to obtain the sin and cos of the arguments, instead of
\      FSINCOS. In kForth, FSIN and FCOS use the C math library,
\      which, under Linux, provides much higher accuracy for large
\      arguments than using the word FSINCOS which calls the f.p.u.
\      instruction of the same name.
\
\   2. Reference values for test code are computed using the
\      functions, SphericalBesselJ[l,x] and SphericalBesselY[l,x]
\      on Wolfram Alpha.

[UNDEFINED] square  [IF] : square  dup * ;   [THEN]
[UNDEFINED] fsquare [IF] : fsquare fdup f* ; [THEN]

BEGIN-MODULE
BASE @ DECIMAL

fvariable cx
fvariable sx
fvariable cu
fvariable cv
0 value lu
0 value lv
0 value w

Public:

1000 value MAX-L
MAX-L FLOAT ARRAY rbes{
MAX-L FLOAT ARRAY rneu{

: sphfuncs ( F: x -- )
    \ Set starting values j_lmax-1(x) and n_0(x) for recursion
    1.0e0 fdup rbes{ MAX-L 1- } f!  rbes{ MAX-L 2- } f!
    fdup fsin sx f!
    fdup fcos fdup cx f!   rneu{ 0 } f!
    fdup sx f@ f* cx f@ f+ rneu{ 1 } f!

    fdup fsquare         \ F: x x^2

    \ Recursively generate j_l(x) and n_l(x)
    MAX-L 2 DO
      MAX-L I - to lu
      I 2- to lv
      fdup lv 1+ square 4 * 1- s>f f/
      rneu{ lv } f@ f* fnegate rneu{ lv 1+ } f@ f+ rneu{ lv 2+ } f!
      fdup lu 1+ square 4 * 1- s>f f/
      rbes{ lu 1+ } f@ f* fnegate rbes{ lu } f@ f+ rbes{ lu 1- } f!
    LOOP                 \ F: x x^2

    \ Scale j_l(x)
    3.0e0 f/ rbes{ 1 } f@ f* cx f@ f* fnegate
    rbes{ 0 } f@ rneu{ 1 } f@ f* f+
    MAX-L 0 DO  rbes{ I } f@ fover f/ rbes{ I } f!  LOOP
    fdrop                \ F: x

    \ Normalize j_l(x) and n_l(x)
    1.0e0 fover f/ cu f!
    -1.0e0         cv f! \ F: x
    MAX-L 0 DO
      I 2* to w
      fdup w 1+ s>f  f/  cu f@ f* fdup cu f!
      rbes{ I } f@ f* rbes{ I } f!
      w 1- s>f fover f/  cv f@ f* fdup cv f!
      rneu{ I } f@ f* fnegate rneu{ I } f!
    LOOP
    fdrop
;

BASE !
END-MODULE

TEST-CODE? [IF]
[UNDEFINED] T{ [IF] include ttester.4th [THEN]
BASE @ DECIMAL

1e-16  abs-near f!
5e-16  rel-near f!
set-near

TESTING SPHFUNCS
t{ 0.1e0 sphfuncs -> }t
t{ rbes{ 0 }   f@  ->  9.98334166468281523E-001 r}t  \ j_0  (0.1)
t{ rbes{ 10 }  f@  ->  7.27151099671367155E-021 r}t  \ j_10 (0.1)
t{ rbes{ 100 } f@  ->  7.46290351349733307E-290 r}t  \ j_100(0.1)
t{ rneu{ 0 }   f@  -> -9.95004165278025766E+000 r}t  \ n_0  (0.1)
t{ rneu{ 10 }  f@  -> -6.54901397465628083E+019 r}t  \ n_10 (0.1)
t{ rneu{ 100 } f@  -> -6.66647616739126082E+287 r}t  \ n_100(0.1)
t{ 1.0e0 sphfuncs -> }t
t{ rbes{ 0 }   f@  ->  8.41470984807896507E-001 r}t  \ j_0  (1)
t{ rbes{ 10 }  f@  ->  7.11655264004731302E-011 r}t  \ j_10 (1)
t{ rbes{ 100 } f@  ->  7.44472774166107689E-190 r}t  \ j_100(1)
t{ rneu{ 0 }   f@  -> -5.40302305868139717E-001 r}t  \ n_0  (1)
t{ rneu{ 10 }  f@  -> -6.72215008256208444E+008 r}t  \ n_10 (1)
t{ rneu{ 100 } f@  -> -6.68307946325867751E+186 r}t  \ n_100(1)
t{ 10.0e0 sphfuncs -> }t
t{ rbes{ 0 }   f@  -> -5.44021110889369813E-002 r}t  \ j_0  (10)
t{ rbes{ 10 }  f@  ->  6.46051544925642643E-002 r}t  \ j_10 (10)
t{ rbes{ 100 } f@  ->  5.83204018200587675E-090 r}t  \ j_100(10)
t{ rneu{ 0 }   f@  ->  8.39071529076452452E-002 r}t  \ n_0  (10)
t{ rneu{ 10 }  f@  -> -1.72453672088057849E-001 r}t  \ n_10 (10)
t{ rneu{ 100 } f@  -> -8.57322630932998279E+085 r}t  \ n_100(10)
t{ 100.0e0 sphfuncs -> }t
t{ rbes{ 0 }   f@  -> -5.06365641109758794E-003 r}t  \ j_0  (100)
t{ rbes{ 10 }  f@  -> -1.95657859713429006E-004 r}t  \ j_10 (100)
t{ rbes{ 100 } f@  ->  1.08804770114383365E-002 r}t  \ j_100(100)
t{ rneu{ 0 }   f@  -> -8.62318872287683934E-003 r}t  \ n_0  (100)
t{ rneu{ 10 }  f@  ->  1.00257773736361539E-002 r}t  \ n_10 (100)
t{ rneu{ 100 } f@  -> -2.29838504915622810E-002 r}t  \ n_100(100)
t{ 200.0e0 sphfuncs -> }t
t{ rbes{ 0 }   f@  -> -4.36648648606997291E-003 r}t  \ j_0  (200)
t{ rbes{ 10 }  f@  ->  3.54317289031424494E-003 r}t  \ j_10 (200)
t{ rbes{ 100 } f@  -> -1.93609723624755680E-003 r}t  \ j_100(200)
t{ rbes{ 200 } f@  ->  6.24553158028404332E-003 r}t  \ j_200(200)
t{ rbes{ 300 } f@  ->  7.62022360196212765E-032 r}t  \ j_300(200)
t{ rneu{ 0 }   f@  -> -2.43593837503502955E-003 r}t  \ n_0  (200)
t{ rneu{ 10 }  f@  ->  3.53275680310172060E-003 r}t  \ n_10 (200)
t{ rneu{ 100 } f@  -> -5.01666824197730591E-003 r}t  \ n_100(200)
t{ rneu{ 200 } f@  -> -1.26612996092208560E-002 r}t  \ n_200(200)
t{ rneu{ 300 } f@  -> -1.46283071227275816E+026 r}t  \ n_300(200)

BASE !
[THEN]
