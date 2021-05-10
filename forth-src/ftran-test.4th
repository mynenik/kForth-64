\ Test ftran202
\
\ K. Myneni, Creative Consulting for Research and Education
\ 
\ Revisions:
\   2010-06-03  km
\   2010-08-06  km  added test for "-x^2" to check consistency with Fortran

include ans-words
include strings
include fsl/complex           \ complex arithmetic package
include fsm2                  \ finite state machine
include chr_tbl               \ character encoding pkg

include ftran202
include lists
include ttester

\ Hayes' style notation for testing equality of list results

: }list  ( ... -- | Compare the stack [expected] contents with the saved [actual] contents)  
  depth actual-depth @  = IF        \ if depths match
    depth ?dup IF                   \ if there is something on the stack
      0 DO                          \ for each stack item
        actual-results i CELLS + a@      \ compare actual with expected
        equal NOT IF S" INCORRECT RESULT: " ERROR LEAVE THEN
      LOOP
    THEN 
  ELSE                                  \ depth mismatch
    s" WRONG NUMBER OF RESULTS: " ERROR 
  THEN
;

: fl" ( <string> -- list ) (f") make-token-list ;
 

CR
TESTING (f")
t{  fl" -x"         ->  '( x F@  FNEGATE )    }list
t{  fl" x+y"        ->  '( x F@  y  F@  F+ )  }list
t{  fl" x^2+y^2"    ->  '( x F@ f^2  y F@ f^2  F+ )  }list
t{  fl" a*(b+x)-w"  ->  '( a F@ b F@ x F@ F+ F* w F@ F- )  }list
t{  fl" a=b*c-d/tanh(w)+abs(x)"  ->  
       '( b F@ c F@ F* d F@ w F@ FTANH F/ F- x F@ FABS F+ a F! )  }list
t{  fl" atan2(x,y)" ->  '( x F@ y F@ FATAN2 )  }list


fvariable x
fvariable y
3e x f!
4e y f!


TESTING f$"
t{ f$" -x"   ->  -3e   r}t
t{ f$" 1+x"  ->   4e   r}t
t{ f$" 1-x"  ->  -2e   r}t
t{ f$" 1/y"  ->   0.25e  r}t
t{ f$" x^2"  ->   9e   r}t
t{ f$" -x^2" ->  -9e   r}t
t{ f$" x+y"  ->   7e   r}t
t{ f$" x-y"  ->  -1e   r}t
t{ f$" x*y"  ->  12e   r}t
t{ f$" x/y"  ->   0.75e r}t
t{ f$" x^y"  ->   81e  r}t

t{ f$" x^2+y"        ->  13e  r}t
t{ f$" x+y^2"        ->  19e  r}t
t{ f$" (x+y)^2"      ->  49e  r}t
t{ f$" x*(x+y)"      ->  21e  r}t
t{ f$" x^2*(x+y)"    ->  63e  r}t
t{ f$" x*(x^2+y)"    ->  39e  r}t
t{ f$" x*(x+y^2)"    ->  57e  r}t
t{ f$" x*(x^2+y^2)"  ->  75e  r}t



