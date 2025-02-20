\ gpib64-200x.4th
\
\ kForth interface words for the Linux GPIB driver by Frank M. Hess,
\ et al. See the linux-gpib project website on sourceforge:
\
\   http://linux-gpib.sourceforge.net/
\
\ Copyright (c) 1999--2024 Krishna Myneni
\ Provided under the terms of the GNU General Public License
\
\ Requires:
\
\      ans-words.4th
\      modules.4th
\      files.4th
\      ioctl.4th
\      struct-200x.4th
\      struct-200x-ext.4th
\
\ Revisions:
\ 
\  3-22-1999  first working version for Claus Schroeter's
\                  linux-gpib driver
\  3-23-1999  completed port of UR/FORTH GPIB driver
\  5-20-1999  added C_IBTMO and ibtmo timeout words; set
\                  default timeout to 3 seconds.
\  8-07-2006  ported to Frank Hess' linux-gpib driver
\  2-22-2007  added 1 ms delays in send_command, send_bytes, and
\                  read_bytes to accomodate slow GPIB devices  km
\  6-22-2010  revised structures for driver version 3.2.14  km
\  11-26-2010  revised to use name space management with modules.4th  km
\  2011-10-27  use named module, with name GPIB  km
\  2011-11-01  remove prefixes, "gpib_", which are unnecessary km
\  2012-01-06  added IBWAIT, WAIT-IO-COMPLETE, and IBLINES; remove fixed
\                1 ms delays in high level i/o words with WAIT-IO-COMPLETE  km
\  2012-02-23  added stub for IBTRG, for later implementation  km
\  2021-05-06  ported to 64-bit kForth (first working ver. under kforth64) km
\  2021-07-14  use 0< ; fix stack comment for SEND_COMMAND.  km
\  2024-02-22  use revised Forth 200x structure extension fields.  km

Module: gpib
Begin-Module

\ Structures equivalent to those in the driver file gpib_ioctl.h

BEGIN-STRUCTURE boardtype%
    100 ( buf:) +FIELD GPBRD_NAME
END-STRUCTURE


BEGIN-STRUCTURE readwrite%
    ( int64:) +XFIELD  GPRW_BUFFER_PTR
    ( int32:) +LFIELD  GPRW_REQ_COUNT
    ( int32:) +LFIELD  GPRW_CMP_COUNT
    ( int32:) +LFIELD  GPRW_END
    ( int32:) +LFIELD  GPRW_HANDLE
END-STRUCTURE


BEGIN-STRUCTURE opendev%
    ( int32:) +LFIELD  GPOPEN_HANDLE
    ( int32:) +LFIELD  GPOPEN_PAD
    ( int32:) +LFIELD  GPOPEN_SAD
    ( int32:) +LFIELD  GPOPEN_IS_BOARD
END-STRUCTURE


BEGIN-STRUCTURE closedev%
    ( int32:) +LFIELD  GPCLOSE_HANDLE
END-STRUCTURE


BEGIN-STRUCTURE serialpoll%
    ( int32:) +LFIELD  GPSP_PAD
    ( int32:) +LFIELD  GPSP_SAD
    ( int32:) +LFIELD  GPSP_STATUS
END-STRUCTURE


BEGIN-STRUCTURE eos%
    ( int32:) +LFIELD  GPEOS_EOS
    ( int32:) +LFIELD  GPEOS_FLAGS
END-STRUCTURE


BEGIN-STRUCTURE wait%
    ( int32:) +LFIELD  GPWAIT_HANDLE
    ( int32:) +LFIELD  GPWAIT_WAIT_MASK
    ( int32:) +LFIELD  GPWAIT_CLEAR_MASK
    ( int32:) +LFIELD  GPWAIT_SET_MASK
    ( int32:) +LFIELD  GPWAIT_IBSTA
    ( int32:) +LFIELD  GPWAIT_PAD
    ( int32:) +LFIELD  GPWAIT_SAD
    ( int32:) +LFIELD  GPWAIT_TIMEOUT
END-STRUCTURE


BEGIN-STRUCTURE online%
    ( int64:) +XFIELD  GP_INIT_DATA_PTR
    ( int32:) +LFIELD  GP_INIT_DATA
    ( int32:) +LFIELD  GP_ONLINE
END-STRUCTURE


BEGIN-STRUCTURE spollbytes%
    ( int32:) +LFIELD  GPSPOLL_NUM_BYTES
    ( int32:) +LFIELD  GPSPOLL_PAD
    ( int32:) +LFIELD  GPSPOLL_SAD
END-STRUCTURE


