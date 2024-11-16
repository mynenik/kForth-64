\ kstudio.4th
\
\ Sound Recording Software for Linux
\
\ Copyright (c) 2024  Krishna Myneni, krishna.myneni@ccreweb.org
\
\ This software is provided under the GNU General Public License
\ GPL v3.0 or later.
\
\ Last Revised: 2024-11-15  km
\
\ Notes:
\
\   1. The input source may be one of the audio capture
\      sources (card, device) listed by the command
\
\        arecord -l
\
\      The program currently does not determine this
\      information by itself and the card/device must
\      be set manually. The data format, number of
\      audio channels, and sampling rate must also be
\      specified for the input source. See examples
\      of input source specs in this code -- the default
\      source here is an external USB audio digitizer
\      (Scarlett Solo). Example settings are also given
\      for ordinary sound car/chipset line input.
\
\   2. 
include ans-words
include modules
include strings
include files
include utils
include ansi
include struct-200x
include struct-200x-ext
include serial          \ supports remote record and play button
include rs232-switch    \ start/stop switches over serial port
include signal
include syscalls

Also syscalls

\ Convert string to unsigned number
: $>u ( a ucount -- unum )
   bl skip 0 0 2swap >number 2drop drop ;
 
: set-timer-handler ( xt -- xtold )  
    SIGALRM forth-signal ;

\ start the countdown timer
: start-timer ( -- ) 250 250 set-timer ;

\ pause timer signal
: pause-timer ( -- ) 0 0 set-timer ;

\ is the timer running?
: timer-running? ( -- flag )
    get-timer 2 ms get-timer + 0> ;

\ Check for com port access, and if successful, assume
\ recording push-button switch is present and interfaced
\ through the com port.
false value rec-switch-present?

open-sw 0= [IF]
  true to rec-switch-present?
[ELSE]
  cr .( Remote switch com port cannot be opened! )
  false to rec-switch-present?
[THEN]

: poll-button-release ( btn_line -- )
    BEGIN
      1000 usleep
      key? IF
        key 27 = IF drop EXIT THEN
      THEN
      dup read-switch and 0=
    UNTIL drop ;

: poll-rec-release ( -- )  CTS_LINE poll-button-release ;
: poll-play-release ( -- ) DSR_LINE poll-button-release ;

: poll-key ( -- key ) BEGIN  1000 usleep key?  UNTIL  key ;

30 60 * constant MAX_DURATION  \ 30 minutes max recording
44100   constant RATE_CD       \ sampling frequency in Hz (CD quality)

\ Record/play/connect Linux ALSA programs
s" arecord "  $CONSTANT  $CMD_RECORD
s" aplay "    $CONSTANT  $CMD_PLAY
s" aconnect " $CONSTANT  $CMD_CONNECT

\ Recording and/or play options
s" --device=" $CONSTANT  $DEVICE_OPT
s" -c"        $CONSTANT  $CHANNELS_OPT
s" -d"        $CONSTANT  $DURATION_OPT
s" -f"        $CONSTANT  $FORMAT_OPT
s" -l"        $CONSTANT  $LIST_OPT
s" -q"        $CONSTANT  $QUIET_OPT
s" -r"        $CONSTANT  $RATE_OPT
s" -N"        $CONSTANT  $NOBLOCK_OPT
s" --process-id-file" $CONSTANT  $PIDFILE_OPT  \ for $CMD_PLAY only

\ Digitized samples format
s" S16_LE"    $CONSTANT  $FMT_S16_LE
s" S32_LE"    $CONSTANT  $FMT_S32_LE

s" test"      $CONSTANT  $DEF_FILE_PFX  \ default file prefix
s" .wav"      $CONSTANT  $FILE_EXT

\ Temporary file names for recording control/status
s" /tmp/ks_rec_pid.txt" $CONSTANT $TMP_REC_PIDFILE
s" /tmp/ks_pla_pid.txt" $CONSTANT $TMP_PLA_PIDFILE

variable card          \ audio capture card
variable device        \ audio capture device
variable sample-rate   \ Hz
variable duration      \ seconds
variable nchannels     \ number of audio channels
variable nseq          \ sequence number in series
create ^format 8 allot \ samples format string
create ^file-prefix  64 allot  \ file prefix

: set-input-source ( card device -- )
    device !
    dup card !
    CASE
      0 OF   \ Line In/Mic
          2 nchannels !
          RATE_CD sample-rate !
          $FMT_S16_LE ^format pack
        ENDOF
      1 OF   \ Scarlett Solo
          2 nchannels !
          RATE_CD sample-rate !
          $FMT_S32_LE ^format pack
        ENDOF
    ENDCASE
