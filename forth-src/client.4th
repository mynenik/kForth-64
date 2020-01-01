\ client.4th
\
\ A simple client example to complement the simple 
\ server example: server.4th
\
\ Notes:
\
\ 0. To use,
\
\      <ipaddr> <port> client
\
\    where ipaddr is the quad numeric address of the server,
\    e.g. ( 192 168 1 101 ) and port is the port number.
\
\ 1. For more detailed notes, please see the  program, server.4th.
\
\ References:
\ 1. http://www.linuxhowtos.org/C_C++/socket.htm
\
\ Revisions:
\   2010-05-14  km  created
\   2016-06-02  km  include the modules interface
\   2019-12-31  km  additional comments

include ans-words
include struct
include struct-ext
include modules.fs
include syscalls

Also syscalls

include socket

0 value sockfd

create buffer 256 allot
create serv_addr sockaddr_in% %size allot

: clear-sockaddr ( a -- ) sockaddr_in% %size erase ;
: type-quoted ( c-addr u -- )
    [char] " dup >r emit type r> emit ;

: localhost 127 0 0 1 ;  \ ip address of the host computer

: client ( ip1 ip2 ip3 ip4  port -- )
    depth 5 < ABORT" Usage: ip1 ip2 ip3 ip4 port client"
    serv_addr clear-sockaddr    
    htons serv_addr sockaddr_in->sin_port w!
    AF_INET serv_addr sockaddr_in->sin_family w!

    \ We don't do host lookup by name; use ip address from stack
    dotted.quad htonl serv_addr sockaddr_in->sin_addr !

    AF_INET SOCK_STREAM 0 socket  dup to sockfd
    0< ABORT" ERROR opening socket"
   
    sockfd serv_addr sockaddr_in% %size connect 
    0< ABORT" ERROR connecting to server"

    ." Please enter a request for the server: "
    buffer 255 accept  >r 
    sockfd buffer r> write 0< ABORT" ERROR writing to socket"
    buffer 256 erase
    sockfd buffer 255 read dup 
    0< ABORT" ERROR reading from socket"
    cr ." Server replies: " buffer swap type-quoted
    
    sockfd close ABORT" Error closing socket"
    cr
;

