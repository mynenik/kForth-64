\ mini-oof-demo.4th
\
\ Bernd Paysan's example code, with extra annotations,
\ to illustrate use of the mini-oof.4th object-oriented
\ extensions for standard Forth.
\
\ See:
\   1. Gforth package and docs; https://github.com/forthy42/gforth
\   2. https://bernd-paysan.de/mini-oof.html
\
\ This example shows how to define a class, create objects,
\   create a derived class, override inherited class methods,
\   and use objects.
\
\ Revisions:
\
\   1998-10-24      original code by B. Paysan
\   2003-02-15      adapted for kForth by K. Myneni
\   2003-02-27  km  use of new changed in mini-oof.4th
\   2011-03-03  km  removed include of ans-words.4th, not needed
\                     for kforth 1.5.x.
\   2021-08-27  km  revised for full compatibility with B.P.'s
\                     moof-exm.fs (see Ref. 1).

include ans-words
include mini-oof
include strings
include ansi

[undefined] cell [IF]  1 cells constant cell  [THEN]

\ Define a button class

object class
       cell var text
       cell var len
       cell var x
       cell var y
       method init
       method draw
end-class button

\ Define the methods of the button class

:noname ( o -- )  >r 
  r@ x @ r@ y @ at-xy r@ text a@ r> len @ type ;
button defines draw

:noname ( addr u o -- ) >r 
  0 r@ x ! 0 r@ y ! r@ len ! r> text ! ;
button defines init

\ Now that we have defined the class and the methods, we may
\   create an object of the button class and perform some 
\   initialization.

button new constant foo   \ create object 'foo' of class 'button'
s" thin foo" foo init	  \ call method 'init' for foo		  
25 foo x !  6 foo y !	  \ set the x and y coordinates of foo


\ Next, we define a new class called 'bold-button' which is 
\   derived from the class 'button'. Therefore, it inherits
\   all of the variables and methods from the button class. 
\   We will override the method 'draw' in the derived class.

button class
end-class bold-button	\  No new variables or methods in derived class

: bold	  text_bold ; 
: normal  text_normal ;

:noname  bold  [ button :: draw ] normal ;
bold-button defines draw  \ override method 'draw'

bold-button new constant bar \ create object 'bar' of class 'bold-button'
s" fat bar" bar init
28 bar x !  7 bar y !

\ Now we put our objects into action!

page
foo draw
bar draw

