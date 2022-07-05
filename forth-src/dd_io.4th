\ Double Double-precision arithmetic  I/O words
\
\ ---------------------------------------------------
\     (c) Copyright 2006  Julian V. Noble.          \
\       Permission is granted by the author to      \
\       use this software for any application pro-  \
\       vided this copyright notice is preserved.   \
\ ---------------------------------------------------

\ This is an ANS Forth program requiring the
\   FLOAT, FLOAT EXT, FILE and TOOLS EXT wordsets.
\
\ Environmental dependences:
\       Assumes independent floating point stack

\ Based on I/O subroutines from
\
\   DDFUN: A Double-Double Floating Point Computation Package
\   IEEE Fortran-90 version
\   Version Date:  2005-01-26
\
\   Author:
\
\      David H. Bailey
\      NERSC, Lawrence Berkeley Lab
\      Mail Stop 50B-2239
\      Berkeley, CA 94720
\      Email: dhbailey@lbl.gov
\
\  GLOSSARY:
\
\    DD>$  ( F: x xx -- ) ( -- caddr u )  convert dd# to string
\    DDFS. ( F: x xx -- )                 output the dd#
\
\ Notes:
\
\  1. DD>$ has been modified to use PRECISION setting.
\
\ Requires:
\   ans-words
\   ddarith

[UNDEFINED] f>s [IF] : f>s f>d d>s ; [THEN]
[UNDEFINED] tab [IF] : tab 9 emit ; [THEN]

\ Output a dd# .

\ Algorithm:
\
\  1. Determine sign and power of 10
\  2. Normalize so that significand lies between 1 and 10
\  3. Peel digits off from left by converting to integer
\       multiplying by dd10 and repeating
\  4. Construct output string digit by digit, append
\       sign and exponent, and display.

10e0 0e0  ddconstant dd10

: getSign   ( f: x xx -- x xx)  ( -- f)
    FOVER  F0<  ;

: getPower   ( f: x xx -- x xx) ( --  n)
    FOVER   FABS  FLOG
    ( FDUP  F0< )
    ( IF  1e0 F- F>S  ELSE  THEN )
    F>S
;

