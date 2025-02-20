\ hp34401.4th
\
\ GPIB interface to the HP34401A multimeter
\
\ Requires:
\   ans-words
\   modules.4th
\   strings.4th
\   gpib.4th
\
\ Revisions:
\
\	3-23-1999	ported from UR/FORTH
\	6-17-1999	modified to talk to two meters
\       2011-11-01  km  updated to use modular gpib interface
\	2011-11-03  km  make code modular, with interface per unit;
\                         add CLEAR member.
\       2021-05-12  km  update stack diagram for CLEAR member.

Module: hp34401
Begin-Module

22 value PRI_ADDR  \ default GPIB primary address for meter        

Public:

: set-pad ( u -- ) to PRI_ADDR ;
: get-pad ( -- u ) PRI_ADDR ;

\ Clear the meter
: clear ( -- error ) PRI_ADDR  ∋ gpib clear_device ;

\ Return the measured value from meter
: read ( -- ) ( F: -- r )
 	PRI_ADDR 	\ GPIB address of meter
	dup
	c" READ?" swap ∋ gpib send_command
	18 swap        ∋ gpib read_bytes
	∋ gpib in_buf  fnumber_buf 1+ 16 cmove
	15 fnumber_buf c!                                       
	fnumber_buf string>f ;

End-Module






