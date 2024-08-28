\ strings.4th
\
\ String utility words for kForth
\
\ Copyright (c) 1999--2024 Krishna Myneni
\
\ This software is provided under the terms of the
\ GNU General Public License.
\
\ Please report bugs to <krishna.myneni@ccreweb.org>.
\
\ Glossary:
\
\  Create a string constant
\       $CONSTANT ( a1 u1 "name" -- )
\
\  Character tests and conversions
\ 	IS_LC_ALPHA ( c -- b )
\ 	ISDIGIT     ( c -- b )
\ 	UCASE       ( c1 -- c2 )
\
\  String search and replace primitives
\  	SCAN        ( a1 u1 c -- a2 u2 )
\ 	SKIP        ( a1 u1 c -- a2 u2 )
\       REPLACE-CHAR ( a u c1 c2 -- a u )
\
\  Copy a string to a counted string
\       PACK        ( a u a2 -- )
\       PLACE       ( a u a2 -- )  same as PACK
\
\  LMI UR/Forth STRx words
\ 	STRCPY      ( ^str a -- )
\ 	STRLEN      ( a -- u )
\ 	STRBUFCPY   ( ^str1 -- ^str2 )
\ 	STRCAT      ( a1 u1 a2 u2 -- a3 u3 )
\ 	STRPCK      ( a u -- ^str )
\
\  String parsing primitives
\ 	PARSE_TOKEN ( a u -- a2 u2 a3 u3 )
\ 	PARSE_LINE  ( a u -- a1 u1 a2 u2 ... an un n )
\
\  Counted string to Base 10 single and double integer conversions
\ 	STRING>S    ( ^str -- n )
\ 	STRING>UD   ( ^str -- ud )
\ 	STRING>D    ( ^str -- d )
\
\  Single and double integer to Base 10 counted string conversions
\ 	U>STRING    ( u -- ^str )
\ 	S>STRING    ( n -- ^str )
\ 	UD>STRING   ( ud -- ^str )
\ 	D>STRING    ( d -- ^str )
\
\  Floating point number to scientific and fixed point string conversion
\ 	F>STRING    ( n -- ^str ) ( F: r -- ) | ( r n -- ^str )
\ 	F>FPSTR     ( n -- a u )  ( F: r -- ) | ( r n -- a u )
\
\  Counted string to floating point number conversion
\ 	STRING>F    ( ^str -- )   ( F: -- r ) | ( ^str -- r )
\
\  Formatted floating point output
\ 	F.RD        ( w n -- )    ( F: r -- ) | ( r w n -- )
\
\  String parsing and conversion to multiple floating point values
\ 	PARSE_ARGS  ( a u -- n ) ( F: r1 ... rn ) | ( a u -- r1 ... rn n )
\       PARSE_CSV   ( a u -- n ) ( F: r1 ... rn ) | ( a u -- r1 ... rn n )
\
\ 	
BASE @
DECIMAL

\ Create a new allocated and initialized fixed string
\ from an existing string which may be transient in 
\ memory or mutable.
: $constant  ( a u <name> -- )
    dup allocate IF -59 throw THEN
    swap 2dup 2>r cmove 2r> 2constant ;


\ Return true if c is a lower case alphabetical character
: is_lc_alpha ( c -- b )
	[char] a [ char z 1+ ] literal within ;	

\ Return true if c is ascii value of '0' through '9'	
: isdigit ( c -- b )
	[char] 0 [ char 9 1+ ] literal within ;

\ Change alphabet character to upper case
: ucase ( c1 -- c2 )
	dup [CHAR] a [ CHAR z 1+ ] literal within
	IF 95 and THEN ;

\ Search for first occurrence of character c in a string:
\   a1 u1 is the string to be searched
\   a2 u2 is the substring starting with character c
: scan ( caddr1 u1 c -- caddr2 u2 )
    >r rp@ 1 search invert if + 0 then r> drop ;

\ Search for first occurrence of character not equal to c in a string
\   a1 u1 is the string to be searched,
\   a2 u2 is the substring starting with char <> c
: skip ( caddr1 u1 c -- caddr2 u2 )
    over 0> IF
      over 0 DO
        2 pick c@ over <> IF leave
        ELSE >r 1 /string r> THEN
      LOOP
    THEN
    drop ;

