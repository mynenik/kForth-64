\ wl-collisions.4th
\
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


	
