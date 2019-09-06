\ user.4th
\
\ Determine user properties on a Linux system:
\   username, user id, group id, actual name, home directory
\
\ Copyright (c) 2002 Krishna Myneni,
\   Creative Consulting for Research and Education
\
\ Requires:
\	strings.4th
\	files.4th
\	utils.4th
\
\ Revisions:
\   2007-02-27  modified get-username to set EOL in get-username  km

create username 64 allot		\ counted string
create user_actual_name  256 allot	\ "
create user_home_dir 256 allot          \ "
create pwd_line_buf  256 allot
variable user_id
variable group_id
variable pwd_fd

s" /etc/passwd" $constant SYSTEM_PWD_FILE

: get-username  ( -- a u )
	s" echo $USER > username" shell drop
	s" username" R/O open-file
	if
	  \ Unable to open the file, set username to NULL string
	  drop 0 username !
	else
	  dup username 1+ 63 rot read-line drop
	  if username c! else drop 0 username ! then
	  close-file drop
	then 
	username count ;

: next_pwd_field ( a u -- a2 u2 a3 u3 )
	\ a3 u3 is the next field value string; a2 u2 is the rest
	[char] : scan dup 0= 
	if 2dup 
	else 1 /string 2dup [char] : scan dup >r 2swap r> - 
	then ;  

: get-user-properties ( a u -- )
	username pack
	SYSTEM_PWD_FILE  R/O  open-file
	if
	  \ Unable to open the password file, set actual name to NULL string
	  drop 0 user_actual_name !
	else
	  pwd_fd !
	  begin
	    pwd_line_buf 256 pwd_fd @ read-line drop
	  while
	    pwd_line_buf swap
	    username count search
	    if
	      \ Found user entry in the password file; parse info
	      next_pwd_field 2drop
	      next_pwd_field evaluate user_id !
	      next_pwd_field evaluate group_id !
	      next_pwd_field user_actual_name pack
	      next_pwd_field user_home_dir pack
	    then
	    2drop
	  repeat
	  drop pwd_fd @ close-file drop
	then ;
