\ sockets.4th
\
\ Krishna Myneni, Creative Consulting for Research & Education
\ http://ccreweb.org
\
\ Revisions:
\   2010-05-11  km   created
\   2010-05-13  km   added network byte order utils and dotted.quad
\   2010-05-15  km   added SHUT_x constants; structure size checks
\   2019-12-29  km   added direct syscalls for 64-bit systems.
\
\ From /usr/include/asm/sockios.h

\ Socket-level I/O control calls.
HEX
8901  constant  FIOSETOWN
8902  constant  SIOCSPGRP
8903  constant  FIOGETOWN
8904  constant  SIOCGPGRP
8905  constant  SIOCATMARK
8906  constant  SIOCGSTAMP          \ Get stamp
DECIMAL

\ From /usr/include/asm/socket.h

\ For setsockopt
 1  constant  SOL_SOCKET

 1  constant  SO_DEBUG
 2  constant  SO_REUSEADDR
 3  constant  SO_TYPE
 4  constant  SO_ERROR
 5  constant  SO_DONTROUTE
 6  constant  SO_BROADCAST
 7  constant  SO_SNDBUF
 8  constant  SO_RCVBUF
 9  constant  SO_KEEPALIVE
10  constant  SO_OOBINLINE
11  constant  SO_NO_CHECK
12  constant  SO_PRIORITY
13  constant  SO_LINGER
14  constant  SO_BSDCOMPAT
\ To add :#define SO_REUSEPORT 15
16  constant  SO_PASSCRED
17  constant  SO_PEERCRED
18  constant  SO_RCVLOWAT
19  constant  SO_SNDLOWAT
20  constant  SO_RCVTIMEO
21  constant  SO_SNDTIMEO

\ Security levels - as per NRL IPv6 - don't actually do anything
22  constant  SO_SECURITY_AUTHENTICATION
23  constant  SO_SECURITY_ENCRYPTION_TRANSPORT
24  constant  SO_SECURITY_ENCRYPTION_NETWORK

25  constant  SO_BINDTODEVICE

\ Socket filtering
26  constant  SO_ATTACH_FILTER
27  constant  SO_DETACH_FILTER

28  constant  SO_PEERNAME
29  constant  SO_TIMESTAMP
SO_TIMESTAMP constant SCM_TIMESTAMP

30  constant  SO_ACCEPTCONN

\ from /usr/include/linux/socket.h

struct
  int16:   sockaddr->sa_family
  14 buf:  sockaddr->sa_data
end-struct sockaddr%

struct
   int16: sockaddr_in->sin_family   \ should be AF_INET 
   int16: sockaddr_in->sin_port
   int32: sockaddr_in->sin_addr
   8 buf: sockaddr_in->sin_zero     \ not used, must be zero 
end-struct sockaddr_in%


struct
  ( cell%  field) int32:  hostent->h_name        \ official name of host
  ( cell%  field) int32:  hostent->h_aliases     \ alias list 
  ( cell%  field) int32:  hostent->h_addrtype    \ host address type
  ( cell%  field) int32:  hostent->h_length      \ length of address
  ( cell%  field) int32:  hostent->h_addr_list   \ list of addresses from name server
end-struct hostent%


struct
  ( cell%  field) int32:  linger->l_onoff
  ( cell%  field) int32:  linger->l_linger
end-struct linger%


struct
  ( cell%  field) int32:  msghdr->msg_name     \ socket name
  ( cell%  field) int32:  msghdr->msg_namelen  \ length of name
  ( cell%  field) int32:  msghdr->msg_iov      \ data blocks
  ( cell%  field) int32:  msghdr->msg_iovlen   \ number of blocks
  ( cell%  field) int32:  msghdr->msg_control    \ per protocol magic 
  ( cell%  field) int32:  msghdr->msg_controllen  \ length of cmsg list
  ( cell%  field) int32:  msghdr->msg_flags  
end-struct msghdr%


struct
  ( cell%  field) int32:  cmsghdr->cmsg_len
  ( cell%  field) int32:  cmsghdr->cmsg_level
  ( cell%  field) int32:  cmsghdr->cmsg_type  
end-struct cmsghdr%

\ Verify structure sizes
1 [IF]
: check-struct-size ( n1 nsize -- )  
    >r %size r> <> ABORT" structure is incorrect size!"  ;

sockaddr_in%  16  check-struct-size
hostent%      20  check-struct-size
linger%        8  check-struct-size
msghdr%       28  check-struct-size
cmsghdr%      12  check-struct-size
[THEN]

\ from /usr/include/linux/socket.h