\ Replace char c1 with char c2 in string
: replace-char ( c-addr u c1 c2 -- c-addr u )
    2over 0 ?DO    \ c-addr u c1 c2 a
      dup c@
      3 pick = IF  2dup c! THEN
      1+
    LOOP
    drop 2drop ;

\ Copy string to counted string at a2
: pack ( a u a2 -- )
    2dup c! char+ swap cmove ;

synonym place pack

\ Copy a counted string to address a
: strcpy ( ^str a -- )
    over c@ 1+ cmove ;

\ Length of a null-terminated string
: strlen ( addr -- u )
    0
    BEGIN over c@
    WHILE 1+ swap 1+ swap
    REPEAT
    nip ;

\ Circular String Buffer

16384 constant STR_BUF_SIZE
create string_buf STR_BUF_SIZE allot
variable str_buf_ptr
string_buf str_buf_ptr !

\ Adjust current pointer to accomodate u bytes.
\ This word is for internal use only.
: adjust_str_buf_ptr ( u -- )
	str_buf_ptr a@ swap +
	string_buf STR_BUF_SIZE + >=
	IF
	  string_buf str_buf_ptr !	\ wrap pointer
	THEN ;

\ Copy a counted string to the circular string buffer
: strbufcpy ( ^str1 -- ^str2 )
	dup c@ 1+ dup adjust_str_buf_ptr
	swap str_buf_ptr a@ strcpy
	str_buf_ptr a@ dup rot + str_buf_ptr ! ;

\ Concatenate two strings. Return the concatenated string
\ which is stored in the circular buffer and has limited
\ persistence.
: strcat ( a1 u1 a2 u2 -- a3 u3 )
	rot 2dup + 1+ adjust_str_buf_ptr 
	-rot
	2swap dup >r
	str_buf_ptr a@ swap cmove
	str_buf_ptr a@ r@ +
	swap dup r> + >r
	cmove 
	str_buf_ptr a@
	dup r@ + 0 swap c!
	dup r@ + 1+ str_buf_ptr !
	r> ;

\ Make a counted string in the circular buffer from a string
: strpck ( a u -- ^str )
	255 min dup 1+ adjust_str_buf_ptr 
	dup str_buf_ptr a@ c!
	tuck str_buf_ptr a@ 1+ swap cmove
	str_buf_ptr a@ over + 1+ 0 swap c!
	str_buf_ptr a@
	dup rot 1+ + str_buf_ptr ! ;


\ Parse next token from the string separated by a blank:
\   a2 u2 is the remaining substring
\   a3 u3 is the token string
: parse_token ( a u -- a2 u2 a3 u3)
	BL SKIP 2DUP BL SCAN 2>R R@ - 2R> 2SWAP ;

: parse_line ( a u -- a1 u1 a2 u2 ... n )
	( -trailing)
	0 >r
	BEGIN
	  parse_token
	  dup
	WHILE
	  r> 1+ >r
	  2swap
	REPEAT  
	2drop 2drop r> ;

\ Base 10 number to string conversions and vice-versa

\ Return counted string representing u in base 10
: u>string ( u -- ^str )
    base @ swap decimal 0 <# #s #> strpck swap base ! ;

\ Return counted string representing ud in base 10
: ud>string ( ud -- ^str )
    base @ >r decimal <# #s #> strpck r> base ! ;

\ Convert counted string to unsigned double in base 10
: string>ud ( ^str -- ud )
    count base @ >r decimal 0 0 2swap >number 2drop r> base ! ;

\ Return counted string representing d in base 10
: d>string ( d -- ^str )
    dup >r dabs ud>string r> 
	0< IF s" -" rot count strcat strpck THEN ;

\ Convert counted string to signed double in base 10
: string>d ( ^str -- d )
    base @ >r decimal number? drop r> base ! ;

\ Return counted string representing n in  base 10
: s>string ( n -- ^str )
    dup >r abs u>string r> 0< IF 
	  s" -" rot count strcat strpck
    THEN ;

variable  number_sign
variable  number_val

