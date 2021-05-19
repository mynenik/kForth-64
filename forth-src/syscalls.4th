\ syscalls.4th
\
\ Selected system calls for kForth ver >= 1.5.x on Linux.
\
\ !!! see WARNING below !!!  
\
\ Copyright (c) 2004--2020 Krishna Myneni,
\ Provided under the GNU General Public License
\
\ Notes:
\
\ 0)   WARNING: Not all system calls provided here as Forth words have been
\               tested. USE WITH CAUTION -- it may be possible to DAMAGE
\               YOUR SYSTEM due to bugs in this code, or with improper 
\               arguments to a syscall word. The appropriate arguments for
\               a particular system call are documented in the Linux man
\               page, section 2, for that call. For example, type 
\
\                     man 2 lseek
\
\               to obtain the man page for the lseek system call.
\               Note the following for the arguments to a word:
\
\             a) addresses to strings must contain a NULL terminated
\                string.
\
\             b) addresses to structures must contain data packed with
\                the correct alignment for that structure.
\
\ 1)   System calls under Linux may also be performed using a software
\      interrupt, $80, and placing the parameters in appropriate
\      registers.
\ 
\ 2)   There are over 300 system calls under Linux. A number of
\      these are provided in the form of Forth words here. System call 
\      numbers may be found in /usr/include/asm/unistd_32.h 
\
\ 3)   The words OPEN, CLOSE, READ, WRITE, LSEEK, and IOCTL are already
\        defined in kForth with the same behavior.
\
\ Revisions:
\ 	2004-09-16  created  KM 
\       2005-11-07  ported to kForth (requires asm-x86.4th)  KM
\       2009-09-26  the word SYSCALL has been intrinsic to kForth
\                   since v. 1.4.1; this file is now updated
\                   to use the intrinsic SYSCALL and no longer requires
\                   asm-x86.4th;  KM
\       2010-04-17  renamed this file from syscalls386.4th to
\                   syscalls.4th; KM
\       2010-04-29  added numerous syscalls; most have NOT been tested  KM
\       2010-04-30  renamed open to sys_open; revised comments  KM
\       2012-01-25  made syscalls a module  km
\       2012-01-27  fixed stack diagram for getcwd; mmap with 6 args
\                   needs to use syscall 90 with 1 structure arg  KM
\       2015-08-01  added MAP_ANONYMOUS  km
\       2019-12-29  updated for use on both 64-bit and 32-bit systems  km
\       2020-01-30  conditional definition of FSYNC (now intrinsic) km
BASE @
DECIMAL

Module: syscalls
Begin-Module

Public:
: 64bit? 1 cells 8 = ;
: 32bit? 1 cells 4 = ;

64bit? [IF]

