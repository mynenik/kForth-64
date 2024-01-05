\ mpfr_bessel.4th
\
\ High precision calculation of Bessel functions using
\ the MPFR library interface
\
\ Example: Compute and print J1(2.44) to 40 digits
\
\    244 2 1 rbes-jn  40 mpfr.
\
\ K. Myneni, 2011-06-25
\ krishna.myneni@ccreweb.org
\
\ Notes:
\
\   1. The floating point argument to the MPFR library functions,
\      mpfr_xn, is computed at high precision from two integer 
\      arguments to rbes-xn. This method avoids the lower fixed 
\      precision (53-bit) of a floating point number parsed by
\      the Forth interpreter.
\
\      The argument to mpfr_xn, is arg1 * 10^(-arg2), where
\      arg1 and arg2 are the two integers passed to rbes-xn.
\
\ Requires:
\
\  ans-words
\  modules.fs
\  syscalls
\  mc
\  asm
\  strings
\  lib-interface
\  libs/gmp/libmpfr
\  libs/gmp/mpfr-utils  (optional)

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

\ Compute the Bessel function J_n(x), where x = arg/(10^scale)
: rbes-jn ( narg nscale n -- a )
    >r num scaled-arg 
    dst swap r> swap GMP_RNDN mpfr_jn drop
    dst ;

\ Compute the Bessel function Y_n(x), where x = arg/(10^scale)
: rbes-yn ( narg nscale n -- a )
    >r num scaled-arg 
    dst swap r> swap GMP_RNDN mpfr_yn drop
    dst ;

