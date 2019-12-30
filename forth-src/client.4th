\ client.4th
\
\ A simple client example to complement the simple 
\ server example: server.4th
\
\ From: http://www.linuxhowtos.org/C_C++/socket.htm
\
\ kForth version
\
\ Revisions:
\   2010-05-14  km  created
\   2016-06-02  km  include the modules interface

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

    ." Please enter a message to send to the server: "
    buffer 255 accept  >r 
    sockfd buffer r> write 0< ABORT" ERROR writing to socket"
    buffer 256 erase
    sockfd buffer 255 read dup 
    0< ABORT" ERROR reading from socket"
    cr ." SERVER>> " buffer swap type
   
    sockfd close drop cr
;

