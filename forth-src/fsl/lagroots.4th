\ lagroots   Laguerre algorithm for polynomial roots

\ Forth Scientific Library Algorithm #61


FALSE [IF]

  ----------------------------------------------------
  |   (c) Copyright 2000  Julian V. Noble.           |
  |       Permission is granted by the author to     |
  |       use this software for any application pro- |
  |       vided this copyright notice is preserved.  |
  ----------------------------------------------------

  This algorithm was submitted to the Forth Scientific Library by JVN
  but had not been reviewed by the time of his death.  Some adjustments
  have been made by C. G. Montgomery in the course of the reviewing process.
  The original submission simply printed the roots obtained, but included
  the comments "The complex roots found are printed.  This is ugly.
  Improving it would require changing things."
  For this version, David N. Williams has provided the changes needed:
  the roots are stored in an array.  Words are also provided to print
  them if desired.

  (lagroots.fs   Version 1.0   30 November 2010   cgm)

  References:

       F.S. Acton, "Numerical Methods that (Usually) Work"
       (Mathematical Ass'n of America, Washington, DC, 1990)

       http://en.wikipedia.org/wiki/Laguerre%27s_method

  Algorithm:

       For a given z, assume z - z1 = a, and for all other
       roots, z - zn = b ; then

           G = p'(z)/p(z) = 1/a + (n-1)/b
       and

           H = G^2 - p"(z)/p(z) = 1/a^2 + (n-1)/b^2 .

       Eliminate b to get

           a = n/( G +- sqrt((nH-G^2)*(n-1)) ) .

       The next guess is z' = z - a .
       Iterate until converged, then deflate polynomial
        by the factor (z - root) and repeat.

  This is an ANS Forth program requiring the
  FLOAT, FLOAT EXT, FILE and TOOLS EXT wordsets.

  Environmental dependencies:

       Assumes an independent floating point stack

       Complex numbers and functions follow the conventions and
       nomenclature of complex.fs, Algorithm 60 of the FSL,
       version 1.0.2 or later, which should be loaded before this file.

       The complex sqrt function, ZSQRT, is assumed to map
       (0, 2*pi) into (0, pi). That is, its branch cut is the
       positive real axis.  Therefore the value PRINCIPAL-ARG
       in complex.fs is set to FALSE.

       Arrays are generated and accessed with the FSL
       words ARRAY and }

[THEN]

