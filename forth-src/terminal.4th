\ terminal.4th
\
\ Simple terminal module with plug-in comm interfaces, 
\ for kForth
\
\ Written by David P. Wallace and Krishna Myneni
\ Provided under the terms of the GNU General Public License
\
\ Requires:
\
\	ans-words.4th
\	modules.fs  (0.5.0 or later)
\       struct.4th
\       struct-ext.4th
\	strings.4th
\	ansi.4th
\	files.4th
\	( communications module reference, Comm )
\
\ Revisions:
\	2004-03-13  Avoid response lag to input due to key? in terminal;
\	              added Send File function  KM
\       2005-09-28  Fixed problem associated with read-line  KM
\       2007-08-03  Added includes for struct and struct-ext to use new serial.4th  KM
\       2011-10-27  Extensive revision for use as a module with generic interfaces  km
\	2011-10-30  Factoring, added echo control, and minor cosmetic changes  km
\	2011-10-31  Added <LF> key and means of toggling tx characters between
\                     CR and CR-LF. Changed Exit function to F5 instead of Esc;
\                     Esc is typically needed in terminal communications.  km
\       2011-11-05  replaced module reference operator for v0.3.4 of modules.4th  km
\	2012-02-15  updated for v 0.5.0 of modules.fs  km

Module: terminal

ALSO Comm       \ dependency on module Comm

Begin-Module

: >UPC 95 AND ;
: EKEY ( -- u | return extended key as concatenated byte sequence )
       BEGIN key? UNTIL
       0 BEGIN  key?  WHILE  8 lshift key or  REPEAT ;

1 CELLS 8 = CONSTANT 64BIT?

HEX
0D     CONSTANT  <CR>
0A     CONSTANT  <LF>
1B     CONSTANT  ESC
1B4F50 CONSTANT  F1
1B4F51 CONSTANT  F2
1B4F52 CONSTANT  F3
1B4F53 CONSTANT  F4
64BIT? [IF]
1B5B31357E
[ELSE]
  5B31357E
[THEN]
CONSTANT F5
DECIMAL

0      CONSTANT  HELP_ROW
BLUE   CONSTANT  HELP_EKEY_COLOR
BLACK  CONSTANT  HELP_TEXT_COLOR
WHITE  CONSTANT  HELP_BACK_COLOR
BLACK  CONSTANT  TERM_BACK_COLOR
WHITE  CONSTANT  TERM_TEXT_COLOR

: clear-line ( row background -- ) 
	background 0 swap 2dup at-xy 80 spaces at-xy ;

: clear-help ( -- ) 
	HELP_ROW HELP_BACK_COLOR clear-line ;

: set-colors ( -- )
	TERM_TEXT_COLOR foreground
	TERM_BACK_COLOR background ;

Public:
  
: help ( -- | show the help line )
        save_cursor
	clear-help
	HELP_EKEY_COLOR foreground   ." F1 "
	HELP_TEXT_COLOR foreground   ." Show Key Help   "
	HELP_EKEY_COLOR foreground   ." F2 "
	HELP_TEXT_COLOR foreground   ." Capture On/Off  "
	HELP_EKEY_COLOR foreground   ." F3 "
	HELP_TEXT_COLOR foreground   ." Send Text File  "
	HELP_EKEY_COLOR foreground   ." F4 "
	HELP_TEXT_COLOR foreground   ." Echo  "
	HELP_EKEY_COLOR foreground   ." F5 "
	HELP_TEXT_COLOR foreground   ." Exit"
	restore_cursor
;

\ Display a message on the help line
: help-msg ( a u -- )
	clear-help
	HELP_TEXT_COLOR foreground
	type
;

Private:

variable fid
FALSE VALUE ?capture
create filename 256 allot
create capture-filename 256 allot

Public:

\ Accept filename and copy it to a counted string buffer
: get-filename ( a -- )  filename dup 254 accept strpck swap strcpy ;

: close-capture-file ( -- )  fid @ close drop FALSE to ?capture ;

: capture-file ( -- )
	?capture IF 
 	  close-capture-file
	  s" Capture file closed!" help-msg
        ELSE
	  s" Capture to file named: " help-msg
	  capture-filename dup get-filename
	  file-exists IF
	    clear-help
	    ." File " capture-filename count type 
	    ."  already exists! Overwrite (Y/N)? "
	    key >upc [char] Y = IF
	      capture-filename count W/O O_TRUNC or open-file
	      0= IF fid ! TRUE to ?capture
	      ELSE
	        s" Unable to open output file!" help-msg
	        EXIT
	      THEN
	    ELSE
	      s" Capture cancelled!" help-msg EXIT
	    THEN
	  ELSE
	    capture-filename count W/O create-file
	    0= IF fid ! TRUE to ?capture
	      ELSE
	        s" Unable to open output file!" help-msg
	        EXIT
	      THEN
	  THEN
        THEN 