\ From /usr/include/asm/unistd_64.h
0 constant NR_read
1 constant NR_write
2 constant NR_open
3 constant NR_close
4 constant NR_stat
5 constant NR_fstat
6 constant NR_lstat
7 constant NR_poll
8 constant NR_lseek
9 constant NR_mmap
10 constant NR_mprotect
11 constant NR_munmap
12 constant NR_brk
13 constant NR_rt_sigaction
14 constant NR_rt_sigprocmask
15 constant NR_rt_sigreturn
16 constant NR_ioctl
17 constant NR_pread64
18 constant NR_pwrite64
19 constant NR_readv
20 constant NR_writev
21 constant NR_access
22 constant NR_pipe
23 constant NR_select
24 constant NR_sched_yield
25 constant NR_mremap
26 constant NR_msync
27 constant NR_mincore
28 constant NR_madvise
29 constant NR_shmget
30 constant NR_shmat
31 constant NR_shmctl
32 constant NR_dup
33 constant NR_dup2
34 constant NR_pause
35 constant NR_nanosleep
36 constant NR_getitimer
37 constant NR_alarm
38 constant NR_setitimer
39 constant NR_getpid
40 constant NR_sendfile
41 constant NR_socket
42 constant NR_connect
43 constant NR_accept
44 constant NR_sendto
45 constant NR_recvfrom
46 constant NR_sendmsg
47 constant NR_recvmsg
48 constant NR_shutdown
49 constant NR_bind
50 constant NR_listen
51 constant NR_getsockname
52 constant NR_getpeername
53 constant NR_socketpair
54 constant NR_setsockopt
55 constant NR_getsockopt
56 constant NR_clone
57 constant NR_fork
58 constant NR_vfork
59 constant NR_execve
60 constant NR_exit
61 constant NR_wait4
62 constant NR_kill
63 constant NR_uname
64 constant NR_semget
65 constant NR_semop
66 constant NR_semctl
67 constant NR_shmdt
68 constant NR_msgget
69 constant NR_msgsnd
70 constant NR_msgrcv
71 constant NR_msgctl
72 constant NR_fcntl
73 constant NR_flock
74 constant NR_fsync
75 constant NR_fdatasync
76 constant NR_truncate
77 constant NR_ftruncate
78 constant NR_getdents
79 constant NR_getcwd
80 constant NR_chdir
81 constant NR_fchdir
82 constant NR_rename
83 constant NR_mkdir
84 constant NR_rmdir
85 constant NR_creat
86 constant NR_link
87 constant NR_unlink
88 constant NR_symlink
89 constant NR_readlink
90 constant NR_chmod
91 constant NR_fchmod
92 constant NR_chown
93 constant NR_fchown
94 constant NR_lchown
95 constant NR_umask
96 constant NR_gettimeofday
97 constant NR_getrlimit
98 constant NR_getrusage
99 constant NR_sysinfo
100 constant NR_times
101 constant NR_ptrace
102 constant NR_getuid
103 constant NR_syslog
104 constant NR_getgid
105 constant NR_setuid
106 constant NR_setgid
107 constant NR_geteuid
108 constant NR_getegid
109 constant NR_setpgid
110 constant NR_getppid
111 constant NR_getpgrp
112 constant NR_setsid
113 constant NR_setreuid
114 constant NR_setregid
115 constant NR_getgroups
116 constant NR_setgroups
117 constant NR_setresuid
118 constant NR_getresuid
119 constant NR_setresgid
120 constant NR_getresgid
121 constant NR_getpgid
122 constant NR_setfsuid
123 constant NR_setfsgid
124 constant NR_getsid
125 constant NR_capget
126 constant NR_capset
127 constant NR_rt_sigpending
128 constant NR_rt_sigtimedwait
129 constant NR_rt_sigqueueinfo
130 constant NR_rt_sigsuspend
131 constant NR_sigaltstack
132 constant NR_utime
133 constant NR_mknod
134 constant NR_uselib
135 constant NR_personality
136 constant NR_ustat
137 constant NR_statfs
138 constant NR_fstatfs
139 constant NR_sysfs
140 constant NR_getpriority
141 constant NR_setpriority
142 constant NR_sched_setparam
143 constant NR_sched_getparam
144 constant NR_sched_setscheduler
145 constant NR_sched_getscheduler
146 constant NR_sched_get_priority_max
147 constant NR_sched_get_priority_min
148 constant NR_sched_rr_get_interval
149 constant NR_mlock
150 constant NR_munlock
151 constant NR_mlockall
152 constant NR_munlockall
153 constant NR_vhangup
154 constant NR_modify_ldt
155 constant NR_pivot_root
156 constant NR__sysctl
157 constant NR_prctl
158 constant NR_arch_prctl
159 constant NR_adjtimex
160 constant NR_setrlimit
161 constant NR_chroot
162 constant NR_sync
163 constant NR_acct
164 constant NR_settimeofday
165 constant NR_mount
166 constant NR_umount2
167 constant NR_swapon
168 constant NR_swapoff
169 constant NR_reboot
170 constant NR_sethostname
171 constant NR_setdomainname
172 constant NR_iopl
173 constant NR_ioperm
174 constant NR_create_module
175 constant NR_init_module
176 constant NR_delete_module
177 constant NR_get_kernel_syms
178 constant NR_query_module
179 constant NR_quotactl
180 constant NR_nfsservctl
181 constant NR_getpmsg
182 constant NR_putpmsg
183 constant NR_afs_syscall
184 constant NR_tuxcall
185 constant NR_security
186 constant NR_gettid
187 constant NR_readahead
188 constant NR_setxattr
189 constant NR_lsetxattr
190 constant NR_fsetxattr
191 constant NR_getxattr
192 constant NR_lgetxattr
193 constant NR_fgetxattr
194 constant NR_listxattr
195 constant NR_llistxattr
196 constant NR_flistxattr
197 constant NR_removexattr
198 constant NR_lremovexattr
199 constant NR_fremovexattr
200 constant NR_tkill
201 constant NR_time
202 constant NR_futex
203 constant NR_sched_setaffinity
204 constant NR_sched_getaffinity
205 constant NR_set_thread_area
206 constant NR_io_setup
207 constant NR_io_destroy
208 constant NR_io_getevents
209 constant NR_io_submit
210 constant NR_io_cancel
211 constant NR_get_thread_area
212 constant NR_lookup_dcookie
213 constant NR_epoll_create
214 constant NR_epoll_ctl_old
215 constant NR_epoll_wait_old
216 constant NR_remap_file_pages
217 constant NR_getdents64
218 constant NR_set_tid_address
219 constant NR_restart_syscall
220 constant NR_semtimedop
221 constant NR_fadvise64
222 constant NR_timer_create
223 constant NR_timer_settime
224 constant NR_timer_gettime
225 constant NR_timer_getoverrun
226 constant NR_timer_delete
227 constant NR_clock_settime
228 constant NR_clock_gettime
229 constant NR_clock_getres
230 constant NR_clock_nanosleep
231 constant NR_exit_group
232 constant NR_epoll_wait
233 constant NR_epoll_ctl
234 constant NR_tgkill
235 constant NR_utimes
236 constant NR_vserver
237 constant NR_mbind
238 constant NR_set_mempolicy
239 constant NR_get_mempolicy
240 constant NR_mq_open
241 constant NR_mq_unlink
242 constant NR_mq_timedsend
243 constant NR_mq_timedreceive
244 constant NR_mq_notify
245 constant NR_mq_getsetattr
246 constant NR_kexec_load
247 constant NR_waitid
248 constant NR_add_key
249 constant NR_request_key
250 constant NR_keyctl
251 constant NR_ioprio_set
252 constant NR_ioprio_get
253 constant NR_inotify_init
254 constant NR_inotify_add_watch
255 constant NR_inotify_rm_watch
256 constant NR_migrate_pages
257 constant NR_openat
258 constant NR_mkdirat
259 constant NR_mknodat
260 constant NR_fchownat
261 constant NR_futimesat
262 constant NR_newfstatat
263 constant NR_unlinkat
264 constant NR_renameat
265 constant NR_linkat
266 constant NR_symlinkat
267 constant NR_readlinkat
268 constant NR_fchmodat
269 constant NR_faccessat
270 constant NR_pselect6
271 constant NR_ppoll
272 constant NR_unshare
273 constant NR_set_robust_list
274 constant NR_get_robust_list
275 constant NR_splice
276 constant NR_tee
277 constant NR_sync_file_range
278 constant NR_vmsplice
279 constant NR_move_pages
280 constant NR_utimensat
281 constant NR_epoll_pwait
282 constant NR_signalfd
283 constant NR_timerfd_create
284 constant NR_eventfd
285 constant NR_fallocate
286 constant NR_timerfd_settime
287 constant NR_timerfd_gettime
288 constant NR_accept4
289 constant NR_signalfd4
290 constant NR_eventfd2
291 constant NR_epoll_create1
292 constant NR_dup3
293 constant NR_pipe2
294 constant NR_inotify_init1
295 constant NR_preadv
296 constant NR_pwritev
297 constant NR_rt_tgsigqueueinfo
298 constant NR_perf_event_open
299 constant NR_recvmmsg
300 constant NR_fanotify_init
301 constant NR_fanotify_mark
302 constant NR_prlimit64
303 constant NR_name_to_handle_at
304 constant NR_open_by_handle_at
305 constant NR_clock_adjtime
306 constant NR_syncfs
307 constant NR_sendmmsg
308 constant NR_setns
309 constant NR_getcpu
310 constant NR_process_vm_readv
311 constant NR_process_vm_writev
312 constant NR_kcmp
313 constant NR_finit_module
314 constant NR_sched_setattr
315 constant NR_sched_getattr
316 constant NR_renameat2
317 constant NR_seccomp
318 constant NR_getrandom
319 constant NR_memfd_create
320 constant NR_kexec_file_load
321 constant NR_bpf
322 constant NR_execveat
323 constant NR_userfaultfd
324 constant NR_membarrier
325 constant NR_mlock2
326 constant NR_copy_file_range
327 constant NR_preadv2
328 constant NR_pwritev2
329 constant NR_pkey_mprotect
330 constant NR_pkey_alloc
331 constant NR_pkey_free
332 constant NR_statx
333 constant NR_io_pgetevents
334 constant NR_rseq
424 constant NR_pidfd_send_signal
425 constant NR_io_uring_setup
426 constant NR_io_uring_enter
427 constant NR_io_uring_register
428 constant NR_open_tree
429 constant NR_move_mount
430 constant NR_fsopen
431 constant NR_fsconfig
432 constant NR_fsmount
433 constant NR_fspick
434 constant NR_pidfd_open
435 constant NR_clone3
436 constant NR_close_range
437 constant NR_openat2
438 constant NR_pidfd_getfd
439 constant NR_faccessat2
440 constant NR_process_madvise
441 constant NR_epoll_pwait2

