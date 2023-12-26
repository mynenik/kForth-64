(     Title:  kForth bindings for the GNU Multiple
              Precision Library, GNU MP 5.0.1
       File:  libgmp.4th
  Test file:  libgmp-test.4th
     Author:  David N. Williams
    License:  LGPL
    Version:  0.7.0
    Started:  February 24, 2011 
    Revised:  March 22, 2011 [ported to kForth-32 by KM]
              Dec 25, 2023 [partial port to kForth-64; km] 

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

vocabulary gmp
also gmp definitions

s" libgmp.so" open-lib
0= [IF]  check-lib-error  [THEN]
cr .( Opened the GMP library )
cr .( Loading gmp library functions ) cr

[undefined] struct [IF]
s" struct.4th" included
s" struct-ext.4th" included
[THEN]

\ from /usr/include/gmp-x.h
0 constant GMP_ERROR_NONE
1 constant GMP_ERROR_UNSUPPORTED_ARGUMENT
2 constant GMP_ERROR_DIVISION_BY_ZERO
4 constant GMP_ERROR_SQRT_OF_NEGATIVE
8 constant GMP_ERROR_INVALID_ARGUMENT

struct
        int:         mpz_struct->mp_alloc
        int:         mpz_struct->mp_size
        cell% field  mpz_struct->mp_d
end-struct  mpz_struct%

struct
        4 mpz_struct% %size field   mpq_struct->mp_num
        4 mpz_struct% %size field   mpq_struct->mp_den
end-struct  mpq_struct%

struct
        int:         mpf_struct->mp_prec
        int:         mpf_struct->mp_size
        int:         mpf_struct->mp_exp
        cell% field  mpf_struct->mp_d
end-struct  mpf_struct%

\ libgmp 5.0.1 functions

\ 5.1 Initialization

: mpz_init ( a -- )
   [ s" __gmpz_init"   lsym check-lib-error ] literal fcall1 drop ;

: mpz_clear ( a -- )
   [ s" __gmpz_clear"  lsym check-lib-error ] literal fcall1 drop ;


\ 5.2 Assignment

: mpz_set  ( a a -- )
   [ s" __gmpz_set"    lsym check-lib-error ] literal fcall2 drop ;

: mpz_set_ui ( a u -- )
   [ s" __gmpz_set_ui" lsym check-lib-error ] literal fcall2 drop ;

: mpz_set_si ( a n -- )
   [ s" __gmpz_set_si" lsym check-lib-error ] literal fcall2 drop ;

: mpz_set_d ( a -- ) ( F: r -- )
  [ s" __gmpz_set_d" lsym check-lib-error ] literal fcall(1,1;0,0) ;

: mpz_set_q ( a a -- )
   [ s" __gmpz_set_q" lsym check-lib-error ] literal fcall2 drop ;

: mpz_set_f ( a a -- )
   [ s" __gmpz_set_f" lsym check-lib-error ] literal fcall2 drop ;

: mpz_set_str ( a a n -- n )
   [ s" __gmpz_set_str"  lsym check-lib-error ] literal fcall3 ;

: mpz_swap ( a a -- )
   [ s" __gmpz_swap" lsym check-lib-error ] literal fcall2 drop ;


\ 5.3 Combined initialization and assignment

: mpz_init_set ( a a -- )
   [ s" __gmpz_init_set" lsym check-lib-error ] literal fcall2 drop ;

: mpz_init_set_ui ( a u -- )
   [ s" __gmpz_init_set_ui" lsym check-lib-error ] literal fcall2 drop ;

: mpz_init_set_si ( a n -- )
   [ s" __gmpz_init_set_si" lsym check-lib-error ] literal fcall2 drop ;

: mpz_init_set_d ( a -- ) ( F: r -- )
   [ s" __gmpz_init_set_d" lsym check-lib-error ] literal fcall(1,1;0,0) ;

: mpz_init_set_str ( a a n -- n )
   [ s" __gmpz_init_set_str" lsym check-lib-error ] literal fcall3 ;


\ 5.4 Conversion

: mpz_get_ui ( a -- u )
   [ s" __gmpz_get_ui" lsym check-lib-error ] literal fcall1 ;

: mpz_get_si ( a -- n )
   [ s" __gmpz_get_si" lsym check-lib-error ] literal fcall1 ;

: mpz_get_d ( a -- ) ( F: -- r )
  [ s" __gmpz_get_d"  lsym check-lib-error ] literal fcall(1,0;1,1) drop ;

\ mpz_get_d_2exp ( a a -- ) ( F: -- r )
\  [ s" __gmpz_get_d_2exp" lsym check-lib-error ] literal fcall2_r1 ;

\ first arg is zstring, second arg is base, third arg is mpz
: mpz_get_str ( a n a -- a )
   [ s" __gmpz_get_str"  lsym check-lib-error ] literal fcall3 ;


\ 5.5 Arithmetic

: mpz_add ( a a a -- )
   [ s" __gmpz_add"    lsym check-lib-error ] literal fcall3 drop ;

: mpz_add_ui ( a a n -- )
   [ s" __gmpz_add_ui" lsym check-lib-error ] literal fcall3 drop ;

: mpz_sub ( a a a -- )
   [ s" __gmpz_sub"    lsym check-lib-error ] literal fcall3 drop ;

: mpz_sub_ui ( a a n -- )
   [ s" __gmpz_sub_ui" lsym check-lib-error ] literal fcall3 drop ;

: mpz_ui_sub ( a n a -- )
   [ s" __gmpz_ui_sub" lsym check-lib-error ] literal fcall3 drop ;

: mpz_mul ( a a a -- )
   [ s" __gmpz_mul"    lsym check-lib-error ] literal fcall3 drop ;

: mpz_mul_si ( a a n -- )
   [ s" __gmpz_mul_si" lsym check-lib-error ] literal fcall3 drop ;

: mpz_mul_ui ( a a n -- )
   [ s" __gmpz_mul_ui" lsym check-lib-error ] literal fcall3 drop ;

: mpz_addmul ( a a a -- )
   [ s" __gmpz_addmul" lsym check-lib-error ] literal fcall3 drop ;

: mpz_addmul_ui ( a a n -- )
   [ s" __gmpz_addmul_ui" lsym check-lib-error ] literal fcall3 drop ;

: mpz_submul ( a a a -- )
   [ s" __gmpz_submul" lsym check-lib-error ] literal fcall3 drop ;

: mpz_submul_ui ( a a n -- )
   [ s" __gmpz_submul_ui" lsym check-lib-error ] literal fcall3 drop ;

: mpz_mul_2exp ( a a n -- )
   [ s" __gmpz_mul_2exp"  lsym check-lib-error ] literal fcall3 drop ;

: mpz_neg ( a a -- )
   [ s" __gmpz_neg"   lsym check-lib-error ] literal fcall2 drop ;

: mpz_abs ( a a -- )
   [ s" __gmpz_abs"   lsym check-lib-error ] literal fcall2 drop ;

\ 5.6 Division

: mpz_cdiv_q ( a a a -- )
   [ s" __gmpz_cdiv_q" lsym check-lib-error ] literal fcall3 drop ;

: mpz_cdiv_r ( a a a -- )
   [ s" __gmpz_cdiv_r" lsym check-lib-error ] literal fcall3 drop ;

\ : mpz_cdiv_qr ( a a a a -- )
\   [ s" __gmpz_cdiv_qr" lsym check-lib-error ] literal fcall4 drop ;

: mpz_cdiv_q_ui ( a a n -- n )
   [ s" __gmpz_cdiv_q_ui" lsym check-lib-error ] literal fcall3 ;

: mpz_cdiv_r_ui ( a a n -- n )
   [ s" __gmpz_cdiv_r_ui" lsym check-lib-error ] literal fcall3 ;

\ : mpz_cdiv_qr_ui ( a a a n -- n )
\   [ s" __gmpz_cdiv_qr_ui" lsym check-lib-error ] literal fcall4 ;

: mpz_cdiv_ui ( a n -- n )
   [ s" __gmpz_cdiv_ui" lsym check-lib-error ] literal fcall2 ;

: mpz_cdiv_q_2exp ( a a n -- )
   [ s" __gmpz_cdiv_q_2exp" lsym check-lib-error ] literal fcall3 drop ;

: mpz_cdiv_r_2exp ( a a n -- )
   [ s" __gmpz_cdiv_r_2exp" lsym check-lib-error ] literal fcall3 drop ;

: mpz_fdiv_q ( a a a -- )
   [ s" __gmpz_fdiv_q" lsym check-lib-error ] literal fcall3 drop ;

: mpz_fdiv_r ( a a a -- )
   [ s" __gmpz_fdiv_r" lsym check-lib-error ] literal fcall3 drop ;

\ : mpz_fdiv_qr ( a a a a -- )
\   [ s" __gmpz_fdiv_qr" lsym check-lib-error ] literal fcall4 drop ;

\ mpz_fdiv_q_ui
\ mpz_fdiv_r_ui
\ mpz_fdiv_qr_ui
\ mpz_fdiv_ui
\ mpz_fdiv_q_2exp
\ mpz_fdiv_r_2exp
\ etc.

: mpz_mod ( a a a -- )
   [ s" __gmpz_mod" lsym check-lib-error ] literal fcall3 drop ;


\ 5.7 Exponentiation

\ : mpz_powm ( a a a a -- )
\   [ s" __gmpz_powm" lsym check-lib-error ] literal fcall4 drop ;

\ : mpz_powm_ui ( a a n a -- )
\   [ s" __gmpz_powm_ui" lsym check-lib-error ] literal fcall4 drop ;

: mpz_pow_ui ( a a n -- )
   [ s" __gmpz_pow_ui" lsym check-lib-error ] literal fcall3 drop ;

: mpz_ui_pow_ui ( a n n -- )
   [ s" __gmpz_ui_pow_ui" lsym check-lib-error ] literal fcall3 drop ;


\ 5.8 Root extraction

: mpz_root ( a a n -- n )
   [ s" __gmpz_root" lsym check-lib-error ] literal fcall3 ;

\ : mpz_rootrem ( a a a n -- )
\   [ s" __gmpz_rootrem" lsym check-lib-error ] literal fcall4 drop ;

: mpz_sqrt ( a a -- )
   [ s" __gmpz_sqrt" lsym check-lib-error ] literal fcall2 drop ;

: mpz_sqrtrem ( a a a -- )
   [ s" __gmpz_sqrtrem" lsym check-lib-error ] literal fcall3 drop ;

: mpz_perfect_power_p ( a -- n )
   [ s" __gmpz_perfect_power_p" lsym check-lib-error ] literal fcall1 ;

: mpz_perfect_square_p ( a -- n )
   [ s" __gmpz_perfect_square_p" lsym check-lib-error ] literal fcall1 ;


\ 5.9 Number theoretics

: mpz_probab_prime_p ( a n -- n )
   [ s" __gmpz_probab_prime_p" lsym check-lib-error ] literal fcall2 ;

: mpz_nextprime ( a a -- )
   [ s" __gmpz_nextprime" lsym check-lib-error ] literal fcall2 drop ;

: mpz_gcd ( a a a -- )
   [ s" __gmpz_gcd" lsym check-lib-error ] literal fcall3 drop ;

: mpz_gcd_ui ( a a n -- n )
   [ s" __gmpz_gcd_ui" lsym check-lib-error ] literal fcall3 drop ;

\ : mpz_gcdext ( a a a a a -- )
\   [ s" __gmpz_gcdext" lsym check-lib-error ] literal fcall5 drop ;

: mpz_lcm ( a a a -- )
   [ s" __gmpz_lcm" lsym check-lib-error ] literal fcall3 drop ;

: mpz_lcm_ui ( a a n -- )
   [ s" __gmpz_lcm_ui" lsym check-lib-error ] literal fcall3 drop ;

: mpz_invert ( a a a -- n )
   [ s" __gmpz_invert" lsym check-lib-error ] literal fcall3 ;

: mpz_jacobi ( a a -- n )
   [ s" __gmpz_jacobi" lsym check-lib-error ] literal fcall2 ;

: mpz_legendre ( a a -- n )
   [ s" __gmpz_legendre" lsym check-lib-error ] literal fcall2 ;

\ mpz_kronecker is same as mpz_jacobi  (see /usr/include/gmp-i386.h)


\ 5.10 Comparison

: mpz_cmp ( a a -- n )
   [ s" __gmpz_cmp"    lsym check-lib-error ] literal fcall2 ;

: mpz_cmp_d ( a -- n ) ( F: r -- )
   [ s" __gmpz_cmp_d" lsym check-lib-error ] literal fcall(1,1;1,0) ;

: mpz_cmp_si ( a n -- n )
   [ s" __gmpz_cmp_si" lsym check-lib-error ] literal fcall2 ;

: mpz_cmp_ui ( a u -- n )
   [ s" __gmpz_cmp_ui" lsym check-lib-error ] literal fcall2 ;

: mpz_cmpabs ( a a -- n )
   [ s" __gmpz_cmpabs" lsym check-lib-error ] literal fcall2 ;

: mpz_cmpabs_d ( a -- n ) ( F: r -- )
   [ s" __gmpz_cmpabs_d" lsym check-lib-error ] literal fcall(1,1;1,0) ;

: mpz_cmpabs_ui ( a u -- n )
   [ s" __gmpz_cmpabs_ui" lsym check-lib-error ] literal fcall2 ;

: mpz_sgn ( a -- n )
    mpz_struct->mp_size @
    dup 0<  IF drop -1 ELSE
      0> IF 1 ELSE 0 THEN
    THEN ;

: sizeof_mpz ( -- n ) mpz_struct% %size ;
: sizeof_mpq ( -- n ) mpq_struct% %size ;
: sizeof_mpf ( -- n ) mpf_struct% %size ;

sizeof_mpz constant /MPZ
sizeof_mpq constant /MPQ
sizeof_mpf constant /MPF

also forth definitions

