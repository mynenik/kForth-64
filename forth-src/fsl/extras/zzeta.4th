(
 * LANGUAGE    : ANS Forth with extensions
 * PROJECT     : Forth Environments
 * DESCRIPTION : The Riemann Zeta function [real and complex]
 * CATEGORY    : Special functions
 * AUTHOR      : Marcel Hendrix
 * LAST CHANGE : April 29, 2012, Marcel Hendrix
)

\ Original 60-digit precision version posted to comp.lang.forth
\ by Marcel Hendrix on 30 April 2012. Ported for FSL compatibility
\ and use with double precision, by K. Myneni, 2 May 2012.
\
\ Provides:
\
\   zeta  ( F: r1 -- r2 )   \ real zeta function
\   zzeta ( F: z1 -- z2 )   \ complex zeta function
\
\ Requires:
\
\   modules.x
\   fsl/fsl-util.x
\   fsl/complex.x
\   ttester.x  ( to execute test code )
\
\  Notes:
\
\  In Canadian Mathematical Society, Conference Proceedings, 1991.
\  'An Efficient Algorithm for the Riemann Zeta Function,' P. Borwein
\
\  Borwein's algorithm 2:
\
\              k
\            .--- (n+i-1)! * 4^i
\  d_k = n *  >   ---------------
\            '--- (n-i)! * (2*i)!
\             i=0
\
\                                n-1
\                 -1           .---- (-1)^k (d_k - d_n)
\  Zeta(s) = --------------- *  >    ------------------
\            d_n*(1-2^(1-s))   '----      (k+1)^s
\                                k=0
\
\  The algorithm only works for Re(s) > 1. A special case is when
\  Im(s) = 0.5, but it relates to efficiency, not to accuracy.

cr .( Riemann Zeta Function    Version 1.00 MHX )

Begin-Module

BASE @ DECIMAL

[UNDEFINED] f2^  [IF] : f2^  ( F: x -- r ) 2e fswap f** ; [THEN]
[UNDEFINED] f2*  [IF] : f2*  ( F: x -- r ) 2e f* ; [THEN]