[ELSE]

\ From /usr/include/asm/unistd_32.h
  0  constant  NR_RESTART
  1  constant  NR_EXIT
  2  constant  NR_FORK
  3  constant  NR_READ
  4  constant  NR_WRITE
  5  constant  NR_OPEN
  6  constant  NR_CLOSE
  7  constant  NR_WAITPID
  8  constant  NR_CREAT
  9  constant  NR_LINK
 10  constant  NR_UNLINK
 11  constant  NR_EXECVE
 12  constant  NR_CHDIR
 13  constant  NR_TIME
 14  constant  NR_MKNOD
 15  constant  NR_CHMOD
 16  constant  NR_LCHOWN
 17  constant  NR_BREAK
 18  constant  NR_OLDSTAT
 19  constant  NR_LSEEK
 20  constant  NR_GETPID
 21  constant  NR_MOUNT
 22  constant  NR_UMOUNT
 23  constant  NR_SETUID
 24  constant  NR_GETUID
 25  constant  NR_STIME
 26  constant  NR_PTRACE
 27  constant  NR_ALARM
 28  constant  NR_OLDFSTAT
 29  constant  NR_PAUSE
 30  constant  NR_UTIME
 31  constant  NR_STTY
 32  constant  NR_GTTY
 33  constant  NR_ACCESS
 34  constant  NR_NICE
 35  constant  NR_FTIME
 36  constant  NR_SYNC
 37  constant  NR_KILL
 38  constant  NR_RENAME
 39  constant  NR_MKDIR
 40  constant  NR_RMDIR
 41  constant  NR_DUP
 42  constant  NR_PIPE
 43  constant  NR_TIMES
 44  constant  NR_PROF
 45  constant  NR_BRK
 46  constant  NR_SETGID
 47  constant  NR_GETGID
 48  constant  NR_SIGNAL
 49  constant  NR_GETEUID
 50  constant  NR_GETEGID
 51  constant  NR_ACCT
 52  constant  NR_UMOUNT2
 53  constant  NR_LOCK
 54  constant  NR_IOCTL
 55  constant  NR_FCNTL
 56  constant  NR_MPX
 57  constant  NR_SETPGID
 58  constant  NR_ULIMIT
 59  constant  NR_OLDOLDUNAME
 60  constant  NR_UMASK
 61  constant  NR_CHROOT
 62  constant  NR_USTAT
 63  constant  NR_DUP2
 64  constant  NR_GETPPID
 65  constant  NR_GETPGRP
 66  constant  NR_SETSID
 67  constant  NR_SIGACTION
 68  constant  NR_SGETMASK
 69  constant  NR_SSETMASK
 70  constant  NR_SETREUID
 71  constant  NR_SETREGID
 72  constant  NR_SIGSUSPEND
 73  constant  NR_SIGPENDING
 74  constant  NR_SETHOSTNAME
 75  constant  NR_SETRLIMIT
 76  constant  NR_GETRLIMIT
 77  constant  NR_GETRUSAGE
 78 constant  NR_GETTIMEOFDAY
 79 constant  NR_SETTIMEOFDAY
 80 constant  NR_GETGROUPS
 81 constant  NR_SETGROUPS
 82 constant  NR_SELECT
 83 constant  NR_SYMLINK
 84 constant  NR_OLDLSTAT
 85 constant  NR_READLINK
 86 constant  NR_USELIB
 87 constant  NR_SWAPON
 88 constant  NR_REBOOT
 89 constant  NR_READDIR
 90 constant  NR_MMAP
 91 constant  NR_MUNMAP
 92 constant  NR_TRUNCATE
 93 constant  NR_FTRUNCATE
 94 constant  NR_FCHMOD
 95 constant  NR_FCHOWN
 96 constant  NR_GETPRIORITY
 97 constant  NR_SETPRIORITY
 98 constant  NR_PROFIL
 99 constant  NR_STATFS
