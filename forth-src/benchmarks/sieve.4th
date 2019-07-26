\ sieve.4th
\
\ Forth benchmark
\
\ To time the benchmark, type
\
\	time&date main time&date .s
\
: secs time&date  swap 60 * + swap 3600 * +  nip nip nip ;

create flags 8190 allot
variable eflag

: primes  ( -- n )  
  flags 8190 1 fill  
  0 3 eflag a@ flags
  do   
    i c@
    if
      i over + 
      dup eflag a@ <
      if
        eflag a@ swap
        do 0 i c! dup +loop
      else
        drop  
      then
      swap 1+ swap
    then  
    2+
  loop
  drop ;

: benchmark  
	0 1000 0 do  primes nip loop ;


: main 
	flags 8190 + eflag !
	benchmark .
;

\ HPPA/720, 50 MHz: user 3.90s



