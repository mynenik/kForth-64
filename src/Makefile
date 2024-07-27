#
# Makefile for kForth-64
#
# Copyright (c) 1998--2024 Krishna Myneni, 
#   <krishna.myneni@ccreweb.org>
#
# This software is provided under the terms of the GNU 
# Affero General Public License (AGPL), v3.0 or later.
#
# Possible invocations:
#
#	make		creates dynamically linked release executable
#	make clean	remove all object files belonging to this project
#	make debug	create statically linked debug executable
#	make archive	create a compressed tar file (for release)
#       make snapshot   create a development snapshot
#
# Notes:
#
#   1. If a debug version is being built, always invoke "make clean" 
#      before "make debug".
#
#
# Default debug option creates a release version of the executable.
# Invoke "make debug" if you want to create an executable
# that contains debugging information for the GNU debugger (gdb).

VERSION = 0.5.0
DEF_DIR_VAR=KFORTH_DIR
BUILD_DATE=`date +%F`
DEBUG = 
TARGET_CPU = x86_64
TARGET_OS  = linux

# location of gcc and g++
GCCDIR = /usr/bin

# library path
LIBPATH = /usr/lib:/usr/lib32

CPP = ${GCCDIR}/g++
CC  = ${GCCDIR}/gcc
CPPFLAGS = -c -fpie -Wall
CFLAGS = -c -fpie -Wall
FAST = -D__FAST__
NOFPSTACK =
OBJS = kforth.o ForthVM.o ForthCompiler.o vm64.o vmc.o
FOBJS = kforth-fast.o ForthVM-fast.o ForthCompiler-fast.o vm64-fast.o vmc-fast.o
# LIBS = -pie -lreadline -lncurses -ldl -lm
# LIBS = -pie -lreadline -ldl -lm
LIBS = -pie -lreadline -ltinfo -ldl -lm

all:	
	make kforth64
#	make kforth64-fast


kforth64: ${OBJS} 
	${CPP} -o kforth64 ${DEBUG} ${OBJS} -L${LIBPATH} ${LIBS}

kforth64-fast: ${FOBJS}
	${CPP} -o kforth64-fast ${DEBUG} ${FOBJS} -L${LIBPATH} ${LIBS}

clean:
	- rm -f ${OBJS} ${FOBJS} kforth64 kforth64-fast


debug:
	make kforth64 "DEBUG = -g"

kforth.o: kforth.cpp ForthVM.h ForthCompiler.h VMerrors.h
	${CPP} ${CPPFLAGS} ${DEBUG} -DVERSION=\"${VERSION}\" \
	-DBUILD_DATE=\"${BUILD_DATE}\" kforth.cpp

kforth-fast.o: kforth.cpp ForthVM.h ForthCompiler.h VMerrors.h
	${CPP} ${CPPFLAGS} ${DEBUG} -DVERSION=\"${VERSION}\" \
	-DBUILD_DATE=\"${BUILD_DATE}\" ${FAST} -o kforth-fast.o kforth.cpp

ForthCompiler.o: ForthCompiler.cpp ForthCompiler.h fbc.h ForthWords.h \
	VMerrors.h kfmacros.h
	${CPP} ${CPPFLAGS} ${DEBUG} ForthCompiler.cpp

ForthCompiler-fast.o: ForthCompiler.cpp ForthCompiler.h fbc.h ForthWords.h \
	VMerrors.h kfmacros.h
	${CPP} ${CPPFLAGS} ${DEBUG} ${FAST} ForthCompiler.cpp

ForthVM.o: ForthVM.cpp ForthVM.h fbc.h ForthCompiler.h VMerrors.h kfmacros.h
	${CPP} ${CPPFLAGS} -DDIR_ENV_VAR=\"${DEF_DIR_VAR}\" \
        ${DEBUG} ForthVM.cpp

ForthVM-fast.o: ForthVM.cpp ForthVM.h fbc.h ForthCompiler.h VMerrors.h kfmacros.h
	${CPP} ${CPPFLAGS} -DDIR_ENV_VAR=\"${DEF_DIR_VAR}\" \
        ${DEBUG} ${FAST} -o ForthVM-fast.o ForthVM.cpp

vmc.o: vmc.c kfmacros.h
	${CC} ${CFLAGS} ${DEBUG} vmc.c

vmc-fast.o: vmc.c kfmacros.h
	${CC} ${CFLAGS} ${DEBUG} ${FAST} -o vmc-fast.o vmc.c

vm64.o: vm64.s vm64-common.s
	as -o vm64.o vm64.s

vm64-fast.o: vm64-fast.s vm64-common.s
	as -o vm64-fast.o vm64-fast.s

# end of makefile