\ Address families
 0  constant  AF_UNSPEC
 1  constant  AF_UNIX             \ Unix domain sockets 
 1  constant  AF_LOCAL            \ POSIX name for AF_UNIX
 2  constant  AF_INET             \ Internet IP Protocol
 3  constant  AF_AX25             \ Amateur Radio AX.25
 4  constant  AF_IPX              \ Novell IPX
 5  constant  AF_APPLETALK        \ AppleTalk DDP
 6  constant  AF_NETROM           \ Amateur Radio NET/ROM
 7  constant  AF_BRIDGE           \ Multiprotocol bridge
 8  constant  AF_ATMPVC           \ ATM PVCs
 9  constant  AF_X25              \ Reserved for X.25 project  
10  constant  AF_INET6            \ IP version 6
11  constant  AF_ROSE             \ Amateur Radio X.25 PLP
12  constant  AF_DECnet           \ Reserved for DECnet project
13  constant  AF_NETBEUI          \ Reserved for 802.2LLC project
14  constant  AF_SECURITY         \ Security callback pseudo AF
15  constant  AF_KEY              \ PF_KEY key management API
16  constant  AF_NETLINK
AF_NETLINK  constant  AF_ROUTE    \ Alias to emulate 4.4BSD 
17  constant  AF_PACKET           \ Packet family                
18  constant  AF_ASH              \ Ash                          
19  constant  AF_ECONET           \ Acorn Econet                 
20  constant  AF_ATMSVC           \ ATM SVCs                     
21  constant  AF_RDS              \ RDS sockets                  
22  constant  AF_SNA              \ Linux SNA Project (nutters!) 
23  constant  AF_IRDA             \ IRDA sockets                 
24  constant  AF_PPPOX            \ PPPoX sockets                
25  constant  AF_WANPIPE          \ Wanpipe API Sockets 
26  constant  AF_LLC              \ Linux LLC                    
29  constant  AF_CAN              \ Controller Area Network      
30  constant  AF_TIPC             \ TIPC sockets                 
31  constant  AF_BLUETOOTH        \ Bluetooth sockets            
32  constant  AF_IUCV             \ IUCV sockets                 
33  constant  AF_RXRPC            \ RxRPC sockets                
34  constant  AF_ISDN             \ mISDN sockets                
35  constant  AF_PHONET           \ Phonet sockets               
36  constant  AF_IEEE802154       \ IEEE802154 sockets           
37  constant  AF_MAX              \ For now.. 


\ Protocol families
 0  constant  PF_UNSPEC      \ Unspecified.
 1  constant  PF_LOCAL       \ Local to host (pipes and file-domain).
PF_LOCAL constant PF_UNIX    \ Old BSD name for PF_LOCAL.
PF_LOCAL constant PF_FILE    \ Another non-standard name for PF_LOCAL.
 2  constant  PF_INET        \ IP protocol family.
 3  constant  PF_AX25        \ Amateur Radio AX.25.
 4  constant  PF_IPX         \ Novell Internet Protocol.
 5  constant  PF_APPLETALK   \ Appletalk DDP.
 6  constant  PF_NETROM      \ Amateur radio NetROM.
 7  constant  PF_BRIDGE      \ Multiprotocol bridge.
 8  constant  PF_ATMPVC      \ ATM PVCs.
 9  constant  PF_X25         \ Reserved for X.25 project.
10  constant  PF_INET6       \ IP version 6.
11  constant  PF_ROSE        \ Amateur Radio X.25 PLP.
12  constant  PF_DECnet      \ Reserved for DECnet project.
13  constant  PF_NETBEUI     \ Reserved for 802.2LLC project.
14  constant  PF_SECURITY    \ Security callback pseudo AF.
15  constant  PF_KEY         \ PF_KEY key management API.
16  constant  PF_NETLINK
PF_NETLINK constant PF_ROUTE \ Alias to emulate 4.4BSD.
17  constant  PF_PACKET      \ Packet family.
18  constant  PF_ASH         \ Ash.
19  constant  PF_ECONET      \ Acorn Econet.
20  constant  PF_ATMSVC      \ ATM SVCs.
22  constant  PF_SNA         \ Linux SNA Project
23  constant  PF_IRDA        \ IRDA sockets.
24  constant  PF_PPPOX       \ PPPoX sockets.
25  constant  PF_WANPIPE     \ Wanpipe API sockets.
31  constant  PF_BLUETOOTH   \ Bluetooth sockets.
32  constant  PF_MAX         \ For now.. 

