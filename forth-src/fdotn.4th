\ fdotn.4th
\ by peter on c.l.f <peter@noreply.tin.it>
\
\ 02 Oct 2026
\
\ Revisions:
\   2026-10-04 km; modified to work on both unified fp/data stack
\              and separate fp stack systems.
\
\ Print double-precision floating point to n decimal places,
\ correctly rounded.
\
\ kForth user notes:
\   |n| is restricted to the range 0 <= |n| < 769

\ Cell counted string words
-1 [if]
: xcount ( addr -- addr+cell count )
    dup @ swap cell+ swap ; 
    
: xappend ( addr n addr2 -- ) \ append string to string at addr2
    2dup 2>r
    xcount + swap cmove
    r> xcount r> + swap 1 cells - ! ;
    
: xplace ( addr n addr2 -- ) \ place string to string at addr2    
    dup 0 swap !
    xappend ;

: cxappend ( c addr2 -- ) \ append c to end of string at addr2    
    dup >r xcount + c! 
    1 r> +! ;
    
: cxfill ( n c addr2 -- ) \ append n cs to the end of string at addr2
    >r over r@ swap >r 
    xcount + -rot fill
    r> r> +! ;

\ redirect output to memory

VARIABLE (string-buf)

: sbuf  (string-buf) a@ ;

: sbuf> sbuf xcount ;

: init-string-buf ( addr -- addr-old) \ retrieve addr-old from 
    (string-buf) a@ swap		     \ string-buf, place addr there
    dup 0 swap ! (string-buf) ! ;
    
: >sbuf>  ( addr-old -- addr len ) \ retrieve addr len and set 
    >r sbuf xcount		   \ string-buf to old value
    r> (string-buf) ! ;

: semit  ( c -- )		   \ type to buffer
    sbuf cxappend ;
    
: stype ( addr len -- )
	sbuf xappend ;
    
: sfill ( n c -- )                \ fill buffer with n cs
    sbuf cxfill ;

: nl   10 semit ; 

: s.  s>d swap over dabs <# #s rot sign #> stype ;

\ : strbuf 1024 allocate throw ;

variable (strindx)
create (strbuf) 16384 allot

: strbuf  ( -- addr )   \ circular buffer with 16 1024 buffers
     (strindx) dup >r a@ 1024 + 16384 mod dup r> ! (strbuf) + ;

[then]
\ print float to n decimals

create fpad 1024 allot

: .sign ( f -- )
\   13 and 32 + semit ;             \ prints bl for positive
    if 45 semit then ;             \ use this to only print -

: .zeros ( n -- )
    48 sfill ;
    
: s"0."  s" 0." stype ;
    
: one-or-zero ( F: r -- )           \ exp<=0 n=0 round to +-1 or 0
    fround>s 48 + semit ;           \ kForth version
\    fround f>s 48 + semit ;        \ ANS version
    
: f.n-case-00  ( F: r  --  )        \ exp<=0 n=0 round to +-1 or 0
    one-or-zero 46 semit ;
     
: f.n-case-e+n<0 ( F: r -- ) ( n  -- )
    >r fdrop r>
    s"0." .zeros ;

: f.n-case-e+n=0 ( F: r -- ) ( n e -- )
    2>r
    fdup r> abs s>f falog f* fswap  \ prepare fp for rounding
    r>
    1- f.n-case-e+n<0               \ print 1 less zero
    one-or-zero ;
    
: f.n-case-e>0 ( F: r -- ) (  n e -- )
    over + swap >r                  \ e+n  r: n  f: r
    fpad 1024 48 fill
    fpad swap represent 2drop       \ e' r: n
    dup >r                          \ e' r: n e'
    fpad swap stype 2r>             \ n e'
    over 0 >= if 46 semit then      \ n e' 
    fpad +                          \ n fpad+e'
    swap 0 max stype ;
    
: f.n-case-e<=0 ( F: r -- )  ( n e -- )
    over +  1 max swap >r           \ e+n r: n
    fpad 1024 48 fill
    fpad swap represent 2drop       \ e' r: n
    dup >r                          \ e' r: n e'
    s"0." abs .zeros  
    fpad 2r> +                      \ fpad n+e'
    stype ;

0 [IF]  \ original version
: (f.n) ( F:fp n -- )
    strbuf init-string-buf >r       \ save old string on rs
    fdup fpad 32 represent          \ find exp and sign
    swap .sign fabs                 \ print the sign
    0= if 2drop fdrop 
          fpad 3 stype else         \ print nan or inf             
    over 0< if 
        swap over 1- negate max swap else   \ limit negative n
        swap over 1024 swap - min swap then \ limit positive n
    2dup 0 <= swap 0= and             \ n e f
    if 2drop   f.n-case-00 else
    2dup + 0<
    if drop f.n-case-e+n<0 else
    2dup + 0=
    if  f.n-case-e+n=0 else
    dup 0>
    if  f.n-case-e>0 else
    f.n-case-e<=0 
    then then then then then r> >sbuf> ;
[THEN]
    
: (f.n) ( F: r -- ) ( n -- caddr u )
    strbuf init-string-buf >r >r  \ save old string r: addr n
    fdup fabs fswap fpad 32 represent  \ find exp and sign  ( exp sign f )
    swap .sign                    \ print the sign ( exp f )
    0= if drop fdrop 
      fpad 3 stype
      2r> 2drop EXIT
    else  
      r> swap over  \ n exp n  r: addr 
      0< if 
        swap over 1- negate max swap else   \ limit negative n
        swap over 1024 swap - min swap then \ limit positive n
        2dup 0 <= swap 0= and             \ n e f
    if 2drop f.n-case-00 else
    2dup + 0<
    if drop f.n-case-e+n<0 else
    2dup + 0=
    if  f.n-case-e+n=0 else
    dup 0>
    if  f.n-case-e>0 else
    f.n-case-e<=0 
    then then then then then r> >sbuf> ;

: f.n  (f.n) type space ;