BEGIN-STRUCTURE boardinfo%
    ( int32:) +LFIELD  GPBD_PAD
    ( int32:) +LFIELD  GPBD_SAD
    ( int32:) +LFIELD  GPBD_PPCONFIG
    ( int32:) +LFIELD  GPBD_AUTOPOLLING
    ( int32:) +LFIELD  GPBD_IS_SYSCON
    ( int32:) +LFIELD  GPBD_T1_DELAY
    ( int32:) +LFIELD  GPBD_IST_NO7BIT
END-STRUCTURE



\ GPIB Driver IOCTL numbers, following those defined in the driver file gpib_ioctl.h

160  constant  GPIB_CODE

GPIB_CODE   100  readwrite%       _IOWR  constant  C_IBRD
GPIB_CODE   101  readwrite%       _IOWR  constant  C_IBWRT
GPIB_CODE   102  readwrite%       _IOWR  constant  C_IBCMD
GPIB_CODE     3  opendev%         _IOWR  constant  C_IBOPENDEV
GPIB_CODE     4  closedev%        _IOW   constant  C_IBCLOSEDEV
GPIB_CODE     5  wait%            _IOWR  constant  C_IBWAIT
GPIB_CODE     6  1                _IOWR  constant  C_IBRPP
GPIB_CODE     9  4                _IOW   constant  C_IBSIC
GPIB_CODE    10  4                _IOW   constant  C_IBSRE
GPIB_CODE    11                   _IO    constant  C_IBGTS
GPIB_CODE    12  4                _IOW   constant  C_IBCAC
GPIB_CODE    14  2                _IOR   constant  C_IBLINES
GPIB_CODE    17  4                _IOW   constant  C_IBTMO
GPIB_CODE    18  serialpoll%      _IOWR  constant  C_IBRSP
GPIB_CODE    19  eos%             _IOW   constant  C_IBEOS
GPIB_CODE    20  1                _IOW   constant  C_IBRSV
GPIB_CODE    26  4                _IOW   constant  C_IBMUTEX
GPIB_CODE    29  boardinfo%       _IOR   constant  C_IBBOARD_INFO
GPIB_CODE    33  2                _IOR   constant  C_IBEVENT
GPIB_CODE    34  4                _IOW   constant  C_IBRSC
GPIB_CODE    35  4                _IOW   constant  C_IB_T1_DELAY
GPIB_CODE    36                   _IO    constant  C_IBLOC
GPIB_CODE    39  online%          _IOW   constant  C_IBONL


\ ---- Debugging 
0 [IF]
BASE @
HEX
    cr .( linux-gpib driver ioctl codes: ) cr
    cr .( IBRD         ) C_IBRD  u.
    cr .( IBWRT        ) C_IBWRT u.
    cr .( IBCMD        ) C_IBCMD u.
    cr .( IBOPENDEV    ) C_IBOPENDEV u.
    cr .( IBCLOSEDEV   ) C_IBCLOSEDEV u.
    cr .( IBWAIT       ) C_IBWAIT u.
    cr .( IBRPP        ) C_IBRPP u.
    cr .( IBSIC        ) C_IBSIC u.
    cr .( IBSRE        ) C_IBSRE u.
    cr .( IBGTS        ) C_IBGTS u.
    cr .( IBCAC        ) C_IBCAC u.
    cr .( IBLINES      ) C_IBLINES u.
    cr .( IBTMO        ) C_IBTMO u.
    cr .( IBRSP        ) C_IBRSP u.
    cr .( IBEOS        ) C_IBEOS u.
    cr .( IBRSV        ) C_IBRSV u.
    cr .( IBMUTEX      ) C_IBMUTEX u.
    cr .( IBBOARD_INFO ) C_IBBOARD_INFO u.
    cr .( IBEVENT      ) C_IBEVENT u.
    cr .( IBRSC        ) C_IBRSC u.
    cr .( IB_T1_DELAY  ) C_IB_T1_DELAY u.
    cr .( IBLOC        ) C_IBLOC u.
    cr .( IBONL        ) C_IBONL u.
    
(
    Under Linux 2.6.x, the following codes result:
    
IBRD         c010a000
IBWRT        c010a001
IBCMD        c010a002
IBOPENDEV    c010a003
IBCLOSEDEV   4004a004
IBWAIT       c020a005
IBRPP        c001a006
IBSIC        4004a009
IBSRE        4004a00a
IBGTS        a00b
IBCAC        4004a00c
IBLINES      8002a00e
IBPAD        4008a00f
IBSAD        4008a010
IBTMO        4004a011
IBRSP        c00ca012
IBEOS        4008a013
IBRSV        4001a014
IBMUTEX      4004a01a
IBBOARD_INFO 801ca01d
IBEVENT
IBRSC    
IB_T1_DELAY
IBLOC        
IBONL        400ca027
)
BASE !
[THEN]

