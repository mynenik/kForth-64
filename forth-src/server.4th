\ server.4th
\
\ A simple TCP/IP server
\
\ Notes:
\
\ 0. Starting the server demo, on the server machine:
\ 
\      $ kforth server[.4th] -e "<port> server bye"
\ 
\ 1. Starting the client demo, on the client machine:
\ 
\       $ kforth client[.4th] -e "<ipaddr> <port> client bye"  
\ 
\ 2. To test the server and client programs on the same machine, 
\    use different terminal windows for the server and client,  
\    and use "localhost" as the ipaddr argument for the client, e.g.
\
\    $ kforth client -e "localhost 5000 client bye"
\
\    For the example above, the server is assumed to be listening
\    on port 5000. 
\
\ 3. For testing client/server communications across a network, 
\    ensure that the server's firewall configuration permits tcp 
\    access on the desired port. Use port numbers above 1024 which 
\    don't conflict with known services on your system (see 
\    /etc/services ).
\
\ References:
\  1. http://www.linuxhowtos.org/C_C++/socket.htm
\  2. "Linux Socket Programming, by example", W. W. Gay, Que (2000).
\
\ Revisions:
\   2010-05-11  km  created
\   2016-06-02  km  include the modules interface
\   2019-12-20  km  display port number in server message
\   2019-12-31  km  display connection message with client IP address
\   2020-02-04  km  use UW@
include ans-words
include struct
include struct-ext
include modules.fs
include syscalls

Also syscalls

include socket

0 value sockfd
0 value newsockfd

create buffer 256 allot
create serv_addr sockaddr_in% %allot drop
create cli_addr  sockaddr_in% %allot drop
variable clilen

: clear-sockaddr ( a -- ) sockaddr_in% %size erase ;
: show-ip ( a -- ) sockaddr_in->sin_addr @ 
             dup 255 and 3 .r  [char] . emit 
    8 rshift dup 255 and 3 .r  [char] . emit
    8 rshift dup 255 and 3 .r  [char] . emit
    8 rshift 3 .r ;

: type-quoted ( c-addr u -- ) 
    [char] " dup >r emit type r> emit ; 

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
    serv_addr sockaddr_in->sin_port uw@ ntohs . ." ..." cr

    sockaddr_in% %size clilen !
    sockfd cli_addr clilen sock_accept to newsockfd
    newsockfd 0< ABORT" ERROR on sock_accept"
    ." Client connected from IP address: "
    cli_addr show-ip cr

    buffer 256 erase
    newsockfd buffer 255 read  dup
    0< ABORT" ERROR reading from socket"
    ." Client request: " buffer swap type-quoted
    newsockfd s" Request Acknowledged" write 
    0< ABORT" ERROR writing to socket" 

    newsockfd close ABORT" Error closing connection" 
    sockfd close ABORT" Error closing socket"
    cr
;

 
