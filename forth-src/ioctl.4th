\ ioctl.4th
\
\ Ported from Linux 2.6.x, /usr/include/asm-i386/ioctl.h 
\ (for use in Forth interfaces to device drivers)
\
\ K. Myneni, 2006-08-09
\
\ Revisions:
\
 8  constant  IOC_NRBITS
 8  constant  IOC_TYPEBITS
14  constant  IOC_SIZEBITS
 2  constant  IOC_DIRBITS

1 IOC_NRBITS    LSHIFT 1-  constant  IOC_NRMASK
1 IOC_TYPEBITS  LSHIFT 1-  constant  IOC_TYPEMASK
1 IOC_SIZEBITS  LSHIFT 1-  constant  IOC_SIZEMASK
1 IOC_DIRBITS   LSHIFT 1-  constant  IOC_DIRMASK

                           0 constant IOC_NRSHIFT
IOC_NRSHIFT   IOC_NRBITS   + constant IOC_TYPESHIFT
IOC_TYPESHIFT IOC_TYPEBITS + constant IOC_SIZESHIFT
IOC_SIZESHIFT IOC_SIZEBITS + constant IOC_DIRSHIFT

\ Direction bits
0 constant IOC_NONE
1 constant IOC_WRITE
2 constant IOC_READ

: _IOC ( dir type nr size -- u )
    IOC_SIZESHIFT lshift swap
    IOC_NRSHIFT   lshift OR swap
    IOC_TYPESHIFT lshift OR swap
    IOC_DIRSHIFT  lshift OR
;

: _IO ( type nr -- u ) IOC_NONE -rot 0 _IOC ;

: _IOR ( type nr size -- u ) >r IOC_READ -rot r> _IOC ;

: _IOW ( type nr size -- u ) >r IOC_WRITE -rot r> _IOC ;

: _IOWR ( type nr size -- u ) >r IOC_READ IOC_WRITE or -rot r> _IOC ;

