\ mpfr-utils.4th
\
\ utilities for mpfr types
\

create mpstr 256 allot
create mpexp 16  allot

\ Output a multi-precision float to specified number of digits in
\ base 10 using standard rounding
: mp>str ( amp u -- addr u )
    2>r mpstr mpexp 10 2r@ swap GMP_RNDN mpfr_get_str drop
    mpstr 2r> nip ;

: mpfr. ( amp u -- ) 
    mp>str
    over c@ [char] - = IF
      [char] - emit
      1- swap 1+ swap
    THEN
    [char] 0 emit [char] . emit type
    [char] E emit mpexp @ s>string count type ;

\ Compare significant digits in string with value in a multi-precision
\ variable. Return 0 if dst agrees to u significant digits; non-zero
\ otherwise
: sdcomp ( addr u amp -- n ) over mp>str compare ;



