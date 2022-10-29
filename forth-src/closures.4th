\ closures.4th
\
\ Provides run-time generated unnamed functions which
\ bind runtime-computed value(s).
\
\ From Ruvim on comp.lang.forth, 10/17/2022
\  https://groups.google.com/g/comp.lang.forth/c/g-Je7CXe6DA/m/rbqXIIe3BQAJ
\

: partial1 ( x xt1 -- xt2 )
    2>r :noname r> r> postpone literal compile,
    postpone ;
;

: cl[n:d postpone [: ; immediate
: ]cl postpone ;] postpone partial1 ; immediate



