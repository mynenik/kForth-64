\ wl-tools.4th
\
\ Glossary:
\
\   WL-INFO      ( wid -- ) Display information about words in wordlist.
\   WL-IMMEDIATE ( wid -- ) Display IMMEDIATE words in a wordlist.
\   WL-CREATED   ( wid -- ) Display CREATEd words in a wordlist.
\   SO-CREATED   ( -- )     Display all CREATEd words in search order.
\   WL-COLLISIONS ( wid1 wid2 -- ) Display name collisions between two wlists.
\
\ Example of Use:
\
\   hex forth-wordlist wl-info
\   hex forth-wordlist wl-created
\
\ right justified output of a string in a field
: $.R ( caddr1 u1 nfield -- | assume nfield > u1)
   over - spaces type ;

: immediate? ( nt -- flag )
    name>compile ['] execute = nip ;

: word-info ( nt -- flag )
   cr
   dup name>string 32 $.R      \ display the word name
   dup immediate? 
   4 spaces
   IF   s" IMM "  \ display precedence IMMEDIATE
   ELSE s"     "
   THEN type
   name>interpret   
   dup >body swap   \ -- pfa xt 
   16 u.r           \ display the xt
   2 spaces
   16 u.r           \ display the pfa
   true ;

\ Display info on each word in the specified wordlist:
\   Name, Precedence, xt, pfa 
: wl-info ( wid -- )
    ['] word-info swap traverse-wordlist ;

\ Display name of IMMEDIATE word
: immediate-word ( nt -- flag )
    dup immediate? IF
      cr name>string 4 spaces type
    ELSE
      drop
    THEN
    true ;

\ Display all IMMEDIATE words in the specified wordlist
: wl-immediate ( wid -- )
   ['] immediate-word swap traverse-wordlist cr ;

\ Display name and body address for a CREATEd word only:
\ i.e. has a non-zero xt and non-zero body address
: created-word ( nt -- flag )
   dup name>interpret 
   ?dup IF
     >body ?dup IF   
       swap name>string cr 32 $.R     \ display the wordname
       4 spaces 16 u.r   \ display the body address
     ELSE drop
     THEN
   ELSE drop
   THEN
   true ;

\ Display the CREATEd words in the specified wordlist
: wl-created ( wid -- )
   ['] created-word swap traverse-wordlist cr ;

\ Display all CREATEd words in the search order
: so-created ( -- )
    get-order 0 do cr wl-created loop ;


\ Show all name collisions between two wordlists
\
\ Usage:
\  	wid1 wid2 wl-collisions 

variable wid2

: next-name2 ( c-addr u nt -- c-addr u flag )
	name>string
	2over 2over compare 0= IF
	  cr type false
	ELSE
	  2drop true
	THEN ;

: next-name1 ( nt -- c-addr u flag )
	name>string ['] next-name2 wid2 a@ traverse-wordlist 
	2drop true ;

: wl-collisions ( wid1 wid2 -- ) 
	wid2 ! ['] next-name1 swap traverse-wordlist ;

