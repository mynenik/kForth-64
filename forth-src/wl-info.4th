\ wl-info.4th
\
\ Requires:
\
\   ans-words
\   strings
\
\ Example of Use:
\
\   hex forth-wordlist wl-info cr .s

\ kForth-specific implementation of Forth-2012 NAME>STRING
\  (15.6.2.1909.40 in Tools Ext)
: name>string ( nt -- caddr u ) dup strlen ;

\ right justified output of a string in a field
: $.R ( caddr1 u1 nfield -- | assume nfield > u1)
   over - spaces type ;

: word-info ( nt -- flag )
   name>string 
   2dup cr 32 $.R   \ display the word name
   strpck find      \ obtain the word's xt and precedence
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
   ['] word-info swap traverse-wordlist ;

