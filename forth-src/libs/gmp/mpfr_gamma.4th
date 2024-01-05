\ mpfr_gamma.4th
\
\ High precision calculation of the real gamma function using
\ the MPFR library interface
\
\ Example: Compute and print gamma[1.5] to 40 digits
\
\    15 1 rgamma  40 mpfr.
\
\ K. Myneni, 2011-05-17
\ krishna.myneni@ccreweb.org
\
\ Notes:
\
\   1. The floating point argument to the MPFR library function,
\      mpfr_gamma, is computed at high precision from two integer 
\      arguments to rgamma. This method avoids the lower fixed 
\      precision (53-bit) of a floating point number parsed by
\      the Forth interpreter.
\
\      The argument to mpfr_gamma, is x = arg1 * 10^(-arg2), where
\      arg1 and arg2 are the two integers passed to rgamma. The first 
\      arg may be signed, but arg2 is assumed to be positive. Obviously, 
\      the use of single length integers restricts the range of 
\      arguments which may be passed to mpfr_gamma.
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
2048 mpfr_set_default_prec

mpfr_t dst
mpfr_t num
mpfr_t sca

dst  mpfr_init
num  mpfr_init
sca  mpfr_init

\ Compute the gamma function of x = arg/(10^scale)
: rgamma ( narg nscale -- a )
    1 swap 
    dup 0> IF  0 DO 10 * LOOP  ELSE  DROP  THEN  \ narg 10^scale
    sca  swap GMP_RNDN      mpfr_set_ui  drop
    num  swap GMP_RNDN      mpfr_set_si  drop
    num  num  sca GMP_RNDN  mpfr_div     drop
    dst  num  GMP_RNDN      mpfr_gamma   drop
    dst
;


