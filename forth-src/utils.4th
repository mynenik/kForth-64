\ utils.4th
\
\ Some handy utilities for kForth
\
\ Glossary:
\
\   SHELL  ( c-addr u -- n )  execute a shell command
\   TDSTRING ( -- c-addr u )  return a date and time string
\   TABLE  ( m1 ... mn n "name" -- ) create a named table of singles
\   CTABLE ( c1 ... cn n "name" -- ) create a named table of pchars/bytes
\   $TABLE ( a1 u1 ... an un n umax "name" -- ) create a named string table
\   PACK   ( a1 u1 a2 -- ) copy a string to a counted string at a2 
\   PLACE  ( a1 u1 a2 -- ) same as PACK
\   $CONSTANT ( a1 u1 "name" -- ) create a named and initialized string constant
\   ENUM   ( u "namelist" -- ) create a list of enumerated constants
\   IS-PATH-DELIM? ( c -- flag ) return true if character is a path delimiter
\          CAUTION: the definition of IS-PATH-DELIM? may be system-specific.
\   SPLIT-PATH ( c-addr u -- c-pathaddr u1 c-fileaddr u2 )
\          split a string containing a file path into the path string
\          and a file name string
\
\ Requires: ans-words.4th  strings.4th
\

: shell ( a u -- n | execute a shell command) 
    strpck system ;

: tdstring ( -- a u | return a date and time string )
    time&date
    s"  "
    rot 0 <# [char] - hold # # # # #> strcat
    rot 0 <# [char] - hold # # #>     strcat
    rot 0 <# bl hold # # #>           strcat
    rot 0 <# [char] : hold # # #>     strcat
    rot 0 <# [char] : hold # # #>     strcat
    rot 0 <# # # #>                   strcat
;

: table ( v1 v2 ... vn n <name> -- | create a table of singles ) 
    create dup cells allot? over 1- cells + swap
    0 ?do dup >r ! r> 1 cells - loop drop ;

: ctable ( ... n <name> -- | create a table of characters/byte values)
    dup >r create allot? dup r> + 1-
    ?do	 i c! -1 +loop ;

: $table ( a1 u1 a2 u2 ... an un n umax <name> -- | create a string table )
    CREATE  2DUP * CELL+ allot? 2DUP ! 
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
    2dup c! char+ swap cmove ;	

: place  ( addr len c-addr -- | copy string to counted string at a2)
     2DUP 2>R
     CHAR+ SWAP CHARS MOVE
     2R> C!
; 

: $constant  ( a u <name> -- | create a string constant )
    create dup >r cell+ allot? dup r@ swap ! cell+ r> cmove  
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

\ Split a string containing path+filename into a path name and
\ file name.
\
\ The definition of IS-PATH-DELIM? assumes that the recognized
\ path delimiter characters are not used within the file name.
: is-path-delim? ( c -- flag )
    dup dup
    [char] \ = >r
    [char] / = >r
    [char] : =
    r> or r> or ;

: split-path ( c-addr u -- c-pathaddr u1 c-fileaddr u2 )
    ?dup IF
      2dup + 1- 1  \ -- c-addr u  {c-addr+u-1} 1
      begin
        over c@ is-path-delim? 0= >r
        dup 3 pick <= r> and
      while
        -1 /string
      repeat
      \ -- c-addr u  c-addr2 u2
      ?dup IF
        1 /string   \ c-addr u c-fileaddr u2
        2dup 2>r nip
        -  2r>
      ELSE
        2>r drop 0 2r>
      THEN
    ELSE
      0 2dup
    THEN ;


