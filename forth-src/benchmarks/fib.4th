\ fib.4th
\
\ Forth benchmark
\
\ To time the execution, type
\
\	ms@ 34 fib drop ms@ swap - .
\

: fib ( n1 -- n2 )
    dup 2 < if
	drop 1
    else
	dup
	1- recurse
	swap 2 - recurse
	+
    then ;

: main 34 fib . ;