100 constant  NR_FSTATFS
101 constant  NR_IOPERM
102 constant  NR_SOCKETCALL
103 constant  NR_SYSLOG
104 constant  NR_SETITIMER
105 constant  NR_GETITIMER
106 constant  NR_STAT
107 constant  NR_LSTAT
108 constant  NR_FSTAT
109 constant  NR_OLDUNAME
110 constant  NR_IOPL
111 constant  NR_VHANGUP
112 constant  NR_IDLE
113 constant  NR_VM86OLD
114 constant  NR_WAIT4
115 constant  NR_SWAPOFF
116 constant  NR_SYSINFO
117 constant  NR_IPC
118 constant  NR_FSYNC
119 constant  NR_SIGRETURN
120 constant  NR_CLONE
121 constant  NR_SETDOMAINNAME
122 constant  NR_UNAME
123 constant  NR_MODIFY_LDT
124 constant  NR_ADJTIMEX
125 constant  NR_MPROTECT
126 constant  NR_SIGPROCMASK
127 constant  NR_CREATE_MODULE
128 constant  NR_INIT_MODULE
129 constant  NR_DELETE_MODULE
130 constant  NR_GET_KERNEL_SYMS
131 constant  NR_QUOTACTL
132 constant  NR_GETPGID
133 constant  NR_FCHDIR
134 constant  NR_BDFLUSH
135 constant  NR_SYSFS
136 constant  NR_PERSONALITY
137 constant  NR_AFS_SYSCALL
138 constant  NR_SETFSUID
139 constant  NR_SETFSGID
140 constant  NR_LLSEEK
141 constant  NR_GETDENTS
142 constant  NR_NEWSELECT
143 constant  NR_FLOCK
144 constant  NR_MSYNC
145 constant  NR_READV
146 constant  NR_WRITEV
147 constant  NR_GETSID
148 constant  NR_FDATASYNC
149 constant  NR__SYSCTL
150 constant  NR_MLOCK
151 constant  NR_MUNLOCK
152 constant  NR_MLOCKALL
153 constant  NR_MUNLOCKALL
154 constant  NR_SCHED_SETPARAM
155 constant  NR_SCHED_GETPARAM
156 constant  NR_SCHED_SETSCHEDULER
157 constant  NR_SCHED_GETSCHEDULER
158 constant  NR_SCHED_YIELD
159 constant  NR_SCHED_GET_PRIORITY_MAX
160 constant  NR_SCHED_GET_PRIORITY_MIN
161 constant  NR_SCHED_RR_GET_INTERVAL
162 constant  NR_NANOSLEEP
163 constant  NR_MREMAP
164 constant  NR_SETRESUID
165 constant  NR_GETRESUID
166 constant  NR_VM86
167 constant  NR_QUERY_MODULE
168 constant  NR_POLL
169 constant  NR_NFSSERVCTL
170 constant  NR_SETRESGID
171 constant  NR_GETRESGID
172 constant  NR_PRCTL
173 constant  NR_RT_SIGRETURN
174 constant  NR_RT_SIGACTION
175 constant  NR_RT_SIGPROCMASK
176 constant  NR_RT_SIGPENDING
177 constant  NR_RT_SIGTIMEDWAIT
178 constant  NR_RT_SIGQUEUEINFO
179 constant  NR_RT_SIGSUSPEND
180 constant  NR_PREAD64
181 constant  NR_PWRITE64
182 constant  NR_CHOWN
183 constant  NR_GETCWD
184 constant  NR_CAPGET
185 constant  NR_CAPSET
186 constant  NR_SIGALTSTACK
187 constant  NR_SENDFILE
188 constant  NR_GETPMSG
189 constant  NR_PUTPMSG
190 constant  NR_VFORK
191 constant  NR_UGETRLIMIT
192 constant  NR_MMAP2
193 constant  NR_TRUNCATE64
194 constant  NR_FTRUNCATE64
195 constant  NR_STAT64
196 constant  NR_LSTAT64
197 constant  NR_FSTAT64
198 constant  NR_LCHOWN32
199 constant  NR_GETUID32
200 constant  NR_GETGID32
201 constant  NR_GETEUID32
202 constant  NR_GETEGID32
203 constant  NR_SETREUID32
204 constant  NR_SETREGID32
205 constant  NR_GETGROUPS32
206 constant  NR_SETGROUPS32
207 constant  NR_FCHOWN32
208 constant  NR_SETRESUID32
209 constant  NR_GETRESUID32
210 constant  NR_SETRESGID32
211 constant  NR_GETRESGID32
212 constant  NR_CHOWN32
213 constant  NR_SETUID32
214 constant  NR_SETGID32
215 constant  NR_SETFSUID32
216 constant  NR_SETFSGID32
217 constant  NR_PIVOT_ROOT
218 constant  NR_MINCORE
219 constant  NR_MADVISE
220 constant  NR_GETDENTS64
221 constant  NR_FCNTL64

