\ voigt.4th
\
\ Calculate the convolution of Gaussian and Lorentzian functions. 
\
\ The Voigt function, which arises frequently in spectroscopy, is 
\ related to the Faddeeva function, w(z), through the relation,
\ 
\         K(x, y) = Re(w(z))
\
\ with  z = x + i*y.
\ 
\ x is the normalized detuning from line center, defined by
\
\         x = sqrt(ln(2)) * Delta/gamma_G
\
\ where Delta is the detuning from line center, and gamma_G is
\ the half-width at half-maximum (HWHM) for the Gaussian profile.
\
\ y is the ratio of the widths of the Lorentzian and Gaussian
\ profiles,
\
\         y = sqrt(ln(2)) * gamma_L/gamma_G
\
\ where gamma_L is the width (HWHM) for the Lorentzian profile.
\
\
\ Alternatively, the normalized Voigt probability density function 
\ is given by
\
\         V(x; sigma, gamma_L) = (1/sqrt(2pi))* Re(w(z))/sigma
\
\ with
\
\         z = (x + i*gamma_L)/(sigma*sqrt(2))
\
\ where  sigma is the standard deviation of the Gaussian distribution, and
\ gamma_L is the HWHM width for the Lorentzian distribution. The relation
\ between sigma and gamma_G is
\
\         sigma = gamma_G/sqrt(2*ln(2)) 
\
\ Notes:
\
\ 1. The widths of the constituent Gaussian and Lorentzian profiles MUST
\    FIRST BE SET, prior to calling any of the Voigt function words. Two
\    methods may be used:
\
\    a) Specify the full-width at half maximum (FWHM) of the Gaussian and 
\       Lorentzian profiles, Gamma_G and Gamma_L. Use the word, 
\
\           set-fwhm-widths
\
\       to specify the FWHM widths of the constituent profiles.
\
\    b) Speciy the standard deviation (sigma) of the Gaussian, and the 
\       half-width at half-maximum (gamma_L) of the Lorentzian. Use
\
\           set-sd-hwhm-widths
\
\ 2. The approach used here computes the complex function, w(z), using the
\    high-accuracy algorithm, zwofz. For lengthy spectral calculations, or
\    for least-squares fitting of Voigt profiles to data, a faster approach 
\    may be needed. A fast, but less accurate method of computing the Voigt 
\    profile, with a relative error between 1e-2 and 1e-5, is given in ref. [2].
\
\ 3. Reference values to six significant digits are provided in ref. [4].
\
\ References:
\
\ 1. W. Demtroeder, Laser Spectroscopy: Basic Concepts and Instrumentation, 
\    3rd ed., 2003.
\
\ 2. R.J. Wells, Rapid Approximation to the Voigt/Faddeeva Function and its
\    Derivatives, Journal of Quantitative Spectroscopy and Radiative Transfer,
\    v. 62, p. 29 (1999). 
\
\ 3. http://en.wikipedia.org/wiki/Voigt_profile
\
\ 4. C. Young, Tables for calculating the Voigt profile, Technical Report,
\    College of Engineering, University of Michigan, July 1965, available
\    online at   http://hdl.handle.net/2027.42/8438
\
\ 
\ Copyright (c) 2009--2022 Krishna Myneni, krishna.myneni@ccreweb.org
\ Provided under the LGPL
\
\ Revisions:
\   2009-08-21  km  v1.0
\   2022-05-10  km  v1.1; fixed bug in SET-FWHM-WIDTHS with
\                   computing V_Y (imaginary part of z);
\                   modified test code accordingly.
\
\ Requires fsl-util.4th zwofz.4th
[UNDEFINED] zwofz [IF] include zwofz [THEN]
CR .( VOIGT             V1.1      10 May  2022 )
BASE @
DECIMAL

2e fsqrt           fconstant  SQRT_2
2e PI f* fsqrt     fconstant  SQRT_2PI 
2e fln fsqrt       fconstant  SQRT_LN2
2e fln 2e f* fsqrt fconstant  SQRT_2LN2

\ Convert between width at half-max of Gaussian profile and its s.d.
: fwhm>sigma ( F: Gamma -- sigma ) 2e f/ SQRT_2LN2 f/ ;
: sigma>fwhm ( F: sigma -- Gamma ) 2e f* SQRT_2LN2 f* ;

\ parameters which are functions of the Gaussian and Lorentzian widths
fvariable v_y
fvariable v_gamma
fvariable v_sigma
fvariable v_xscale
fvariable v_vscale
fvariable v_im_z

\ Set Gaussian and Lorentzian widths, and associated parameters for the 
\ Voigt profile calculations. This must be done once, either with 
\ set-fwhm-widths, or with set-sd-hwhm-widths, prior to using the 
\ functions, K(x,y), L(x), G(x), or V(x).

: set-voigt-params ( -- )  \ helper word
     v_sigma f@ 
     fdup SQRT_2PI f*       v_vscale f!   \ scale factor for V(x) 
     SQRT_2 f* fdup         v_xscale f!   \ scale factor for x>z
     v_gamma f@ fswap f/    v_im_z   f!   \ imaginary part of z