\ Usage:
\    Store the coefficients of the input polynomial in a{ .
\    Then       z0 eps d{ n  roots 
\      where n is the order of the polynomial
\            z0 is an initial guess at a root
\            eps is the desired precision          
\    will store the roots found in the array d{ .
\    They can be printed by executing
\               d{ n }z.
\    or         d{ n }zs.

\    Note that the array a{ of n+1 coefficients is overwritten.

\ Revisions:
\   2010-12-28 km  version 1.0.2 revised for use with unified stack 
\                  systems and separate fp stack systems (note that 
\                  order of arguments is important!); replaced use 
\                  of }zmov with }zcopy (the two are not identical); 
\                  save and restore base; use Public: Private: to 
\                  hide internal data; added word ZROOTS to pass 
\                  input coefficients as arg to root finder. Changed 
\                  example code to automated test code (with ttester),
\                  with reference values exact to machine precision.
\   2011-09-16 km  use Neal Bridges' anonymous modules.
\   2012-02-19 km  use KM/DNW's modules library
CR .( LAGROOTS          V1.0.2b        19 February  2012  JVN, CGM)
BEGIN-MODULE

BASE @
DECIMAL

FALSE TO PRINCIPAL-ARG

\ complex fp arrays
\ the j-th component of an array is the coefficient of z^j

Private:
20 constant MAX_TERMS

MAX_TERMS  COMPLEX  array a{  \ (complex) coefficients of input polynomial
MAX_TERMS  COMPLEX  array b{  \ coefficients of quotient polynomial
MAX_TERMS  COMPLEX  array c{  \ coefficients related to 1st derivative
MAX_TERMS  COMPLEX  array d{  \ results

\ complex variables

: zvariables    ( n --)  0 DO  zvariable  LOOP  ;

3 zvariables  p'  zz  zp

fvariable epsilon

6 VALUE max_iter

\ ------------------------------------------- synthetic division
\   p[z] = (z-s) * q[z] + p[s]
\   'p is address of coeff array of input polynomial p
\   'q is address of coeff array of quotient polynomial q
\   n is degree of polynomial

Private:

0 ptr p{
0 ptr q{

Public:

: }zsynth  ( r 'p 'q n -- p[r])  \ ( 'p 'q n -- ) ( f: s -- p[s])
    >r to q{  to p{ \ LOCALS| n q{ p{ |
    p{ r@ } z@                      ( f: -- s q_[n-1]=p_n)
    0  r> 1- DO                      \ count down from n-1 to 1
        zdup q{ I } z!              \ store q_i
        zover z*                    ( f: -- s q_[i]*s) 
        p{ I } z@ z+                ( f: -- s q_[i-1]=[q_i]*s+p_i])
    -1 +LOOP                        ( f: -- s p[s])
    znip
;
\ --------------------------------------- end synthetic division

\ ---------------------------------------------- Horner's method
\ Evaluate the complex polynomial of degree n.  Based on FSL
\ Algorithm 3, the Horner method.

Private:

0 ptr p{

Public:

: }zpeval ( z 'p +n -- p[z])  \ ( 'p +n -- ) ( f: z -- p[z] )
  >r to p{
  0e 0e 
  0 r> DO zover z* ( a{ ) p{ i } z@ z+ -1 +LOOP
  zswap zdrop
;
\ ------------------------------------------ end Horner's method

: zmax     ( f: z1 z2 -- z1 | z2)   \ leave value with larger |z|
    zover zover                     ( f: z1 z2 z1 z2)
    |z|^2  -frot |z|^2              ( f: -- z1 z2 |z2|^2  |z1|^2)
    F<   IF zdrop  ELSE  znip  THEN  ;

Private:

0 value n

Public:

: new_diff   ( z n -- a)   \ ( n --) ( f: z -- a)  \ calculate
    to n  \  LOCALS| n |
    zdup zz z!                  \ save initial guess
    a{ b{ n }zsynth             ( f: -- p[z]) 
    zz z@  b{ c{ n 1- }zsynth   ( f: -- p[z] p'[z] )
    p' z!
    zz z@  c{ n 2 - }zpeval     ( f: -- p[z] p"[z]/2 )
    z2*  zover  z*  znegate     ( f: -- p[z] -p[z]*p"[z] )
    p' z@  z^2  z+              ( f: -- p[z] H*p^2)
    n s>f  z*f  p' z@  z^2 z-   ( f: -- p[z] n*H*p^2-p'^2)
    n 1-  s>f  z*f  zsqrt       ( f: -- p[z] R)
    zdup  znegate               ( f: -- p[z] R  -R)
    p' z@  z+                   ( f: -- p[z] R p'-R)
    zswap p' z@  z+             ( f: -- p[z] p'-R p'+R)
    zmax   z/                   ( f: -- p[z]/zmax[p'-R,p'+R])
    n s>f  z*f     \ a = n*p/( p' +|- sqrt((nH*p^2-p'^2)*(n-1)) )
;

: new_z     ( f: a --)   znegate  zz z@  z+ zp z!  ;

: apart?    zz z@ zp z@  z-  |z|  epsilon f@  F>  ;

Private:

0 value n
0 value #iter

Public:

: <root>   ( n -- zroot)  \ ( n --) ( f: -- root)
    0                           \ #iter = 0
    to #iter  to n  \ LOCALS| #iter n |
    zz z@  n new_diff  new_z    \ compute zp = zz - a
    BEGIN   apart?
            #iter max_iter <
            AND
    WHILE   zp z@
            n new_diff  new_z   \ zp = zz - a
            #iter 1+ TO #iter
    REPEAT
;

\ Find the roots of a polynomial p, with three coefficients and
\ degree two or less.  The three possible results, with two,
\ one, or no roots on the fp stack, leave 2, 1, or 0 on the data
\ stack.

Private:

0 ptr p{

Public:

: quadroots  ( 'p -- [2 f: z1 z2] | [1 f: z1] | 0 )
  to p{  \ LOCALS| p{ |
  p{ 2 } z@  0e 0e z=
  IF  p{ 1 } z@ 0e 0e z=
    IF    0          \ p{1} and p{2} = 0
    ELSE             \ p{2} = 0
       p{ 0 } z@ p{ 1 } z@ z/ znegate
       1 \ single root
    THEN
  ELSE               \ p{2} <> 0; 2 roots
    p{ 1 } z@  znegate    ( f: -b)
    zdup  z^2
    p{ 0 } z@  p{ 2 } z@
    z*  z2*  z2*  z-
    zsqrt                  ( f: -b d)
    zover zover            ( f: -b d -b d)
    z+  z2/  p{ 2 } z@ z/  ( f: -b d z1)
    -zrot
    z-  z2/  p{ 2 } z@ z/
    2 \ pair of roots
  THEN
;

\ }zcopy assumes contiguous array storage
: }zcopy  ( src dst n -- )  \ copy first n elements from src to dst
    COMPLEXES >r 0 } swap 0 } swap r> move ;

\  n >= 2 is degree of input polynomial in a{
\ 'd is addr of complex array for storing n roots

Private:

0 value n
0 ptr d{

Public:

: roots   ( z0 epsilon 'd +n -- )   \ ( 'd +n --) ( f: z0 epsilon -- )
    to n  to d{  \ LOCALS| n d{ |
    n 2 < ABORT" roots: polynomial degree must be at least 2"
    epsilon F!  zz z!
    BEGIN   n 2 >
    WHILE   n <root>          \ get a root
            n 1-  TO n
            zp z@ d{ n } z!   \ store it
            b{ a{ n 1+ }zcopy \ create q_{n-1}
    REPEAT
    a{ quadroots ( 2) drop
    d{ 1 } z!   d{ 0 } z!
;

: zroots ( z0 epsilon 'inp 'out +n -- )
    dup 1+ MAX_TERMS > ABORT" polynomial order is too high!"
    >r swap a{ r@ 1+ }zcopy
    r> roots ;

\ display the first m elements of a complex 1-array with their indices

: }zs. ( 'a m -- )  0 DO i . ( 'a) dup i } z@ zs. cr LOOP drop ;
: }z.  ( 'a m -- )  0 DO i . ( 'a) dup i } z@ z.  cr LOOP drop ;

BASE !
END-MODULE

\ some examples for testing

TEST-CODE? [IF]
[undefined] T{  [IF] s" ttester" included [THEN]
: z}t  rr}t ;

BASE @
DECIMAL

1e-15 abs-near f!
1e-15 rel-near f!
set-near

\ Test case for synthetic division:

7 COMPLEX ARRAY  a{
7 COMPLEX ARRAY  b{

        7.e0 0e0 a{ 0 } z!
       -5.e0 0e0 a{ 1 } z!
        1.e0 0e0 a{ 2 } z!
      -14.e0 0e0 a{ 3 } z!
        0.e0 0e0 a{ 4 } z!
        3.e0 0e0 a{ 5 } z!

CR TESTING }ZSYNTH
t{ 5.e0 0e0  a{ b{ 5 }zsynth  ->  7.63200E3  0.00000E-1  z}t
t{ b{ 0 } z@  ->  1.52500E3  0.00000E0  z}t
t{ b{ 1 } z@  ->  3.06000E2  0.00000E0  z}t
t{ b{ 2 } z@  ->  6.10000E1  0.00000E0  z}t
t{ b{ 3 } z@  ->  1.50000E1  0.00000E0  z}t
t{ b{ 4 } z@  ->  3.00000E0  0.00000E0  z}t


\ Test case for roots:
\
\   p(z) = z^6 + 4*z^5 - 6*z^4 - 4*z^3 - 7*z^2 - 48*z + 60

        1.e0 0e0 a{ 6 } z!
        4.e0 0e0 a{ 5 } z!
       -6.e0 0e0 a{ 4 } z!
       -4.e0 0e0 a{ 3 } z!
       -7.e0 0e0 a{ 2 } z!
      -48.e0 0e0 a{ 1 } z!
       60.e0 0e0 a{ 0 } z!

\ Exact roots from Maxima:
\
\ (%i2) solve(z^6 + 4*z^5 - 6*z^4 - 4*z^3 - 7*z^2 - 48*z + 60 = 0, z);
\ (%o2) [z = 2, z = - 2, z = 1, z = - sqrt(3) %i, z = sqrt(3) %i, z = - 5]

TESTING ZROOTS
3e fsqrt fconstant sqrt{3}
t{ 10e0 0e0 1e-15 a{ b{ 6 zroots  ->  }t
t{ b{ 0 } z@  ->  -5e  0e  z}t
t{ b{ 1 } z@  ->   0e  sqrt{3} fnegate  z}t
t{ b{ 2 } z@  ->  -2e  0e  z}t
t{ b{ 3 } z@  ->   0e  sqrt{3}  z}t
t{ b{ 4 } z@  ->   1e  0e  z}t
t{ b{ 5 } z@  ->   2e  0e  z}t

BASE !
[THEN]

