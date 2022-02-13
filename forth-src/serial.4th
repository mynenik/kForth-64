\ serial.4th
\
\ kForth interface words for Linux serial communcations.
\
\ Copyright (c) 2000--2012 David P. Wallace, Krishna Myneni
\ Provided under the terms of the GNU General Public License
\
\ Requires:
\
\       ans-words.4th
\	strings.4th
\       struct.4th
\       struct-ext.4th
\	modules.4th       v 0.3.4 or later
\
\ Revisions:
\
\	3-13-2000  first working version
\	6-03-2001  modified serial_open to disable XON/XOFF flow control,
\	             added bit constants for c_iflag, etc.,
\		     modified serial_setparams for readability  KM
\      12-13-2001  modified serial_open to disable CR to NL translation.  KM
\       8-03-2007  revised to use structure definition for termios,
\                    included J. Zakiya's refactorization of the
\                    serial_setxxx words, replaced NOT with INVERT,
\                    and fixed stack diagram for serial_close KM
\     2011-10-28 km revised to use KM's preliminary module implementation,
\                    version 0.3.1.
\     2011-11-05 km revised to use v 0.3.4; revised module ref operator.
\     2012-03-24 km added modem line constants and additional ioctl constants;
\                     added LOWER-DTR and RAISE-DTR.
\     2022-02-13 km added LOWER-RTS and RAISE-RTS.

module: serial
begin-module

\ termios structure

struct
    int:    C_IFLAG
    int:    C_OFLAG
    int:    C_CFLAG
    int:    C_LFLAG
    int16:  C_LINE
    64 buf: C_CC
    int:    C_ISPEED
    int:    C_OSPEED
end-struct termios%

create termios termios% %allot drop

\ modem lines
hex
   1 constant TIOCM_LE
   2 constant TIOCM_DTR
   4 constant TIOCM_RTS
   8 constant TIOCM_ST
  10 constant TIOCM_SR
  20 constant TIOCM_CTS
  40 constant TIOCM_CAR
  80 constant TIOCM_RNG
 100 constant TIOCM_DSR
decimal

\ c_iflag bits

   1 constant IGNBRK
   2 constant BRKINT
   4 constant IGNPAR
   8 constant PARMRK
  16 constant INPCK
  32 constant ISTRIP
  64 constant INLCR
 128 constant IGNCR
 256 constant ICRNL
 512 constant IUCLC
1024 constant IXON
2048 constant IXANY
4096 constant IXOFF
8192 constant IMAXBEL

\ c_oflag bits

   1 constant OPOST
   2 constant OLCUC
   4 constant ONLCR
   8 constant OCRNL
  16 constant ONOCR
  32 constant ONLRET
  64 constant OFILL
 128 constant OFDEL
 256 constant NLDLY

Public:

\ c_cflag bits
			\ baud rates constants
4111 constant CBAUD
   0 constant B0
   7 constant B300
   9 constant B1200
  11 constant B2400
  12 constant B4800
  13 constant B9600
  14 constant B19200
  15 constant B38400
4097 constant B57600
4098 constant B115200
			\ character size constants
  48 constant CSIZE
   0 constant CS5
  16 constant CS6
  32 constant CS7
  48 constant CS8

\ parity constants

768 constant CPARITY
  0 constant PARNONE
256 constant PAREVEN
768 constant PARODD

\ stop bits constants

64 constant CSTOPB
0 constant ONESTOPB
64 constant TWOSTOPB

Private:

\ c_lflag bits

   1 constant ISIG
   2 constant ICANON
   4 constant XCASE
   8 constant ECHO
  16 constant ECHOE
  32 constant ECHOK
  64 constant ECHONL
 128 constant NOFLSH
 256 constant TOSTOP
 512 constant ECHOCTL
1024 constant ECHOPRT
2048 constant ECHOKE
4096 constant FLUSHO
16384 constant PENDIN
32768 constant IEXTEN

Public:

\ com port constants

0 constant COM1
1 constant COM2
2 constant COM3
3 constant COM4

Private:

\ ioctl request constants

hex
5401 constant TCGETS     \ get serial port settings; posix func tcgetattr()
5402 constant TCSETS     \ set serial port settings; posix func tcsetattr()
5403 constant TCSETSW    \ 
5404 constant TCSETSF    \ 
5409 constant TCSBRK     \ sends break for given time; posix func tcsendbreak()
540A constant TCXONC     \ controls software flow control; posix func tcflow()  
540B constant TCFLSH     \ flush the input and/or output queue; posix tcflush()
541B constant FIONREAD   \ return number of bytes in input buffer
5415 constant TIOCMGET   \ return the state of the modem bits
5418 constant TIOCMSET   \ set the state of the modem bits
5459 constant TIOCSERGETLSR \ get line status register
545c constant TIOCMIWAIT    \ wait for a change on serial input line(s)
decimal

