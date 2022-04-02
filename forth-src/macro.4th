\ macro.4th
\
\ MACRO wordset from Wil Baden's Tool Belt series in
\ Forth Dimensions (FD) Vol. 19, No. 2, July/August 1997.
\ Original code has been modified by Jabari Zakiya to make 
\ more efficient MACRO which allows insertion of parameters 
\ following the macro. "\" represents place where parameter 
\ is inserted.
\
\ Example:  
\	    MACRO  ??  " IF  \  THEN "
\	    : FOO .. ?? EXIT .... ;  ?? compiles to -- IF EXIT THEN
\
\ Requires:
\	ans-words.4th  (kForth only)
\
\ Revisions:
\
\   2003-02-06  km  kForth version created
\   2004-02-07  km  revised def of MACRO for kForth 1.2.0
\   2011-03-01  km  removed requirement of strings.4th  
\
\ For use with ANS Forths, define the following:
\
\     : NONDEFERRED ;

[undefined] allot? [IF]  : allot? ( u -- a ) here swap allot ;  [THEN]

: PLACE  ( caddr n addr -)  2DUP  C!  CHAR+  SWAP  CHARS  MOVE ;
: SSTRING ( char "ccc" - addr) WORD COUNT DUP 1+ CHARS ALLOT? PLACE ;

: split-at-char  ( a  n  char  -  a  k  a+k  n-k)
     >r  2dup  
     BEGIN  
       dup  
     WHILE  
        over  c@  r@  -
        ( WHILE  1 /STRING  REPEAT  THEN)
	0= IF  r> drop tuck 2>r - 2r> EXIT THEN 
	1 /string 
     REPEAT
     r> drop  tuck  2>r  -  2r> ;


: DOES>MACRO  \ Compile the macro, including external parameters
    DOES> count  
    BEGIN 
      [char] \  split-at-char  
      2>r  evaluate  r@
    WHILE 
      bl word count evaluate 
      2r>  1 /string 
    REPEAT
    2r> 2drop ;

: MACRO  
    CREATE IMMEDIATE  NONDEFERRED  
    CHAR SSTRING DOES>MACRO ;


\ Further examples of macros:
\
\	 macro sum() " \ @ \ @ + ."
\ Use:
\
\	variable a
\	variable b
\	variable c
\	variable d
\
\	: test  sum() a b   sum() c d ;
