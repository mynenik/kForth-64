\ rs232-switch.4th
\
\ External push button switch(es) connected to serial port 
\ via RTS/CTS/DSR lines may be queried with this code to
\ find out button status (pushed in/closed or open) of two
\ switches. This is useful in applications when you can't access
\ the keyboard easily.
\
\ Krishna Myneni, 15 Novermber 2024, krishna.myneni@ccreweb.org
\
\  PC Serial Port (DB9 connector) Example with 1 switch connected
\  to RTS/CTS lines.
\
\   1  DCD  <--           ==============
\   2  RXD  <--            \ 1 2 3 4 5 /  ( male connector )
\   3  TXD  -->             \ 6 7 8 9 /
\   4  DTR  -->              =========
\   5  GND 
\   6  DSR  <--           SW1 /==== SW3          ==== SW3
\   7  RTS  -->        -->===/              -->\
\   8  CTS  <--        <--1K---==== SW2  <--1K--\==== SW2
\   9  RI   <--              (open/OFF)         (closed/ON)
\
\ There is a 1K resistor in series with pin SW2 on the switch.
\
\ To use:
\   1. Open the serial port (COM1 is shown in this example)
\   2. Enable the switch(es) using RAISE-RTS
\   3. Wait for short delay (1 millisecond is more than enough)
\   4. Query the switch(es) using READ-SWITCH
\   5. Disable the switch(es) using LOWER-RTS
\   6. Repeat from step 2 as needed
\   7. Close the serial port
\
\ Notes:
\   0. Valid port values are COM1--COM4, USBCOM1--USBCOM2 (see serial.4th).
\
\   1. Users on Linux must be members of the dialout group to perform
\      i/o on serial ports.
\
\   2. At present there is no way to query the existence of an external
\      switch attached to the serial port. This can be done if we use
\      an additional modem input line e.g. DCD, to read both output 
\      terminals of the first three terminal switch.
\
\ Requires:
\   ans-words
\   modules
\   struct-200x
\   struct-200x-ext
\   strings
\   serial

Also serial

base @
decimal

hex
 20 constant CTS_LINE
100 constant DSR_LINE
decimal

\ SW_PORT can take the values COM1 -- COM4, USBCOM1 -- USBCOM2
COM1 value SW_PORT

variable com			

: open-sw  ( -- ior )
    SW_PORT ∋ serial open com !
    com @ 1 <  ;

: close-sw ( -- ior )  com @ ∋ serial close ;

\ Return non-zero if switch/switches are closed (ON), 0 otherwise
\ u = hex  20 for CTS
\ u = hex 100 for DSR
\ u = hex 120 for both
: read-switch ( -- u )
    com @ get-modem-bits 
    dup  CTS_LINE and
    swap DSR_LINE and or ;

: enable-switch  ( -- )  com @ raise-rts ;
: disable-switch ( -- )  com @ lower-rts ;

base !

