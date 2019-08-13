\ utils.4th
\
\ Some handy utilities for kForth
\
\ Requires:
\ 	strings.4th
\
\ Revisions:
\       2002-09-02  created  KM
\	2002-09-19  added PACK and $CONSTANT  KM
\       2007-07-31  replaced definition of $CONSTANT with
\                   more general version, added ENUM 
\                   and CTABLE, and simplified $TABLE  KM
\       2007-08-02  removed useless code from ENUM  km
\       2011-06-18  added PLACE from Wil Baden's toolbelt  km
\       2019-08-07  replaced description of PTR in comments  km

: shell ( a u -- n | execute a shell command) 
    strpck system ;

\ pfe shell command
\ : shell  system ; \ c-addr u -- n | execute a shell command in PFE

\ gforth shell command
\ : shell  system  $? ; \ c-addr u -- n | execute a shell command in gforth

\ iforth shell command
\ : shell  system  RETURNCODE @ ;  \ c-addr u -- n | shell command in iForth

\ PTR is similar to VALUE except it returns a number with an address
\ type. The word TO may be used to change the value of a named ptr.
: ptr ( a <name> -- ) 
    create 1 cells ?allot ! does> a@ ;


: table ( v1 v2 ... vn n <name> -- | create a table of singles ) 
    create dup cells ?allot over 1- cells + swap
    0 ?do dup >r ! r> 1 cells - loop drop ;


: ctable ( ... n <name> -- | create a table of characters/byte values)
    dup >r create ?allot dup r> + 1-
    ?do	 i c! -1 +loop ;


: $table ( a1 u1 a2 u2 ... an un n umax <name> -- | create a string table )
    CREATE  2DUP * CELL+ ?allot 2DUP ! 
    CELL+ >R 2DUP SWAP 1- * R> + 
    SWAP ROT  
    0 ?DO  
	2>R  R@  1-  MIN  DUP  2R@  DROP  C!
	2R@  DROP  1+  SWAP  CMOVE
	2R>  DUP >R  -  R>
    LOOP 2DROP
  DOES>  ( n a -- an un) 
    DUP @ ROT * + CELL+ COUNT ;  	


: pack ( a u a2 -- | copy string to counted string at a2)
    2dup c! 1+ swap cmove ;	

: place  ( addr len c-addr -- | copy string to counted string at a2)
     2DUP 2>R
     CHAR+ SWAP CHARS MOVE
     2R> C!
; 

: $constant  ( a u <name> -- | create a string constant )
    create dup >r cell+ ?allot dup r@ swap ! cell+ r> cmove  
    does> ( a -- a' u ) dup @ swap cell+ swap ; 


( simple enumeration utility

  Use:    val enum name1 name2 name3 ...

  where val is the unsigned integer starting value, and name1, name2,
  name3, ... are defined by enum to be constants taking the values

       val, val+1, val+2, ...

  e.g.  "0 enum orange apple banana"
)
: enum ( u <namelist> -- )
    BEGIN
	bl word count dup
    WHILE
            2>r dup s" constant " 
	    2r> strcat evaluate
	    1+
    REPEAT
    2drop drop ;
