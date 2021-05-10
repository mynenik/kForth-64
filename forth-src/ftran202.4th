\ ******** ANS-compatible FORmula TRANslator ********
\          see ftrandoc.txt for instructions
\ ---------------------------------------------------
\     (c) Copyright 2001  Julian V. Noble.          \
\       Permission is granted by the author to      \
\       use this software for any application pro-  \
\       vided this copyright notice is preserved.   \
\ ---------------------------------------------------

\ Revisions:
\
\   2010-06-02  km; this version is 2.02b for kForth 1.5.x,
\               integrated fp/data stack system; thanks
\               to "Ed" on comp.lang.forth for suggestion on
\               replacement of locals code in recursive and 
\               re-entrant words; see ftran-test.4th.
\
\ ===== kForth specific ================================
\
\ ans-words  must be included

[undefined] f>string [IF] s" strings" included [THEN]  \ strings pkg
[undefined] ptr [IF] : ptr create 1 cells allot? ! does> a@ ; [THEN]              
[undefined] fsm: [IF] s" fsm2" included [THEN]         \ finite state machine
[undefined] char_table: [IF] s" chr_tbl" included [THEN]  \ character encoding pkg
[undefined] z@ [IF] s" fsl/complex" included [THEN]  \ FSL complex arithmetic pkg

\ ==== end of kForth specific scaffolding ==============


\ program begins here

[undefined]  ?exit   [IF]
    : ?exit  ( flag)    POSTPONE IF
                        POSTPONE EXIT
                        POSTPONE THEN  ;    IMMEDIATE
[THEN]

[undefined] OFF  [IF]
    : OFF   ( adr -- )   FALSE  SWAP !  ;
    : ON    ( adr -- )   TRUE   SWAP !  ;
[THEN]

FORTH-WORDLIST  SET-CURRENT     \ a precaution

\ raising to integer powers
[undefined] f^2  [IF]   : f^2  FDUP  F*  ;  [THEN]
    : f^3  FDUP  FDUP  F* F*  ;
    : f^4  f^2  f^2  ;

\ increment if true   ( ptr f -- ptr+1 | ptr)
: ?inc   S" 1  AND  + "  EVALUATE  ;  IMMEDIATE


WORDLIST  ptr  ftran                    \ create separate wordlist
ftran SET-CURRENT                       \ for FOR...TRAN... def'ns
GET-ORDER  ftran  SWAP 1+  SET-ORDER    \ make ftran findable

\ -------------------------------------------- string manipulation
: $ends   ( c-adr -- end beg)   \ convert c-adr to ends
    COUNT  DUP  0>              ( beg n f)
    -1 AND +                    ( beg  n-1|0)
    OVER  +  SWAP ;             ( end beg)

: ends->count   ( end beg -- c-adr u)  TUCK  -  1+  ;

0 ptr src
0 ptr dst
0 value n

: concat    ( src u dst --)  \ append u chars from src to dst
    \ LOCALS| dst n src |
    TO dst  TO n  TO src
    src   dst CELL+   dst @   +    n CMOVE
    n   dst @   +    dst !  ;
\ ---------------------------------------- end string manipulation


\ ------------------------------------------------ data structures
\ 1. String-pointer stack:
\    3 cells wide, cell at base_adr holds $ptr

16 CONSTANT  max_depth      \ this seems enough

\               $ stack space  +  1 cell for pointer
CREATE $stack   max_depth  3 *  CELLS   CELL+  ALLOT

\ HERE  $stack -  1 CELLS -  CONSTANT  $max  \ max depth (cells)
max_depth 3 * CELLS  CONSTANT  $max  \ max depth (cells)

: $init   -3 CELLS  $stack  !  ;   $init

: $ptr    ( -- adr offset)    $stack DUP  @  ;

: $lbound ( offset)    0<  ABORT" empty $stack!"  ;

: ($pop)  ( adr offset -- end beg op)
          DUP   $lbound                       \ bounds check
          + CELL+                             ( adr[TO$])
          DUP >R   CELL+ DUP a@ SWAP CELL+ a@ SWAP
          R>  @   ;       ( end beg op)

: $pop    ( -- end beg op)
          $ptr                                ( adr offset)
          ($pop)                              ( end beg op)
          -3 CELLS $stack +!  ;               \ dec $ptr

