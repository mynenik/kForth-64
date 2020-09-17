\ notes.4th
\
\ Simple electronic note-keeping system
\
\ Copyright (c) 2001--2020 Krishna Myneni
\ Provided under the GNU General Public License
\ 
\ Required files:
\
\       strings.x
\       struct.x   (intrinsic to Gforth)
\       struct-ext.x
\       user.x
\
\ Additional requirements for kForth:
\
\       ans-words.4th
\	files.4th
\	utils.4th
\	
\ Notes:
\
\ 1. Each notes database file can hold 2560 note records, and each
\      individual note record may be up to 64K in size.
\ 
\ 2. The structure of the notes database is:
\
\	index		1024 bytes
\	note records	Each record is variable length, but the length 
\			  is always a multiple of 64 bytes
\
\    The structure of a note record is:
\
\	date stamp	4 bytes
\	time stamp	4 bytes
\	user name	8 bytes
\	record length	4 bytes
\	checksum	4 bytes
\	pad area1	pad to 64 bytes
\	keywords list	64 bytes
\	title		64 bytes
\	pad area2	64 bytes
\	body		multiple of 64 bytes
\
\ 3. Compatible definitions for ANS Forth systems are provided below.
\      Set the value of "kForth" to FALSE when not using kForth. 
\      Methods of passing shell commands vary among Forth systems. 
\      The ANS Forth section defines "shell" for PFE, gforth and iForth. 
\      Uncomment the definition appropriate for your system. A shell 
\      command is used to find the name of the user entering a new note 
\      into the notes database in the word "!author". If this feature is 
\      not needed, disable it in the definition of !author.
\
\ 4. Change the default notes file name DEF-NOTES-FILE for your use.
\
\ 5. The notes database index has not been fully implemented.

decimal

true value kForth     \ set to true for kForth

1 CELLS 4 < [IF]
  cr .( ** SYSTEM MUST HAVE MINIMUM CELL SIZE OF 32-BITS ** ) cr
  ABORT
[THEN]

[undefined] LE-L@  [IF]
: BYTES  CHARS ;
: B!    ( x addr --    ) SWAP 255 AND SWAP C! ;
: B@    (   addr -- x  ) C@ 255 AND ;
: b@+ ( x1 addr1 -- x2 addr2 )  SWAP 8 LSHIFT OVER B@ + SWAP 1 BYTES + ;
: b@- ( x1 addr1 -- x2 addr2 )  1 BYTES - DUP B@ ROT 8 LSHIFT + SWAP ;
: b!+ ( x1 addr1 -- x2 addr2 )  2DUP B! 1 BYTES + SWAP 8 RSHIFT SWAP ;
: b!- ( x1 addr1 -- x2 addr2 )  1 BYTES - 2DUP B! SWAP 8 RSHIFT SWAP ;

: LE-L@ ( addr -- x )  0 SWAP 4 BYTES + b@- b@- b@- b@- DROP ;
: LE-L! ( x addr -- )  b!+ b!+ b!+ b!+  2DROP ;

[THEN]

kForth [IF]

[undefined] strpck  [IF] include strings.4th    [THEN]
[undefined] R/O     [IF] include files.4th      [THEN]
[undefined] shell   [IF] include utils.4th      [THEN]
[undefined] get-username [IF] include user.4th  [THEN]
[undefined] struct  [IF] include struct.4th     [THEN]
[undefined] int32:  [IF] include struct-ext.4th [THEN]

[ELSE]   \ ANS Forth

include strings.fs
\ include struct.fs
include struct-ext.fs

: a@         \ a1 -- a2  | fetch address stored at a1
	@ ;

: allot?     \ n -- a | allot n bytes, return start address
       here swap allot ;


: file-exists  \ ^filename  -- flag | return true if file exists
	count R/O open-file
	if drop false else close-file drop true then ;	

: pack ( a u a2 -- | copy string to counted string at a2)
    2dup c! 1+ swap cmove ;	