;

create ^device-option    16 allot
create ^channels-option   8 allot
create ^rate-option       8 allot
create ^format-option     8 allot
create ^duration-option   8 allot

\ Make a file name string from file prefix and sequence number
: prefix-to-name ( ^str useq -- a u )
    >r count r> 0 <# # # # #> strcat  $FILE_EXT strcat ;
 
: make-option-strings ( -- )
    $DEVICE_OPT s" hw:" strcat
    card @   0 <# # #> strcat s" ," strcat
    device @ 0 <# # #> strcat ^device-option pack
    $CHANNELS_OPT s"  " strcat
    nchannels @ 0 <# # #> strcat ^channels-option pack
    $RATE_OPT sample-rate @ 0 <# #S #> strcat ^rate-option pack
    $FORMAT_OPT s"  " strcat ^format count strcat ^format-option pack
    $DURATION_OPT s"  " strcat duration @ MAX_DURATION min 
    0 <# #S #> strcat ^duration-option pack
;

: make-recording-cmd ( -- a u )
    $CMD_RECORD
    $NOBLOCK_OPT strcat s"  " strcat
    $QUIET_OPT   strcat s"  " strcat
    ^device-option   count strcat s"  " strcat
    ^channels-option count strcat s"  " strcat
    ^rate-option     count strcat s"  " strcat
    ^format-option   count strcat s"  " strcat
    ^duration-option count strcat s"  " strcat
    ^file-prefix nseq @ prefix-to-name strcat 
    s"  " strcat     
;

\ Return play command to play recorded sequence useq
: make-play-command ( useq -- a u )
    >r
    $CMD_PLAY
    $PIDFILE_OPT      strcat s"  " strcat
    $TMP_PLA_PIDFILE  strcat s"  " strcat  
    ^file-prefix r> prefix-to-name strcat
    s"  " strcat
;

\ Display recording options
: .options ( -- )
    cr ." Audio Input Device: "
    card @ CASE 
      0 OF ." Line In/Mic" ENDOF
      1 OF ." Scarlett Solo" ENDOF
    ENDCASE
    cr ." # Channels:  " nchannels @ 2 .r
    cr ." Sample Rate: " sample-rate @ 5 .r ."  Hz"
    cr ." Max Length:  " duration @ 4 .r ."  s"
    cr ." Data Format: " ^format count type
    cr ." File Prefix: " ^file-prefix count type
    cr ." Sequence #:  " nseq @ 3 .r 
    cr
    rec-switch-present? timer-running? and IF
      cr ." Remote buttons active." cr
    ELSE
      cr ." Remote switchbox not available. Use keyboard." cr
    THEN
;
 
variable tmp_fid
create tmp_line_buf 128 allot
\ Return process id (pid) from a previously written temp file.
\ return 0 if unable to open/read temp file
: get-pid-from-file ( caddr u -- pid | 0 )
    R/O open-file IF
      drop 0  \ error opening temp file
    ELSE
      tmp_fid !
      tmp_line_buf 128 erase
      tmp_line_buf 127 tmp_fid @ read-line IF
        2drop 0  \ error reading temp file
      ELSE
        drop tmp_line_buf swap parse_token 2swap 2drop 
        $>u
      THEN
      tmp_fid @ close-file drop
    THEN
;

: remove-rec-pid-file ( -- )
    $TMP_REC_PIDFILE delete-file drop ;

\ Get currently running process id's.
: get-rec-pid  ( -- pid | 0 ) $TMP_REC_PIDFILE get-pid-from-file ;
: get-play-pid ( -- pid | 0 ) $TMP_PLA_PIDFILE get-pid-from-file ;

create ^rec-cmd 256 allot
: rec-start ( -- )
    1 nseq +!  \ increment sequence number
    make-option-strings
    make-recording-cmd s" &" strcat ^rec-cmd pack
    ^rec-cmd count cr type
    ^rec-cmd system 0= IF
      3000 usleep
      s" pidof " $CMD_RECORD strcat
      s" > " strcat $TMP_REC_PIDFILE strcat
      strpck system 0= IF
        cr ." Recording started at " tdstring type cr
        EXIT
      THEN
    THEN
    cr ." Error executing command:"
    cr ^rec-cmd count type
    cr ." Recording NOT started." cr
    -1 nseq +!  \ restore sequence number 