: $ubound ( offset)    $max > ABORT" $stack too deep!"  ;

: $push   ( end beg op -- )
          3 CELLS  $stack  +!                 \ inc $ptr
          $ptr                                ( end beg op adr offset)
          DUP  $ubound                        \ bounds check
          + CELL+  DUP >R                     ( end beg op adr[TO$])
          !   R>  CELL+  2!  ;

\ 2. Null string
    \ CREATE bl$ 1 C, BL C,
    CREATE bl$ ( 1 C, BL C,) 2 ?ALLOT 1 OVER C! BL SWAP 1+ C!
    bl$   $ends   2CONSTANT  0null

\ 3. re-vectorable dummy names
    DEFER expr             \ for indirect recursion
    DEFER term
    DEFER factor

    DEFER .op              \ for compilation
    DEFER do_id
    DEFER try_fp#
    DEFER .fp#
    DEFER do_@
    DEFER do_^
    DEFER do_fn

\ 4. place to make output string
    CREATE out_pad 512 CHARS  CELL+ ALLOT    \ long output $

\ -------------------------------------------- end data structures


\ -------------------------------------------------- formula input
CREATE  in_pad 256 ALLOT
0 in_pad C!

CREATE formula-string 256 ALLOT
0 ptr formula-ptr

[defined] >IN [IF]

