\ numerov.4th
\
\ Integrate the 2nd order differential equation,
\
\   P''(r) = Q(r)P(r)
\
\ using the Numerov algorithm.
\
\ The Numerov algorithm may be expressed by the recurrence
\ relation,
\
\  F_n+1 = [(2 + 10*T_n)/(1 - T_n)]*F_n - F_n-1
\
\ where,
\
\    T_n = (h^2/12)*Q_n
\
\    F_n = (1 - T_n)*P_n
\
\ Given the input array, Q_n, and the first two values of the
\ array P, P_0 and P_1, initialized, the recurrence relation
\ is applied to compute the successive values of P_n. 
\
\
\ References:
\
\ 1. B. Numerov, Publs. observatoire central astrophys. Russ., 
\    v. 2, p. 188 (1933).
\
\ 2. http://en.wikipedia.org/wiki/Numerov%27s_method
\
\ 3. Anders Blom, 2002, "Computing algorithms for solving the 
\    Schroedinger and Poisson equations", available on the web at
\    http://www.teorfys.lu.se/personal/Anders.Blom/useful/scr.pdf
\
\ Copyright (c) 2010 Krishna Myneni
\
\ This code may be used for any purpose, as long as the
\ copyright notice above is preserved.
\
\ Revisions:
\    2011-09-16  km; use Neal Bridges' anonymous modules.
\    2012-02-19  km; use KM/DNW's modules library.

BEGIN-MODULE

BASE @
DECIMAL

Private:

0 ptr num_Q{
0 ptr num_P{

FLOAT DARRAY num_F{

fvariable h^2/12
fvariable T_n-1
fvariable T_n
fvariable T_n+1

Public:

: numerov_integrate ( 'P 'Q n h -- )
    FSQUARE 12e F/ h^2/12 F!
    >r  to num_Q{  to num_P{
    & num_F{ r@ }malloc
    malloc-fail? ABORT" numerov_integrate: Unable to allocate mem!"
    \ compute F_0 and F_1
    1e num_Q{ 0 } F@  h^2/12 F@ F* fdup T_n-1 F!  F- num_P{ 0 } F@ F*  num_F{ 0 } F!
    1e num_Q{ 1 } F@  h^2/12 F@ F* fdup T_n   F!  F- num_P{ 1 } F@ F*  num_F{ 1 } F!
    r> 2 DO
      num_Q{ I } F@  h^2/12 F@ F*  T_n+1 F!
      T_n F@ 10e F* 2e F+  num_F{ I 1- } F@ F*  1e  T_n F@ F- F/
      num_F{ I 2 - } F@  F-  fdup num_F{ I } F!
      1e T_n+1 F@ F- F/  num_P{ I } F!
      T_n F@  T_n-1 F!  T_n+1 F@  T_n F!
    LOOP
    & num_F{ }free
;


BASE !
END-MODULE      