224 constant  NR_GETTID
225 constant  NR_READAHEAD
226 constant  NR_SETXATTR
227 constant  NR_LSETXATTR
228 constant  NR_FSETXATTR
229 constant  NR_GETXATTR
230 constant  NR_LGETXATTR
231 constant  NR_FGETXATTR
232 constant  NR_LISTXATTR
233 constant  NR_LLISTXATTR
234 constant  NR_FLISTXATTR
235 constant  NR_REMOVEXATTR
236 constant  NR_LREMOVEXATTR
237 constant  NR_FREMOVEXATTR
238 constant  NR_TKILL
239 constant  NR_SENDFILE64
240 constant  NR_FUTEX
241 constant  NR_SCHED_SETAFFINITY
242 constant  NR_SCHED_GETAFFINITY
243 constant  NR_SET_THREAD_AREA
244 constant  NR_GET_THREAD_AREA
245 constant  NR_IO_SETUP
246 constant  NR_IO_DESTROY
247 constant  NR_IO_GETEVENTS
248 constant  NR_IO_SUBMIT
249 constant  NR_IO_CANCEL
250 constant  NR_FADVISE64

252 constant  NR_EXIT_GROUP
253 constant  NR_LOOKUP_DCOOKIE
254 constant  NR_EPOLL_CREATE
255 constant  NR_EPOLL_CTL
256 constant  NR_EPOLL_WAIT
257 constant  NR_REMAP_FILE_PAGES
258 constant  NR_SET_TID_ADDRESS
259 constant  NR_TIMER_CREATE
260 constant  NR_TIMER_SETTIME
261 constant  NR_TIMER_GETTIME
262 constant  NR_TIMER_GETOVERRUN
263 constant  NR_TIMER_DELETE
264 constant  NR_CLOCK_SETTIME
265 constant  NR_CLOCK_GETTIME
266 constant  NR_CLOCK_GETRES
267 constant  NR_CLOCK_NANOSLEEP
268 constant  NR_STATFS64
269 constant  NR_FSTATFS64
270 constant  NR_TGKILL
271 constant  NR_UTIMES
272 constant  NR_FADVISE64_64
273 constant  NR_VSERVER
274 constant  NR_MBIND
275 constant  NR_GET_MEMPOLICY
276 constant  NR_SET_MEMPOLICY
277 constant  NR_MQ_OPEN
278 constant  NR_MQ_UNLINK
279 constant  NR_MQ_TIMEDSEND
280 constant  NR_MQ_TIMEDRECEIVE
281 constant  NR_MQ_NOTIFY
282 constant  NR_MQ_GETSETATTR
283 constant  NR_KEXEC_LOAD
284 constant  NR_WAITID

