\ lists-test.4th
\
\ Demonstration of basic list manipulation facilities provided by lists.4th.
\
\ Copyright (c) 2003, 2006, 2010 Creative Consulting for Research & Education
\ Provided under the GNU General Public License.
\
\ Revisions:
\
\	2003-04-14  km
\       2006-04-19  km extensive revision using Hayes' style tests;
\                     renamed from test-lists.4th to lists-test.4th 
\       2010-06-20  km no longer requires strings.4th; renamed }LIST to L}T
\
\ Notes:
\
\ 1. Some simple examples are borrowed from P. Norvig's,
\    "Paradigms of Artificial Intelligence Programming:
\     Case Studies in Common Lisp"
\
\ 2. Some list functions are not exemplified here.
\

include ans-words
include lists
include ttester
DECIMAL

ALSO LISP

\ Hayes' style notation for testing equality of list results

: l}t  ( ... -- | Compare the stack [expected] contents with the saved [actual] contents)  
  depth actual-depth @  = IF        \ if depths match
    depth ?dup IF                   \ if there is something on the stack
      0 DO                          \ for each stack item
        actual-results i CELLS + a@      \ compare actual with expected
        equal invert IF S" INCORRECT RESULT: " ERROR LEAVE THEN
      LOOP
    THEN 
  ELSE                                  \ depth mismatch
    s" WRONG NUMBER OF RESULTS: " ERROR 
  THEN
;


COMMENT Defining lists
TESTING '( 
nil  ptr  x
nil  ptr  y
nil  ptr  z 
t{ '( a b c )  to  x -> }t
t{ '( 1 2 3 )  to  y -> }t
t{ '( @x @y )  to  z -> }t
t{ x -> '( a b c ) l}t
t{ y -> '( 1 2 3 ) l}t
t{ z -> '( ( a b c ) ( 1 2 3 ) ) l}t

COMMENT List Element Retrieval
TESTING FIRST CAR REST CDR SECOND LAST
t{ x  first  -> quote a  l}t
t{ x  car    -> quote a  l}t
t{ x  rest   -> '( b c ) l}t
t{ x  cdr    -> '( b c ) l}t
t{ x  second -> quote b  l}t
t{ x  last   -> '( c )   l}t

COMMENT List Properties
TESTING LENGTH #ATOMS REVERSE CONS
t{ x  length -> 3 }t
t{ x  #atoms -> 3 }t
t{ z  length -> 2 }t
t{ z  #atoms -> 6 }t
t{ x  reverse -> '( c b a ) l}t
t{ x  -> '( a b c ) l}t
t{ quote 0  y cons -> '( 0 1 2 3 ) l}t

COMMENT Predicate Functions
TESTING NULL LISTP QUOTE NUMBERP ATOMP
t{ nil  null  -> TRUE  }t
t{ x    null  -> FALSE }t
t{ x    listp -> TRUE  }t
t{ quote 3  listp   -> FALSE }t
t{ quote 3  atomp   -> TRUE  }t
t{ quote 3  numberp -> TRUE  }t
t{ quote a  numberp -> FALSE }t
t{ quote a  atomp   -> TRUE  }t
t{ z  car   listp   -> TRUE  }t
t{ x  car   listp   -> FALSE }t

COMMENT Equality Operators
TESTING EQ EQUAL
t{ x x  eq -> TRUE  }t
t{ x y  eq -> FALSE }t
t{ '( a b c )  x  eq -> FALSE }t
t{ '( a b c )  x  equal -> TRUE }t
t{ quote a  x car  eq -> TRUE }t

COMMENT List Element Location
TESTING MEMBER NTH POSITION
t{ quote 2 y  member  -> '( 2 3 ) l}t
t{ 2 x  nth   -> quote c l}t
t{ quote c x  position ->  2 }t
t{ quote d x  position -> -1 }t

COMMENT List Element Removal, Deletion, Substitution
TESTING REMOVE SUBSTITUTE MAPCAR DELETE
t{ quote 2 y  remove  -> '( 1 3 ) l}t
t{ y  -> '( 1 2 3 ) l}t
t{ quote 4 quote 2 y substitute -> '( 1 4 3 ) l}t

: negate-number ( ^val1 -- ^val2 )
    dup numberp if car negate 0 cons then ;

t{ y ' negate-number mapcar  -> '( -1 -4 -3 ) l}t
t{ quote 4 y  delete  -> '( 1 3 ) l}t
t{ y  -> '( 1 3 ) l}t

COMMENT Construction of Lists from other Lists
TESTING LIST APPEND NCONC 
nil  ptr  r
nil  ptr  s 
t{ '( a b c d e )  to  r -> }t
t{ '( f g h )  to  s -> }t
t{ r s  cons   -> '( ( a b c d e ) f g h )     l}t
t{ r s  list   -> '( ( a b c d e ) ( f g h ) ) l}t 
t{ r s  append -> '( a b c d e f g h )         l}t
t{ r           -> '( a b c d e )               l}t
t{ r s  nconc  -> '( a b c d e f g h )         l}t
t{ r           -> '( a b c d e f g h )         l}t
t{ s           -> '( f g h )                   l}t


TESTING MEMBER:TEST
t{ '( ( a b ) c )  to  r -> }t
t{ '( a b )  to  s -> }t
t{ s  r  member  -> nil l}t
t{ s  r  ' equal  member:test  -> '( ( a b ) c ) l}t
t{ s  r  reverse  ' equal member:test -> '( ( a b ) ) l}t
t{ r  -> '( ( a b ) c ) l}t
t{ r  reverse  to  r -> }t
t{ r  ->	'( c ( a b ) ) l}t


COMMENT Set Operations
TESTING INTERSECTION UNION SET-DIFFERENCE SUBSETP ADJOIN
t{ '( a b c d ) to r -> }t
t{ '( c d e )   to s -> }t
t{ r s  intersection	-> '( d c ) l}t
t{ r s  union		-> '( e a b c d ) l}t
t{ r s  set-difference	-> '( b a ) l}t
t{ s r  subsetp		-> FALSE }t
t{ quote b s  adjoin	-> '( b c d e ) l}t
t{ quote c s  adjoin	-> '( c d e ) l}t


COMMENT Lists that span multiple lines	 

nil ptr fruits

t{ '( apple pear banana grape kiwi papaya mango tomato 
   orange grapefruit tangerine watermelon cantaloupe )  to fruits  -> }t

nil ptr vegetables

t{ '( potato corn onion carrot bean pea )  to vegetables -> }t

nil ptr produce

t{ fruits vegetables union to produce -> }t
produce print


cr .stat