\ Socket level values
255  constant  SOL_RAW         
261  constant  SOL_DECNET      
262  constant  SOL_X25         
263  constant  SOL_PACKET      
264  constant  SOL_ATM       \ ATM layer (cell level)
265  constant  SOL_AAL       \ ATM Adaption Layer (packet level)
266  constant  SOL_IRDA        

\ Maximum queue length specifiable by listen
128  constant  SOMAXCONN       


\ Flags we can use with send and recv. 
\   Added those for 1003.1g not all are supported yet
HEX
   1  constant  MSG_OOB         
   2  constant  MSG_PEEK        
   4  constant  MSG_DONTROUTE   
   4  constant  MSG_TRYHARD        \ Synonym for MSG_DONTROUTE for DECnet
   8  constant  MSG_CTRUNC      
  10  constant  MSG_PROBE          \ Do not send. Only probe path f.e. for MTU 
  20  constant  MSG_TRUNC       
  40  constant  MSG_DONTWAIT       \ Nonblocking io                
  80  constant  MSG_EOR            \ End of record 
 100  constant  MSG_WAITALL        \ Wait for a full request 
 200  constant  MSG_FIN         
 400  constant  MSG_SYN         
 800  constant  MSG_CONFIRM        \ Confirm path validity 
1000  constant  MSG_RST         
2000  constant  MSG_ERRQUEUE       \ Fetch message from error queue 
4000  constant  MSG_NOSIGNAL       \ Do not generate SIGPIPE 
8000  constant  MSG_MORE           \ Sender will send more 

MSG_FIN  constant MSG_EOF         

40000000  constant MSG_CMSG_CLOEXEC      \ Set close_on_exit for file
                                         \ descriptor received through
                                         \ SCM_RIGHTS
DECIMAL

\ socket types

 1  constant  SOCK_STREAM   \ Sequenced, reliable, connection-based byte streams
 2  constant  SOCK_DGRAM    \ Connectionless, unreliable datagrams of fixed max length
 3  constant  SOCK_RAW      \ Raw protocol interface
 4  constant  SOCK_RDM      \ Reliably-delivered messages
 5  constant  SOCK_SEQPACKET  \ Sequenced, reliable, connection-based datagrams of fixed len
 6  constant  SOCK_DCCP     \ Datagram Congestion Control Protocol
10 constant   SOCK_PACKET   \ Linux specific

SOCK_PACKET 1+ constant SOCK_MAX

\ flags
4000 constant SOCK_NONBLOCK
\ SOCK_CLOEXEC

\ from /usr/include/linux/net.h

 1  constant  SYS_SOCKET                
 2  constant  SYS_BIND
 3  constant  SYS_CONNECT
 4  constant  SYS_LISTEN
 5  constant  SYS_ACCEPT
 6  constant  SYS_GETSOCKNAME
 7  constant  SYS_GETPEERNAME
 8  constant  SYS_SOCKETPAIR
 9  constant  SYS_SEND
10  constant  SYS_RECV
11  constant  SYS_SENDTO
12  constant  SYS_RECVFROM
13  constant  SYS_SHUTDOWN
14  constant  SYS_SETSOCKOPT
15  constant  SYS_GETSOCKOPT
16  constant  SYS_SENDMSG
17  constant  SYS_RECVMSG
18  constant  SYS_ACCEPT4

1 16 LSHIFT constant __SO_ACCEPTCON        \ performed a listen           


HEX 
       0  constant  INADDR_ANY      \ Address to accept any incoming messages
ffffffff  constant  INADDR_BROADCAST  \ Address to send to all hosts
ffffffff  constant  INADDR_NONE  \ Address indicating an error return

DECIMAL
 127  constant  IN_LOOPBACKNET   \ Network number for local host loopback

\ from /usr/include/sys/socket.h
\ parameters for SHUTDOWN
0  constant  SHUT_RD
1  constant  SHUT_WR
2  constant  SHUT_RDWR

\ --------------------------------
\ Network Byte Order Utilities
\ --------------------------------
variable endian
1 endian !

endian C@ [IF] 
\ little ENDIAN systems need some byte shuffling

: htons ( n1 -- n2 | put lower two bytes in big endian order)
    DUP 8 RSHIFT SWAP 255 AND 8 LSHIFT OR ;

: htonl ( n1 -- n2 | put in big endian )
    DUP >R       255 AND 24 LSHIFT  
    R@  8 RSHIFT 255 AND 16 LSHIFT OR
    R@ 16 RSHIFT 255 AND  8 LSHIFT OR
    R> 24 RSHIFT 255 AND OR
;

\ htons and htonl are their own inverses
: ntohs ( n1 -- n2 )  htons ; 
: ntohl ( n1 -- n2 )  htonl ;

[ELSE] 