: $constant  ( a u <name> -- | create a string constant )
    create dup >r cell+ allot? dup r@ swap ! cell+ r> cmove  
    does> ( -- a' u ) dup @ swap cell+ swap ;  

\ pfe shell command
\ : shell  system ; \ c-addr u -- n | execute a shell command in PFE

\ gforth shell command
: shell  system  $? ; \ c-addr u -- n | execute a shell command in gforth

\ iforth shell command
\ : shell  system  RETURNCODE @ ;  \ c-addr u -- n | shell command in iForth


10 constant EOL

include user.fs

[THEN]


: u>d  ( u -- d ) 0 ;
: d>u  ( d -- u ) drop ;

: >upper ( a u -- a u )
        2DUP 0 ?DO DUP C@ DUP is_lc_alpha IF 95 AND THEN OVER C! 1+ LOOP DROP ;

	
s" /home/" get-username strcat s" /notes.db" strcat $constant  DEF-NOTES-FILE

s" ERROR: unable to create new notes file "  $constant  E-NEW-CREATE-MSG
s" ERROR: unable to open notes file "	     $constant  E-OPEN-MSG
s" ERROR: notes file already exists."        $constant  E-FILE-EXISTS-MSG
s" ERROR: unable to read the index." 	     $constant  E-READ-INDEX-MSG
s" ERROR: unable to write the index."        $constant  E-WRITE-INDEX-MSG
s" ERROR: unable to find first record."	     $constant  E-POS-MSG
s" ERROR: unable to read the record." 	     $constant  E-READ-MSG
s" ERROR: unable to write the note." 	     $constant  E-WRITE-MSG
s" ERROR: checksum does not match."          $constant  E-CHECKSUM-MSG

s" > "  $constant  NOTE-PROMPT
s" Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec" $constant MONTHS


	
1024 			constant  INDEX-SIZE

\ all int32 fields use little-endian storage
struct
    int32:  DATE-OFFSET
    int32:  TIME-OFFSET
    8 buf:  USER-OFFSET
    int32:  LENGTH-OFFSET
    int32:  CHECKSUM-OFFSET
    40 buf: PAD1-OFFSET
    64 buf: KEYWORDS-OFFSET
    64 buf: TITLE-OFFSET
    64 buf: PAD2-OFFSET
end-struct note-record-header%

note-record-header% %size  constant  HDRSIZE

create my-notes-file 256 allot
DEF-NOTES-FILE my-notes-file pack
variable my-notes-fd

: close-notes ( -- )  my-notes-fd @ close-file drop ;

: error-abort ( a u -- ) close-notes type abort ;

create notes-index 1024 allot

: clear-index ( -- )  notes-index INDEX-SIZE erase ;
clear-index

: read-index ( -- ior | return 0 if successful)
    notes-index INDEX-SIZE my-notes-fd @ read-file
    drop INDEX-SIZE <> ;

: write-index ( -- ior | return 0 if successful)
    notes-index INDEX-SIZE my-notes-fd @ write-file drop
    my-notes-fd @ file-position 2drop INDEX-SIZE <> ;

\ Return index which may contain a file offset in the index table
\ for a nearby note, and the number of additional notes to advance
: nearest-note-index ( n -- m index )  1- 10 /mod  ;

: notes-index[]  ( idx -- a ) 4 * notes-index + ;
    
\ Return nearest file offset and remaining number of notes to read 
\ to advance to the desired note
: nearest-offset ( n -- m u | u is the file offset )
	nearest-note-index  notes-index[]  LE-L@ ;

: set-notes-file-position ( ud -- ior | set the current file position)
    my-notes-fd @ reposition-file ;

: get-notes-file-position ( -- ud | return the current file position)
    my-notes-fd @ file-position drop ;

: position-at-first-note ( -- ior | set file position at first note)
    INDEX-SIZE u>d set-notes-file-position ;

: use-notes ( ^name -- | select note files from the input stream )
    count my-notes-file pack ;
   
: create-notes ( ^name -- | create a new notes file )
	use-notes
	my-notes-file c@ 0= if
	  cr ." ERROR: no file name specified."
	else
	  my-notes-file file-exists if
	    cr E-FILE-EXISTS-MSG type 
	  else
	    my-notes-file count R/W create-file
	    if 
	      cr E-NEW-CREATE-MSG type
	    else
	      my-notes-fd !  cr 
	      clear-index
	      write-index if  E-WRITE-INDEX-MSG error-abort  then
	      close-notes
	      ." Successfully created new notes file " 
	    then my-notes-file count type  cr
	  then 
	then ;

: open-notes ( n -- | open the notes file with access method given by n )
	\ n can be either R/O or R/W
	my-notes-file count rot open-file
	if drop E-OPEN-MSG type 
	  my-notes-file count type cr abort 
	then
	my-notes-fd !
;

: open-notes-append ( -- )
	my-notes-file count R/W open-file
	if drop E-OPEN-MSG type  
	  my-notes-file count type cr abort
	then
	my-notes-fd !
	read-index  if  E-READ-INDEX-MSG error-abort  then 
	my-notes-fd @ file-size drop 
	set-notes-file-position drop  \ position at EOF 
;


\ Time utilities

: dmy>s ( day month year -- n | pack day month year into single cell )
	9 lshift swap 5 lshift or or ;

: s>dmy ( n -- day month year | unpack date )
	dup dup 31 and swap 5 rshift 15 and rot 9 rshift ; 

: smh>s ( sec min hour -- n | pack secs minutes hours into single cell )
	12 lshift swap 6 lshift or or ;

: s>smh ( n -- sec min hour | unpack time )
	dup dup 63 and swap 6 rshift 63 and rot 12 rshift ;


create note-hdr note-record-header% %allot drop
64 1024 * constant MAXBODYSIZE
create note-body MAXBODYSIZE allot

: @date-stamp ( -- n ) note-hdr DATE-OFFSET LE-L@ ;
: @time-stamp ( -- n ) note-hdr TIME-OFFSET LE-L@ ;
: @record-length ( -- n ) note-hdr LENGTH-OFFSET LE-L@ ;
: @note-checksum ( -- n ) note-hdr CHECKSUM-OFFSET LE-L@ ;
: @body-length ( -- n ) @record-length HDRSIZE - ;
: !date-stamp ( -- ) time&date dmy>s note-hdr DATE-OFFSET LE-L! 2drop drop ;
: !time-stamp ( -- ) time&date 2drop drop smh>s note-hdr TIME-OFFSET LE-L! ;
: !record-length ( n -- ) note-hdr LENGTH-OFFSET LE-L! ;
: !note-checksum ( n -- ) note-hdr CHECKSUM-OFFSET LE-L! ;

: !title ( addr count -- )
	note-hdr TITLE-OFFSET 64 blank
	64 min note-hdr TITLE-OFFSET swap cmove ;

: !keywords ( addr count -- )
	>upper note-hdr KEYWORDS-OFFSET 64 blank
	64 min note-hdr KEYWORDS-OFFSET swap cmove ;

: !author ( -- )
	note-hdr USER-OFFSET dup 8 blank
	get-username 8 min rot swap cmove ;

	
: ?note-checksum ( -- n | compute the checksum for the body of the note )
	@body-length dup 0> swap MAXBODYSIZE <= and
	if
	  0 note-body
	  @body-length 0 do dup >r c@ + r> 1+ loop drop
	else
	  -1
	then ;   
	   
: read-note-hdr ( -- ior )
	note-hdr HDRSIZE my-notes-fd @ read-file
	swap HDRSIZE <> or ; 

: read-note-body ( -- ior )  \ assumes hdr has been read
	note-body @body-length my-notes-fd @ read-file
	swap @body-length <> or ; 

: read-next-note ( -- ior | read a note from the current position )
	read-note-hdr 0= if read-note-body else true then ;

: set-note-position ( n -- flag | set position in file for note n )
	\ origin is n=1; return 0 if successfull.
	dup nearest-offset
	dup 0= if
	  \ The offset is not available; we must search for the record
	  2drop 1-  
	  position-at-first-note drop
	else
	  \ Position at the nearest note for which we have an offset
	  u>d set-notes-file-position drop
	  nip
	then
	\ Read up to the desired record
	0 ?do read-next-note if unloop true exit then loop 
	false ;

: read-note ( n -- ior | read note n from the database )
	set-note-position 0= if read-next-note else true then ;

: write-note-hdr ( -- ior | ior = 0 if success )
	get-notes-file-position
	note-hdr HDRSIZE my-notes-fd @ write-file drop
	get-notes-file-position  d- dnegate 
	HDRSIZE u>d d= invert ;

: write-note-body ( -- ior | ior = 0 if success )
	get-notes-file-position
	note-body @body-length my-notes-fd @ write-file drop
	get-notes-file-position  d- dnegate
	@body-length u>d d= invert ;

: write-note ( -- ior )
	write-note-hdr 0= if write-note-body else true then ; 

: tab 9 emit ;

: display-count ( n -- )
	s>d <# # # # # #> type ;

: display-note-time-stamp ( -- )
	@date-stamp s>dmy 4 .r bl emit
	12 min 1- 2* 2* MONTHS drop + 3 type 
	bl emit 2 .r 2 spaces
	@time-stamp s>smh 
	s>d <# [char] : hold # # #> type
	s>d <# [char] : hold # # #> type
	s>d <# # # #> type  ;

: display-note-author ( -- )
	note-hdr USER-OFFSET 8 type ;

: display-note-title ( -- )
	note-hdr TITLE-OFFSET 64 -trailing type ;

: display-note-keywords ( -- )
	note-hdr KEYWORDS-OFFSET 64 -trailing type ;

: display-note-header ( -- ) 
	display-note-time-stamp 2 spaces 
	display-note-author 2 spaces
	display-note-title ;

: display-note-body ( -- )
	note-body @body-length type ;

variable note-counter

: list-notes ( n1 n2 -- | display headers for notes n1 through n2 )
	over 0< if nip 1 swap then
	R/O open-notes
	read-index  if  E-READ-INDEX-MSG error-abort  then
	swap dup note-counter !
	set-note-position if  drop E-POS-MSG error-abort  then
	cr
	begin
	  read-next-note dup
	  0= if
	    note-counter @ display-count [char] : emit 2 spaces
	    display-note-header cr
	    1 note-counter +!
	  then
	  over note-counter @ u< or
	until
	drop
	close-notes ;

: view-notes ( n1 n2 -- | view notes n1 through n2 )
	over 0< if 2drop exit then
	dup 0< if drop dup then 1+
	R/O open-notes
	read-index  if  E-READ-INDEX-MSG error-abort  then
	swap dup set-note-position  if  2drop E-POS-MSG error-abort  then
	cr
	?do
	  read-next-note
	  if
	    close-notes
	    ." Note " i . ." not found" cr
	    unloop exit
	  else
	    i display-count [char] : emit 2 spaces
	    display-note-header cr
	    display-note-body cr 
	    @note-checksum ?note-checksum <> if
	      E-CHECKSUM-MSG type then 
	  then
	loop
	close-notes ;

: .keys ( -- | list all keywords )
	R/O open-notes 
	position-at-first-note  if  E-POS-MSG error-abort  then
	begin read-next-note 0= 
	while
	  note-hdr KEYWORDS-OFFSET 64 -trailing dup 
	  if type cr else 2drop then
	repeat 
	close-notes ;

: search-notes ( ^keyword -- | search all notes for keyword )
    R/O open-notes
    position-at-first-note 
    if drop close-notes E-POS-MSG type exit  then
    1 note-counter ! 
    count >upper
    begin
	read-next-note 0=
    while
	    note-hdr KEYWORDS-OFFSET 64
	    2over search >r 2drop
	    note-hdr TITLE-OFFSET 64 >upper
	    2over search r> or >r 2drop
	    note-body @body-length >upper
	    2over search r> or
	    if 
		note-counter @ display-count [char] : emit 2 spaces
		display-note-header cr 7 spaces
		display-note-keywords
		cr
	    then
	    2drop
	    1 note-counter +!
    repeat
    2drop
    close-notes
;

: rebuild-index ( -- | clear and re-populate the index record )
	R/O open-notes
	position-at-first-note  if  close-notes E-POS-MSG type exit  then
	clear-index
	1
	begin
	  dup nearest-note-index
	  swap 0= IF
	    get-notes-file-position  d>u
	    swap  notes-index[]  LE-L!
	  ELSE  drop  THEN
	  read-next-note 0=
	while
	  1+
	repeat
	drop
	close-notes
;

: commit-index ( -- | write the current index record in memory to notes file)
	R/W open-notes
	write-index IF cr E-WRITE-INDEX-MSG type THEN
	close-notes  
;


variable note-body-ptr
create input-line 132 allot
variable input-count

: get-keywords ( -- )
	." KEYWORDS: " input-line 64 accept 
	input-line swap !keywords ;

: pad64 ( n1 -- n2 | n2 is the next multiple of 64 for n1 )
	64 /mod swap 0<> if 1+ then 6 lshift ; 

: take-note ( -- )
	note-hdr HDRSIZE blank
	EOL word count !title
	note-body MAXBODYSIZE blank
	note-body note-body-ptr !
	cr ." Type ':q' on single line when finished." cr
	begin
	  NOTE-PROMPT type
	  input-line 132 accept input-count ! cr
	  input-count @ 2 =
	  input-line c@ [char] : =
	  input-line 1+ c@ 95 and [char] Q = 
	  and and invert
	while
	  input-line note-body-ptr a@ input-count @ cmove
	  input-count @ note-body-ptr +!
	  EOL note-body-ptr a@ !
	  1 note-body-ptr +!
	repeat

	note-body-ptr @ note-body - pad64 \ compute padded body length
	HDRSIZE + !record-length		
	get-keywords cr
	!date-stamp !time-stamp !author	
	?note-checksum !note-checksum	
	open-notes-append
	write-note if E-WRITE-MSG type then
	close-notes 
;

: get-number ( -- n | parse input to obtain a numeric argument )
	bl word string>s ;

: validate-index ( n1 -- n1 or -1 | check for n1 <= 0 )
	dup 0 <= if drop -1 then ;

: order-index-pair ( n1 n2 -- n1 n2 or n2 n1 )
	dup 0> if 2dup > if swap then then ;

: get-note-range ( -- n1 n2 | parse input to obtain arguments to commands )
	get-number validate-index
	get-number validate-index
	order-index-pair ;

create modified-hdr note-record-header% %allot drop

: modify-note ( n -- | allow user to modify the title and keywords of a note )
	dup 0 <= if drop exit then 
	dup R/O open-notes
	read-index  if  E-READ-INDEX-MSG error-abort  then
	read-note close-notes 
	if drop E-READ-MSG type abort then
	display-note-header cr
	." Current Title: " display-note-title cr
	." New Title    : " input-line 64 blank input-line 64 accept
	dup 0> if input-line swap !title else drop then cr
	." Current Keywords: " display-note-keywords cr
	." New Keywords    : " input-line 64 blank input-line 64 accept
	dup 0> if input-line swap !keywords else drop then cr
	note-hdr modified-hdr HDRSIZE cmove	\ keep copy of the mod hdr
	R/W open-notes
	read-index        if  E-READ-INDEX-MSG error-abort  then 
	set-note-position if  E-POS-MSG error-abort  then
	modified-hdr note-hdr HDRSIZE cmove
	write-note-hdr    if  E-WRITE-MSG type  then 
	close-notes ;
	  

: help-notes ( -- )

	tab ." ln [range]    " tab ." List notes in the specified range" cr
	tab ." vn <range>    " tab ." View notes in the specified range" cr
	tab ." tn [title]    " tab ." Take a new note" cr
	tab ." un <filename> " tab ." Use the specified notes file" cr
	tab ." cn <filename> " tab ." Create a new notes file" cr
	tab ." mn <note>     " tab ." Modify title or keywords of note" cr
	tab ." sn <text>     " tab ." Search notes for text" cr
	tab ." hn            " tab ." Display this list of commands" cr
	cr 
	." <> is required argument, [] is optional argument" cr
	." 'range' can be either a single note number, e.g. 3, or a range" cr
	."   entered in the form of a pair of numbers, e.g. 3 5" cr
;

\ User commands

: cn ( -- | create specified notes file ) bl word create-notes ;
: un ( -- | use specified notes file ) bl word use-notes ;
: ln ( -- | list specified notes ) get-note-range list-notes ;
: vn ( -- | view specified notes ) get-note-range view-notes ;
: tn ( -- | take a new note ) take-note ;
: mn ( -- | modify title/keys for specified note) get-number modify-note ;
: sn ( -- | search notes ) EOL word search-notes ;
: hn ( -- | display help for notes commands ) help-notes ;

.( Current notes file: ) my-notes-file count type cr 
.( Commands: cn un ln vn tn mn sn [ hn for help ] )

