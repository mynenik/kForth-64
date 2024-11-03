\ rs232-switch.4th
\
\ External push button switch connected to serial port 
\ via RTS/CTS lines may be queried with this code to
\ find out button status (pushed in/closed or open). 
\ This is useful in applications when you can't access
\ the keyboard easily.
\ 
\  PC Serial Port (DB9 connector)
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
\   1. Open the com port (COM1 is shown in this example)
\   2. Enable the switch using RAISE-RTS
\   3. Query the switch using READ-SWITCH
\   4. Disable the switch using LOWER-RTS
\   5. Close the com port
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
decimal

variable com			

: open-com  ( -- ior )
    COM1 ∋ serial open com !
    com @ 0> IF 
      com @ c" 8N1" set-params
      com @ B57600 set-baud
      com @ ∋ serial flush 
      0
    ELSE 1 THEN
;

: close-com ( -- ior )  com @ ∋ serial close ;

\ Return true if switch is closed (ON), false otherwise
: read-switch ( -- bOn )
    com @ get-modem-bits CTS_LINE and 0<> ;

: enable-switch  ( -- )  com @ raise-rts ;
: disable-switch ( -- )  com @ lower-rts ;

base !

