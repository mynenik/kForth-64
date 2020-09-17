\ files.4th
\
\ This code provides kForth with most of the Forth standard 
\ File Access wordset (Forth-94 / Forth-2012)
\
\ kForth provides the built-in low level file access words:
\
\   OPEN  LSEEK  CLOSE  READ  WRITE  FSYNC
\
\ The definitions below provide standard and non-standard Forth
\ file i/o words and constants.
\
\ Glossary:
\
\   CREATE-FILE  ( c-addr u fam -- fd ior )
\   OPEN-FILE    ( c-addr u fam -- fd ior )
\   CLOSE-FILE   ( fd -- ior )
\   READ-FILE    ( c-addr u1 fd -- u2 ior )
\   WRITE-FILE   ( c-addr u fd -- ior )
\   FILE-POSITION    ( fd -- ud ior )
\   REPOSITION-FILE  ( ud fd -- ior )
\   FILE-SIZE    ( fd -- ud ior )
\   FILE-EXISTS  ( ^filename -- flag )
\   DELETE-FILE  ( c-addr u -- ior )
\   RENAME-FILE  ( c-addr1 u1 c-addr2 u2 -- ior ) -- see restrictions
\   READ-LINE    ( c-addr u1 fd -- u2 flag ior )
\   WRITE-LINE   ( c-addr u fd -- ior )
\   FLUSH-FILE   ( fd -- ior )
\
\ Copyright (c) 1999--2020 Krishna Myneni
\
\ This software is provided under the terms of the GNU General
\ Public License.
\
\ Requires:
\
\  strings.4th
\

base @
hex
  0 constant R/O  \ Forth-94/2012 11.6.1.2054
  1 constant W/O  \ Forth-94/2012 11.6.1.2425
  2 constant R/W  \ Forth-94/2012 11.6.1.2056

  A constant EOL

 40 constant O_CREAT
 80 constant O_EXCL
200 constant O_TRUNC
400 constant O_APPEND
  0 constant O_BINARY

  0 constant SEEK_SET
  1 constant SEEK_CUR
  2 constant SEEK_END
base !
create EOL_BUF 4 allot
EOL EOL_BUF c!
0 EOL_BUF 1+ c!

\ BIN ( fam1 -- fam2 )
\ Modify file access method to select binary access mode
\ Forth-94/2012 File Access word set 11.6.1.2054
: BIN O_BINARY or ;

variable read_count

\ CREATE-FILE  ( c-addr u fam -- fileid ior )
\ Create a file with the specified name.
\ Forth-94/2012 File Access word set 11.6.1.1010
: create-file
	>r strpck r> O_CREAT or open
	dup 0> invert ;

\ OPEN-FILE  ( c-addr u fam -- fileid ior )
\ Open the file with the specified name and access method.
\ Forth-94/2012 File Access word set 11.6.1.1970
: open-file
	>r strpck r> open
	dup 0> invert ;

\ CLOSE-FILE ( fileid -- ior )
\ Close the file identified by fileid.
\ Forth-94/2012 File Access word set 11.6.1.0900
: close-file  close ;

\ READ-FILE ( c-addr u1 fileid -- u2 ior )
\ Read u1 characters from specified file into buffer at c-addr.
\ Forth-94/2012 File Access word set 11.6.1.2080
: read-file  -rot read dup -1 = ;

\ WRITE-FILE ( c-addr u fileid -- ior )
\ Write u characters to file from buffer at c-addr.
\ Forth-94/2012 File Access word set 11.6.1.2480
: write-file  -rot write 0< ;

\ FILE-POSITION ( fileid -- ud ior )
\ Return the current file position, ud, for the specified file.
\ Forth-94/2012 File Access word set 11.6.1.1520
: file-position
	0 SEEK_CUR lseek dup -1 = >r s>d r> ;

\ REPOSITION-FILE ( ud fileid -- ior )
\ Change the current file position to ud for the specified file.
\ Forth-94/2012 File Access word set 11.6.1.2142
: reposition-file
	-rot drop SEEK_SET lseek 0< ;

\ FILE-SIZE ( fileid -- ud ior )
\ Return the size in pchars, ud, for the specified file.
\ Forth-94/2012 File Access word set 11.6.1.1522
: file-size
	dup >r r@ file-position drop 2>r  
	0 SEEK_END lseek dup -1 = >r s>d r>
	2r> r> reposition-file drop ;

\ FILE-EXISTS ( ^filename -- flag )
\ Return true if the named file in counted string exists.
\ Non-standard word.
: file-exists
	count R/O open-file
	if drop false else close-file drop true then ;	

\ DELETE-FILE ( c-addr u -- ior )
\ Delete the file named by c-addr, u
\ Forth-94/2012 File Access words 11.6.1.1190
: delete-file
        s" rm " 2swap strcat strpck system ; 

\ RENAME-FILE ( c-addr1 u1 c-addr2 u2 -- ior )
\ Rename the file named c-addr,u1 to name given by c-addr2,u2
\ Forth-94/2012 File Access Ext word set 11.6.2.2130
\
\ RENAME-FILE has a limit for the sum of the two filenames
\ to be less than 250 pchars because of limitations in the 
\ argument to SYSTEM.
: rename-file
    2>r 2>r s" mv " 2r> strcat s"  " strcat 2r> strcat 
    strpck system ;

\ READ-LINE ( c-addr u1 fileid -- u2 flag ior )
\ Read the next line from the file into memory at c-addr
\ Forth-94/2012 File Access word set 11.6.1.2090
: read-line
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

\ WRITE-LINE ( c-addr u fileid -- ior )
\ Write u characters from c-addr followed by a line terminator
\ Forth-94/2012 File Access wordset 11.6.1.2485
: write-line
	dup >r write-file
	EOL_BUF 1 r> write-file
	or ;

\ FLUSH-FILE ( fileid -- ior )
\ Force any buffered information written to file to be stored on disk.
\ Forth-94/2012 File Access word set 11.6.2.1560
: flush-file fsync ;

