\ mpfr_sph_bes_neu.4th
\
\ Spherical Bessel and Neumann functions for large index range.
\ High-precision calculation using the GNU MPFR library.
\
\ Use recurrence relations to compute the spherical Bessel and 
\ Neumann functions, j_l(x) and n_l(x), for l over a range of
\ values. The relative accuracy of j_l(x) and n_l(x) depends
\ on the recursion length, which may be initialized.
\
\ The computed function values for different l's are returned in
\ double precision arrays rbes{ and rneu{ with l as the index. 
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
\ Forth MPFR version by K. M., 2023-03-19
\
\ Revisions:
\   2026-02-09  km  allow dynamic resizing of the recursion length.
\
\ References
\   1. E. Gillman and H. R. Fiebig, "Accurate recursive generation
\      of spherical Bessel and Neumann functions for a large range
\      of indices," Computers in Physics vol. 2, p. 62 (1988).
\
\ Notes:
\
\ Requires:
\
\   libs/gmp/libmpfr.4th
\   libs/gmp/mpfr-utils.4th
\   fsl/fsl-util.4th
\   fsl/fsl-dynmem

128 mpfr_set_default_prec

BEGIN-MODULE
BASE @ DECIMAL

mpfr_t m1
mpfr_t m2
mpfr_t m3

mpfr_t mx
mpfr_t mxx
mpfr_t cx
mpfr_t sx
mpfr_t cu
mpfr_t cv

m1 mpfr_init
m2 mpfr_init
m3 mpfr_init
mx mpfr_init
mxx mpfr_init
cx mpfr_init
sx mpfr_init
cu mpfr_init
cv mpfr_init

fvariable x

0 value lu
0 value lv
0 value w

0 value MAX-L

Public:

FLOAT DARRAY rbes{
FLOAT DARRAY rneu{

/MPFR DARRAY mp_rbes{
/MPFR DARRAY mp_rneu{

: get-recurse ( -- u ) MAX-L ;

: set-recurse ( u -- error )
    \ release previously allocated memory
    MAX-L IF
      & rbes{ }free
      & rneu{ }free
      & mp_rbes{ }free
      & mp_rneu{ }free
      malloc-fail? IF
        drop
        malloc-fail? EXIT
      THEN
    THEN

    dup IF
      & rbes{ over }malloc
      & rneu{ over }malloc
      & mp_rbes{ over }malloc
      & mp_rneu{ over }malloc
      malloc-fail? 0= IF
        to MAX-L
      ELSE
        drop
      THEN
      malloc-fail?
    ELSE
      dup to MAX-L
    THEN
;

: sphfuncs ( F: x -- )
    x f!
    mx x f@ GMP_RNDN mpfr_set_d drop

    MAX-L 0 DO
      mp_rbes{ i } mpfr_init
      mp_rneu{ i } mpfr_init
    LOOP

    \ Set starting values j_lmax-1(x) and n_0(x) for recursion
    mp_rbes{ MAX-L 1- } 1 GMP_RNDN mpfr_set_ui drop
    mp_rbes{ MAX-L 2- } 1 GMP_RNDN mpfr_set_ui drop
    
    sx mx GMP_RNDN mpfr_sin drop
    cx mx GMP_RNDN mpfr_cos drop
    mp_rneu{ 0 } cx GMP_RNDN mpfr_set drop
    m1 sx mx GMP_RNDN mpfr_mul drop
    mp_rneu{ 1 } m1 cx GMP_RNDN mpfr_add drop

    mxx mx mx GMP_RNDN mpfr_mul drop

    \ Recursively generate j_l(x) and n_l(x)
    MAX-L 2 DO
      MAX-L I - to lu
      I 2- to lv
      m1 lv 1+ dup * 4 * 1- GMP_RNDN mpfr_set_ui drop 
      m2 mxx m1 GMP_RNDN mpfr_div drop
      m2 m2 mp_rneu{ lv } GMP_RNDN mpfr_mul drop
      m2 m2 GMP_RNDN mpfr_neg drop
      m3 m2 mp_rneu{ lv 1+ } GMP_RNDN mpfr_add drop
      mp_rneu{ lv 2+ } m3 GMP_RNDN mpfr_set drop
      m1 lu 1+ dup * 4 * 1- GMP_RNDN mpfr_set_ui drop 
      m2 mxx m1 GMP_RNDN mpfr_div drop
      m2 m2 mp_rbes{ lu 1+ } GMP_RNDN mpfr_mul drop
      m2 m2 GMP_RNDN mpfr_neg drop
      m3 m2 mp_rbes{ lu } GMP_RNDN mpfr_add drop
      mp_rbes{ lu 1- } m3 GMP_RNDN mpfr_set drop
    LOOP

    \ Scale j_l(x)
    m1 3 GMP_RNDN mpfr_set_ui drop
    m1 mxx m1 GMP_RNDN mpfr_div drop
    m1 m1 mp_rbes{ 1 } GMP_RNDN mpfr_mul drop
    m2 m1 cx GMP_RNDN mpfr_mul drop
    m2 m2 GMP_RNDN mpfr_neg drop
    m3 mp_rbes{ 0 } GMP_RNDN mpfr_set drop
    m3 m3 mp_rneu{ 1 } GMP_RNDN mpfr_mul drop
    m3 m2 m3 GMP_RNDN mpfr_add drop
    MAX-L 0 DO  
      mp_rbes{ I } mp_rbes{ I } m3 GMP_RNDN mpfr_div drop  
    LOOP

    \ Normalize j_l(x) and n_l(x)
    m1 1 GMP_RNDN mpfr_set_ui drop
    cu m1 mx GMP_RNDN mpfr_div drop 
    cv -1 GMP_RNDN mpfr_set_si drop
    MAX-L 0 DO
      I 2* to w
      m1 w 1+ GMP_RNDN mpfr_set_ui drop
      m2 mx m1 GMP_RNDN mpfr_div drop
      cu m2 cu GMP_RNDN mpfr_mul drop
      mp_rbes{ I } cu mp_rbes{ I } GMP_RNDN mpfr_mul drop
      m1 w 1- GMP_RNDN mpfr_set_si drop
      m2 m1 mx GMP_RNDN mpfr_div drop
      cv m2 cv GMP_RNDN mpfr_mul drop 
      m3 cv mp_rneu{ I } GMP_RNDN mpfr_mul drop
      mp_rneu{ I } m3 GMP_RNDN mpfr_neg drop
    LOOP

    \ Copy results to double precision arrays
    MAX-L 0 DO
      mp_rbes{ I } GMP_RNDN mpfr_get_d rbes{ I } f!
      mp_rneu{ I } GMP_RNDN mpfr_get_d rneu{ I } f!
    LOOP

    \ Free the mpfr arrays
    MAX-L 0 DO
      mp_rbes{ I } mpfr_clear
      mp_rneu{ I } mpfr_clear
    LOOP
;

: sphfuncs_mpfr_cleanup ( -- )
    m1 mpfr_clear
    m2 mpfr_clear
    m3 mpfr_clear
    mx mpfr_clear
    mxx mpfr_clear
    cx mpfr_clear
    sx mpfr_clear
    cu mpfr_clear
    cv mpfr_clear
    mpfr_free_cache
;

BASE !
END-MODULE
