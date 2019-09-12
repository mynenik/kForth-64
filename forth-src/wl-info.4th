\ wl-info.4th
\
\ Glossary:
\
\   WL-INFO     ( wid -- )  Display information about words in wordlist.
\   WL-CREATED  ( wid -- )  Display CREATEd words in a wordlist.
\   SO-CREATED  ( -- )      Display all CREATEd words in search order.
\
\ Example of Use:
\
\   hex forth-wordlist wl-info
\   hex forth-wordlist wl-created
\
\ right justified output of a string in a field
: $.R ( caddr1 u1 nfield -- | assume nfield > u1)
   over - spaces type ;

: word-info ( wid nt -- wid flag )
   over >r          \ keep a copy of the wid 
   name>string 
   2dup cr 32 $.R      \ display the word name
   r> search-wordlist  \ obtain the word's xt and precedence
   4 spaces
   1 = IF s" IMM "  \ display precedence IMMEDIATE
   ELSE   s"     "
   THEN type  
   dup >body swap   \ -- pfa xt/cfa 
   16 u.r           \ display the xt/cfa
   2 spaces
   16 u.r           \ display the pfa ( may not be valid )
   true ;

\ Display info on each word in the specified wordlist:
\   Name, Precedence, xt/cfa, pfa 
: wl-info ( wid -- )
   dup ['] word-info swap traverse-wordlist drop ;

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