\ constants from linux-gpib: drivers/gpib/include/gpib_user.h

\ IBSTA status bits
 1  0 lshift  constant  DCAS   \ device clear state
 1  1 lshift  constant  DTAS   \ device trigger state
 1  2 lshift  constant  LACS   \ GPIB interface is addressed as Listener
 1  3 lshift  constant  TACS   \ GPIB interface is addressed as Talker
 1  4 lshift  constant  ATN    \ Attention is asserted
 1  5 lshift  constant  CIC    \ GPIB interface is Controller-in-Charge
 1  6 lshift  constant  REM    \ remote state
 1  7 lshift  constant  LOK    \ lockout state
 1  8 lshift  constant  CMPL   \ I/O is complete
 1  9 lshift  constant  EVENT  \ DCAS, DTAS, or IFC has occurred
 1 10 lshift  constant  SPOLL  \ board serial polled by busmaster
 1 11 lshift  constant  RQS    \ Device requesting service
 1 12 lshift  constant  SRQI   \ SRQ is asserted
 1 13 lshift  constant  END    \ EOI or EOS encountered
 1 14 lshift  constant  TIMO   \ Time limit on I/O or wait function exceeded
 1 15 lshift  constant  ERR    \ Function call terminated on error

\ IBERR error codes

  0  constant  EDVR         \ system error
  1  constant  ECIC         \ not CIC
  2  constant  ENOL         \ no listeners
  3  constant  EADR         \ CIC and not addressed before I/O
  4  constant  EARG         \ bad argument to function call
  5  constant  ESAC         \ not SAC
  6  constant  EABO         \ I/O operation was aborted
  7  constant  ENEB         \ non-existent board (GPIB interface offline)
  8  constant  EDMA         \ DMA hardware error detected
 10  constant  EOIP         \ new I/O attempted with old I/O in progress
 11  constant  ECAP         \ no capability for intended operation
 12  constant  EFSO         \ file system operation error
 14  constant  EBUS         \ bus error
 15  constant  ESTB         \ lost serial poll bytes
 16  constant  ESRQ         \ SRQ stuck on
 20  constant  ETAB         \ Table overflow
 
BASE @
HEX
\ GPIB command messages
 01  constant  CMD_GTL      \ go to local
 04  constant  CMD_SDC      \ selected device clear
 05  constant  CMD_PPC      \ parallel poll configure
 08  constant  CMD_GET      \ group execute trigger
 09  constant  CMD_TCT      \ take control
 11  constant  CMD_LLO      \ local lockout
 14  constant  CMD_DCL      \ device clear
 15  constant  CMD_PPU      \ parallel poll unconfigure
 18  constant  CMD_SPE      \ serial poll enable
 19  constant  CMD_SPD      \ serial poll disable
 20  constant  CMD_LAD      \ value to be or'd to obtain listen address
 3F  constant  CMD_UNL      \ unlisten
 40  constant  CMD_TAD      \ value to be or'd to obtain talk address
 5F  constant  CMD_UNT      \ untalk
 60  constant  CMD_SAD      \ my secondary address (base)
 60  constant  CMD_PPE      \ parallel poll enable (base)
 70  constant  CMD_PPD      \ parallel poll disable

BASE !

variable driver
c" /dev/gpib0" driver ! 
variable fd

Public:


variable gplock
variable gprsc
variable gpremote
variable gptimeout       \ timeout in microseconds
variable gpduration      \ duration to send IFC CLEAR in microsec

create gponl   online%     allot
create gprw    readwrite%  allot
create gpinfo  boardinfo%  allot
create gpwait  wait%       allot

create ibcmd_buf       64  allot
create in_buf       16384  allot
create out_buf      16384  allot

: open ( -- ior | open the gpib device driver )
    driver a@ R/W ∋ Forth open dup fd ! 0< ;

: close ( -- ior | close the device driver )
    fd @ ∋ Forth close ;

: ibboard_info ( -- error | return board info in )
    fd @ C_IBBOARD_INFO gpinfo ioctl ;

: iblock ( -- error | lock the board)
    true gplock L!
    fd @ C_IBMUTEX gplock ioctl ;

: ibunlock ( -- error | unlock the board)
    false gplock L!
    fd @ C_IBMUTEX gplock ioctl ;

