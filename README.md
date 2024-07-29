# kForth-64
64-bit Forth System for x86_64-GNU/Linux

Copyright &copy; 1998--2024 Krishna Myneni, <krishna.myneni@ccreweb.org>

### Contributors:

*  David P. Wallace
*  Matthias Urlichs
*  Guido Draheim
*  Brad Knotwell
*  Alaric B. Snell
*  Todd Nathan
*  Bdale Garbee
*  Christopher M. Brannon
*  David N. Williams
*  Iruatã M. S. Souza

## LICENSE

kForth-64 for x86_64-GNU/Linux is provided under the terms of the GNU
Affero General Public License (AGPL), v3.0 or later.


## INSTALLATION 

The following packages are required to build and maintain kForth-64 from
its source package, on a GNU/Linux system:

    binutils
    gcc
    gcc-c++
    glibc
    glibc-devel
    libstdc++-devel
    make
    readline
    readline-devel
    patchutils

Some or all of these packages may already be installed on your GNU/Linux
system, but if they are not, you should install them for your GNU/Linux
distribution. GNU C/C++ version 4.0 or later is recommended.

To build:

1. Unpack the files if you obtained them as a `.zip` or `.tar.gz` file.

2. Change to the `kForth-64-branch/src/` directory, where "branch" is the project
   branch, e.g. `master`, and type `make` to build the executables. A successful
   build results in two executables, `kforth64` and `kforth64-fast`.

3. Move the executables into the search path. It is recommended to move
   the kForth-64 executables to `/usr/local/bin` . You must have root privileges to do this.

4. Specify the default directory in which kforth64 will search for Forth source
   files not found in the current directory. The environment variable `KFORTH_DIR`
   may be set to this directory. For example, under the BASH shell, if you want
   the default directory to be your `~/kForth-64-branch/forth-src/` directory, add the
   following lines to your `.bash_profile` file (or `.profile` on some systems):

           KFORTH_DIR=~/kForth-64-branch/forth-src
           export KFORTH_DIR

## Forth Source Examples

Sample source code files, typically with the extension `.4th`, are
included in the `kForth-64-branch/forth-src/` directory. These files serve as
programming examples for kForth-64, in addition to providing useful
libraries of Forth words and applications written in Forth. Within the
`forth-src/` subdirectory, you will find additional subdirectories containing
different categories of Forth libraries or applications. These include:

`system-test/`     A set of automated tests to validate the Forth system against
                   the Forth-2012 standard

`fsl/`             modules for numeric computation from the Forth Scientific Library, including test code

`games/`           console games written in Forth

`libs/`            Forth interfaces to C shared object libraries, such as the
                   GNU Multiprecision Library, gmp, and the GNU Multiprecision
                   Floating-Point Library, mpfr.

`benchmarks/`      simple benchmarks to compare the relative speed of Forth systems


Important system-level files in the `forth-src/` subdirectory include,

* `ans-words.4th`   Forth-94 words provided in source form
* `strings.4th`     String handling library
* `files.4th`       Standard Forth words for file i/o
* `ansi.4th`        ANSI terminal control
* `dump.4th`        Forth `DUMP` utility
* `ssd.4th`         Forth `SEE` utility
* `modules.4th`     A framework for modular programming in Forth
* `serial.4th`      Low-level serial port interface
* `syscalls.4th`    Operating System calls
* `signal.4th`      Signals interface (see `signals-ex.4th` and `sigfpe.4th`)
* `socket.4th`      Sockets interface
* `lib-interface.4th` Interface to shared object libraries.
* `ttester.4th`     Test harness used by the automated test code

## Documentation

The current version of the kForth-64 User's Guide is located in `doc/`. A copy of the Forth-2012 standards document is also provided here. Please note important differences between kForth-64 and Forth-2012, discussed in section 4 of the User's Guide.

The portable modular programming framework documentation is provided in `doc/`.

