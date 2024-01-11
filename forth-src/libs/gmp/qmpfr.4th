\ qmpfr.4th
\
\ A small interface for MPFR arithmetic
\
\ Copyright (c) 2015--202 Krishna Myneni
\
\ Notation:
\ --------
\   q   an mpfr type, which is an address to a
\       structure containing the multiprecision
\       floating point data. A "q" occupies one
\       cell on the data stack.
\
\   u   an unsigned integer
\
\   r   a double precision floating point number
\
\ 
\ Provides the following arithmetic words:
\
\   quset  qdset  qset  qdget
\   q+   q-   q*   q/
\   qu+  qu-  qu*  qu/
\   qd+  qd-  qd*  qd/
\   qupow  qpow
\   qnegate  qabs  qsqrt  qexp   qln   qlog10
\   qcos     qsin  qtan   qacos  qasin qatan
\   qatan2
\
\ Prior to declaring and initializing q variables, with
\ mpfr_t and mpfr_init, for use with the above words,
\ execute SET-Q-PRECISION with the number of bits to use
\ for representing real numbers.
\
\ Requires:
\   libmpfr.4th  ( kForth interface to libmpfr.so, version >= 3 )
\  

Begin-Module


Public:

: set-q-precision ( ubits -- )
    dup 0> invert IF drop 128 THEN 
    mpfr_set_default_prec
;
 
: qset  ( qdst qsrc -- ) GMP_RNDN mpfr_set drop ;     
: quset ( q u -- ) GMP_RNDN mpfr_set_ui  drop ;
: qdset ( q r -- ) GMP_RNDN mpfr_set_d drop ;
: qdget ( q -- r ) GMP_RNDN mpfr_get_d ;

: q+  ( qdst q1 q2 -- ) GMP_RNDN mpfr_add drop ;
: q-  ( qdst q1 q2 -- ) GMP_RNDN mpfr_sub drop ;
: q*  ( qdst q1 q2 -- ) GMP_RNDN mpfr_mul drop ;
: q/  ( qdst q1 q2 -- ) GMP_RNDN mpfr_div drop ;

: qu+ ( qdst q u -- ) GMP_RNDN mpfr_add_ui drop ;
: qu- ( qdst q u -- ) GMP_RNDN mpfr_sub_ui drop ;
: qu* ( qdst q u -- ) GMP_RNDN mpfr_mul_ui drop ;
: qu/ ( qdst q u -- ) GMP_RNDN mpfr_div_ui drop ;

: qd+ ( qdst q r -- ) GMP_RNDN mpfr_add_d drop ;
: qd- ( qdst q r -- ) GMP_RNDN mpfr_sub_d drop ;
: qd* ( qdst q r -- ) GMP_RNDN mpfr_mul_d drop ;
: qd/ ( qdst q r -- ) GMP_RNDN mpfr_div_d drop ;

: qupow ( qdst q u -- ) GMP_RNDN mpfr_pow_ui drop ;
: qpow  ( qdst q1 q2 -- ) GMP_RNDN mpfr_pow drop ;

: qnegate ( qdst qsrc -- ) GMP_RNDN mpfr_neg drop ;
: qabs    ( qdst qsrc -- ) GMP_RNDN mpfr_abs drop ;
: qsqrt   ( qdst qsrc -- ) GMP_RNDN mpfr_sqrt drop ;
: qexp    ( qdst qsrc -- ) GMP_RNDN mpfr_exp drop ;
: qln     ( qdst qsrc -- ) GMP_RNDN mpfr_log drop ;
: qlog10  ( qdst qsrc -- ) GMP_RNDN mpfr_log10 drop ;
: qcos    ( qdst qsrc -- ) GMP_RNDN mpfr_cos drop ;
: qsin    ( qdst qsrc -- ) GMP_RNDN mpfr_sin drop ;
: qtan    ( qdst qsrc -- ) GMP_RNDN mpfr_tan drop ;
: qacos   ( qdst qsrc -- ) GMP_RNDN mpfr_acos drop ;
: qasin   ( qdst qsrc -- ) GMP_RNDN mpfr_asin drop ;
: qatan   ( qdst qsrc -- ) GMP_RNDN mpfr_atan drop ;
: qatan2  ( qdst qy qx -- ) GMP_RNDN mpfr_atan2 drop ;


End-Module

