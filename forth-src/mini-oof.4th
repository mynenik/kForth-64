\ mini-oof.4th
\
\ Bernd Paysan's simple object-oriented extensions to ANS Forth, 
\ adapted to kForth. See: http://www.jwdt.com/~paysan/mini-oof.html
\
\ For example of usage, see mini-oof-demo.4th
\
\ Revisions:
\
\   1998-10-24    original code by B. Paysan
\   2003-02-15    adapted for kForth by K. Myneni
\   2003-02-27 km changed definition of new to leave object address on stack
\   2011-03-03 km removed requirement on strings.4th and ans-words.4th 
\                   for kForth 1.5.x

: method ( m v -- m' v) 
	create over 1 cells ?allot ! swap cell+ swap
	does>  ( ... o -- ... ) @ over a@ + a@ execute ;

: var ( m v size -- m v')
	create over 1 cells ?allot ! +
	does>  ( o -- addr) a@ + ;

create object 2 cells ?allot 1 cells over ! cell+ 2 cells swap !

: class ( class -- class methods vars )  dup 2@ ;

: undefined-method
	true abort" undefined class method called" ;

: end-class ( class methods vars --  | create the vtable )
	over create ?allot dup >r 2dup ! nip cell+ 2dup ! cell+
	swap 2 cells ?DO ['] undefined-method over ! cell+ 1 cells +LOOP
	drop cell+ dup cell+ r> rot @ 2 cells /string move ;


: defines ( xt class -- | define a method for a class ) ' >body @ + ! ;

\ The definitions of 'new' and '::' are different from the ones in 
\   Paysan's original mini-oof. This version of 'new' CREATEs as well as 
\   ALLOTs (since allot must always be used jointly with create in kForth).
\   This version of '::' only returns the execution token of the
\   specified class' method name. See demo code for usage.

: new ( class -- o | create object and leave its address on stack)
       create dup @ ?allot dup >r ! r> ;

: :: ( class "method" -- xt ) ' >body @ + a@ ;



