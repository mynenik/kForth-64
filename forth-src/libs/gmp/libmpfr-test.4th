\ libmpfr-test.4th
\
\ Test the Forth interface to the GNU MPFR shared library.
\
\ Copyright (c) -- 2023 Krishna Myneni
\
\ Provided under the Lesser Gnu Public License (LGPL)
\
\ Notes:
\ 
\ 1. We set a default precision of 256 bits for the significand
\    (mantissa). When exactly representable arguments at this
\    precision are provided to a function, we should obtain 77
\    significant decimal digits in the result.
\
\ 2. In order for libmpfr.4th to load correctly, a symbolic link
\    "libmpfr.so" must exist and point to the current shared 
\    object library file in /usr/lib/ .
\
\ Revisions:
\   2015-02-08  km; fixed test with mpfr_cos for MPFR v3.
\   2023-03-18  km; fixed problems with mpfr_cos and mpfr_sin 
\                   tests, added default path for libmpfr.4th,
\                   added tests for mpfr_acos, mpfr_asin,
\                   mpfr_sec, mpfr_csc, mpfr_cot.

include ans-words
include modules.fs
include syscalls
include mc
include asm
include strings
include lib-interface
include libs/gmp/libmpfr
include libs/gmp/mpfr-utils
include ttester

true VERBOSE !

DECIMAL

