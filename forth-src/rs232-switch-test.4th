\ rs232-switch-test.4th
\
\ Test external two-position switch interfaced through serial port.
\
include ans-words
include strings
include modules
include struct-200x
include struct-200x-ext
include serial
include rs232-switch

false value user-abort?

: test-switch ( -- )
    open-com ABORT" Unable to open serial port!"
    read-switch IF
      cr ." CTS is raised. Ensure switch is OFF and try again."
      cr close-com drop EXIT
    THEN
    cr ." Press a key on the keyboard to raise RTS."
    BEGIN key? UNTIL  key drop
    enable-switch
    cr ." Press and hold the push-button switch."
    cr ." If there is no effect, press Esc to exit the test." cr
    false to user-abort?
    BEGIN
      key? dup IF
        key 27 = and dup
        IF true to user-abort? THEN
      THEN
      0=
    WHILE
      read-switch 0=
    WHILE
    REPEAT
      cr ." CTS has been raised (switch is ON)."
      cr ." Please release the switch to OFF position."
      BEGIN
        1000 usleep
        read-switch 0=
      UNTIL
      cr ." CTS is low (switch is OFF)."
    THEN
    disable-switch
    close-com drop
    user-abort? IF cr ." Test aborted by user!" cr THEN
;


cr cr .( Type 'TEST-SWITCH' to check operation of switch. ) cr