16 value N_valid_digits 
N_valid_digits 14 10 */ value N
N 1+ float array Zc{

fvariable x
fvariable y
fvariable z
zvariable zx 
0e 0e zx z!

:NONAME ( -- )
    1.0e x f!
    1.0e y f!
    1.0e z f!
    N 1+ 0 DO  
      x f@ Zc{ I } f!
       N I - s>f  N I + s>f f* 4.0e f* y f@ f* fdup y f!
       I 2* 1+ s>f  I 2* 2+ s>f f*  z f@ f* fdup z f!
       ( y z ) f/ x f@ f+ x f!
    LOOP ;
execute

Public:

\ Valid for x > 1
: zeta ( F: x -- z )
    x f!
    0.0e
    0 N 1- ?DO
       Zc{ N } f@  Zc{ I } f@ f-
       I 1+ s>f x f@ f**  f/ fswap f-
    -1 +LOOP
    ( sum) 
    Zc{ N } f@ f/ x f@ fnegate f2^ f2* 1.0e fswap f-  f/
;

: zzeta ( F: z1 -- z2 )
   zx z!
   0e 0e
   0 N 1- ?DO
      Zc{ N } f@  Zc{ I } f@  f-  0e
      I 1+ s>f  0e zx z@ z^  z/ zswap z-
   -1 +LOOP
   ( sum) Zc{ N } f@ z/f  
   2e 0e zx z@ znegate z^  2e z*f  1e 0e zswap z- z/ 
;

BASE !
End-Module

test-code? [IF]
include ttester
BASE @
DECIMAL

1e-256 abs-near f!
2e-16  rel-near f!   
set-near

\ 60 digit reference values computed by Marcel Hendrix
\ using MPFR/MPC version of zzeta.

1e 0e f/ fconstant +inf
cr
TESTING ZETA
t{  0e zeta  ->  -5.00000000000000e-01  r}t
t{  1e zeta  ->  +inf  r}t
t{  2e zeta  ->  1.6449340668482264364724151666460251892190e r}t
t{  3e zeta  ->  1.2020569031595942853997381615114499907651e r}t
t{  4e zeta  ->  1.0823232337111381915160036965411679027749e r}t
t{  5e zeta  ->  1.0369277551433699263313654864570341680573e r}t
t{  6e zeta  ->  1.0173430619844491397145179297909205279018e r}t
t{  7e zeta  ->  1.0083492773819228268397975498497967595993e r}t
t{  8e zeta  ->  1.0040773561979443393786852385086524652574e r}t
t{  9e zeta  ->  1.0020083928260822144178527692324120604826e r}t
t{ 10e zeta  ->  1.0009945751278180853371459589003190170015e r}t
t{ 11e zeta  ->  1.0004941886041194645587022825264699364626e r}t
t{ 12e zeta  ->  1.0002460865533080482986379980477396709530e r}t
t{ 13e zeta  ->  1.0001227133475784891467518365263573957058e r}t
t{ 14e zeta  ->  1.0000612481350587048292585451051353337383e r}t
t{ 15e zeta  ->  1.0000305882363070204935517285106450625779e r}t
t{ 16e zeta  ->  1.0000152822594086518717325714876367220132e r}t
t{ 17e zeta  ->  1.0000076371976378997622736002935630292028e r}t
t{ 18e zeta  ->  1.0000038172932649998398564616446219397200e r}t
t{ 19e zeta  ->  1.0000019082127165539389256569577951013428e r}t
t{ 20e zeta  ->  1.0000009539620338727961131520386834493354e r}t

\ need some reference values for points off the real axis. km,20120502
TESTING ZZETA
t{  2e 0e zzeta  -> 1.6449340668482264364724151666460251892189e0 0e rr}t
t{  3e 0e zzeta  -> 1.2020569031595942853997381615114499907649e0 0e rr}t
t{  4e 0e zzeta  -> 1.0823232337111381915160036965411679027747e0 0e rr}t
t{  5e 0e zzeta  -> 1.0369277551433699263313654864570341680570e0 0e rr}t                    
t{  6e 0e zzeta  -> 1.0173430619844491397145179297909205279018e0 0e rr}t
t{  7e 0e zzeta  -> 1.0083492773819228268397975498497967595998e0 0e rr}t
t{  8e 0e zzeta  -> 1.0040773561979443393786852385086524652589e0 0e rr}t
t{  9e 0e zzeta  -> 1.0020083928260822144178527692324120604856e0 0e rr}t
t{ 10e 0e zzeta  -> 1.0009945751278180853371459589003190170060e0 0e rr}t
t{ 11e 0e zzeta  -> 1.0004941886041194645587022825264699364686e0 0e rr}t
t{ 12e 0e zzeta  -> 1.0002460865533080482986379980477396709604e0 0e rr}t
t{ 13e 0e zzeta  -> 1.0001227133475784891467518365263573957142e0 0e rr}t
t{ 14e 0e zzeta  -> 1.0000612481350587048292585451051353337474e0 0e rr}t
t{ 15e 0e zzeta  -> 1.0000305882363070204935517285106450625876e0 0e rr}t
t{ 16e 0e zzeta  -> 1.0000152822594086518717325714876367220232e0 0e rr}t
t{ 17e 0e zzeta  -> 1.0000076371976378997622736002935630292130e0 0e rr}t
t{ 18e 0e zzeta  -> 1.0000038172932649998398564616446219397304e0 0e rr}t
t{ 19e 0e zzeta  -> 1.0000019082127165539389256569577951013532e0 0e rr}t
t{ 20e 0e zzeta  -> 1.0000009539620338727961131520386834493459e0 0e rr}t

BASE !
[THEN]

