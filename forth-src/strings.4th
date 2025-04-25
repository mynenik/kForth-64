\ strings.4th
\
\ String utility words for kForth
\
\ Copyright (c) 1999--2025 Krishna Myneni
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
\ 	STRCPY      ( ^str a -- )
\ 	STRLEN      ( a -- u )
\
\  STRx words using circular buffer
\  **	STRBUFCPY   ( ^str1 -- ^str2 )
\       STRBUFMOVE  ( a1 u1 -- a2 u2 )
\ 	STRCAT      ( a1 u1 a2 u2 -- a3 u3 )  \ LMI Forth
\ 	STRPCK      ( a u -- ^str )           \ LMI Forth
\
\  String parsing primitives
\  *	PARSE-TOKEN ( a u -- a2 u2 a3 u3 ) 
\  *	PARSE-LINE  ( a u -- a1 u1 a2 u2 ... an un n )
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
\  *	PARSE-FLOATS     ( a u -- n ) ( F: r1 ... rn ) | ( a u -- r1 ... rn n )
\  *    PARSE-CSV-FLOATS ( a u -- n ) ( F: r1 ... rn ) | ( a u -- r1 ... rn n )
\
\
\  * PARSE_TOKEN and PARSE_LINE are deprecated names for 
\    PARSE-TOKEN and PARSE-LINE
\
\  * PARSE_ARGS and PARSE_CSV are deprecated names for PARSE-FLOATS
\    and PARSE-CSV-FLOATS
\
\ ** STRBUFCPY is deprecated. Use COUNT STRPCK to copy a
\    counted string to the circular buffer, and use
\    STRBUFMOVE to copy a c-addr u string to the buffer.
 	
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

\ Copy a counted string to address a.
\ Does not append null terminator.
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
string_buf STR_BUF_SIZE + constant STR_BUF_PTR_MAX
variable str_buf_ptr
string_buf str_buf_ptr !

\ Adjust current pointer to accomodate u bytes.
\ This word is for internal use only.
: adjust_str_buf_ptr ( u -- )
   dup STR_BUF_SIZE >= IF -9 throw  \ string buffer not big enough
   ELSE
     str_buf_ptr a@ + STR_BUF_PTR_MAX >=
     IF  string_buf str_buf_ptr !  THEN    \ wrap pointer
   THEN ;

\ Concatenate two strings. Return the concatenated string
\ which is stored in the circular buffer and has limited
\ persistence. Input strings are not modified.
: strcat ( a1 u1 a2 u2 -- a3 u3 )
   2 pick 2dup + 1+ adjust_str_buf_ptr drop
   2over  str_buf_ptr a@   swap cmove  \ a1 u2 a2 u2
   tuck                                \ a1 u1 u2 a2 u2
   3 pick str_buf_ptr a@ + swap cmove  \ a1 u1 u2 
   + nip  str_buf_ptr a@   swap        \ abuf u1+u2  
   2dup + 0 over c!                    \ ( null terminate )
   1+ str_buf_ptr ! ;

\ Make a counted string in the circular buffer from a string.
\ Input string is not modified.
: strpck ( a u -- ^str )
   255 min dup 2+ adjust_str_buf_ptr   \ a ulim
   2dup str_buf_ptr a@ 2dup c!         \ a ulim a ulim abuf
   1+ swap cmove nip                   \ ulim 
   str_buf_ptr a@ tuck + 1+            \ abuf abuf2 
   0 over c!                           \ ( null terminate )
   1+ str_buf_ptr ! ;

\ Copy a counted string to the circular string buffer.
\ Return address of the copied cs. Input cs is not modified.
\ ** The word STRBUFCPY is deprecated -- Use COUNT STRPCK ** 
: strbufcpy ( ^str1 -- ^str2 )  count strpck ;

\ Copy a c-addr u string to the circular string buffer.
\ Return the address and count of the copied string. The
\ input string is not modified.
: strbufmove ( a1 u1 -- a2 u2 )
    STR_BUF_SIZE 1- min  \ a1 ulim 
    dup 1+ adjust_str_buf_ptr  \ a1 ulim
    tuck str_buf_ptr a@  \ ulim a1 ulim abuf
    swap cmove           \ ulim
    str_buf_ptr a@ swap  \ abuf ulim
    2dup +               \ abuf ulim aend
    0 over c!            \ ( null terminate )
    1+ str_buf_ptr ! ;

\ Parse next token from a string separated by a blank:
\   a2 u2 is the remaining substring
\   a3 u3 is the token string
: parse-token ( a u -- a2 u2 a3 u3)
   bl skip 2dup bl scan 2>r r@ - 2r> 2swap ;

\ Parse a line into substrings which are separated by one
\ or more spaces
: parse-line ( a u -- a1 u1 a2 u2 ... n )
   0 >r
   BEGIN
     parse-token
     dup
   WHILE
     1 rp@ +!  \ r> 1+ >r
     2swap
   REPEAT  
   2drop 2drop r> ;

\ Older word names PARSE_TOKEN and PARSE_LINE are deprecated 
synonym parse_token parse-token
synonym parse_line  parse-line

\ Base 10 number to string conversions and vice-versa

\ Return counted string representing u in base 10
: u>string ( u -- ^str )
    base @ swap 10 base ! 0 <# #s #> strpck swap base ! ;

\ Return counted string representing ud in base 10
: ud>string ( ud -- ^str )
    base @ >r 10 base ! <# #s #> strpck r> base ! ;

\ Convert counted string to unsigned double in base 10
: string>ud ( ^str -- ud )
    count base @ >r 10 base ! 0 0 2swap >number 2drop r> base ! ;

\ Return counted string representing d in base 10
: d>string ( d -- ^str )
    dup >r dabs ud>string r> 
	0< IF s" -" rot count strcat strpck THEN ;

\ Convert counted string to signed double in base 10
: string>d ( ^str -- d )
    base @ >r 10 base ! number? drop r> base ! ;

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
    count bl skip base @ >r 10 base ! >float 
    0= IF NAN THEN r> base ! ;

\ Parse a string delimited by spaces into fp numbers

[DEFINED] FDEPTH [IF]
: parse-floats ( a u -- n ) ( F: -- r1 ... rn )
	0 >r  
	BEGIN
	  dup 0>
	WHILE
	  bl skip dup
        WHILE
	  2dup bl scan 
          dup IF 
            2>r  r@ - strpck string>f 2r>
          ELSE
            2drop strpck string>f 0 dup
          THEN
	  1 rp@ +!   \ r> 1+ >r
	REPEAT
        THEN
	2drop r> ;
[ELSE]
: parse-floats ( a u -- r1 ... rn n )
	0 >r  2>r
	BEGIN
	  r@ 0>
	WHILE
	  2r> bl skip 2>r 
          r@
        WHILE 
	  2r> 2dup bl scan
          dup IF 
            2>r  r@ - strpck string>f 2r>
          ELSE 
	    2drop strpck string>f 0 dup
          THEN
	  1 rp@ +!   \ r> 1+ >r 
          2>r
	REPEAT
        THEN
	2r> 2drop r> ;
[THEN]

: parse-csv-floats ( a u -- n ) ( F: -- r1 ... rn ) \ ( a u -- r1 ... rn n )
    [char] , bl replace-char parse-floats ;

\ Older names PARSE_ARGS and PARSE_CSV are deprecated
synonym parse_args parse-floats
synonym parse_csv  parse-csv-floats

BASE !

