\ wl-info.4th
\
\ Example of Use:
\
\   hex forth-wordlist wl-info cr .s
\   hex forth-wordlist wl-data-words
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

\ Display name and data field address for a word only
\ if it has a non-zero body address and non-zero xt.
: data-word ( nt -- flag )
   dup name>interpret 
   ?dup IF
     >body ?dup IF   
       swap name>string cr 32 $.R     \ display the wordname
       4 spaces 16 u.r   \ display the data field address
     ELSE drop
     THEN
   ELSE drop
   THEN
   true ;

: wl-data-words ( wid -- )
   ['] data-word swap traverse-wordlist cr ;