286 constant  NR_ADD_KEY
287 constant  NR_REQUEST_KEY
288 constant  NR_KEYCTL
289 constant  NR_IOPRIO_SET
290 constant  NR_IOPRIO_GET
291 constant  NR_INOTIFY_INIT
292 constant  NR_INOTIFY_ADD_WATCH
293 constant  NR_INOTIFY_RM_WATCH
294 constant  NR_MIGRATE_PAGES
295 constant  NR_OPENAT
296 constant  NR_MKDIRAT
297 constant  NR_MKNODAT
298 constant  NR_FCHOWNAT
299 constant  NR_FUTIMESAT
300 constant  NR_FSTATAT64
301 constant  NR_UNLINKAT
302 constant  NR_RENAMEAT
303 constant  NR_LINKAT
304 constant  NR_SYMLINKAT
305 constant  NR_READLINKAT
306 constant  NR_FCHMODAT

[THEN]

: syscall0 0 swap syscall ;
: syscall1 1 swap syscall ;
: syscall2 2 swap syscall ;
: syscall3 3 swap syscall ;
: syscall4 4 swap syscall ;
: syscall5 5 swap syscall ;
: syscall6 6 swap syscall ;

create mmap_args 6 cells allot

: !-- ( n a1 -- a2 ) tuck ! 1 cells - ;  \ utility to fill structure

Public:

\   sysexit is NOT the recommended way to exit back to the 
\   system from Forth. It is provided here as a demo of a very 
\   simple syscall.
: sysexit ( ncode -- ) NR_EXIT syscall1 ;
: execve  ( afilename aargv aenvp -- n ) NR_EXECVE syscall3 ;
: reboot  ( nmagic nmagic2 ncmd aarg -- n ) NR_REBOOT syscall4 ;
: sync    ( -- n ) NR_SYNC syscall0 ;
: uname   ( abuf -- n )  NR_UNAME syscall1 ;
: sethostname ( aname nlen -- n ) NR_SETHOSTNAME syscall2 ;
: setdomainname ( aname nlen -- n ) NR_SETDOMAINNAME syscall2 ;
: syslog  ( ntype abufp nlen -- n ) NR_SYSLOG syscall3 ;
: uselib  ( alibrary -- n )  NR_USELIB syscall1 ;

32bit? [IF]
: socketcall ( ncall aargs -- n )  NR_SOCKETCALL syscall2 ;
[THEN]

\ File system handling
: mount   ( asrc atarget afilesystype umountflags adata -- n ) NR_MOUNT syscall5 ;

32bit? [IF]
: umount  ( atarget -- n ) NR_UMOUNT syscall1 ;
[THEN]
: umount2 ( atarget nflags -- n ) NR_UMOUNT2 syscall2 ;
: ustat   ( ndev aubuf -- n ) NR_USTAT syscall2 ;
: statfs  ( apath astatfsbuf -- n ) NR_STATFS syscall2 ;
: fstatfs ( fd astatfsbuf -- n ) NR_FSTATFS syscall2 ;
: swapon  ( apath nswapflags -- n )  NR_SWAPON syscall2 ;
: swapoff ( apath -- n )  NR_SWAPOFF syscall1 ;
 

\ System time calls
32bit? [IF]
: stime        ( atime -- n ) NR_STIME syscall1 ;
[THEN]
: time         ( atime -- ntime ) NR_TIME syscall1 ;
: nanosleep    ( areq arem -- n ) NR_NANOSLEEP syscall2 ;
: gettimeofday ( atimeval atimezone -- n )  NR_GETTIMEOFDAY syscall2 ;
: settimeofday ( atimeval atimezone -- n )  NR_SETTIMEOFDAY syscall2 ;

 
\ Process handling
0 constant P_ALL
1 constant P_PID
2 constant P_PGID

1 constant WNOHANG
2 constant WUNTRACED
2 constant WSTOPPED
4 constant WEXITED
8 constant WCONTINUED

: fork    ( -- pid ) NR_FORK syscall0 ;
: getpid  ( -- u | get process id ) NR_GETPID syscall0 ;
: waitid  ( idtype id asiginfo options -- n ) 
    NR_WAITID syscall4 ;
32bit? [IF]
: waitpid ( pid astatus noptions -- pid ) NR_WAITPID syscall3 ;
[THEN]
: ptrace  ( nrequest pid addr adata -- n ) NR_PTRACE syscall4 ;
: brk     ( addr -- n ) NR_BRK syscall1 ;
: acct    ( afilename -- n ) NR_ACCT syscall1 ;
: times   ( abuf -- n ) NR_TIMES syscall1 ;
: iopl    ( nlevel -- n ) NR_IOPL syscall1 ;
: kill    ( npid nsig -- n ) NR_KILL syscall2 ;
: chroot  ( apath -- n ) NR_CHROOT syscall1 ;
: ioperm  ( ufrom unum nturnon -- n ) NR_IOPERM syscall3 ;

32bit? [IF]
: nice ( ninc -- n ) NR_NICE syscall1 ;
[THEN]