\ : ibsta ( -- status | return status of last gpib function )
\	ibargs OF_IB_IBSTA + @ ;
\
\ : iberr ( -- error | return error code of last gpib function )
\	ibargs OF_IB_IBERR + @ ;
\
\ : ibcnt ( -- count | return count from last gpib function )
\	ibargs OF_IB_IBCNT + @ ;

\ ibonl requires sysadmin privelage in linux-gpib driver
: ibonl ( b -- error | place the gpib online/offline )
    gponl GP_ONLINE L!  0 gponl GP_INIT_DATA L!
    fd @ C_IBONL gponl ioctl ;

: ibrsc ( req_ctrl -- error | request system control )
    gprsc L!
    fd @ C_IBRSC gprsc ioctl ;

: ibsic ( usec -- error | send interface clear on gpib board)
    gpduration L!
    fd @ C_IBSIC gpduration ioctl ;

: ibsre ( b -- error | set or clear remote enable line )
    gpremote L! 
    fd @ C_IBSRE gpremote ioctl ;

: iblines ( aclines -- ibsta | return status of eight GPIB control lines )
    >r fd @ C_IBLINES r>  ioctl ;

: ibtmo ( v -- error | set timeout to v microseconds)
    gptimeout L!
    fd @ C_IBTMO gptimeout ioctl ;

: ibcmd ( c_n ... c_2 c_1 n -- error | send command bytes to gpib )
    dup gprw GPRW_REQ_COUNT L!
    0 DO ibcmd_buf i + c! LOOP
    ibcmd_buf gprw GPRW_BUFFER_PTR !
    0 gprw GPRW_HANDLE L!
    0 gprw GPRW_CMP_COUNT L!
    0 gprw GPRW_END L!
    fd @ C_IBCMD gprw ioctl
;

: ibrd ( buf u -- error | read u bytes into buf )
    gprw  GPRW_REQ_COUNT L!
    gprw  GPRW_BUFFER_PTR !
    0 gprw GPRW_CMP_COUNT L!
    0 gprw GPRW_HANDLE L!
    0 gprw GPRW_END L!
    fd @ C_IBRD gprw ioctl 
;

: ibwrt ( buf u -- error | write u bytes from buf )
    gprw GPRW_REQ_COUNT L!  
    gprw GPRW_BUFFER_PTR !
       0 gprw GPRW_CMP_COUNT L!
       0 gprw GPRW_HANDLE L!
    true gprw GPRW_END L!
    fd @ C_IBWRT gprw ioctl 
;

: ibwait ( umask -- error | wait for events )
     dup DTAS DCAS or SPOLL or and
         gpwait GPWAIT_CLEAR_MASK L!
         gpwait GPWAIT_WAIT_MASK  L!
       0 gpwait GPWAIT_SET_MASK   L!
    1000 gpwait GPWAIT_TIMEOUT    L!
       0 gpwait GPWAIT_HANDLE     L!
    fd @ C_IBWAIT gpwait ioctl 
;

\ ------ end of GPIB primitives

: ibtrg ( n -- error )
;

: wait-io-complete ( -- )  CMPL ibwait drop ;

: clear_device ( n -- error | send SDC to device at primary address n )
    CMD_SDC swap CMD_LAD or  CMD_TAD 3 ibcmd ;

: send_command ( ^str n  -- | send a string to device at primary address n )
    CMD_LAD or  CMD_TAD 2 ibcmd drop    \ set talker and listener
    wait-io-complete
    count ibwrt drop                    \ write data
    wait-io-complete
    CMD_UNT CMD_UNL 2 ibcmd drop ;      \ untalk and unlisten             

\ send_bytes is similar to send_command except that it uses
\ the output buffer, gpib_out_buf, rather than a counted string.                             
: send_bytes ( u n -- | send u bytes to device at primary address n )
    CMD_LAD or  CMD_TAD 2 ibcmd drop     \ set talker and listener
    wait-io-complete
    out_buf swap ibwrt drop              \ write data
    wait-io-complete
    CMD_UNT CMD_UNL 2 ibcmd drop ;       \ untalk and unlisten       


: read_bytes ( u n -- | read u bytes from device at primary address n )
    CMD_TAD or  CMD_LAD 2 ibcmd drop   \ set listener and talker
    wait-io-complete
    in_buf swap ibrd drop              \ read data
    wait-io-complete
    CMD_UNL CMD_UNT 2 ibcmd drop ;     \ untalk and unlisten            

: init ( -- error | initialize the gpib board and interface )
    \ 1 ibonl
    iblock
    100 ibsic     or
    true ibsre    or
    3000000 ibtmo or
;

End-Module

