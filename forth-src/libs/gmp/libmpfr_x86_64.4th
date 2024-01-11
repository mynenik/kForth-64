(     Title:  kForth bindings for the GNU Multiple
              Precision Floatint-Point Reliable Library, 
              for GNU MPFR Ver. >= 3.0.0
       File:  libmpfr.4th
  Test file:  gmpr-test.fs
     Author:  David N. Williams
    License:  LGPL
    Version:  0.8.4c
    Started:  March 25, 2011 
    Revised:  July 10, 2011 -- adapted for kForth by K. Myneni,
                2015-02-08 fixed problem with mpfr_div_d.
                2023-03-18 use Forth 200x structures.
                2023-12-27 port to 64-bit library.
Any part of this file not derived from the GMP library is
)  
\ Copyright  (C) 2011 by David N. Williams
(  
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or at your option any later version.

This library is distributed in the hope that it will be useful 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Library General Public License for moref details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
MA 02111-1307 USA.
)

vocabulary mpfr
also mpfr definitions

0 value hndl_MPFR
s" libmpfr.so" open-lib
dup 0= [IF] check-lib-error [THEN]
to hndl_MPFR
cr .( Opened the MPFR library )

[UNDEFINED] begin-structure [IF] 
s" struct-200x.4th" included
[THEN]

BEGIN-STRUCTURE mpfr_struct%
  FIELD:   mpfr_struct->mpfr_prec
  FIELD:   mpfr_struct->mpfr_sign
  FIELD:   mpfr_struct->mpfr_exp
  FIELD:   mpfr_struct->mpfr_d
END-STRUCTURE

mpfr_struct%  constant /MPFR

\ Create and allot a mpfr number type
: mpfr_t create mpfr_struct% allot ;


          2  constant  MPFR_PREC_MIN
-1 1 rshift  constant  MPFR_PREC_MAX


 0  constant  MPFR_RNDN   \ round to nearest, with ties to even
 1  constant  MPFR_RNDZ   \ round toward zero
 2  constant  MPFR_RNDU   \ round toward +Inf
 3  constant  MPFR_RNDD   \ round toward -Inf
 4  constant  MPFR_RNDA   \ round away from zero
 5  constant  MPFR_RNDF   \ faithful rounding

MPFR_RNDN  constant  GMP_RNDN
MPFR_RNDZ  constant  GMP_RNDZ
MPFR_RNDU  constant  GMP_RNDU
MPFR_RNDD  constant  GMP_RNDD
MPFR_RNDA  constant  GMP_RNDA


\ libmpfr 3.0.1 functions

\ 5.1 Initialization

: mpfr_init ( a -- )
   [ s" mpfr_init" lsym check-lib-error ] literal fcall1 drop ;
: mpfr_init2 ( a n -- )
   [ s" mpfr_init2" lsym check-lib-error ] literal fcall2 drop ;
: mpfr_clear ( a -- )
   [ s" mpfr_clear" lsym check-lib-error ] literal fcall1 drop ;
: mpfr_set_default_prec ( n -- )
   [ s" mpfr_set_default_prec" lsym check-lib-error ] literal fcall1 drop ;
: mpfr_get_default_prec ( -- n )
   [ s" mpfr_get_default_prec"  lsym check-lib-error ] literal fcall0 ;
: mpfr_set_prec ( a n -- )
   [ s" mpfr_set_prec" lsym check-lib-error ] literal fcall2 drop ;
: mpfr_get_prec ( a -- n )
   [ s" mpfr_get_prec" lsym check-lib-error ] literal fcall1 ;

\ 5.2 Assignment

