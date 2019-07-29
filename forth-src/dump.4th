\ dump.4th
\
\ memory dump utility
\
\ Copyright (c) 1999 Krishna Myneni
\ Creative Consulting for Research and Education
\
\ This software is provided under the terms of the GNU
\ General Public License.
\
\ Last Revised: 4-25-1999
\

create dump_display_buf 20 allot

: hexchar ( n -- m | return ascii hex char value for n: 0 - 15 )
	dup 9 > if 10 - 65 + else 48 + then ;

: dump_display_char ( n -- n|46 )
	dup 33 < over 126 > or if drop 46 then ;

: dump ( a n -- | display n bytes starting at a )
	dup 0> if
	  0 do
	    i 16 mod 0= 
	    if 
	      cr dup . 58 emit 2 spaces 
	    then
	    dup c@ 16 /mod 
	    hexchar emit hexchar emit
	    2 spaces
	    dup c@ dump_display_char
	    dump_display_buf i 16 mod + c!
	    i 16 mod 15 =
	    if dump_display_buf 16 type then
	    1+
	  loop
	  drop
	else
	  2drop
	then ;
 