fp-stack? [IF]
: normalize  ( f: x xx -- y yy) ( n -- n')
    ddabs                       ( f: |x+xx| )
    DUP  dd10  dd^n  dd/        ( f: [|x|+|xx|]/10^n ) ( n)

  \ make sure it's between 1 and 10
    BEGIN   FOVER   10e0  F>
    WHILE   dd10  dd/   1 +  REPEAT

    BEGIN   FOVER   1e0   F<
    WHILE   dd10  dd*   1 -  REPEAT
;   ( f: [y+yy] = [x+xx]/10^n' )    ( n')
[ELSE]
variable temp
: normalize  ( f: x xx -- y yy) ( n -- n')
    temp !
    ddabs                       ( f: |x+xx| )
    dd10 temp @ dd^n  dd/       ( [|x|+|xx|]/10^n )  \ ( f: [|x|+|xx|]/10^n ) ( n)

  \ make sure it's between 1 and 10
    BEGIN   FOVER   10e0  F>
    WHILE   dd10  dd/   1 temp +!  REPEAT

    BEGIN   FOVER   1e0   F<
    WHILE   dd10  dd*   -1 temp +!  REPEAT
    temp @
;   ( f: [y+yy] = [x+xx]/10^n' )    ( n')
[THEN]

fp-stack? [IF]
: peelDigit ( f: y yy -- y' yy')    ( -- digit)
    FOVER                           ( f: y yy y)
    1e-10 F+                        ( f: y yy y+epsilon)
                                    \ fixes rounding problem
    F>D   2DUP  D>F  0e0  dd-
    D>S
;
[ELSE]
: peelDigit ( f: y yy -- y' yy')    ( -- digit)
    FOVER                           ( f: y yy y)
    1e-10 F+                        ( f: y yy y+epsilon)
                                    \ fixes rounding problem
    F>D  2DUP  2>R  D>F  0e0  dd- 
    2R>  D>S
;
[THEN]

\ ******** bug in peelDigit fixed Wednesday, March 08 2006 by JVN
\          thanks to M. Hendrix for finding it

: shiftBy10       dd10  dd*  ;

\ Convert a double double to a string

create ddout_digits 128 allot
fp-stack? [IF]
: dd>$ ( F: x xx -- ) ( -- caddr u )
    FOVER   F0=  IF  dddrop s" 0.0 DD 0"  EXIT  THEN   \ handle 0
    getSign
    getPower normalize
    S>D  SWAP  OVER  DABS       \ convert exponent
    <#  #S  ROT SIGN            \ append  digits of exponent
    BL       HOLD
    [char] d HOLD
    [char] d HOLD
    BL       HOLD    \ append dd
    PRECISION 1- 0 ?DO
      peelDigit
      ddout_digits PRECISION 1- + I - c!
      shiftBy10
    LOOP  peelDigit ddout_digits c!
    PRECISION 1- 0 ?DO
      ddout_digits I + c@
      S>D   #  2DROP
    LOOP
    [char] .  HOLD
    ddout_digits PRECISION 1- + c@ S>D  #  2DROP
    ROT  IF  [char] -  ELSE  [char] +  THEN   HOLD
    #> f2drop
;
[ELSE]
: dd>$ ( x xx -- caddr u )
    FOVER   F0=  IF  dddrop s" 0.0 DD 0"  EXIT  THEN   \ handle 0
    getSign >R
    getPower normalize R> SWAP
    S>D  SWAP  OVER  DABS       \ convert exponent
    <#  #S  ROT SIGN            \ append  digits of exponent
    BL       HOLD
    [char] d HOLD
    [char] d HOLD
    BL       HOLD  2>R >R   \ append dd
    PRECISION 1- 0 ?DO 
      peelDigit
      ddout_digits PRECISION 1- + I - c!
      shiftBy10   
    LOOP  peelDigit ddout_digits c!
    R> 2R> 
    PRECISION 1- 0 ?DO
      ddout_digits I + c@ 
      S>D   #  2DROP
    LOOP
    [char] .  HOLD  
    ddout_digits PRECISION 1- + c@ S>D  #  2DROP
    ROT  IF  [char] -  ELSE  [char] +  THEN   HOLD
    #> 2>R f2drop 2R>
;
[THEN]

: ddfs.     ( f: x xx -- )  \ display double-double in E-format
    dd>$ type ;

32 SET-PRECISION

0 [IF]    \ the code below appears to have some issues in kForth

15 SET-PRECISION

: test
    SWAP  DO  1e0 0e0 3e0 0e0  dd/  dd10 I dd^n  dd*
              CR I .  TAB TAB  ddfs. LOOP
;

: test1
    SWAP  DO  1e0 0e0 6e0 0e0  dd/  dd10 I dd^n  dd*
              CR I .  TAB TAB  ddfs. LOOP
;


\ Convert a string representing a dd# to internal form
\   as 2 IEEE 64-bit floats

\ Algorithm:
\
\   0. initialize buffers hi$ and lo$
\   1. skip leading + sign, leave - flag on stack.
\   2. copy digits to hi$ buffer until dp found;
\        let L be # digits to left of dp.
\   3. continue copying until #digits = MaxPlaces/2
\        or string is exhausted.
\   4. IF   (string is exhausted) set lo$ to 0e0
\      ELSE append remaining digits to lo$
\           until #digits = MaxPlaces  THEN
\   5. hi$ >FLOAT   1e0  exactmul
\      lo$ >FLOAT   1e0  exactmul
\      dd+
\   6. get p = power of 10, let p' = p + L - MaxPlaces/2
\   7. p' dd10 dd^n  dd*

\ : $ends   ( c-adr u -- end beg)   \ convert c-adr u to ends
\    OVER  +   1-  SWAP ;          ( end beg)

\ : ends->count   ( end beg -- c-adr u)  TUCK  -  1+  ;

\ needs vector1.f      ( include)
\ needs fsm2.f         ( include)


30 CONSTANT  MaxPlaces

CREATE lo#  MaxPlaces  CHARS ALLOT  \ numerical string buffers
CREATE hi#  MaxPlaces  CHARS ALLOT

: digit?    ( c -- f)   \ test for digit
    [ CHAR 0 ] LITERAL  [ CHAR 9  1+ ]  LITERAL  WITHIN
;

: dp?   [CHAR] .  =    ;

: dDeE?     ( c -- f)
    [CHAR] d  OVER  =
              OVER  [CHAR] D  =  OR
              OVER  [CHAR] e  =  OR
              SWAP  [CHAR] E  =  OR
;

: |power|     ( c-addr count -- |p|) \ abs value of pwr of 10
    0 0  2SWAP  >NUMBER   ( -- ud2 c-addr2 u2)
    0=  IF  DROP  D>S  ELSE  ." Bad exponent"  ABORT   THEN
;

0 ptr beg
0 ptr end

: do_exponent  ( end beg -- p end')    \ peel exponent from right
    to beg to end \ LOCALS| beg end |
        0                               \ count on stack
            BEGIN   end beg >           ( n f1)
                    end C@  digit?      ( n f1 f2)
                    AND
            WHILE   end 1-  TO end      \ dec adr
                    1+                  \ inc count
            REPEAT

        end 1+  SWAP   |power|          ( |p|)
        end C@  [char] -  =                 \ get sign of p
        IF  NEGATE  end  1-  TO end   THEN  ( -- p)

        end C@  [char] +  =             \ bypass + sign
        IF  end  1-  TO  end  THEN

        end C@  dDeE?  -1  AND  end +  TO  end  \ advance past dDeE
        end C@  dDeE?  -1  AND  end +           ( -- p end')

        DUP  C@  DUP  digit?  SWAP  dp?  OR  \ digit|dp are legal
            0=  ABORT" Bad exponent"         \ anything else n.g.

\        end C@  dDeE?  -1  AND  ( DUP  >R)
\                end +  TO  end  \ advance past dDeE
\        end C@  dDeE?  -1  AND  ( DUP)  end +           ( -- p end')
\            ( SWAP  R>  OR  0=  ABORT" Bad exponent" )  \ no dDeE !

;


: [dig|dp]  ( char -- col#)     \ 0 = "other", 1 = digit, 2 = dp
    DUP  digit?  1 AND  SWAP  dp?  2 AND  +
;

: init_buffer   ( c-addr -- )   \ initialize a string buffer
    0 OVER  C!  1+  MaxPlaces  1-  [CHAR] 0  FILL
;

: +char     ( c-addr c -- )     \ append char to counted $
    OVER  COUNT  +              ( c-addr c c-addr+u)
    C!   DUP C@   1+  SWAP  C!  \ store c, inc $len
;

0 VALUE  pre_dp         \ # of digits to left of dp
0 VALUE  post_dp        \ # of digits to right of dp

: +hi   ( c -- )
    hi#  SWAP  +char        \ append character
    pre_dp  1+  TO  pre_dp  \ increment count
;

: +hi|lo   ( c -- )
    pre_dp  post_dp +  MaxPlaces 2/  <
    IF    hi#   ELSE   lo#   THEN
    SWAP  +char                 \ append character
    post_dp  1+  TO  post_dp    \ increment post_dp
;

: err1   TRUE  ABORT" Non-digit in significand!"  ;
: err2   TRUE  ABORT" One dp to a customer!"  ;


FALSE [IF]
3 wide  fsm:  <<hi/lo>>     ( c col# --)
\ input       other   |    digit      |      dp    |
\ state  -------------------------------------------
  ( 0)   ||  err1 >2  || +hi     >0   ||  DROP >1
  ( 1)   ||  err1 >2  || +hi|lo  >1   ||  err2 >3
  ( 2)   ( abnormal termination w/ error1 )
  ( 3)   ( abnormal termination w/ error2 )
;fsm
[THEN]

\ FALSE [IF]
0 VALUE  (state)        : >state  TO  (state)  ;

: <<hi/lo>>     ( c col# --)
    (state) 3 *  +          ( c cell#)
    case
        0   OF  err1   2 >state     ENDOF
        1   OF  +hi    0 >state     ENDOF
        2   OF  drop   1 >state     ENDOF
        3   OF  err1   2 >state     ENDOF
        4   OF  +hi|lo 1 >state     ENDOF
        5   OF  err2   3 >state     ENDOF
    endcase
;
\ [THEN]

: leadingSign   ( end beg -- sgn end beg')
    DUP C@  [CHAR] -  OVER =    ( end beg c f1)
    >R  [CHAR] +  =  R@  OR     ( end beg f2+f1)
    1 AND +  R>  -ROT
;

: initialize
    hi#  init_buffer            \ buffers
    lo#  init_buffer
    lo#  [CHAR] .  +char
    0 TO pre_dp   0 TO post_dp  \ counts
    0 >state  ( <<hi/lo>>)         \ fsm
;

: >(hi/lo)  ( end beg -- )  \ digits to hi# and lo#
    BEGIN   2DUP >=         ( end beg f)
            pre_dp  post_dp  +  MaxPlaces  <=  AND
    WHILE   DUP  C@  DUP  [dig|dp]  <<hi/lo>>
            1+              ( end beg+1)
    REPEAT  2DROP
;

: buf->dd   ( c_addr )  ( f: x xx)  \ convert buffer to dd
    COUNT  >FLOAT  0=  ABORT" Float conversion failed"
    1e0  exactmul
;

: adjustExponent    ( pwr)  ( f: |y+yy| -- |x+xx|)
    pre_dp  +               ( p+n1)
    pre_dp post_dp +        ( p+n1 n1+n2)
    MaxPlaces 2/  MIN  -    ( p'=p+n1-MIN[n1+n2,MaxP/2] )
    dd10  dd^n  dd*
;

: >dd   ( c-addr u -- )  ( f: -- x xx)
    OVER  +   1-  SWAP          ( end beg)  \ $ends
    initialize                  ( end beg)
    leadingSign                 ( sgn end beg')
    TUCK  do_exponent   ROT     ( sgn pwr end' beg')
    >(hi/lo)                    \ digits -> hi/lo buffers
    hi#  buf->dd    lo#  buf->dd    dd+     ( f: |y+yy|)
    ( s p)  adjustExponent      ( s)
    IF  ddnegate  THEN          \ adjust sign
;


false [IF]

cr .( Examples: ) cr

s" -11.1112222233333444445555566666dd-45" >dd cr ddfs.
cr .( -1.1111222223333344444555556666603 dd -44  ok )

s" +-11.1112222233333444445555566666dd-45" >dd cr ddfs.
cr .( Error: >dd Non-digit in significand! )

s" +11.1112222.233333444445555566666dd-45" >dd cr ddfs.
cr .( Error: >dd One dp to a customer! )

s" +11.1112222233333444445555566666dd+45" >dd cr ddfs.
cr .( +1.1111222223333344444555556666604 dd 46  ok )

s" +11.1112222233333444445555566666" >dd cr ddfs.
cr .( +0.0000000000000000000000000000000 dd 0  ok  <- Must have exponent field)

s" +11.1112222233333444445555566666dd" >dd cr ddfs.
cr .( +1.1111222223333344444555556666603 dd 1  ok )

s" +11.1112222233333444445555566666D" >dd cr ddfs.
cr .( +1.1111222223333344444555556666603 dd 1  ok )

s" 1111122.222333D" >dd cr ddfs.
cr .( +1.1111222223330000000000000000000 dd 6  ok )

[THEN]

[THEN]