\ big ENDIAN systems already use network byte order
: htons ;
: htonl ;
: ntohs ;
: ntohl ;

[THEN]
\ --------------------------------
\ IP address utilities
\ ( from M. McGowan's ipsubnet.4th )
\ --------------------------------

: dotted.quad  ( n1 n2 n3 n4 -- m )
     >r >r >r 256 * r> + 256 * r> + 256 * r> + ;

\ --------------------------------
\  Socket words
\ --------------------------------

\ ior result is zero on success, -1 on error

1 cells 8 = [IF]
\ 64-bit system calls

: socket ( ndomain ntype nprotocol -- sockfd ) NR_socket syscall3 ;
: bind ( sockfd asock nlen -- ior ) NR_bind syscall3 ;
: connect ( sockfd asock nlen -- ior ) NR_connect syscall3 ;
: listen ( sockfd nbacklog -- ior ) NR_listen syscall2 ;
: sock_accept ( sockfd asock alen -- sockfd ) NR_accept syscall3 ;
: getsockname ( sockfd asock alen -- ior ) NR_getsockname syscall3 ;
: getpeername ( sockfd asock alen -- ior ) NR_getpeername syscall3 ;
: socketpair ( ndomain ntype nprotocol asv -- ior ) NR_socketpair syscall4 ;
: send ( sockfd abuf nlen nflags -- n ) 0 0 NR_sendto syscall6 ;
: sendto ( sockfd abuf nlen nflags adest nlen -- n ) NR_sendto syscall6 ;
: recv ( sockfd abuf nlen nflags -- n ) 0 0 NR_recvfrom syscall6 ;
: recvfrom ( sockfd abuf nlen nflags asrc alen -- n ) NR_recvfrom syscall6 ;
: shutdown ( sockfd nhow -- ior ) NR_shutdown syscall2 ;
: sendmsg ( sockfd amsg nflags -- n ) NR_sendmsg syscall3 ;
: recvmsg ( sockfd amsg nflags -- n ) NR_recvmsg syscall3 ;
: setsockopt ( sockfd nlevel noptname aoptval noptlen -- ior )
   NR_setsockopt syscall5 ;
: getsockopt ( sockfd nlevel noptname aoptval aoptlen -- ior )
   NR_getsockopt syscall5 ;

[ELSE]

create socketcall-args 10 cells allot

: set-socketcall-args ( n1 ... nm m -- )
    dup >r 1- cells socketcall-args + 
    r> 0 ?DO 2dup ! 1 cells - nip  LOOP
    drop 
;

: do-socketcall ( nargs ncall -- ior )
     >R set-socketcall-args R> socketcall-args socketcall ;

: socket ( ndomain ntype nprotocol -- sockfd )  3 SYS_SOCKET do-socketcall ;
: bind ( sockfd asock nlen -- ior )  3 SYS_BIND  do-socketcall ;
: connect ( sockfd asock nlen -- ior )  3 SYS_CONNECT do-socketcall ;
: listen ( sockfd nbacklog -- ior )     2 SYS_LISTEN do-socketcall ;
: sock_accept ( sockfd asock alen -- sockfd )  3 SYS_ACCEPT do-socketcall ;
: getsockname ( sockfd asock alen -- ior ) 3 SYS_GETSOCKNAME do-socketcall ;
: getpeername ( sockfd asock alen -- ior ) 3 SYS_GETPEERNAME do-socketcall ;
: socketpair ( ndomain ntype nprotocol asv -- ior ) 4 SYS_SOCKETPAIR do-socketcall ;
: send ( sockfd abuf nlen nflags -- n )  4 SYS_SEND do-socketcall ;
: sendto ( sockfd abuf nlen nflags adest nlen -- n ) 6 SYS_SENDTO do-socketcall ;
: recv ( sockfd abuf nlen nflags -- n )  4 SYS_RECV do-socketcall ;
: recvfrom ( sockfd abuf nlen nflags asrc alen -- n ) 6 SYS_RECVFROM do-socketcall ;
: shutdown ( sockfd nhow -- ior )  2 SYS_SHUTDOWN do-socketcall ;
: sendmsg ( sockfd amsg nflags -- n ) 3 SYS_SENDMSG do-socketcall ;
: recvmsg ( sockfd amsg nflags -- n ) 3 SYS_RECVMSG do-socketcall ;

: setsockopt ( sockfd nlevel noptname aoptval noptlen -- ior ) 
    5 SYS_SETSOCKOPT do-socketcall ;
: getsockopt ( sockfd nlevel noptname aoptval aoptlen -- ior ) 
    5 SYS_GETSOCKOPT do-socketcall ;

[THEN]