\ Get character from input stream. From Wil Baden's opg .
: get-char      ( -- char | 0 for EOL | negative for EOF )
    SOURCE      ( -- start_of_input #chars)
    >IN @       ( -- start_of_input #chars  input_ptr)
    >   IF    >IN @ CHARS + C@  1 >IN +!
        ELSE  DROP REFILL 0=
        THEN    ;

: parse_formula ;

[ELSE]

: get-char      ( -- char | 0 for EOL | negative for EOF )
	 formula-string C@ 
	 formula-ptr formula-string 1+ -
	 > IF  formula-ptr C@ formula-ptr 1+ TO formula-ptr 
	   ELSE [CHAR] " THEN 
;

: parse_formula ( <formula> -- )
    [CHAR] " WORD formula-string strcpy 
    formula-string 1+ TO formula-ptr ;

[THEN]


: +c!    ( n c-adr --)  \ add n to the char at c-adr
    TUCK  C@  +  SWAP  C!  ;

: append_char  ( c c-adr --)    \ append 1 char to a counted string
    1 OVER  +c!         \ increment count
    DUP  C@  +  C!  ;   \ get new address and store

VARIABLE {}level

: >0,4    {}level  @  0>  4 AND  ;  ( -- 0 | 4)

: copy       ( c --)   in_pad  append_char   ;
: copy&inc   ( c --)   copy    1 {}level +!  ;
: copy&dec   ( c --)   copy   -1 {}level +!  ;

: err0    CR  ." right } before left {"  ABORT  ;
: err1    CR  ." left { between right }'s" ABORT  ;
: err2    CR  ." no chars betw. successive {'s or }'s"  ABORT  ;
: err3    CR  ." last char before 1st } must be blank" ABORT ;
: err4    CR  ." first char after last { must be blank" ABORT ;


7 4 fsm: put_char   ( c col# --)
\ input       other   |    bl     |       {        |      }
\ state  -----------------------------------------------------------
  ( 0)   ||  copy >0  || DROP >0  ||  copy&inc >1  || err0   >5
  ( 1)   ||  err4 >6  || copy >2  ||  copy&inc >1  || err3   >6
  ( 2)   ||  copy >2  || copy >3  ||  err2     >5  || err3   >6
  ( 3)   ||  copy >2  || copy >3  ||  err2     >5  || copy&dec >0,4
  ( 4)   ||  err3 >6  || err2 >6  ||  err1     >5  || copy&dec >0,4
  ( 5)   ( abnormal termination w/ error0 or error1 )
  ( 6)   ( abnormal termination w/ error2 or error3 )
;fsm


: [put_char]  ( c -- col#)  \ char -> col #:   in    out
    1 OVER  BL       =  AND       ( -- c n) \  other    0
    OVER    [CHAR] { =  2 AND +   ( -- c n) \    bl     1
    SWAP    [CHAR] } =  3 AND +   ( -- #)   \    {      2
;                                           \    }      3

0 VALUE ()level
: count_parens   ( c -- c )
    DUP  [CHAR] ( =  1  AND
    OVER [CHAR] ) =  -1 AND  +  ( -- c n)
    ()level +  TO  ()level  ;


: get_formula
    {}level OFF
    in_pad   OFF
    0 >state put_char
    parse_formula
    BEGIN   get-char    count_parens
            DUP  [CHAR] "  <>
    WHILE   DUP  0>
            IF    DUP  [put_char]  put_char
            ELSE  DROP   THEN
    REPEAT  DROP
    ()level  0<>  ABORT" Unbalanced parentheses!" ;


\ ---------------------------------------------- end formula input

\ ---------------------------------------------- conversion tables
: 'dfa    '  >BODY  ;

128 char_table: [token]        \ convert ASCII char to token
\ "other" -> 0
 1 'dfa [token]    CHAR Z  CHAR A  install
 1 'dfa [token]    CHAR z  CHAR a  install

 \ modified January 8th, 2004
 1 'dfa [token]    CHAR [  +  C!    \ for address passing
 1 'dfa [token]    CHAR ]  +  C!    \ for address passing

 2 'dfa [token]    CHAR E  CHAR D  install
 2 'dfa [token]    CHAR e  CHAR d  install
 3 'dfa [token]    CHAR 9  CHAR 0  install
 4 'dfa [token]    CHAR .  +  C!
 5 'dfa [token]    CHAR (  +  C!
 6 'dfa [token]    CHAR {  +  C!
 7 'dfa [token]    CHAR }  +  C!
 8 'dfa [token]    CHAR )  +  C!
 9 'dfa [token]    CHAR +  +  C!
10 'dfa [token]    CHAR -  +  C!
11 'dfa [token]    CHAR *  +  C!
12 'dfa [token]    CHAR /  +  C!
13 'dfa [token]    CHAR ^  +  C!
15 'dfa [token]    CHAR =  +  C!
17 'dfa [token]    CHAR ,  +  C!
\ ------------------------------------------ end conversion tables

\ -------------------------------------------------- finding stuff
\ terminology:  (end,beg) = pointers to substring
\                op       = operator token

: skip_name   ( end beg --)
    DUP  C@  [token]  1 3 WITHIN        \ 1st char a letter or [ ?
    IF  BEGIN   DUP C@   [token]  1 4 WITHIN   \ skip letters or digits
        WHILE   1+   REPEAT
    ELSE  CR ." A proper name must begin with a letter!"  ABORT
    THEN    ;

0 value level
0 value c1
0 value c2

: [skip]    ( end beg c1 c2 -- end beg')
    0  ( LOCALS| level c2 c1 |)
    TO level
    TO c2
    TO c1
    DUP  C@  c1 <>  ?exit       \ 1st char <> c1
    BEGIN   DUP C@
            CASE
                c1 OF  1  level +  TO  level  ENDOF
                c2 OF  -1 level +  TO  level  ENDOF
            ENDCASE
            1+                      ( end beg')
            DUP C@   c2 <>          \ next char <> c2
            level 0>   INVERT AND   \ and level <= 0
            >R  2DUP <   R>     OR  \ or past end of string
    UNTIL
;

: skip_{}   ( end beg -- end beg')  [CHAR] {  [CHAR] }  [skip]  ;

: skip_()   ( end beg -- end beg')  [CHAR] (  [CHAR] )  [skip]  ;

: skip_digits   ( adr -- adr')          \ skip digits rightward
    BEGIN  DUP C@  [CHAR] 0  [CHAR] 9 1+  WITHIN
    WHILE  1+  REPEAT  ;

: skip_dp   ( adr -- adr|adr+1)         \ skip decimal point
    DUP C@  [CHAR] .  =  ?inc  ;

: skip+     ( adr -- adr|adr+1)     \ skip + sign
    DUP C@  [CHAR] +  =  ?inc  ;

: skip-     ( adr -- adr|adr+1)     \ skip - sign
    DUP C@  [CHAR] -  =  ?inc  ;

: skip_fp#    ( adr -- adr')            \ skip past a fp#
    skip_digits  skip_dp  skip_digits   \ skip mantissa
    DUP C@  [token]  2 =                \ d,D,e or E ?
    IF  1+  ELSE  EXIT  THEN
    skip+  skip-  skip_digits  ;        \ skip exponent

: pass_thru ( end beg -- end beg')
    skip-                             \ ignore leading -
    DUP C@  [token]  CASE
        3 OF   skip_fp#   ENDOF       \ digit
        4 OF   skip_fp#   ENDOF       \ dec. pt.
        1 OF   skip_name              \ letter
               skip_{}
               skip_()    ENDOF
        2 OF   skip_name              \ dDeE
               skip_{}
               skip_()    ENDOF
        5 OF   skip_()    ENDOF       \ left paren: (
    ENDCASE
;


: [op]     ( char -- token)     \ in        out
    [token]                     \ "other"    0
    7  -  DUP  0>  AND  2/  ;   \ + or -     1
                                \ * or /     2
                                \  ^         3
                                \  =         4
                                \  ,         5

: op_find   ( end beg c -- adr | 0)     \ find exposed operator
    [op]   >R           ( end beg)      \ save op token
    BEGIN   pass_thru   \ ignore id's, fp#'s, fn's, (expr)'s
            DUP C@  [op]  R@ <>         \ op not found
            >R   2DUP >   R> AND        \ and not done
    WHILE   1+                          \ incr. ptr
    REPEAT  TUCK 
\    >  AND                              ( -- adr | 0)
\ recoded line above to preserve type-checking for kForth  -- km 9/23/03  
    <= IF DROP 0  THEN                  ( -- adr | 0)
    R>  DROP                            \ clean up
;

\ ---------------------------------------------- end finding stuff

\ -------------------------------------------------------- parsing

: assign    \ assign -> id = expr | id = | expr
    $init
    out_pad OFF
    in_pad  $ends  2DUP  [CHAR] =  op_find  ( end beg  ptr|0)
    ?DUP  IF    1-  TUCK  >R  [CHAR] =  $push   \ id = expr
                ( end) R> 2 +   BL  $push   expr
          ELSE  OVER C@  [CHAR] =  =            \ id =
            IF  SWAP 1-  SWAP  [CHAR] =
            ELSE   BL   THEN                    \ expr
            $push
          THEN
    expr
;


0 ptr end
0 ptr beg
0 value op

: <expr>    \ expr -> term | term & expr
    end >r  beg >r  op >r
    $pop  to op  to beg  to end
    end beg  [CHAR] +  op_find       ( ptr | false)
    ?DUP IF ( ptr)  DUP  c@   >R            \ save op'
\                                           $stack:
            ( ptr)  end  OVER 1+ R>  $push  \ expr'     op'
            ( ptr)  1-  beg  op  $push      \ term      op
            term  RECURSE
    ELSE    end beg op  $push  term         \ term      op
    THEN
    r> to op  r> to beg  r> to end
;

0 ptr end
0 ptr beg
0 value op

: <term>      \ term -> factor | factor % term
    end >r beg >r op >r
    $pop   to op to beg to end  ( LOCALS| op beg end |)
    end beg  [CHAR] *  op_find      ( ptr true | false)
    ?DUP IF ( ptr)  DUP  c@   >R            \ save op'
\                                           $stack:
                    0NULL  op  $push        \ null      op
                    end  OVER 1+ R>  $push  \ term'     op'
            ( ptr)  1-  beg  BL  $push      \ factor    bl
            factor  RECURSE
    ELSE    end beg op  $push
    THEN
    factor r> to op r> to beg r> to end ;

\ -------------- auxiliary words for parsing factor --------------
: <do_F@>   S"  F@ "  ;
: <do_z@>   S"  z@ "  ;

0 value op
0 ptr beg
0 ptr end

: <do_id>   ( end beg op -- op)
    to op to beg to end ( LOCALS| op beg end |)
    op [CHAR] =   =                     \ op is =
    end beg  0null D=                   \ $ is 0null
    OR   INVERT                         \ true if neither
    >R                                  \ defer flag

    \ modification for address-passing, January 8th, 2004
    beg C@ [CHAR] [  =          \ enclosed in [] ?
    end C@ [CHAR] ]  =  AND     \
    >R                          \ defer flag
    R@  IF  beg 1+  TO  beg     \ remove []
            end 1-  TO  end
        THEN
    R>  INVERT                  \ not in []

    end beg ends->count  do_id
    R>  AND                     \ not =, and not null$
    IF  do_@  do_id   THEN    op
;

: leading-?     ( adr -- f)
    DUP C@ [CHAR] -  =   SWAP 1+ C@  [token] 3 <>  AND  ;

: $fneg   S" FNEGATE "  ;
: $zneg   S" znegate "  ;

DEFER neg$   ' $fneg  IS neg$

0 value op
0 ptr beg
0 ptr end

: try_id    ( op end beg -- f) \ true =>  $ was an id
    to beg to end to op ( LOCALS| beg end op |)
    beg skip- C@  [token]  1 3 WITHIN   \ begins with letter
    beg C@  BL =   OR                   \ or a blank
    end C@  [CHAR] )  <> AND            \ doesn't end with )
    DUP
    IF  end beg  skip-  op <do_id> .op  \ was an id
        beg C@  [CHAR] - =
        IF   neg$  do_fn  THEN
    THEN                                \ wasn't an id
;


: <try_fp#>    ( op end beg -- f) \ true =>  $ was a fp#
    ends->count  >FLOAT
    IF   .fp#  .op  TRUE   ELSE   DROP  FALSE   THEN
;


: <try_z#>  ( op end beg -- f) \ true =>  $ was a fp#
    ends->count  >FLOAT
    IF   0e0  .fp#   .op  TRUE   ELSE   DROP  FALSE   THEN
;

: enclosed?  ( end beg -- f)
    C@  [CHAR] (  =    SWAP
    C@  [CHAR] )  =    AND  ;

0 value op
0 ptr beg
0 ptr end
\ try_(expr) is re-entrant due to "factor"
: try_(expr)    ( op end beg -- f) \ true =>  $ was (expr)
    end >r beg >r op >r
    to beg to end to op ( LOCALS| beg end op |)
    end beg  enclosed?
    IF  0null  op  $push   end 1-  beg 1+  BL  $push
        expr   factor  TRUE
    ELSE  FALSE   THEN
    r> to op r> to beg r> to end
;


: <do_f^>   ( n --)
    CASE  1  OF   S"   "       ENDOF
          2  OF   S"  f^2 "    ENDOF
          3  OF   S"  f^3 "    ENDOF
          4  OF   S"  f^4 "    ENDOF
    ENDCASE   do_id
;

: <do_z^>   ( n --)
    CASE  1  OF   S"   "       ENDOF
          2  OF   S"  z^2 "    ENDOF
          3  OF   S"  z^3 "    ENDOF
          4  OF   S"  z^4 "    ENDOF
    ENDCASE   do_id
;

: int<5?   ( end beg -- n TRUE | FALSE)
    ends->count  0 S>D  2SWAP  >NUMBER    ( d adr 0 | d' adr' n)
    0=  IF   2DROP  DUP  1 5 WITHIN     ( n f --)
        ELSE 2DROP  FALSE  THEN ;

0 value op
0 ptr beg
0 ptr end
0 ptr optr
\ try_f1^f2 is re-entrant due to "factor"
: try_f1^f2   ( op end beg -- f)  \ true => $ was f^f
    optr >r end >r beg >r op >r
    0 to optr to beg to end to op ( LOCALS| ptr beg end op |)
    end beg  skip- [CHAR] ^  op_find   TO optr
    optr
    IF  0null  op  $push                \ push operator
        end optr 1+  int<5?              \ is f2 an integer < 5
        IF   optr 1-  beg  skip-         \ parse f1^n
             BL  $push
             factor  do_^
        ELSE DROP                           \ clear stack
             end  optr 1+  [CHAR] ^ $push    \ f2
             optr 1-  beg  skip- BL $push    \ push f1
             factor  factor
        THEN    factor
        beg  C@  [CHAR] -  =  IF  neg$  do_fn  THEN
    THEN    optr  0<>  ( flag)
    r> to op r> to beg r> to end r> to optr
;
\ ************************************************************

: func_lib  ( xt -- c-adr)
    CASE    [']  FABS   OF   C"  FABS "     ENDOF
            [']  FACOS  OF   C"  FACOS "    ENDOF
            [']  FACOSH OF   C"  FACOSH "   ENDOF
            [']  FASIN  OF   C"  FASIN "    ENDOF
            [']  FASINH OF   C"  FASINH "   ENDOF
            [']  FATAN  OF   C"  FATAN "    ENDOF
            [']  FATAN2 OF   C"  FATAN2 "   ENDOF
            [']  FATANH OF   C"  FATANH "   ENDOF
            [']  FCOS   OF   C"  FCOS "     ENDOF
            [']  FCOSH  OF   C"  FCOSH "    ENDOF
            [']  FEXP   OF   C"  FEXP "     ENDOF
            [']  FLN    OF   C"  FLN "      ENDOF
            [']  FMAX   OF   C"  FMAX "     ENDOF
            [']  FMIN   OF   C"  FMIN "     ENDOF
            [']  FSIN   OF   C"  FSIN "     ENDOF
            [']  FSINH  OF   C"  FSINH "    ENDOF
            [']  FTAN   OF   C"  FTAN "     ENDOF
            [']  FSQRT  OF   C"  FSQRT "    ENDOF
            [']  FTANH  OF   C"  FTANH "    ENDOF
    ENDCASE
;

[undefined]  CAPS-FIND   [IF]
    : lcase?        ( char -- flag=true if lower case)
        DUP   [CHAR] a  MAX     ( char max[a,c])
        SWAP  [CHAR] z  MIN     ( max[a,c] min[a,z])
        =   ;

    : ucase   ( c-adr u --)  OVER  +  SWAP
        DO  I C@  DUP  lcase?  32 AND  -  I  C!  LOOP   ;
    \ assumes ASCII character coding
    : CAPS-FIND  DUP COUNT ucase FIND ;
[THEN]

: Fname  ( end beg -- xt TRUE | c-adr FALSE)
\ add leading F to fn.name and look up
    >R  1+  R>                  ( end+1 beg)
    1 PAD  C!  [CHAR] F  PAD 1+  C!
    PAD 1+   -ROT               ( pad+1 end+1 beg)
    DO   1+  I  C@  OVER  C!    \ append char to PAD
         1 PAD +c!              \ incr. count at PAD
    LOOP   DROP
    PAD  CAPS-FIND   0<>
;

: list!       (  --)
    $pop  >R                    \ defer op
    2DUP  [CHAR] ,  op_find     ( end beg ptr|0)  \ -> )comma(
    ?DUP  IF  ROT  OVER  1+     ( beg ptr end ptr+1)
              BL  $push         ( beg ptr)
              1-  SWAP BL $push
              expr  RECURSE
          ELSE  BL  $push  expr \ only 1 arg
          THEN
          R>  .op               \ emit op
;

0 value op
0 ptr beg
0 ptr end
0 ptr optr

: try_func   ( op end beg -- f) \ fn -> id arglist
    0 to optr to beg to end to op ( LOCALS| ptr beg end op |)
    end beg  skip-  skip_name       ( end beg')
    DUP   TO optr                    ( end ptr)
    enclosed?  DUP                  \ looks like a function
    IF   optr 1-  beg  skip-         ( end' beg|beg+1)
         Fname                      \ look up F+fn.name
         beg C@  [CHAR] -  =  >R    \ defer possible NEGATE
         IF     func_lib  $ends     ( end beg)  \ library fn
         ELSE   DROP
                optr 1- beg skip-    ( end beg)  \ other
         THEN   op  $push           \ push function name
         end 1- optr 1+  BL  $push   \ push arg list
         list!                      \ handle arg list
         $pop   -ROT  ends->count  do_fn   .op
         R>  IF  neg$  do_fn  THEN
    THEN
;
\ ---------------- end auxiliary words for factor ----------------

0 value op
0 ptr beg
0 ptr end

: <factor>  \ factor -> id | fp# | ( expr ) | f^f | function
    $pop  to op to beg to end  ( LOCALS| op beg end |)    \ true => success
    op end beg  try_f1^f2  ?exit
    op end beg  try_id     ?exit
    op end beg  try_fp#    ?exit
    op end beg  try_(expr) ?exit
    op end beg  try_func   ?exit
    ." Not a factor!"   ABORT
;

\ ---------------------------------------------------- end parsing

\ --------------------------------------------------- output words
: real_op   ( op --)  [token]
    CASE     9  OF   S"  F+ "   ENDOF
            10  OF   S"  F- "   ENDOF
            11  OF   S"  F* "   ENDOF
            12  OF   S"  F/ "   ENDOF
            13  OF   S"  F** "  ENDOF
            15  OF   S"  F! "   ENDOF
             0  OF   S"  "      ENDOF
    ENDCASE
    do_fn
;

: cmplx_op   ( op --)  [token]
    CASE     9  OF   S"  z+ "   ENDOF
            10  OF   S"  z- "   ENDOF
            11  OF   S"  z* "   ENDOF
            12  OF   S"  z/ "   ENDOF
            13  OF   S"  z^ "   ENDOF
            15  OF   S"  z! "   ENDOF
             0  OF   S"  "      ENDOF
    ENDCASE
    do_fn
;

' <expr>   IS  expr                 \ resolve forward refs
' <term>   IS  term
' <factor> IS  factor


: >out   ( c-adr u --)  out_pad  concat  ;  \ append to out_pad

FORTH-WORDLIST   SET-CURRENT            \ definitions to FORTH

[undefined] $ftemp  [IF]  CREATE  $ftemp  32 CHARS  ALLOT  [THEN]

[defined] REPRESENT [IF]
: f->$  ( f: r --)  ( -- c-adr u)
    BL  $ftemp C!
    $ftemp  CHAR+  [CHAR] .  OVER  C!       ( $ftemp+1)
    CHAR+  PRECISION  REPRESENT             ( n f1 f2)
    INVERT
    IF  ." Can't convert fp# to string!"  ABORT  THEN
    IF  [CHAR] -  $ftemp  C!  THEN          ( n)
    $ftemp  PRECISION  2 +  CHARS  +        ( n adr)
    [CHAR] E  OVER  C!                      \ add E
    CHAR+                                   ( n adr+1)
    SWAP  S>D  TUCK DABS <# #S ROT SIGN #>  ( adr+1 c-adr u)
    ROT  SWAP  DUP >R  CMOVE
    $ftemp  PRECISION  3 +  R>  +  CHARS    ( c-adr u)
    do_fn
;
[ELSE]
: f->$ ( f -- c-adr u)
    14 f>string COUNT  do_fn ;
[THEN]

: (f")    ( --)
    ['] real_op     IS     .op            \ redirect
    ['] <try_fp#>   IS     try_fp#
    ['] f->$        IS     .fp#
    ['] >out        IS     do_id
    ['] >out        IS     do_fn
    ['] <do_f@>     IS     do_@
    ['] <do_f^>     IS     do_^
    ['] $fneg       IS     neg$

    get_formula   assign
    out_pad  DUP  CELL+  SWAP  @  ( c-adr u)
; nondeferred

: f"    (f")    STATE @
    IF  EVALUATE  ELSE  CR  CR  TYPE  THEN  ;  IMMEDIATE nondeferred

: f$"   (f")  EVALUATE  ; nondeferred

: z->$  ( f: x y --)   FSWAP  f->$  0null ends->count do_fn  f->$  ;

: (zz")    ( --)    \ can't use z" -- Win32Forth uses it!
    ['] cmplx_op    IS     .op            \ redirect
    ['] <try_z#>    IS     try_fp#
    ['] z->$        IS     .fp#
    ['] >out        IS     do_id
    ['] >out        IS     do_fn
    ['] <do_z@>     IS     do_@
    ['] <do_z^>     IS     do_^
    ['] $zneg       IS     neg$

    get_formula   assign
    out_pad  DUP  CELL+  SWAP  @  ( c-adr u)
;

: zz"   (zz")   STATE @
    IF  EVALUATE  ELSE  CR  CR  TYPE  THEN
;  IMMEDIATE

: zz$"   (zz")  EVALUATE  ;
\ ----------------------------------------------- end output words
GET-ORDER  NIP  1-  SET-ORDER     \ hide ftran definitions
\ ---------------------------------------------------- end program

