\ server.4th
\
\ A simple server in the internet domain using TCP
\
\ From: http://www.linuxhowtos.org/C_C++/socket.htm
\
\ On the server:
\ 
\   $ kforth server -e "<port> server bye"
\ 
\ On the client:
\ 
\   $ kforth client -e "<ipaddr> <port> client bye"  
\ 
\ To test on the same machine, use different terminal windows
\ for the server and client, and use "localhost" as the 
\ ipaddr argument for the client, e.g.
\
\   $ kforth client -e "localhost 5000 client bye"
\
\ Revisions:
\   2010-05-11  km  created
\   2016-06-02  km  include the modules interface
\   2019-12-20  km  display port number in server message
include ans-words
include struct
include struct-ext
include modules.fs
include syscalls

Also syscalls

include socket

0 value sockfd
0 value newsockfd
variable clilen

create buffer 256 allot
create serv_addr sockaddr_in% %allot drop
create cli_addr  sockaddr_in% %allot drop

: clear-sockaddr ( a -- ) sockaddr_in% %size erase ;

: server ( port -- )
    depth 0= ABORT" Usage: port server"
    serv_addr  clear-sockaddr
    htons      serv_addr sockaddr_in->sin_port    w!
    AF_INET    serv_addr sockaddr_in->sin_family  w!    
    INADDR_ANY serv_addr sockaddr_in->sin_addr !

    AF_INET SOCK_STREAM 0 socket  to sockfd
    sockfd 0< ABORT" ERROR opening socket"

    sockfd serv_addr sockaddr_in% %size bind 
    0< ABORT" ERROR on binding"

    sockfd 5 listen ABORT" ERROR on listen"
    cr ." Listening on port " 
    serv_addr sockaddr_in->sin_port w@ 65535 and ntohs . ." ..." cr
    sockfd cli_addr clilen sock_accept to newsockfd
    newsockfd 0< ABORT" ERROR on sock_accept"

    buffer 256 erase
    newsockfd buffer 255 read  dup
    0< ABORT" ERROR reading from socket"
    ." CLIENT>> "  buffer swap type 
    newsockfd s" I got your message" write 
    0< ABORT" ERROR writing to socket" 

    newsockfd close drop 
    sockfd close drop
    cr
;

 
