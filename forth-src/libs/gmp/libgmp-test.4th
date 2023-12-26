\ libgmp-test.4th
\
\ Test loading the gmp library under kForth, and execute a
\ subset of tests from David N. Williams' gmplib-test.fs
\ on the interface words
\
\ Based on gmplib-test.fs, ver. 0.6.0, written by 
\ David N. Williams.
\
\ Notes:
\
\   1. The word Z"  compiles a null-terminated string. It is defined in
\        lib-interface.4th.
\
\   2. The word, strlen, returns the count of a null-terminated string.
\        It is defined in strings.4th.

include ans-words
include modules.fs
include syscalls
include mc
include asm
include strings
include lib-interface
include libs/gmp/libgmp
include ttester

true VERBOSE !

DECIMAL

-1 constant MAXU

\ *** FOR TESTING

CREATE mzbuf 1024 allot   \ string buffer
CREATE b     /MPZ allot   \ usually for results
t{ b mpz_init -> }t

: mpz= ( a1 a2 -- flag )  mpz_cmp 0= ;
: mpz_n= ( a n -- flag )  b swap mpz_set_si  b mpz= ;
: mpz_u= ( a u -- flag )  b swap mpz_set_ui  b mpz= ;
: $=   ( a1 u1 a2 u2 -- flag) compare 0= ;

\ multiprecision integer to strings
: mpz>$ ( a1 n -- a u | use base n) 
    mzbuf swap rot mpz_get_str dup strlen ;

: mpz>dec$  ( a1 -- a u ) 10 mpz>$ ;

\ print a big integer in current base
: mpz. ( a1 -- ) base @ mpz>$ type ;

\ *** 1 Integers

\ *** 1.1 Initialization

TESTING  mpz_init mpz_clear

CREATE b1 /MPZ allot 
CREATE b2 /MPZ allot
create b3 /MPZ allot
t{ b1 mpz_init ->  }t
t{ b2 mpz_init ->  }t
t{ b3 mpz_init ->  }t


\ *** 1.2 Assignment

TESTING  mpz_set  mpz_set_ui  mpz_set_si

t{ b1 1 mpz_set_si ->  }t
t{ b2 2 mpz_set_si ->  }t
t{ b1 1 mpz_n=     ->  true  }t
t{ b1 2 mpz_n=     ->  false }t
t{ b2 1 mpz_n=     ->  false }t
t{ b2 2 mpz_n=     ->  true  }t

t{ b1 b2  mpz_set  ->  }t
t{ b1 b2  mpz=     -> true }t
t{ b1 MAXU mpz_set_ui ->  }t
t{ b1 MAXU mpz_u=  -> true }t

\ *** 1.3 Combined Initialization and Assignment

TESTING  mpz_init_set  mpz_init_set_ui  mpz_init_set_si

t{ b1 mpz_clear ->  }t
t{ b1 b2 mpz_init_set  ->  }t
t{ b1 b2 mpz=  ->  true  }t 
t{ b1 mpz_clear  -> }t
t{ b1 MAXU mpz_init_set_ui ->  }t
t{ b1 MAXU mpz_u= -> true }t 
t{ b1 mpz_clear -> }t
t{ b1 -11 mpz_init_set_si  ->  }t
t{ b1 -11 mpz_n= -> true }t

\ *** 1.4 Conversion

TESTING  mpz_set_str  mpz_get_str  mpz_get_d

t{ b3 z" 1024" BASE @ mpz_set_str ->  0 }t
t{ PAD 16 blank  ->  }t
t{ PAD BASE @ b3 mpz_get_str -> PAD  }t
t{ s" 1024" PAD over $=      -> true }t

t{ b3 mpz_get_d -> 1024e r}t

\ *** 1.5 Arithmetic

TESTING  mpz_add mpz_add_ui mpz_sub mpz_sub_ui mpz_ui_sub

t{ b1 1 mpz_set_si  ->  }t
t{ b2 2 mpz_set_si  ->  }t

t{ b3 b1 b2  mpz_add    ->   }t      \ b3 = b1 + b2
t{ b3 3      mpz_n=     ->  true }t
t{ b3 b1 b3  mpz_add    ->   }t      \ b3 = b1 + b3
t{ b3 4      mpz_n=     ->  true }t
t{ b3 b1 15  mpz_add_ui ->   }t      \ b3 = b1 + 15
t{ b3 16     mpz_n=     ->  true }t
t{ b3 b1 b2  mpz_sub    ->   }t      \ b3 = b1 - b2
t{ b3 -1     mpz_n=     ->  true }t
t{ b3 b1 15  mpz_sub_ui ->   }t      \ b3 = b1 - 15
t{ b3 -14    mpz_n=     ->  true }t
t{ b3 15  b1 mpz_ui_sub ->   }t      \ b3 = 15 - b1
t{ b3 14     mpz_n=     ->  true }t

t{ b3        z" 123456789123456789123456789" 10 mpz_set_str -> 0 }t
t{ b3 b3 1   mpz_add_ui ->  }t       \ b3 = b3 + 1
t{ b3 mpz>dec$ s" 123456789123456789123456790" $= -> true }t
t{ b3 b3 b3  mpz_add    ->  }t
t{ b3 mpz>dec$ s" 246913578246913578246913580" $= -> true }t

TESTING  mpz_mul  mpz_mul_si  mpz_mul_ui

t{ b3 b2 b2  mpz_mul    -> }t        \ b3 = b2 * b2
t{ b3 4      mpz_n=     ->  true }t
t{ b3 b2 -1  mpz_mul_si -> }t        \ b3 = b2 * -1
t{ b3 -2     mpz_n=     ->  true  }t
t{ b3  2     mpz_n=     ->  false }t

TESTING  mpz_addmul mpz_addmul_ui mpz_submul mpz_submul_ui mpz_mul_2exp

t{ b3 15    mpz_set_si    -> }t      \ b3 = 15
t{ b3 15    mpz_n=        -> true }t
t{ b3 b1 b2 mpz_addmul    -> }t      \ b3 = b3*b1 + b2
t{ b3 17    mpz_n=        -> true }t
t{ b3 b2 13 mpz_addmul_ui -> }t      \ b3 = b3*b2 + 13 
t{ b3 43    mpz_n=        -> true }t
t{ b3 b2 b1 mpz_submul    -> }t      \ b3 = b3 - b2*b1 
t{ b3 41    mpz_n=        -> true }t
t{ b3 b2 3  mpz_submul_ui -> }t      \ b3 = b3 - b2*3
t{ b3 35    mpz_n=        -> true }t
t{ b3 b2 5  mpz_mul_2exp  -> }t      \ b3 = b2 * 2^5 
t{ b3 64    mpz_n=        -> true }t

TESTING  mpz_neg  mpz_abs

t{ b3 b1  mpz_neg  ->  }t         \ b3 = -b1
t{ b3 -1  mpz_n=   ->  true }t
t{ b3 b3  mpz_abs  ->  }t         \ b3 = abs(b3)
t{ b3 b1  mpz=     ->  true }t


