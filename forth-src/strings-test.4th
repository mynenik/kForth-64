\ strings-test.4th
\
\ Test the kForth strings library
\
\ 2024-08-28 km

include ans-words
include strings
include ansi
include ttester
: 2nip ( x1 x2 x3 x4 -- x3 x4 )  2swap 2drop ;

create sbuf 64 allot
6 constant MAX_STRINGS
create StrArray[ MAX_STRINGS cells 2* allot
: S@ ( a -- caddr u ) dup @ swap cell+ a@ swap ;
: ]S@ ( a idx -- caddr u )  cells 2* + S@ ;
: ]S! ( caddr u a idx -- )  cells 2* + 2! ;


s" "  2constant NULL_STRING
s" abcdefghijklmnopqrstuvwxyz" 2constant LC_ALPHABET
s" 0123456789" 2constant DIGITS
LC_ALPHABET nip constant  N_LC_ALPHA
DIGITS nip      constant  N_DIGITS

TESTING UCASE
: ucase-check-all-ascii ( -- b )
    128 0 DO
      I ucase 
      I [char] a [char] z 1+ within IF
        I 32 - =
      ELSE
        I = 
      THEN
      invert IF false unloop EXIT THEN
    LOOP true ;
t{ ucase-check-all-ascii -> true }t

TESTING ISDIGIT IS_LC_ALPHA
: all-digits? ( caddr u -- b | is string all digits?)
   true -rot 0 DO dup c@ isdigit rot and swap 1+ LOOP drop ;

: any-digits? ( caddr u -- b | does string contain any digits?)
   false -rot 0 DO dup c@ isdigit rot or swap 1+ LOOP drop ;

\ Does string contain all lower case alphabet characters?
: all-lc-alpha? ( caddr u -- b )
   true -rot 0 DO dup c@ is_lc_alpha rot and swap 1+ LOOP drop ;

\ Does string contain any lower case alphabet characters?
: any-lc-alpha? ( caddr u -- b )
   false -rot 0 DO dup c@ is_lc_alpha rot or swap 1+ LOOP drop ;

t{ char 0 1- isdigit -> false }t
t{ char 9 1+ isdigit -> false }t
t{ DIGITS any-digits? -> true }t
t{ DIGITS all-digits? -> true }t
t{ LC_ALPHABET all-digits? -> false }t
t{ LC_ALPHABET any-digits? -> false }t

s" Watermelon57" 2constant S1
t{ S1 any-digits? -> true }t
t{ S1 2 - any-digits? -> false }t

t{ DIGITS any-lc-alpha? -> false }t
t{ DIGITS all-lc-alpha? -> false }t
t{ LC_ALPHABET any-lc-alpha? -> true }t
t{ LC_ALPHABET all-lc-alpha? -> true }t
t{ S1 any-lc-alpha? -> true }t
t{ S1 all-lc-alpha? -> false }t
 
TESTING $CONSTANT
: >upper ( a u -- a u )
   dup 0 ?DO over I + dup c@ ucase swap c! LOOP ;
s" ABCDEF" 2constant S2
t{ LC_ALPHABET PAD swap cmove -> }t
t{ PAD N_LC_ALPHA >upper -> PAD N_LC_ALPHA }t
t{ PAD N_LC_ALPHA $constant UC_ALPHABET -> }t
t{ UC_ALPHABET nip -> N_LC_ALPHA }t
t{ UC_ALPHABET drop 6 S2 compare -> 0 }t
t{ PAD N_LC_ALPHA erase -> }t
t{ UC_ALPHABET drop 6 S2 compare -> 0 }t
t{ UC_ALPHABET 1- + c@ -> char Z }t

TESTING SCAN SKIP
t{ LC_ALPHABET char a scan -> LC_ALPHABET }t
t{ LC_ALPHABET char g scan -> LC_ALPHABET 6 /string }t
t{ LC_ALPHABET char z scan -> LC_ALPHABET dup 1- /string }t
t{ LC_ALPHABET char A scan nip -> 0 }t
t{ LC_ALPHABET 0 scan nip -> 0 }t
t{ NULL_STRING char * scan nip -> 0 }t
t{ NULL_STRING 0 scan nip -> 0 }t

t{ LC_ALPHABET char a skip -> LC_ALPHABET 1 /string }t
t{ NULL_STRING char a skip -> NULL_STRING }t
s" boolean" 2constant S3
t{ S3 char o skip -> S3 }t
t{ S3 1 /string char o skip s" lean" compare -> 0 }t

TESTING REPLACE-CHAR
t{ s" 208,671,3.04" char , bl replace-char s" 208 671 3.04" compare -> 0 }t

TESTING PACK
t{ LC_ALPHABET PAD pack -> }t
t{ PAD c@ -> 26 }t
t{ PAD count LC_ALPHABET compare -> 0 }t

t{ PAD 4 char _ fill -> }t
t{ NULL_STRING PAD pack -> }t
t{ PAD count nip -> 0 }t
t{ PAD 1+ 3 s" ___" compare -> 0 }t

TESTING STRCPY STRLEN
t{ PAD  32 erase -> }t
t{ sbuf 32 erase -> }t
t{ LC_ALPHABET sbuf pack -> }t
t{ sbuf PAD strcpy -> }t
t{ PAD count LC_ALPHABET compare -> 0 }t

t{ PAD 32 erase -> }t
t{ NULL_STRING sbuf pack -> }t
t{ sbuf PAD strcpy -> }t
t{ PAD count nip -> 0 }t

t{ PAD LC_ALPHABET nip 1+ erase -> }t
t{ LC_ALPHABET PAD swap cmove -> }t  \ null-terminated string at PAD
t{ PAD strlen -> LC_ALPHABET nip }t

t{ PAD 32 erase -> }t
t{ PAD strlen -> 0 }t

TESTING STRCAT STRPCK
N_DIGITS value n1
N_DIGITS N_LC_ALPHA + value n2
N_DIGITS N_LC_ALPHA 2* + value Nalpha
t{ DIGITS LC_ALPHABET strcat UC_ALPHABET strcat $constant ALPHANUMERIC -> }t
t{ ALPHANUMERIC nip -> Nalpha }t
t{ ALPHANUMERIC DIGITS search -> ALPHANUMERIC true }t
t{ ALPHANUMERIC LC_ALPHABET search -> ALPHANUMERIC n1 - swap n1 + swap true }t
t{ ALPHANUMERIC UC_ALPHABET search -> ALPHANUMERIC n2 - swap n2 + swap true }t

TESTING PARSE_TOKEN PARSE_LINE
s"    3.1415e0  grape      20"  2constant S4
t{ S4 parse_token 2nip s" 3.1415e0" compare -> 0 }t
t{ S4 parse_token 2drop parse_token 2nip s" grape" compare -> 0 }t
t{ S4 parse_token 2drop parse_token 2drop parse_token 2nip s" 20" compare -> 0 }t

t{ S4 parse_line >r StrArray[ 2 ]S! StrArray[ 1 ]S! StrArray[ 0 ]S! r> -> 3 }t
t{ StrArray[ 0 ]S@  s" 3.1415e0" compare -> 0 }t
t{ StrArray[ 1 ]S@  s" grape"    compare -> 0 }t
t{ StrArray[ 2 ]S@  s" 20"       compare -> 0 }t

t{ NULL_STRING parse_line -> 0 }t

\ TESTING STRING>S STRING>UD STRING>D
\ TESTING U>STRING S>STRING UD>STRING D>STRING
\ TESTING F>STRING F>FPSTR
\ TESTING STRING>F
\ TESTING PARSE_ARGS PARSE_CSV