: mpfr_set ( a a n -- n )
   [ s" mpfr_set" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_set_ui ( a u n -- n )
   [ s" mpfr_set_ui" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_set_si ( a n n -- n )
   [ s" mpfr_set_si" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_set_uj ( a n n -- n )
   [ s" __gmpfr_set_uj" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_set_sj ( a n n -- n )
   [ s" __gmpfr_set_sj" lsym check-lib-error ] literal fcall3-dq ;

0 [IF]
: mpfr_set_flt ( a s n -- n )
   [ s" mpfr_set_flt" lsym check-lib-error ] literal fcall3-dq  ;  \ C-word   mpfr_set_flt ( a s n -- n )
[THEN]

: mpfr_set_d ( a n -- n ) ( F: r -- )
   [ s" mpfr_set_d" lsym check-lib-error ] literal fcall(2,1;1,0) ;

\ s" mpfr_set_ld" C-word  mpfr_set_ld  ( a ld n -- n ) \ long double not supported

: mpfr_set_z ( a a n -- n )
   [ s" mpfr_set_z" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_set_q ( a a n -- n )
   [ s" mpfr_set_q" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_set_f ( a a n -- n )
   [ s" mpfr_set_f" lsym check-lib-error ] literal fcall3-dq ;

: mpfr_set_ui_2exp ( a u n n -- n )
   [ s" mpfr_set_ui_2exp" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_set_si_2exp ( a n n n -- n )
   [ s" mpfr_set_si_2exp" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_set_uj_2exp ( a n n n -- n )
   [ s" __gmpfr_set_uj_2exp" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_set_sj_2exp ( a n n n -- n )
   [ s" __gmpfr_set_sj_2exp" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_set_z_2exp ( a a n n -- n )
   [ s" mpfr_set_z_2exp" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_set_str ( a a n n -- n )
   [ s" mpfr_set_str" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_strtofr ( a a a n n -- n )
   [ s" mpfr_strtofr" lsym check-lib-error ] literal fcall5-dq ;

: mpfr_set_nan ( a -- )
   [ s" mpfr_set_nan" lsym check-lib-error ] literal fcall1 drop ;
: mpfr_set_inf ( a n -- )
   [ s" mpfr_set_inf" lsym check-lib-error ] literal fcall2 drop ;
: mpfr_set_zero ( a n -- )
   [ s" mpfr_set_zero" lsym check-lib-error ] literal fcall2 drop ;

: mpfr_swap ( a a -- )
   [ s" mpfr_swap" lsym check-lib-error ] literal fcall2 drop ;


\ 5.3 Combined initialization and assignment
0 [IF]
: mpfr_init_set    ( ax ay nrnd -- n ) 2>r dup mpfr_init  2r> mpfr_set ;
: mpfr_init_set_ui ( a  n  nrnd -- n ) 2>r dup mpfr_init  2r> mpfr_set_ui ;
: mpfr_init_set_si ( a  n  nrnd -- n ) 2>r dup mpfr_init  2r> mpfr_set_si ;
: mpfr_init_set_d  ( a  r  nrnd -- n ) >r 2>r dup mpfr_init 2r> swap r> _mpfr_set_d ;

\ : mpfr_init_set_ld ;  ( long double not supported ) 

: mpfr_init_set_z  ( a1 a2 nrnd -- n ) 2>r dup mpfr_init  2r> mpfr_set_z ;
: mpfr_init_set_q  ( a1 a2 nrnd -- n ) 2>r dup mpfr_init  2r> mpfr_set_q ; 
: mpfr_init_set_f  ( a1 a2 nrnd -- n ) 2>r dup mpfr_init  2r> mpfr_set_f ;


s" mpfr_init_set_str"     C-word  mpfr_init_set_str  ( a a n n -- n )
[THEN]

\ 5.4 Conversion

0 [IF]
s" mpfr_get_flt"          C-word  mpfr_get_flt  ( a n -- r )
[THEN]

: mpfr_get_d ( a n -- ) ( F: -- r )
   [ s" mpfr_get_d" lsym check-lib-error ] literal fcall(2,0;0,1) ;

\ s" mpfr_get_ld" C-word  mpfr_get_ld   ( a n -- ld )  \ long double not supported

: mpfr_get_si ( a n -- n )
   [ s" mpfr_get_si" lsym check-lib-error ] literal fcall2 ;
: mpfr_get_ui ( a n -- u )
   [ s" mpfr_get_ui" lsym check-lib-error ] literal fcall2 ;
: mpfr_get_sj ( a n -- n )
   [ s" __gmpfr_mpfr_get_sj" lsym check-lib-error ] literal fcall2 ;
: mpfr_get_uj ( a n -- n )
   [ s" __gmpfr_mpfr_get_uj" lsym check-lib-error ] literal fcall2 ;

0 [IF]
s" mpfr_get_d_2exp"       C-word  mpfr_get_d_2exp  ( a a n -- r )

\ s" mpfr_get_ld_2exp" C-word mpfr_get_ld_2exp  ( a a n -- ld ) \ long double not supported
[THEN]

: mpfr_get_z_2exp ( a a -- n )
   [ s" mpfr_get_z_2exp" lsym check-lib-error ] literal fcall2 ;
: mpfr_get_z ( a a n -- n )
   [ s" mpfr_get_z" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_get_f ( a a n -- n )
   [ s" mpfr_get_f" lsym check-lib-error ] literal fcall3-dq ;

: mpfr_get_str ( a a n n a n -- a )
   [ s" mpfr_get_str" lsym check-lib-error ] literal fcall6 ;

: mpfr_free_str ( a -- )
   [ s" mpfr_free_str" lsym check-lib-error ] literal fcall1 drop ;

: mpfr_fits_ulong_p ( a n -- n )
   [ s" mpfr_fits_ulong_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_fits_slong_p ( a n -- n )
   [ s" mpfr_fits_slong_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_fits_uint_p ( a n -- n )
   [ s" mpfr_fits_uint_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_fits_sint_p ( a n -- n )
   [ s" mpfr_fits_sint_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_fits_ushort_p ( a n -- n )
   [ s" mpfr_fits_ushort_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_fits_sshort_p ( a n -- n )
   [ s" mpfr_fits_sshort_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_fits_uintmax_p ( a n -- n )
   [ s" mpfr_fits_uintmax_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_fits_intmax_p ( a n -- n )
   [ s" mpfr_fits_intmax_p" lsym check-lib-error ] literal fcall2-dq ;


\ 5.5 Basic Arithmetic

\ Add:
\    mpfr_mul_2exp ( a a u n -- n )
\    mpfr_div_2exp ( a a u n -- n )
\    mpfr_z_sub    ( a a a n -- n )

: mpfr_add ( a a a n -- n )
   [ s" mpfr_add" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_add_ui ( a a u n -- n )
   [ s" mpfr_add_ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_add_si ( a a n n -- n )
   [ s" mpfr_add_si" lsym check-lib-error ] literal fcall4-dq ;

0 [IF]
: mpfr_add_d ( a a n -- n ) ( F: r -- )
   [ s" mpfr_add_d" lsym check-lib-error ] literal fcall(3,1;1,0)s ;
[THEN]

: mpfr_add_z ( a a a n -- n )
   [ s" mpfr_add_z" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_add_q ( a a a n -- n )
   [ s" mpfr_add_q" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_sub ( a a a n -- n )
   [ s" mpfr_sub" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_ui_sub ( a u a n -- n )
   [ s" mpfr_ui_sub" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_sub_ui ( a a u n -- n )
   [ s" mpfr_sub_ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_si_sub ( a n a n -- n )
   [ s" mpfr_si_sub" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_sub_si ( a a n n -- n )
   [ s" mpfr_sub_si" lsym check-lib-error ] literal fcall4-dq ;

0 [IF]
s" mpfr_d_sub"     C-word  _mpfr_d_sub     ( a r a n -- n )
s" mpfr_sub_d"     C-word  _mpfr_sub_d     ( a a r n -- n )
[THEN]

: mpfr_sub_z ( a a a n -- n )
   [ s" mpfr_sub_z" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_sub_q ( a a a n -- n )
   [ s" mpfr_sub_q" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_mul ( a a a n -- n )
   [ s" mpfr_mul" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_mul_ui ( a a u n -- n )
   [ s" mpfr_mul_ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_mul_si ( a a n n -- n )
   [ s" mpfr_mul_si" lsym check-lib-error ] literal fcall4-dq ;

0 [IF]
s" mpfr_mul_d"     C-word  _mpfr_mul_d     ( a a r n -- n )
[THEN]

: mpfr_mul_z ( a a a n -- n )
   [ s" mpfr_mul_z" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_mul_q ( a a a n -- n )
   [ s" mpfr_mul_q" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_div ( a a a n -- n )
   [ s" mpfr_div" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_ui_div ( a u a n -- n )
   [ s" mpfr_ui_div" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_div_ui ( a a u n -- n )
   [ s" mpfr_div_ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_si_div ( a n a n -- n )
   [ s" mpfr_si_div" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_div_si ( a a n n -- n )
   [ s" mpfr_div_si" lsym check-lib-error ] literal fcall4-dq ;

0 [IF]
s" mpfr_d_div"     C-word  mpfr_d_div      ( a r a n -- n )
s" mpfr_div_d"     C-word  _mpfr_div_d     ( a a r n -- n )
[THEN]

: mpfr_div_z ( a a a n -- n )
   [ s" mpfr_div_z" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_div_q ( a a a n -- n )
   [ s" mpfr_div_q" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_sqr ( a a n -- n )
   [ s" mpfr_sqr" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_sqrt ( a a n -- n )
   [ s" mpfr_sqrt" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_sqrt_ui ( a u n -- n )
   [ s" mpfr_sqrt_ui" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_rec_sqrt ( a a n -- n )
   [ s" mpfr_rec_sqrt" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_cbrt ( a a n -- n )
   [ s" mpfr_cbrt" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_root ( a a u n -- n )
   [ s" mpfr_root" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_pow ( a a a n -- n )
   [ s" mpfr_pow" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_pow_ui ( a a u n -- n )
   [ s" mpfr_pow_ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_pow_si ( a a n n -- n )
   [ s" mpfr_pow_si" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_pow_z ( a a a n -- n )
   [ s" mpfr_pow_z" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_ui_pow_ui ( a u u n -- n )
   [ s" mpfr_ui_pow_ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_ui_pow ( a u a n -- n )
   [ s" mpfr_ui_pow" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_neg ( a a n -- n )
   [ s" mpfr_neg" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_abs ( a a n -- n )
   [ s" mpfr_abs" lsym check-lib-error ] literal fcall3-dq ;

: mpfr_dim ( a a a n -- n )
   [ s" mpfr_dim" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_mul_2ui ( a a u n -- n )
   [ s" mpfr_mul_2ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_mul_2si ( a a n n -- n )
   [ s" mpfr_mul_2si" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_div_2ui ( a a u n -- n )
   [ s" mpfr_div_2ui" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_div_2si ( a a n n -- n )
   [ s" mpfr_div_2si" lsym check-lib-error ] literal fcall4-dq ;

\ 5.6 Comparison

\ add mpfr_cmpabs_ui ( a u -- n )

: mpfr_cmp ( a a -- n )
   [ s" mpfr_cmp" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_cmp_ui ( a u -- n )
   [ s" mpfr_cmp_ui" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_cmp_si ( a n -- n )
   [ s" mpfr_cmp_si" lsym check-lib-error ] literal fcall2-dq ;
0 [IF]
: mpfr_cmp_d ( a -- n ) ( F: r -- 0 )
   [ s" mpfr_cmp_d" lsym check-lib-error ] literal fcall(1,1;1,0)s ;
[THEN]
\ s" mpfr_cmp_ld"  C-word  mpfr_cmp_ld     ( a ld -- n ) \ long double not supported

: mpfr_eq ( a a u -- n )
   [ s" mpfr_eq" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_cmp_z ( a a -- n )
   [ s" mpfr_cmp_z" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_cmp_q ( a a -- n )
   [ s" mpfr_cmp_q" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_cmp_f ( a a -- n )
   [ s" mpfr_cmp_f" lsym check-lib-error ] literal fcall2-dq ;

: mpfr_cmp_ui_2exp ( a u n -- n )
   [ s" mpfr_cmp_ui_2exp" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_cmp_si_2exp ( a n n -- n )
   [ s" mpfr_cmp_si_2exp" lsym check-lib-error ] literal fcall3-dq ;

: mpfr_cmpabs ( a a -- n )
   [ s" mpfr_cmpabs" lsym check-lib-error ] literal fcall2-dq ;

: mpfr_nan_p ( a -- n )
   [ s" mpfr_nan_p" lsym check-lib-error ] literal fcall1-dq ;
: mpfr_inf_p ( a -- n )
   [ s" mpfr_inf_p" lsym check-lib-error ] literal fcall1-dq ;
: mpfr_number_p ( a -- n )
   [ s" mpfr_number_p" lsym check-lib-error ] literal fcall1-dq ;
: mpfr_integer_p ( a -- n )
   [ s" mpfr_integer_p" lsym check-lib-error ] literal fcall1-dq ;
: mpfr_zero_p ( a -- n )
   [ s" mpfr_zero_p" lsym check-lib-error ] literal fcall1-dq ;
: mpfr_regular_p ( a -- n )
   [ s" mpfr_regular_p" lsym check-lib-error ] literal fcall1-dq ;
: mpfr_sgn ( a -- n )
   [ s" mpfr_sgn" lsym check-lib-error ] literal fcall0-dq ;

: mpfr_greater_p ( a a -- n )
   [ s" mpfr_greater_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_greaterequal_p ( a a -- n )
   [ s" mpfr_greaterequal_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_less_p ( a a -- n )
   [ s" mpfr_less_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_lessequal_p ( a a -- n )
   [ s" mpfr_lessequal_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_equal_p ( a a -- n )
   [ s" mpfr_equal_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_lessgreater_p ( a a -- n )
   [ s" mpfr_lessgreater_p" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_unordered_p ( a a -- n )
   [ s" mpfr_unordered_p" lsym check-lib-error ] literal fcall2-dq ;


\ 5.7 Special Functions

\ Add:
\    mpfr_log_ui ( a u n -- n )
\    mpfr_dot ( a a a u n -- n )
\    mpfr_beta ( a a a n -- n )
\    mpfr_gamma_inc ( a a a n -- n )
\    mpfr_rootn_ui ( a a u n -- n )

: mpfr_log ( a a n -- n )
   [ s" mpfr_log" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_log2 ( a a n -- n )
   [ s" mpfr_log2" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_log10 ( a a n -- n )
   [ s" mpfr_log10" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_exp ( a a n -- n )
   [ s" mpfr_exp" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_exp2 ( a a n -- n )
   [ s" mpfr_exp2" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_exp10 ( a a n -- n )
   [ s" mpfr_exp10" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_cos ( a a n -- n )
   [ s" mpfr_cos" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_sin ( a a n -- n )
   [ s" mpfr_sin" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_tan ( a a n -- n )
   [ s" mpfr_tan" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_sin_cos ( a a a n -- n )
   [ s" mpfr_sin_cos" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_sec ( a a n -- n )
   [ s" mpfr_sec" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_csc ( a a n -- n )
   [ s" mpfr_csc" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_cot ( a a n -- n )
   [ s" mpfr_cot" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_acos ( a a n -- n )
   [ s" mpfr_acos" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_asin ( a a n -- n )
   [ s" mpfr_asin" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_atan ( a a n -- n )
   [ s" mpfr_atan" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_atan2 ( a a a n -- n )
   [ s" mpfr_atan2" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_cosh ( a a n -- n )
   [ s" mpfr_cosh" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_sinh ( a a n -- n )
   [ s" mpfr_sinh" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_tanh ( a a n -- n )
   [ s" mpfr_tanh" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_sinh_cosh ( a a a n -- n )
   [ s" mpfr_sinh_cosh" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_sech ( a a n -- n )
   [ s" mpfr_sech" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_csch ( a a n -- n )
   [ s" mpfr_csch" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_coth ( a a n -- n )
   [ s" mpfr_coth" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_acosh ( a a n -- n )
   [ s" mpfr_acosh" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_asinh ( a a n -- n )
   [ s" mpfr_asinh" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_atanh ( a a n -- n )
   [ s" mpfr_atanh" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_fac_ui ( a u n -- n )
   [ s" mpfr_fac_ui" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_log1p ( a a n -- n )
   [ s" mpfr_log1p" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_expm1 ( a a n -- n )
   [ s" mpfr_expm1" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_eint ( a a n -- n )
   [ s" mpfr_eint" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_li2 ( a a n -- n )
   [ s" mpfr_li2" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_gamma ( a a n -- n )
   [ s" mpfr_gamma" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_lngamma ( a a n -- n )
   [ s" mpfr_lngamma" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_lgamma ( a a a n -- n )
   [ s" mpfr_lgamma" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_digamma ( a a n -- n )
   [ s" mpfr_digamma" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_zeta ( a a n -- n )
   [ s" mpfr_zeta" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_zeta_ui ( a u n -- n )
   [ s" mpfr_zeta_ui" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_erf ( a a n -- n )
   [ s" mpfr_erf" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_erfc ( a a n -- n )
   [ s" mpfr_erfc" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_j0 ( a a n -- n )
   [ s" mpfr_j0" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_j1 ( a a n -- n )
   [ s" mpfr_j1" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_jn ( a n a n -- n )
   [ s" mpfr_jn" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_y0 ( a a n -- n )
   [ s" mpfr_y0" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_y1 ( a a n -- n )
   [ s" mpfr_y1" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_yn ( a n a n -- n )
   [ s" mpfr_yn" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_fma ( a a a a n -- n )
   [ s" mpfr_fma" lsym check-lib-error ] literal fcall5-dq ;
: mpfr_fms ( a a a a n -- n )
   [ s" mpfr_fms" lsym check-lib-error ] literal fcall5-dq ;

: mpfr_agm ( a a a n -- n )
   [ s" mpfr_agm" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_hypot ( a a a n -- n )
   [ s" mpfr_hypot" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_ai ( a a n -- n )
   [ s" mpfr_ai" lsym check-lib-error ] literal fcall3-dq ;

: mpfr_const_log2 ( a n -- n )
   [ s" mpfr_const_log2" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_const_pi ( a n -- n )
   [ s" mpfr_const_pi" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_const_euler ( a n -- n )
   [ s" mpfr_const_euler" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_const_catalan ( a n -- n )
   [ s" mpfr_const_catalan" lsym check-lib-error ] literal fcall2-dq ;

\ Add:
\   mpfree_cache2 ( a? -- )
\   mpfr_free_pool ( -- )
\   mpfr_mp_memory_cleanup ( -- )

: mpfr_free_cache ( -- )
   [ s" mpfr_free_cache" lsym check-lib-error ] literal fcall0 drop ;

: mpfr_sum ( a a u n -- n )
   [ s" mpfr_sum" lsym check-lib-error ] literal fcall4-dq ;

\ 5.8 Input and output

: mpfr_out_str ( a n n a n -- n )
   [ s" __gmpfr_out_str" lsym check-lib-error ] literal fcall5 ;
: mpfr_inp_str ( a a n n -- n )
   [ s" __gmpfr_inp_str" lsym check-lib-error ] literal fcall4 ;

\ 5.9 Formatted Output

\ 5.10 Integer and Remainder Related Functions

: mpfr_rint ( a a n -- n )
   [ s" mpfr_rint" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_ceil ( a a -- n )
   [ s" mpfr_ceil" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_floor ( a a -- n )
   [ s" mpfr_floor" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_round ( a a -- n )
   [ s" mpfr_round" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_trunc ( a a -- n )
   [ s" mpfr_trunc" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_rint_ceil ( a a n -- n )
   [ s" mpfr_rint_ceil" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_rint_floor ( a a n -- n )
   [ s" mpfr_rint_floor" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_rint_round ( a a n -- n )
   [ s" mpfr_rint_round" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_rint_trunc ( a a n -- n )
   [ s" mpfr_rint_trunc" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_frac ( a a n -- n )
   [ s" mpfr_frac" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_modf ( a a a n -- n )
   [ s" mpfr_modf" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_fmod ( a a a n -- n )
   [ s" mpfr_fmod" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_remainder ( a a a n -- n )
   [ s" mpfr_remainder" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_remquo ( a a a a n -- n )
   [ s" mpfr_remquo" lsym check-lib-error ] literal fcall5-dq ;

\ 5.11 Rounding Related Functions

: mpfr_set_default_rounding_mode ( n -- )
   [ s" mpfr_set_default_rounding_mode" lsym check-lib-error ] literal 
   fcall1 drop ;
: mpfr_get_default_rounding_mode ( -- n )
   [ s" mpfr_get_default_rounding_mode" lsym check-lib-error ] literal
   fcall0 ;

: mpfr_prec_round ( a n n -- n )
   [ s" mpfr_prec_round" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_can_round ( a n n n n -- n )
   [ s" mpfr_can_round" lsym check-lib-error ] literal fcall5-dq ;
: mpfr_min_prec ( a -- n )
   [ s" mpfr_min_prec" lsym check-lib-error ] literal fcall1 ;
: mpfr_print_rnd_mode ( n -- a )
   [ s" mpfr_print_rnd_mode" lsym check-lib-error ] literal fcall1 ;

\ 5.12 Miscellaneous Functions

: mpfr_nexttoward ( a a -- )
   [ s" mpfr_nexttoward" lsym check-lib-error ] literal fcall2 drop ;
: mpfr_nextabove ( a -- )
   [ s" mpfr_nextabove" lsym check-lib-error ] literal fcall1 drop ;
: mpfr_nextbelow ( a -- )
   [ s" mpfr_nextbelow" lsym check-lib-error ] literal fcall1 drop ;

: mpfr_min ( a a a n -- n )
   [ s" mpfr_min" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_max ( a a a n -- n )
   [ s" mpfr_max" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_urandomb ( a a -- n )
   [ s" mpfr_urandomb" lsym check-lib-error ] literal fcall2-dq ;
: mpfr_urandom ( a a n -- n )
   [ s" mpfr_urandom" lsym check-lib-error ] literal fcall3-dq ;

: mpfr_get_exp ( a -- ? )
   [ s" mpfr_get_exp" lsym check-lib-error ] literal fcall1 ;
: mpfr_set_exp ( a n -- n )
   [ s" mpfr_set_exp" lsym check-lib-error ] literal fcall2-dq ;

: mpfr_signbit ( a -- n )
   [ s" mpfr_signbit" lsym check-lib-error ] literal fcall1-dq ;
: mpfr_setsign ( a a n n -- n )
   [ s" mpfr_setsign" lsym check-lib-error ] literal fcall4-dq ;
: mpfr_copysign ( a a a n -- n )
   [ s" mpfr_copysign" lsym check-lib-error ] literal fcall4-dq ;

: mpfr_get_version ( -- a )
   [ s" mpfr_get_version" lsym check-lib-error ] literal fcall0 ;


\ 5.13 Exception Related Functions

\ Add:
\    mpfr_flags_clear ( a -- )
\    mpfr_flags_set ( a -- )
\   
: mpfr_get_emin ( -- n )
   [ s" mpfr_get_emin" lsym check-lib-error ] literal fcall0 ;
: mpfr_get_emax ( -- n )
   [ s" mpfr_get_emax" lsym check-lib-error ] literal fcall0 ;
: mpfr_set_emin ( n -- n )
   [ s" mpfr_set_emin" lsym check-lib-error ] literal fcall1 ;
: mpfr_set_emax ( n -- n )
   [ s" mpfr_set_emax" lsym check-lib-error ] literal fcall1 ;
: mpfr_get_emin_min ( -- n )
   [ s" mpfr_get_emin_min" lsym check-lib-error ] literal fcall0 ;
: mpfr_get_emin_max ( -- n )
   [ s" mpfr_get_emin_max" lsym check-lib-error ] literal fcall0 ;
: mpfr_get_emax_min ( -- n )
   [ s" mpfr_get_emax_min" lsym check-lib-error ] literal fcall0 ;
: mpfr_get_emax_max ( -- n )
   [ s" mpfr_get_emax_max" lsym check-lib-error ] literal fcall0 ;

: mpfr_check_range ( a n n -- n )
   [ s" mpfr_check_range" lsym check-lib-error ] literal fcall3-dq ;
: mpfr_subnormalize ( a n n -- n )
   [ s" mpfr_subnormalize" lsym check-lib-error ] literal fcall3 ;

: mpfr_clear_underflow ( -- )
   [ s" mpfr_clear_underflow" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_clear_overflow ( -- )
   [ s" mpfr_clear_overflow" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_clear_nanflag ( -- )
   [ s" mpfr_clear_nanflag" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_clear_inexflag ( -- )
   [ s" mpfr_clear_inexflag" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_clear_erangeflag ( -- )
   [ s" mpfr_clear_erangeflag" lsym check-lib-error ] literal fcall0 drop ;

: mpfr_set_underflow ( -- )
   [ s" mpfr_set_underflow" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_set_overflow ( -- )
   [ s" mpfr_set_overflow" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_set_nanflag ( -- )
   [ s" mpfr_set_nanflag" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_set_inexflag ( -- )
   [ s" mpfr_set_inexflag" lsym check-lib-error ] literal fcall0 drop ;
: mpfr_set_erangeflag ( -- )
   [ s" mpfr_set_erangeflag" lsym check-lib-error ] literal fcall0 drop ;

: mpfr_clear_flags ( -- )
   [ s" mpfr_clear_flags" lsym check-lib-error ] literal fcall0 drop ;

: mpfr_underflow_p ( -- n )
   [ s" mpfr_underflow_p" lsym check-lib-error ] literal fcall0-dq ;
: mpfr_overflow_p ( -- n )
   [ s" mpfr_overflow_p" lsym check-lib-error ] literal fcall0-dq ;
: mpfr_nanflag_p ( -- n )
   [ s" mpfr_nanflag_p" lsym check-lib-error ] literal fcall0-dq ;
: mpfr_inexflag_p ( -- n )
   [ s" mpfr_inexflag_p" lsym check-lib-error ] literal fcall0-dq ;
: mpfr_erangeflag_p ( -- n )
   [ s" mpfr_erangeflag_p" lsym check-lib-error ] literal fcall0-dq ;

\ 5.14 Compatibility With MPF

: mpfr_reldiff ( a a a n -- )
   [ s" mpfr_reldiff" lsym check-lib-error ] literal fcall4 drop ;

\ 5.15 Custom Interface


also forth definitions

