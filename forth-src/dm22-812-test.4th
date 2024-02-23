\ dm22-812-test.4th
\
\ Test serial interface to the Radio Shack 22-812 digital 
\ multimeter. Display incoming packets in hex form, and
\ validate packet checksum.
\
\ Requires:
\
\       ans-words.4th
\	modules.4th
\       struct-200x.4th
\       struct-200xext.4th
\	strings.4th
\	serial.4th  (module version)
\
\ Revisions:
\   2012-03-17 km based on hexterm.4th
\   2012-03-24 km revised GET-PACKET to raise and lower DTR line
\   2012-03-27 km added packet checksum validation
\   2024-02-21 km load Forth 200x data structures
   
include ans-words
include modules
include struct-200x
include struct-200x-ext
include strings
include serial

Also serial

base @
decimal

COM1 value DM_PORT   \ serial port to which multimeter is connected
9 constant PKT_SIZE  \ size of data packet from meter, in bytes

variable com			
create buf 64 allot

: hexchar ( n -- ) dup 10 < if 48 + emit else 10 - 65 + emit then ;

: hprint ( n -- ) bl emit dup 4 rshift hexchar 
	15 and hexchar bl emit ;

variable pklen

: get-packet ( -- ior )
    com @ raise-dtr
    0 pklen !
    begin
      com @ lenrx if 
        com @ buf pklen @ + 1 ∋ serial read drop
	1 pklen +!
      then
      pklen @ PKT_SIZE =
    until
    com @ lower-dtr
    0
;

57 constant CHECKSUM_OFFSET

\ Calculate and return packet checksum
: packet-checksum ( -- u ) 0 PKT_SIZE 1- 0 do buf I + c@ + loop ;

\ Return true if checksum byte matches the expected checksum
: checksum-valid? ( -- flag )
    packet-checksum CHECKSUM_OFFSET + 255 and 
    buf PKT_SIZE 1- + c@ = ; 

: display-packet ( -- )
    cr buf PKT_SIZE 0 do dup c@ hprint 1+ loop drop ;

: dm-open ( -- ior )
	DM_PORT ∋ serial open com !
	com @ 0> if 
	  com @ c" 8N1" set-params
	  com @ B4800 set-baud
	  com @ ∋ serial flush 
	  0
	else 1 then
	com @ lower-dtr
;

: dm-close ( -- ior )  com @ ∋ serial close ;

true value verbose?

: dm-test ( -- | digital meter )
	dm-open ABORT" Unable to open serial port connection!"
	cr ." Put 22-812 meter in RS232 mode when ready to display packets!"
	get-packet
	if  
	  dm-close drop 
	  cr ." Unable to receive packet!"
	  exit
	then

	cr ." Press ESC to Exit " cr
	
	begin
	  100000 usleep
	  get-packet
	  if dm-close drop cr ." Error receiving packets!" exit then
	  verbose? if display-packet then
	  checksum-valid? invert if ."  Error: Bad Checksum" cr then  
	  key?
	  if key 27 =
	    if
	      dm-close drop
	      exit
	    then
          then
	again ;
		
." Type 'dm-test' to start diagnostics."

base !

