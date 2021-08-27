\ mini-oof.4th
\
\ Bernd Paysan's simple object-oriented extensions to ANS Forth, 
\ adapted to kForth. For example of usage, see mini-oof-demo.4th
\
\ Glossary:
\
\   METHOD  ( m v "name" -- m' v )
\     Define a selector.
\
\   VAR ( m v size "name" -- m v' )  
\     Define a variable with size bytes.
\
\   CLASS ( class -- class selectors vars ) 
\     Start definition of a class.
\
\   END-CLASS ( class selectors vars "name" -- ) 
\     End definition of a class.
\
\   DEFINES  ( xt class "name" -- ) 
\     Bind xt to selector "name" in class.
\
\   NEW  ( class -- o )  
\     Create an object of the class.
\
\   ::  ( class "name" -- )
\     Compile the method for the selector "name" of the 
\      class (not immediate!).
\
\   OBJECT ( -- a-addr )  
\     The base class of all objects.
\
\ References:
\   1. Gforth package and docs: 
\        https://github.com/forthy42/gforth
\
\   2. B. Paysan, Detailed Description of Mini-OOF,
\        https://bernd-paysan.de/mini-oof.html
\
\ Revisions:
\   1998-10-24    original code by B. Paysan
\   2003-02-15 km adapted for kForth
\   2003-02-27 km changed defn of new to leave object address on stack
\   2011-03-03 km removed requirement on strings.4th and ans-words.4th 
\                   for kForth 1.5.x
\   2021-08-27 km revise defns of NEW and :: for full compatibility
\                   with mini-oof.fs from current Gforth package.

: method ( m v -- m' v) 
    create over 1 cells allot? ! swap cell+ swap
    does>  ( ... o -- ... ) @ over a@ + a@ execute ;
: var ( m v size -- m v')
    create over 1 cells allot? ! +  
    does>  ( o -- addr) a@ + ;
: class ( class -- class methods vars )  dup 2@ ;

: cm_undefined true abort" undefined class method called" ;

: end-class ( class methods vars --  | create the vtable )
    over create allot? dup >r 2dup ! nip cell+ 2dup ! cell+
    swap 2 cells ?DO 
      ['] cm_undefined over ! cell+
    1 cells +LOOP drop
    cell+ dup cell+ r> rot @ 2 cells /string move ;

: >vt  ( class "name" -- addr ) ' >body @ + ;
: bind ( class "name -- xt )     >vt a@ ;
: defines ( xt class "name" -- ) >vt ! ;  \ define a method for a class
: new ( class -- o ) dup @ allocate abort" ALLOCATE failure!" swap over ! ;
: :: ( class "name" -- xt ) bind compile, ;

create object 2 cells allot? 1 cells over ! cell+ 2 cells swap !