: getpriority ( nwhich nwho -- n ) NR_GETPRIORITY syscall2 ;
: setpriority ( nwhich nwho nprio -- n ) NR_SETPRIORITY syscall3 ;
: setuid   ( nuid -- n ) NR_SETUID syscall1 ;
: getuid   ( -- nuid ) NR_GETUID syscall0 ;
: setgid   ( ngid -- n ) NR_SETGID syscall1 ;
: getgid   ( -- n ) NR_GETGID syscall0 ;
: geteuid  ( -- n ) NR_GETEUID syscall1 ;
: getegid  ( -- n ) NR_GETEGID syscall0 ;
: setpgid  ( npid npgid -- n ) NR_SETPGID syscall2 ;
: getppid  ( -- npid ) NR_GETPPID syscall0 ;
: getpgrp  ( -- npid ) NR_GETPGRP syscall0 ;
: setsid   ( -- npid ) NR_SETSID syscall0 ;
: setreuid ( nruid neuid -- n ) NR_SETREUID syscall2 ;
: setregid ( nrgid negid -- n ) NR_SETREGID syscall2 ;


\ Memory

\ system constants for mmap, msync, mlockall, mremap
\ from: /usr/include/bits/mman.h
 1  constant  PROT_READ   \ Page can be read
 2  constant  PROT_WRITE  \ Page can be written
 4  constant  PROT_EXEC   \ Page can be executed
 0  constant  PROT_NONE   \ Page can not be accessed
 
\ Sharing types
 1  constant  MAP_SHARED  \ Share changes
 2  constant  MAP_PRIVATE \ Changes are private
16  constant  MAP_FIXED   \ interpret address exactly
32  constant  MAP_ANONYMOUS  \ Don't use a file

\ Flags for msync
 1  constant  MS_ASYNC    \ Sync memory asynchronously
 4  constant  MS_SYNC     \ Synchronous memory sync.
 2  constant  MS_INVALIDATE  \ Invalidate the caches

\ Flags for mlockall
 1  constant  MCL_CURRENT  \ Lock all currently mapped pages
 2  constant  MCL_FUTURE   \ Locak all additions to address space

\ Flags for mremap
 1  constant  MREMAP_MAYMOVE
 2  constant  MREMAP_FIXED

32bit? [IF]

: mmap       ( addr  nlength  nprot  nflags  nfd  noffset -- n ) 
    mmap_args 5 cells +
    !--  \ offset
    !--  \ fd
    !--  \ flags
    !--  \ prot
    !--  \ length
    !    \ addr
    mmap_args NR_MMAP syscall1 ;

: mmap2      ( addr  nlength  nprot  nflags  nfd  noffset -- n )
    NR_MMAP2 syscall6 ;

[ELSE]

: mmap  ( addr nlength nprot nflags nfd noffset -- n )
    NR_MMAP syscall6 ;

[THEN]

: mprotect   ( addr nlen nprot -- n ) NR_MPROTECT syscall3 ;
: munmap     ( addr nlen -- n )  NR_MUNMAP syscall2 ;
: msync      ( addr nlen nflags -- n )  NR_MSYNC syscall3 ;
: mlock      ( addr nlen -- n )  NR_MLOCK syscall2 ;
: munlock    ( addr nlen -- n ) NR_MUNLOCK syscall2 ;
: mlockall   ( nflags -- n ) NR_MLOCKALL syscall1 ;
: munlockall ( -- n )  NR_MUNLOCKALL syscall0 ;
: mremap     ( aoldaddress noldsize nnewsize nflags -- anewmem ) 
    NR_MREMAP syscall4 ;


\ File i/o and handling

\ System constants for file i/o
\ Standard file descriptors from: /usr/include/unistd.h
 0  constant  STDIN_FILENO    \ Standard input
 1  constant  STDOUT_FILENO   \ Standard output
 2  constant  STDERR_FILENO   \ Standard error output

\ Values for "whence" argument to lseek
 0  constant  SEEK_SET        \ Seek from beginning of file
 1  constant  SEEK_CUR        \ Seek from current position
 2  constant  SEEK_END        \ Seek from end of file

\ Constants for open/fcntl, from: /usr/include/bits/fnctl.h
   3  constant  O_ACCMODE
   0  constant  O_RDONLY
   1  constant  O_WRONLY
   2  constant  O_RDWR
 100  constant  O_CREAT     \ not fcntl
 200  constant  O_EXCL      \ not fcntl
 400  constant  O_NOCTTY    \ not fcntl
1000  constant  O_TRUNC     \ not fcntl
2000  constant  O_APPEND
4000  constant  O_NONBLOCK
O_NONBLOCK  constant  O_NDELAY
4010000  constant  O_SYNC
O_SYNC constant  O_FSYNC
20000  constant  O_ASYNC

\ Values for the second argument to fcntl
 0  constant  F_DUPFD    \ Duplicate file descriptor.
 1  constant  F_GETFD    \ Get file descriptor flags.
 2  constant  F_SETFD    \ Set file descriptor flags.
 3  constant  F_GETFL    \ Get file status flags.
 4  constant  F_SETFL    \ Set file status flags.

[UNDEFINED] read  [IF] 
: read ( fd buf count -- n) NR_READ syscall3 ; [THEN]
[UNDEFINED] write [IF] 
: write ( fd buf count -- n) NR_WRITE syscall3 ; [THEN]

\ Change name of OPEN system call to sys_open to avoid name collision
\   with kForth's OPEN 
: sys_open ( addr  flags mode -- fd | file descriptor is returned)
	NR_OPEN syscall3 ;