\ Other utilities
: $constant  ( addr u <name> -- | create a string constant )
    create dup >r cell+ ?allot dup r@ swap ! cell+ r> cmove  
    does> ( addr -- addr' u ) dup @ swap cell+ swap ; 

\ 77 Significant Digits of Selected Constants
\ One 
s" 10000000000000000000000000000000000000000000000000000000000000000000000000000"
$constant ONE$
\ Sqrt(2)
s" 14142135623730950488016887242096980785696718753769480731766797379907324784621"
$constant SQRT2$
\ Pi
s" 3141592653589793238462643383279502884197169399375105820974944592307816406286"
$constant PI$
\ LN(2)
s" 69314718055994530941723212145817656807550013436025525412068000949339362196970"
$constant LN2$ 
\ Golden Ratio
s" 16180339887498948482045868343656381177203091798057628621354486227052604628189"
$constant GR$

cr
COMMENT MPFR Initialization and Assignment
\ Set precision before initializing mp vars
\ DO NOT CHANGE THIS VALUE or incorrect results for tests will occur.
TESTING mpfr_get_default_prec  mpfr_set_default_prec  mpfr_init
t{ mpfr_get_default_prec  -> 53   }t
t{ 256 mpfr_set_default_prec  ->  }t
t{ mpfr_get_default_prec  ->  256 }t

mpfr_t dst
mpfr_t num

t{ dst  mpfr_init  ->  }t
t{ num  mpfr_init  ->  }t
TESTING mpfr_get_prec
t{ dst  mpfr_get_prec  ->  256 }t

TESTING mpfr_const_pi  mpfr_const_log2
t{ dst GMP_RNDN mpfr_const_pi -> -1 }t
t{ PI$ dst sdcomp -> 0 }t
t{ dst GMP_RNDN mpfr_const_log2 -> 1 }t
t{ LN2$ dst sdcomp -> 0 }t

TESTING mpfr_set_ui  mpfr_set_si  mpfr_set
t{ dst 1 GMP_RNDN mpfr_set_ui -> 0 }t
t{ ONE$ dst sdcomp -> 0 }t
t{ dst 1 GMP_RNDN mpfr_set_si -> 0 }t
t{ ONE$ dst sdcomp -> 0 }t
t{ num GMP_RNDN mpfr_const_log2 -> 1 }t
t{ dst num GMP_RNDN mpfr_set -> 0 }t
t{ LN2$ dst sdcomp -> 0 }t

\ TESTING mpfr_set_flt  mpfr_set_d
TESTING mpfr_set_d
fvariable f1
\ t{ 1e f1 sf! -> }t
\ t{ dst f1 @ GMP_RNDN mpfr_set_flt -> 0 }t
\ t{ ONE$ dst sdcomp -> 0 }t
t{ 1e f1 df! -> }t
t{ dst f1 df@ GMP_RNDN mpfr_set_d -> 0 }t
t{ ONE$ dst sdcomp -> 0 }t
\ TESTING mpfr_get_flt  mpfr_get_d
TESTING mpfr_get_d
t{ dst GMP_RNDN mpfr_const_pi -> -1 }t
\ t{ dst GMP_RNDN mpfr_get_flt -> -1e facos f1 sf! f1 sf@ r}t
t{ dst GMP_RNDN mpfr_get_d   -> -1e facos r}t

cr
COMMENT MPFR Arithmetic
TESTING mpfr_add_ui  mpfr_mul_ui  mpfr_div_ui  mpfr_ui_div
TESTING mpfr_sqrt
t{ dst 2 GMP_RNDN mpfr_set_ui -> 0 }t
t{ dst dst GMP_RNDN mpfr_sqrt -> -1 }t
t{ SQRT2$ dst sdcomp -> 0 }t

cr
COMMENT MPFR Special Functions
t{ num 2 GMP_RNDN mpfr_set_ui -> 0 }t

TESTING mpfr_log  mpfr_log2  mpfr_log10
t{ dst num GMP_RNDN mpfr_log -> 1 }t
t{ LN2$ dst sdcomp -> 0 }t
t{ dst num GMP_RNDN mpfr_log2 -> 0 }t
t{ ONE$ dst sdcomp -> 0 }t
t{ dst num GMP_RNDN mpfr_log10 -> -1 }t
t{ s" 3010299956639811952137388947244930267681898814621085413104274611" dst sdcomp -> 0 }t

TESTING mpfr_exp  mpfr_exp2  mpfr_exp10
t{ dst num GMP_RNDN mpfr_exp -> -1 }t
t{ s" 7389056098930650227230427460575007813180315570551847324087127823" dst sdcomp -> 0 }t
t{ dst num GMP_RNDN mpfr_exp2 -> 0 }t
t{ s" 4000000000000000000000000000000000000000000000000000000000000000" dst sdcomp -> 0 }t
t{ dst num GMP_RNDN mpfr_exp10 -> 0 }t
t{ s" 1000000000000000000000000000000000000000000000000000000000000000" dst sdcomp -> 0 }t

TESTING mpfr_cos  mpfr_acos  mpfr_sin  mpfr_asin  mpfr_tan
t{ num 0   GMP_RNDN  mpfr_set_ui ->  0 }t
t{ dst num GMP_RNDN  mpfr_cos    ->  0 }t
t{ ONE$ dst sdcomp -> 0 }t
t{ num -1  GMP_RNDN  mpfr_set_si ->  0 }t
t{ dst num GMP_RNDN  mpfr_acos   -> -1 }t
t{ PI$ dst sdcomp -> 0 }t
t{ num 2   GMP_RNDN mpfr_set_ui -> 0 }t
t{ num dst num GMP_RNDN mpfr_div -> 0 }t  \ num = pi/2 
t{ dst num GMP_RNDN mpfr_sin -> 1 }t
t{ ONE$ dst sdcomp -> 0 }t
t{ num dst GMP_RNDN mpfr_neg -> 0 }t   \ num = -1
t{ dst num GMP_RNDN mpfr_asin -> 1 }t
t{ num 2 GMP_RNDN mpfr_set_ui -> 0 }t
t{ num dst num GMP_RNDN mpfr_div -> 0 }t \ num = -pi/4
t{ dst num GMP_RNDN mpfr_tan -> 1 }t  \ dst = -1
t{ dst dst GMP_RNDN mpfr_abs -> 0 }t
t{ ONE$ 1- dst sdcomp -> 0 }t  \ 1- corrects for lower sig dig with mpfr_tan

TESTING mpfr_sec  mpfr_csc  mpfr_cot
t{ num GMP_RNDN mpfr_const_pi -> -1 }t
t{ dst num GMP_RNDN mpfr_sec -> 1 }t
t{ dst dst GMP_RNDN mpfr_neg -> 0 }t
t{ ONE$ dst sdcomp -> 0 }t
t{ dst num GMP_RNDN mpfr_set -> 0 }t
t{ num 2 GMP_RNDN mpfr_set_ui -> 0 }t
t{ num dst num GMP_RNDN mpfr_div -> 0 }t  \ num = pi/2 
t{ dst num GMP_RNDN mpfr_csc -> -1 }t
t{ ONE$ dst sdcomp -> 0 }t
t{ dst num GMP_RNDN mpfr_set -> 0 }t
t{ num 2 GMP_RNDN mpfr_set_ui -> 0 }t
t{ num dst num GMP_RNDN mpfr_div -> 0 }t  \ num = pi/4
t{ dst num GMP_RNDN mpfr_cot -> -1 }t
t{ ONE$ dst sdcomp -> 0 }t

cr
COMMENT Golden Ratio calculation by four methods
\
\ 1. phi = (1 + sqrt(5))/2
t{ num 5     GMP_RNDN  mpfr_set_ui -> 0 }t
t{ num num   GMP_RNDN  mpfr_sqrt   -> 1 }t
t{ dst num 1 GMP_RNDN  mpfr_add_ui -> 0 }t
t{ dst dst 2 GMP_RNDN  mpfr_div_ui -> 0 }t
t{ GR$ dst sdcomp -> 0 }t
\
\ 2. phi = 2*cos(pi/5)
t{ num       GMP_RNDN  mpfr_const_pi  -> -1 }t
t{ num num 5 GMP_RNDN  mpfr_div_ui    ->  1 }t
t{ dst num   GMP_RNDN  mpfr_cos       ->  1 }t
t{ dst dst 2 GMP_RNDN  mpfr_mul_ui    ->  0 }t
t{ GR$ dst sdcomp -> 0 }t
\
\ 3. Continued square root: phi = sqrt(1 + sqrt(1 + sqrt(1 + ...
: phi-csr ( amp nterms -- )
    >r dup
    dup 2 GMP_RNDN mpfr_set_ui drop
    2dup GMP_RNDN mpfr_sqrt drop
    r> 0 ?do
      2dup 1 GMP_RNDN mpfr_add_ui drop
      2dup GMP_RNDN mpfr_sqrt drop
    loop 
    2drop ;

t{ dst 150 phi-csr ->   }t
t{ GR$ dst sdcomp  -> 0 }t

\ 4. Continued fraction: phi = 1 + 1/(1 + 1/(1 + 1/... 
: phi-cf ( amp nterms -- )
    >r dup
    dup 3 GMP_RNDN mpfr_set_ui drop
    2dup 2 GMP_RNDN mpfr_div_ui drop
    r> 0 ?do
      2dup 1 swap GMP_RNDN mpfr_ui_div drop
      2dup 1 GMP_RNDN mpfr_add_ui drop
    loop
    2drop ;

t{ dst 182 phi-cf ->  }t
t{ GR$ dst sdcomp  -> 0 }t

\ end of Golden Ratio calculations

cr
COMMENT MPFR Cleanup
TESTING mpfr_clear  mpfr_free_cache
t{ num mpfr_clear  ->  }t
t{ dst mpfr_clear  ->  }t
t{ mpfr_free_cache  ->  }t