;

: set-fwhm-widths ( F: Gamma_G  Gamma_L -- )
     f2dup fswap f/ SQRT_LN2 f* v_y  f!  \ value of y for K(x,y)
     2e f/                  v_gamma  f!  \ Lorentzian HWHM
     fwhm>sigma             v_sigma  f!  \ Gaussian s.d.
     set-voigt-params
;

: set-sd-hwhm-widths ( F: sigma gamma_L -- )
     f2dup fswap SQRT_2 f* f/  v_y      f!
                               v_gamma  f!
                               v_sigma  f!
     set-voigt-params
; 

\ Default width values
1e 1e set-fwhm-widths

\ Lorentzian probability density function
: L(x) ( F: x -- L[x] )
     v_gamma f@ fswap fdup f* fover fdup f* f+ f/ pi f/ ; 

\ Gaussian probability density function
: G(x) ( F: x -- G[x] )
    v_sigma f@ fswap fdup f* fover fdup f* 2e f* f/ fnegate fexp 
    fswap SQRT_2PI f* f/ ;

\ standard form of the Voigt function used in spectroscopy
: K(x,y) ( F: x -- K[x,y] )
     v_y f@ zwofz drop fdrop ;

: x>z ( F: x -- z )
     v_xscale f@ f/  v_im_z f@ ;

\ Voigt probability density function
\ returns NaN if both v_sigma and v_gamma are zero.
: Voigt ( F: x -- V[x] )
     v_sigma f@ f0= IF
       L(x)
     ELSE
       v_gamma f@ f0= IF
         G(x)
       ELSE
         x>z  zwofz drop fdrop       \ F: Re(w(z))
         v_vscale f@ f/ 
       THEN
     THEN
;

BASE !

test-code? [IF]
[UNDEFINED] T{ [IF] include ttester [THEN]
[UNDEFINED] )integral [IF] false to test-code? include fsl/adaptint [THEN]
BASE @
DECIMAL

CR TESTING G(x), L(x)
1e-15  rel-near f!
1e-256 abs-near f!
set-near
t{ 1e 0e set-sd-hwhm-widths  v_sigma f@  v_gamma f@  ->  1e 0e  rr}t 
t{  0e G(x)  ->  0.39894228040143269e r}t
t{  1e G(x)  ->  0.24197072451914337e r}t  
t{ -1e G(x)  ->  1e G(x)              r}t
t{ 0e 2e set-fwhm-widths  v_sigma f@  v_gamma f@  ->  0e 1e  rr}t
t{  0e L(x)  ->  0.3183098861837907e  r}t
t{  1e L(x)  ->  0.15915494309189535e r}t
t{ -1e L(x)  ->  1e L(x)              r}t

\ Check normalization of G(x) and L(x)
\ Note the difference in widths and integration limits for G(x) and L(x)!
1e-6 rel-near f!
1e 1e-3 set-sd-hwhm-widths  
t{ use( G(x)   -10e   10e 1e-6 )integral ->  1e r}t
t{ use( L(x) -1000e 1000e 1e-6 )integral ->  1e r}t

\ Accuracy of our calculation is much better than indicated 
\ by rel-near, but the reference values from [4] only have 6 
\ significant digits.
5e-6 rel-near f!
1e-256 abs-near f!
set-near

CR TESTING K(x,y)
t{ SQRT_LN2 1e set-fwhm-widths  v_y f@  ->  1e  r}t  \ y = 1
t{   0.0e  K(x,y)  ->  0.427583e    r}t
t{   0.1e  K(x,y)  ->  0.426043e    r}t
t{   0.5e  K(x,y)  ->  0.391233e    r}t
t{   1.0e  K(x,y)  ->  0.304744e    r}t
t{   1.5e  K(x,y)  ->  0.211836e    r}t
t{   2.0e  K(x,y)  ->  0.140239e    r}t
t{   3.0e  K(x,y)  ->  0.653178e-1  r}t 
t{   4.0e  K(x,y)  ->  0.362814e-1  r}t
t{   5.0e  K(x,y)  ->  0.230031e-1  r}t
t{  10.0e  K(x,y)  ->  0.566994e-2  r}t
t{  20.0e  K(x,y)  ->  0.141223e-2  r}t
t{  50.0e  K(x,y)  ->  0.225721e-3  r}t
t{ 100.0e  K(x,y)  ->  0.564218e-4  r}t
t{ 200.0e  K(x,y)  ->  0.141049e-4  r}t

\ Check normalization of the Voigt probability density function
SQRT_LN2 1e set-fwhm-widths
v_sigma f@ v_gamma f@ f+ 5000e f* 
fdup    fconstant +xlim
fnegate fconstant -xlim

CR TESTING VOIGT
1e-4   rel-near f!
1e-256 abs-near f!
set-near
t{ use(  Voigt -xlim +xlim 1e-4 )integral -> 1e r}t

BASE !
[THEN]