\ Convert counted string to signed integer in base 10 
: string>s ( ^str -- n )
	0 number_val !
	false number_sign !
	count
	0 ?DO
	  dup c@
	  case
	    [char] -  of true  number_sign ! endof 
	    [char] +  of false number_sign ! endof 
	    dup isdigit 
	    IF
	      dup [char] 0 - number_val @ 10 * + number_val !
	    THEN
	  endcase
	  1+
	LOOP
	drop
	number_val @ number_sign @ IF negate THEN ;
 
\ Convert r to a formatted fixed point string with
\ n decimal places, 0 <= n <= 17.
\ WARNING: Requesting a number fixed point decimal places which
\   results in total number of digits > 17 will give
\   incorrect results, e.g. "65536.9921875e 15 f>fpstr type"
\   will output garbage (20 digits are being requested).
: f>fpstr ( n -- a u ) ( F: r -- ) \ ( r n -- a u )
    0 max 17 min >r 10e r@ s>f f** 
    f* fround f>d dup -rot dabs
    <# r> 0 ?DO # LOOP [char] . hold #s rot sign #> ; 

\ Print an fp number as a fixed point string with
\ n decimal places, right-justified in a field of width, w
: f.rd ( w n -- ) ( F: r -- ) \ ( r w n -- )
    swap >r f>fpstr dup 20 > IF
      \ Too many digits requested in fixed point output
      2drop r> 0 ?DO [char] * emit LOOP
    ELSE
      r> over - 
      dup 0> IF spaces ELSE drop THEN type
    THEN ;

create    fnumber_buf 64 allot
variable  fnumber_sign
variable  fnumber_power
variable  fnumber_digits

\ Convert r to a counted string in scientific notation
\ with n decimal places
: f>string ( n -- ^str ) ( F: r -- ) \ ( r n -- ^str )
	>r 
	fdup f0= IF
	  f>d <# r> 0 ?do # loop #> s" e0" strcat 
	  s"  0." 2swap strcat strpck EXIT	  
	THEN
	r>
	dup 16 swap u< IF drop fdrop c" ******" exit THEN  \ test for invalid n
	fnumber_digits !
	0 fnumber_power !
	fdup 0e f< fnumber_sign ! 
	fabs
	fdup 1e f< IF
	  fdup 0e f> IF
	    BEGIN
	      10e f* -1 fnumber_power +!
	      fdup 1e f>=
	    UNTIL
	  THEN
	ELSE
	  fdup 10e f>= IF
	    BEGIN
	      10e f/ 1 fnumber_power +!
	      fdup 10e f<
	    UNTIL
	  THEN
	THEN
	10e fnumber_digits @ s>f f**
	f* floor f>d d>string
	count drop dup fnumber_buf
	fnumber_sign @ 
	IF [char] - ELSE bl THEN 
	swap c!
	fnumber_buf 1+ 1 cmove
	1+
	[char] . fnumber_buf 2+ c!
	fnumber_buf 3 + fnumber_digits @ cmove
	fnumber_buf fnumber_digits @ 3 +	
	s" e" strcat
	fnumber_power @ s>string count strcat
	strpck 	;

0e 0e f/ fconstant NAN
	 
: string>f ( ^str -- ) ( F: -- r ) \ ( ^str -- r )
    count bl skip base @ >r decimal >float 
    0= IF NAN THEN r> base ! ;

\ Parse a string delimited by spaces into fp numbers

[DEFINED] FDEPTH [IF]
: parse_args ( a u -- n ) ( F: -- r1 ... rn )
	0 >r  
	BEGIN
	  dup 0>
	WHILE
	  bl skip 
	  2dup 
	  bl scan 2>r
	  r@ - dup 0= 
	  IF drop r> 0 >r THEN
	  strpck string>f
	  2r> r> 
	  1+ >r
	REPEAT
	2drop r> ;
[ELSE]
: parse_args ( a u -- r1 ... rn n )
	0 >r 
	2>r
	BEGIN
	  r@ 0>
	WHILE
	  2r> bl skip 
	  2dup 
	  bl scan 2>r
	  r@ - dup 0= 
	  IF drop r> 0 >r THEN
	  strpck string>f
	  2r> r> 
	  1+ >r 2>r
	REPEAT
	2r> 2drop r> ;
[THEN]

: parse_csv ( a u -- n ) ( F: -- r1 ... rn ) \ ( a u -- r1 ... rn n )
    [char] , bl replace-char parse_args ;

BASE !