;


Private:

create send-filename 256 allot
create send-line-buffer 256 allot
variable txfid
variable last-send-time
10    VALUE LINE-DELAY        \ delay in ms between sending each line of text
 1    VALUE CHAR-DELAY        \ to send data to *slow* terminals
FALSE VALUE ?sending

Public:
		
: send-file ( -- )
	    s" Text File to Send: " help-msg
	    send-filename dup get-filename
	    file-exists 0= IF
	      s" Input file does not exist!" help-msg
	      EXIT
	    THEN
	    send-filename count R/O open-file 0= IF
	      txfid !
	      s" Sending file " help-msg
	      send-filename count type ."  ..."
	      TRUE to ?sending
	    ELSE
	      s" Unable to open input file!" help-msg
	      EXIT
	    THEN 
	    ms@ last-send-time ! ;


: status? ( -- flag | TRUE equals ok to exit terminal )
        ?sending IF
	  s" File Send in Progress! Halt Sending and Exit (Y/N)? " help-msg
	  key >UPC [CHAR] Y = IF
	    txfid @ close-file drop
	    FALSE TO ?sending
	  ELSE
	    0 EXIT
	  THEN
	THEN
	?capture IF close-capture-file THEN
	TRUE ;

\ Open the terminal display
: open-display ( -- )
	TERM_BACK_COLOR background
	page
	help
	set-colors
	0 HELP_ROW 1+ at-xy
;

\ Close the terminal display
: close-display ( -- )
	text_normal \ restore normal colors and attributes
	page
;

: open  ( aconfig -- )  open-display  ∋ Comm open  ;
: close ( -- )          ∋ Comm close  close-display ;

Private:
create buf 8 allot
true  VALUE ?echo
false VALUE ?crlf

Public:

: toggle-echo ( -- ) ?echo invert to ?echo ;
: toggle-crlf ( -- ) ?crlf invert to ?crlf ;

\ Send the next line from the send file.
: send-next-line ( -- )
	ms@ last-send-time @ - LINE-DELAY >= IF
	    ms@ last-send-time !
	    send-line-buffer 256 txfid @ read-line IF
	      \ error reading file
	      2drop txfid @ close-file drop FALSE to ?sending
	      save_cursor
	      s" Error reading file!" help-msg
	      restore_cursor set-colors	      
	    ELSE
	      FALSE = IF
	        \ reached EOF
		drop txfid @ close-file drop
	        FALSE to ?sending
	        save_cursor
	        s" <<Terminal: Send Completed!>>" help-msg
	        restore_cursor set-colors
	      ELSE
	        send-line-buffer swap
		?echo IF 2dup type cr THEN
		∋ Comm write
	      THEN
	    THEN
	  THEN
;

\ Write the received character to the capture file
: capture-next-char ( -- )
	fid @  buf c@ <CR> = IF 
	  EOL_BUF dup strlen 
	ELSE buf 1 
        THEN   ∋ Forth write drop 
;

\ Transmit character
: tx-char ( c -- )  
	?echo IF dup emit THEN
	dup <LF> = IF 
	  ?crlf IF <CR> ∋ Comm put THEN
        THEN
        ∋ Comm put 
;

: start ( aconfig -- | start a terminal emulator )
	open
	BEGIN
	  ?sending IF  send-next-line  THEN 

	  BEGIN
	    rx-len
	  WHILE
	    ∋ Comm get
	    dup buf c! 
	    dup <CR> = IF drop CR ELSE emit THEN
	    ?capture IF  capture-next-char  THEN
	  REPEAT

	  key?

	  IF
	    EKEY CASE
	      F1   OF help set-colors ENDOF 
	      F2   OF save_cursor capture-file restore_cursor  
	              set-colors ENDOF
	      F3   OF save_cursor send-file restore_cursor     
	              set-colors ENDOF
	      F4   OF toggle-echo ENDOF
	      F5   OF status? IF close EXIT THEN ENDOF
	      dup  tx-char
	    ENDCASE
	  THEN
	AGAIN ;

End-Module


