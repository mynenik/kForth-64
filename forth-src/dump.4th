\ dump.4th
\
\ Memory Dump Utility
\
\ Copyright (c) 1999 Krishna Myneni
\ Creative Consulting for Research and Education
\
\ This software is provided under the terms of the GNU
\ General Public License.
\
\ Last Revised: 2019-08-03
\

BASE @
DECIMAL

create dump_display_buf 20 allot

: hexchar ( n -- m | return ascii hex char value for n: 0 - 15 )
	dup 9 > IF  10 - [char] A  ELSE [char] 0  THEN + ;

: dump_display_char ( n -- n|'.' )
	dup [char] ! < over [char] ~ > or IF drop [char] . THEN ;

: .address ( a -- ) base @ swap hex u. base ! ;

: dump ( a n -- | display n bytes starting at a )
	dup 0> IF
	  0 DO
	    I 16 mod 0= 
	    IF 
	      cr dup .address bl emit [char] : emit 2 spaces 
	    THEN
	    dup c@ 16 /mod 
	    hexchar emit hexchar emit
	    2 spaces
	    dup c@ dump_display_char
	    dump_display_buf i 16 mod + c!
	    i 16 mod 15 =
	    IF dump_display_buf 16 type THEN
	    1+
	  LOOP
	  drop
	ELSE
	  2drop
	THEN ;

BASE !
