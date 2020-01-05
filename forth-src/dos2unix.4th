\ dos2unix.4th
\
\ Convert DOS text file into a Unix text file.
\
\ Copyright (c) 2000--2005 Krishna Myneni
\
\ This software is provided under the GNU General Public
\   License.
\
\ Required files:
\	strings.4th
\	files(w).4th
\
\ Usage:
\	dos2unix	-- user is prompted to enter input and output names
\	d2u filename	-- output file will be named filename.u
\
\ Revisions:
\
\	12-21-2000  fixed null line problem  KM
\       09-28-2005  updated line-by-line due to fix for read-line in files.4th  KM
\
include strings
include files

create ifname 256 allot
create ofname 256 allot

variable if_id
variable of_id

create lbuf 256 allot

: open-dos-unix-files ( -- | open the input and output files )
	ifname count R/O open-file
	if
	  cr ." Error opening input file: " 
	  ifname count type cr
	  abort
	then
	if_id !

	ofname count R/W create-file
	if
	  cr ." Error opening output file: " 
	  ofname count type cr
	  if_id @ close-file 
	  abort
	then
	of_id ! ;

: line-by-line ( -- | copy from input file to output file, line by line )
	begin
	  lbuf 256 if_id @ read-line  ( -- u flag ior ) 
	  IF
	    \ Error reading input file
	    if_id @ close-file drop
	    of_id @ close-file drop
	    cr ." Error reading input file" ABORT
	  ELSE
	    false = IF
	      \ Reached end of input file
	      drop
	      if_id @ close-file drop
	      of_id @ close-file drop
	      exit
	    THEN
	  THEN
	  lbuf swap 1- 0 max 
	  of_id @ write-line drop
	again ;
 
: dos2unix ( -- )
	." Enter DOS text file name: "
	ifname 1+ 255 accept ifname c! 
	." Enter UNIX text file name: "
	ofname 1+ 255 accept ofname c!
	open-dos-unix-files	
	line-by-line ;

: d2u ( -- | same as dos2unix but takes input filename from input stream )
	bl word ifname strcpy
	ifname count s" .u" strcat strpck
	ofname strcpy
	open-dos-unix-files
	line-by-line ;

