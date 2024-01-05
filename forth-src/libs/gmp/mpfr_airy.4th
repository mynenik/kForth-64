\ mpfr_airy.4th
\
\ High precision calculation of Airy function using
\ the MPFR library interface
\
\ Example: Compute and print Ai(-10.0) to 40 digits
\
\    -10 0 airy  40 mpfr.
\
\ K. Myneni, 2013-04-15
\ krishna.myneni@ccreweb.org
\
\ Notes:
\
\   1. The floating point argument to the MPFR library function,
\      mpfr_ai, is computed at high precision from two integer 
\      arguments to airy. This method avoids the lower fixed 
\      precision (53-bit) of a floating point number parsed by
\      the Forth interpreter.
\
\      The argument to mpfr_ai, is arg1 * 10^(-arg2), where
\      arg1 and arg2 are the two integers passed to AIRY.
\
\ Requires:
\   ans-words
\   modules.fs
\   syscalls
\   mc
\   asm
\   strings
\   lib-interface
\   libs/gmp/libmpfr
\   libs/gmp/mpfr-utils  (optional)

\ Set precision before initializing mp vars
256 mpfr_set_default_prec

mpfr_t dst
mpfr_t num
mpfr_t sca

dst  mpfr_init
num  mpfr_init
sca  mpfr_init

\ Return 10^nscale in a mp var, a
: scale-factor ( nscale a -- a )
    swap >r
    dup 10 GMP_RNDN mpfr_set_ui drop
    dup dup r> GMP_RNDN mpfr_pow_ui drop ;

\ Return scaled arg, x = arg/(10^scale) in mp var, a
: scaled-arg ( narg nscale a -- a )
    swap sca scale-factor >r
    dup  rot GMP_RNDN      mpfr_set_si  drop
    dup  dup r> GMP_RNDN   mpfr_div     drop
;

\ Compute the Airy function Ai(x), where x = arg/(10^scale)
: airy ( narg nscale -- a )
    num scaled-arg 
    dst swap GMP_RNDN mpfr_ai drop
    dst ;

