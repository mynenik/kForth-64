\ hexterm.4th
\
\ Hex output terminal for kForth (based on terminal.4th)
\ 
\
\ Requires:
\
\       ans-words.4th
\	modules.4th
\       struct.4th
\       struct-ext.4th
\	strings.4th
\	ansi.4th
\	serial.4th  (module version)
\
\ Revisions:
\   2007-08-03 km revised to use new serial.4th, requiring structures
\   2012-03-17 km revised to use modular version of serial.4th
   
include ans-words
include modules
include struct
include struct-ext
include strings
include ansi
include serial

Also serial

variable com			
create buf 64 allot

: hexchar ( n -- ) dup 10 < if 48 + emit else 10 - 65 + emit then ;

: hprint ( n -- ) [char] < emit dup 4 rshift hexchar 
	15 and hexchar [char] > emit ;


: ht ( -- | terminal emulator )
	\ black background
	page
	\ green background
	\ black foreground
	." Touch Screen Terminal - (Esc) to Exit " cr
	\ white foreground
	\ black background
	
	COM1 ∋ serial open com !
	com @ c" 8N1" set-params
	com @ B4800 set-baud

	begin
	  10000 usleep
	  com @ lenrx
	  if
	    com @ buf 1 ∋ serial read drop
	    buf c@ hprint 
	  then
	  key?
	  if
	    key
	    dup
	    27 =
	    if
	      drop
	      com @ ∋ serial close
	      drop
	      text_normal	\ restore normal foreground/background colors
	      \ page		\ clear the screen
	      exit
	    then
	    buf c!
	    com @ buf 1 ∋ serial write drop
	  then
	again ;
		
." Type 'ht' to start hex terminal on COM1 at 4800, 8N1"




