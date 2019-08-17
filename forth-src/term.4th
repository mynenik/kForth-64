\ term.4th

include ans-words
include modules.fs
include struct
include struct-ext
include strings
include ansi
include files

\ Load multiple communications interfaces, and plug one in to
\ the terminal module

Defer Comm

include dummy-comm     \ Dummy Asynchronous Communications Interface
include serial	       \ Serial Port I/O Module
include serial-comm    \ Serial Communications Interface
\ include other-comm   \ Other Communications Interface 

' dummy-comm IS Comm     \ Use the Dummy Interface
include terminal
: dummy-term terminal ;
' serial-comm IS Comm  \ Use the Serial Interface
include terminal
: serial-term terminal ;

ALSO serial ALSO serial-comm  ALSO serial-term
		
: term ( -- | start the default terminal )
    COM1    ∋ serial-comm config  port !
    B4800   ∋ serial-comm config  baud !
    ∋ serial-comm config  start 
;

ALSO Forth

cr .( Type 'term' to start the default terminal.)