\ file control constants

hex
800 constant O_NDELAY
100 constant O_NOCTTY
002 constant O_RDWR
decimal


: get-options ( handle -- | read serial port options into termios )
    TCGETS termios ioctl drop ;
	
: set-options ( handle -- | write termios into serial port options )
    TCSETS termios ioctl drop ;

: set-bits ( handle value parameter -- )
    \ handle = handle returned by OPEN
    \ value = desired value for parameter ( use constants defined above )
    \ parameter (CBAUD, CPARITY, CSTOPB, CSIZE)
    >r   \ save mask
    swap dup
    get-options
    \ set the parameter
    swap
    termios C_CFLAG @
    r> invert and  or
    termios C_CFLAG !
    set-options ;

Public:

: open ( port -- handle | opens the serial port for communcation )
    \ port is the serial port to open
    \ 0 = ttyS0 (COM1)
    \ 1 = ttyS1 (COM2)
    \ 2 = ttyS2 (COM3)
    \ 3 = ttyS3 (COM4)
    \ handle is a handle to the open serial port
    \ if handle < 0 there was an error opening the port
    dup
    0 >= IF
	s>string count
	s" /dev/ttyS" 2swap strcat strpck
	O_RDWR O_NOCTTY  O_NDELAY or or ∋ Forth open
	dup
	dup get-options
	
	\ Disable XON/XOFF flow control and CR to NL mapping

	termios C_IFLAG @
	IXON IXOFF or IXANY or ICRNL or invert and
	termios C_IFLAG !

	\ Open for raw input

	termios C_LFLAG @
	ISIG ICANON or ECHO or ECHOE or invert
	and  termios C_LFLAG !

	\ Open for raw output

	termios C_OFLAG @
	OPOST invert
	and  termios C_OFLAG !
	set-options
    THEN ;
	
: close ( handle -- ior | closes the port )
    \ handle = serial port handle returned by OPEN
    ∋ Forth close ;

: write ( handle buf num_to_write -- num_written )
    \ handle = serial port handle returned by OPEN
    \ buf = address to buffer that holds chars to be written
    \ num_to_write = number of chars to write
    \ num_written = number of chars actually written
    ∋ Forth write ;
	
: read ( handle buf num_to_read -- num_read )
    \ handle = serial port handle returned by OPEN
    \ buf = address to buffer to hold chars to being read
    \ num_to_read = number of chars to read
    \ num_read = number of chars actually read
    ∋ Forth read ;


: set-baud     ( handle baud -- )      CBAUD    set-bits ;
: set-parity   ( handle parity -- )    CPARITY  set-bits ;
: set-stopbits ( handle stopbits -- )  CSTOPB   set-bits ;
: set-databits ( handle databits -- )  CSIZE    set-bits ;

: flush ( handle -- )  TCFLSH 2 ioctl drop ;

Private:

variable inque

Public:
	
: lenrx ( handle -- rx_len)
    \ handle = serial port handle returned by OPEN
    \ rx_len = number of chars in recieve queue
    FIONREAD inque ioctl drop
    inque @ ;	 	

Private:
variable status

Public:

: lower-dtr ( handle -- )
    dup TIOCMGET status ioctl drop 
    status @ TIOCM_DTR invert and status !
    TIOCMSET status ioctl drop
;

: raise-dtr ( handle -- )
    dup TIOCMGET status ioctl drop
    status @ TIOCM_DTR or status !
    TIOCMSET status ioctl drop
;

: lower-rts ( handle -- )
    dup TIOCMGET status ioctl drop 
    status @ TIOCM_RTS invert and status !
    TIOCMSET status ioctl drop
;

: raise-rts ( handle -- )
    dup TIOCMGET status ioctl drop
    status @ TIOCM_RTS or status !
    TIOCMSET status ioctl drop
;


: set-params ( handle ^str -- )
    \ ^str examples are 8N1, 7E1, etc.
    swap >r
    dup 1+ c@
    CASE
	[char] 8  OF  r@ CS8 set-databits  ENDOF
	[char] 7  OF  r@ CS7 set-databits  ENDOF
    ENDCASE

    dup	2+ c@
    CASE
	[char] N  OF  r@ PARNONE set-parity  ENDOF
	[char] E  OF  r@ PAREVEN set-parity  ENDOF
	[char] O  OF  r@ PARODD  set-parity   ENDOF
    ENDCASE

    3 + c@
    CASE
	[char] 1  OF  r@ ONESTOPB set-stopbits  ENDOF
	[char] 2  OF  r@ TWOSTOPB set-stopbits  ENDOF
    ENDCASE
	
    r> drop ;

end-module

	
