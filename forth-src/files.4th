\ files.4th
\
\ This code provides kForth with a subset of the optional 
\ file access word set, following the guidelines of the ANS 
\ specifications.
\
\ Note that kForth (as of Rls. 3-2-1999) has the built-in
\ low level file access words OPEN, LSEEK, CLOSE, READ, WRITE.
\ The definitions herein provide some of the ANS compatible
\ word set and useful constants.
\
\ Copyright (c) 1999--2010 Krishna Myneni
\ Creative Consulting for Research and Education
\
\ This software is provided under the terms of the GNU General
\ Public License.
\
\ Requires:
\
\	strings.4th
\
\ Revisions:
\
\ 	3-2-1999  created
\	3-6-1999 
\	4-25-1999 added read-line KM
\	10-15-1999 added file-exists KM
\	12-20-1999 fixed create-file and open-file; now
\	           requires strings.4th  KM
\	9-18-2001 fixed problem with constants O_CREAT and O_APPEND  KM
\       4-07-2002 fixed defn of reposition-file; added file-position
\		    and file-size  KM
\	8-13-2002 fixed defn of file-size to not modify file-position  KM
\	8-30-2002 added delete-file  KM
\	9-19-2002 fixed read-line to return success for file with
\	            single line, even if line has no EOL  KM
\       9-26-2003 added the ANS word INCLUDED  km
\       9-28-2005 fixed non-standard behavior of READ-LINE for end-of-file
\                   condition; ior previously was non-zero for EOF condition. KM
\       3-15-2008 removed the definition of INCLUDED, which is now intrinsic  KM 
\       4-22-2010 changed return values for WRITE-FILE  REPOSITION-FILE 
\                   for ANS-Forth compatibility; note that change to
\                   WRITE-FILE will affect WRITE-LINE; fixed a problem
\                   with READ-LINE which didn't handle last line correctly
\                   if there was no EOL at the end of the file.   km
 
base @
hex
  0 constant R/O
  1 constant W/O
  2 constant R/W
  A constant EOL
 40 constant O_CREAT
 80 constant O_EXCL
200 constant O_TRUNC
400 constant O_APPEND
  0 constant SEEK_SET
  1 constant SEEK_CUR
  2 constant SEEK_END
base !
create EOL_BUF 4 allot
EOL EOL_BUF c!
0 EOL_BUF 1+ c!

variable read_count

: create-file ( c-addr count fam -- fileid ior )
	>r strpck r> O_CREAT or open
	dup 0> invert ;

: open-file ( c-addr count fam -- fileid ior )
	>r strpck r> open
	dup 0> invert ;

: close-file ( fileid -- ior )
	close ;

: read-file ( c-addr u1 fileid -- u2 ior )
	-rot read dup -1 = ;
 	 
: write-file ( c-addr u fileid -- ior )
	-rot write 0< ;

: file-position ( fileid -- ud ior )
	0 SEEK_CUR lseek dup -1 = >r s>d r> ;

: reposition-file ( ud fileid -- ior )
	-rot drop SEEK_SET lseek 0< ;

: file-size ( fileid -- ud ior )
	dup >r r@ file-position drop 2>r  
	0 SEEK_END lseek dup -1 = >r s>d r>
	2r> r> reposition-file drop ;

: file-exists ( ^filename  -- flag | return true if file exists )
	count R/O open-file
	if drop false else close-file drop true then ;	

: delete-file ( c-addr count -- ior )
        s" rm " 2swap strcat strpck system ; 

: read-line ( c-addr u1 fileid -- u2 flag ior )
	-rot 0 read_count !
	0 ?do
	  2dup 1 read
	  dup 0< IF  >r 2drop read_count @ false r> unloop exit THEN
	  0= IF    \ reached EOF
	    read_count @ 0= IF 2drop 0 false 0 unloop exit 
			    ELSE leave THEN 
          THEN
	  dup c@ EOL = IF 2drop read_count @ true 0 unloop exit THEN
	  1+
	  1 read_count +!
	loop
	2drop read_count @ true 0 ;

: write-line ( c-addr u fileid -- ior )
	dup >r write-file
	EOL_BUF 1 r> write-file
	or ;

