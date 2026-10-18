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

\ (F.N) print float to n decimals

create fpad 1024 allot

: .sign ( f -- )
\   13 and 32 + semit ;             \ prints bl for positive
    if 45 semit then ;             \ use this to only print -

: .zeros ( n -- )
    48 sfill ;
    
: s"0."  s" 0." stype ;
    
: one-or-zero ( F: r -- )           \ exp<=0 n=0 round to +-1 or 0
    fround>s 48 + semit ;
    
: f.n-case-00  ( F: r  --  )        \ exp<=0 n=0 round to +-1 or 0
\ ." f.n-case-00" cr
    one-or-zero 46 semit ;
     
: f.n-case-e+n<0 ( F: r -- ) ( n -- )
\ ." f.n-case-e+n<0" cr
    >r fdrop r>
    s"0." .zeros ;

: f.n-case-e+n=0 ( F: r -- ) ( n e -- )
\ ." f.n-case-e+n=0" cr
    2>r
    fdup r> abs s>f falog f* fswap  \ prepare fp for rounding
    r>
    1- f.n-case-e+n<0               \ print 1 less zero
    one-or-zero ;

: f.n-case-normal ( F: |r| -- )  ( n e -- )
\ ." f.n-case-normal" cr
    over +  1 max                   ( n e1=max{1, e+n} )
    fpad 1024 [char] 0 fill
    swap >r                         ( F: |r| ) ( e1 ) ( r: n )
    fpad swap represent 2drop       ( F: -- )  ( e' ) ( r: n )
    r> swap                         ( n e' ) 
    dup >r dup 0>                   ( n e' f ) ( r: e' ) 
    if                              \ exp >0
        fpad swap stype
        dup 0 >= if 46 semit then   \ n
        fpad r> +                   \ n fpad+e'
        swap 0 max stype
    else                            \ exp <=0
        s"0." abs .zeros
        fpad swap r> +              \ fpad n+e'
        stype
    then ;

    
: (f.n) ( F: r -- ) ( n -- caddr u )
    strbuf init-string-buf >r >r  \ save old string r: addr n
    fdup fabs fswap fpad 17 represent  \ find exp and sign  ( exp sign f )
    swap >r        \ print the sign ( F: |r|) ( exp flag) ( r: addr n sign)
    0= IF 
      drop fdrop
      r> fpad 3 s" inf" compare 0= IF .sign ELSE drop THEN    
      fpad 3 stype
      r> drop       ( r: addr)
    ELSE  
      r> .sign
      ( F: |r| ) ( exp ) ( r: addr n )
      r> swap  ( n exp ) ( r: addr )
      >r       ( n ) ( r: addr exp)
      dup 0 >= IF
        1024 r@ - min
      ELSE
        r@ 0 <= IF
          drop 0
        ELSE
          1 r@ - max  
        THEN
      THEN
      r>    ( F: |r|) ( n' exp ) ( r: addr ) 

      2dup 0 <= swap 0= and 
      IF  2drop f.n-case-00  ELSE
        2dup + 0<
      IF  drop f.n-case-e+n<0  ELSE
        2dup + 0=
      IF  f.n-case-e+n=0  ELSE
        f.n-case-normal
      THEN THEN THEN
    THEN r> >sbuf> ;

: f.n  (f.n) type space ;