[UNDEFINED] close [IF] 
: close ( fd -- flag )  NR_CLOSE syscall1 ; [THEN]
[UNDEFINED] lseek [IF] 
: lseek ( fd offs type -- offs ) NR_LSEEK syscall3 ; [THEN]

32bit? [IF]
: llseek ( fd offshigh offslow aresult nwhence -- n ) 
    NR_LLSEEK syscall5 ; [THEN]

[UNDEFINED] ioctl [IF] 
: ioctl ( fd  request argp -- error ) NR_IOCTL syscall3 ; [THEN]

: creat    ( apath mode -- n )        NR_CREAT  syscall2 ;
: link     ( aoldpath anewpath -- n ) NR_LINK   syscall2 ;
: unlink   ( apathname -- n )         NR_UNLINK syscall1 ;
: symlink  ( aoldpath anewpath -- n )  NR_SYMLINK syscall2 ;
: readlink ( apath abuf nbufsiz -- nsize )  NR_READLINK syscall3 ;

[UNDEFINED] chdir [IF] 
: chdir ( apath -- n ) NR_CHDIR syscall1 ; [THEN]
: fchdir ( fd -- n )  NR_FCHDIR syscall1 ;
: getcwd ( abuf nsize -- n ) NR_GETCWD syscall2 ;
\ Use getdents instead of readdir syscall
\ : readdir ( nfd adirp ucount -- n )  NR_READDIR syscall3 ;
: getdents ( fd adirp ncount -- n )  NR_GETDENTS syscall3 ;

: umask ( nmask -- n ) NR_UMASK syscall1 ;

: mknod ( apathname nmode ndev -- n ) NR_MKNOD syscall3 ;
: utime ( afilename atimes -- n ) NR_UTIME syscall2 ;

: chmod  ( apath nmode -- n ) NR_CHMOD syscall2 ;
: fchmod ( fd  nmode -- n )  NR_FCHMOD syscall2 ;

: chown  ( apath nowner ngroup -- n )  NR_CHOWN  syscall3 ;
: fchown ( fd  nowner  ngroup -- n )  NR_FCHOWN syscall3 ;
: lchown ( apath nowner ngroup -- n )  NR_LCHOWN syscall3 ;
: access ( apathname nmode -- n ) NR_ACCESS syscall2 ;

[UNDEFINED] fsync [IF] 
: fsync ( fd -- n )  NR_FSYNC syscall1 ; [THEN]
: fcntl ( fd ncmd arg -- n )  NR_FCNTL syscall3 ;
: flock ( fd nop -- n )  NR_FLOCK syscall2 ;
: stat  ( apath  astatbuf  -- n )  NR_STAT  syscall2 ;
: fstat ( fd astatbuf -- n )      NR_FSTAT syscall2 ;
: lstat ( apath  astatbuf  -- n )  NR_LSTAT syscall2 ;
: truncate ( apath  nlength -- n ) NR_TRUNCATE syscall2 ;
: ftruncate ( fd  nlength -- n )  NR_FTRUNCATE syscall2 ;

: rename ( aoldpath anewpath -- n ) NR_RENAME syscall2 ;
: mkdir  ( apathname nmode -- n )   NR_MKDIR  syscall2 ;
: rmdir  ( apathname -- n )         NR_RMDIR  syscall1 ;


: select ( nfds areadfds awritefds aexceptfds atimeout -- n ) 
    NR_SELECT syscall5 ;
: pipe ( afdarray -- n )  NR_PIPE syscall1 ;
 
\ dup and dup2 syscalls
: sys_dup ( oldfd -- n ) NR_DUP syscall1 ;
: sys_dup2 ( oldfd newfd -- n ) NR_DUP2 syscall2 ;


\ Signal handling system calls
: alarm       ( useconds -- u ) NR_ALARM syscall1 ;
: pause       ( -- n ) NR_PAUSE syscall0 ;

32bit? [IF]
: signal      ( nsignum ahandler -- n ) NR_SIGNAL syscall2 ;
: sigaction   ( nsignum asigact aoldact -- n ) NR_SIGACTION syscall3 ;
: sigsuspend  ( amask -- n ) NR_SIGSUSPEND syscall1 ;
: sigpending  ( aset -- n ) NR_SIGPENDING syscall1 ;
: sigprocmask ( nhow aset aoldset -- n ) NR_SIGPROCMASK syscall3 ;
[THEN]

: setitimer   ( nwhich anewval aoldval -- n ) NR_SETITIMER syscall3 ;
: getitimer   ( nwhich acurrval -- n ) NR_GETITIMER syscall2 ;


\ System resource 
: setrlimit ( nresource arlim -- n ) NR_SETRLIMIT syscall2 ;
: getrlimit ( nresource arlim -- n ) NR_GETRLIMIT syscall2 ;
: getrusage ( nwho ausage -- n )  NR_GETRUSAGE syscall2 ;

: getgroups ( nsize agidlist -- n )  NR_GETGROUPS syscall2 ;
: setgroups ( nsize agidlist -- n )  NR_SETGROUPS syscall2 ;

End-Module

BASE !