;

variable rec_pid

: rec-stop ( pid -- )
    dup rec_pid ! SIGTERM kill IF 
      cr ." Unable to kill PID " rec_pid @ . cr 
    ELSE
      cr ." Recording stopped at " tdstring type
      cr s" ls -l " ^file-prefix nseq @ prefix-to-name strcat 
      strpck system drop
      cr 
    THEN 
    remove-rec-pid-file ;


\ Play specified recording number in current sequence
: splay ( u -- )
    dup 0> IF
      >r
      ^file-prefix count nip 0> IF
        r> make-play-command s" &" strcat 
        \ $CMD_PLAY 
        \ $PIDFILE_OPT     strcat s"  " strcat
        \ $TMP_PLA_PIDFILE strcat s"  " strcat  
        \ ^file-prefix r> prefix-to-name strcat
        \ s"  &" strcat
        strpck system drop
      ELSE
        r> drop 
        cr s" No file prefix specified!" type cr
      THEN
    ELSE
      drop cr s" Invalid sequence number!" type cr
    THEN
;

: play-start ( -- ) 
    nseq @ make-play-command s" &" strcat strpck system IF
      cr ." Error executing command!"
    THEN ;

: play-stop  ( pid -- )
    dup SIGTERM kill IF 
      cr ." Unable to kill PID " . cr 
    ELSE
      drop cr ." Playback stopped." cr 
    THEN ;


\ Read remote switch box and take corresponding action
\ if a button is pressed. This is a timer signal handler
\ which is called periodically when the timer is started.
: button-dispatcher ( n -- )
    drop
    enable-switch 1 ms
    read-switch dup IF
      pause-timer
      dup CTS_LINE and IF      \ Rec button pressed
        poll-rec-release
        get-rec-pid dup 0> IF  \ Stop recording in progress
          rec-stop
        ELSE                   \ Start a new recording
          drop rec-start
        THEN
      ELSE
        DSR_LINE and IF           \ Play button pressed
          poll-play-release
          get-play-pid dup 0> IF  \ Stop play in progress
            play-stop
          ELSE
            drop play-start        \ Start play of last recording
          THEN
        THEN
      THEN
      start-timer
    ELSE
      \ any other periodic action needed if no button press
    THEN
    disable-switch
;


: start ( -- )
    get-rec-pid 0> IF
      cr ." Recording in progress! You may kill the"
      cr ." current process by typing 'STOP' or wait for"
      cr ." the process to finish." cr
    ELSE
      rec-start
    THEN
;

\ Terminate the current recording
: stop ( -- )
    get-rec-pid dup 0> IF
      rec-stop
    ELSE
      drop cr ." No recording processes exist." cr
    THEN ;


\ Re-record last sequence number (overwrites last file) 
: redo ( -- ) -1 nseq +! start ;

\ Play last recorded file in current sequence
: play ( -- ) nseq @ splay ;

create inbuf 64 allot  
: new-seq ( -- )
    cr ." Enter file prefix: "
    inbuf 63 accept dup 0= IF
      drop
      cr ." Using default file prefix '"
      $DEF_FILE_PFX 2dup type
    ELSE
      inbuf swap 
    THEN  ^file-prefix pack
    cr ." Enter start sequence #: "
    inbuf 3 accept dup 0> IF
      inbuf swap $>u 
    THEN  nseq !
;

\ Set defaults (specific to system)
0 [IF]
  0 card !   \ internal sound chipset / sound card
  0 device !
[ELSE]
  1 card !    \ external USB audio digitizer
  0 device !
[THEN]
card @ device @ set-input-source
0 nseq !
MAX_DURATION duration !
$DEF_FILE_PFX ^file-prefix pack
make-option-strings
remove-rec-pid-file

: help ( -- )
   cr ." KStudio Commands:"
   cr ."   NEW-SEQ     begin new sequence of recordings."
   cr ."   START       record next take in sequence."
   cr ."   STOP        stop current recording."
   cr ."   REDO        redo last recording in sequence."
   cr ."   PLAY        play last recording."
   cr ." n SPLAY       play recording #n in sequence." 
   cr ."   .OPTIONS    show current recording options."
   cr ."   HELP        display this help text."
   cr
   cr ." Variables:"
   cr ."   nseq        current sequence #" 
;

rec-switch-present? [IF]
   ['] button-dispatcher set-timer-handler drop
   start-timer
[THEN]

help
cr .options


