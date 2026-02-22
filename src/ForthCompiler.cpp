// ForthCompiler.cpp
//
// A compiler to generate kForth Byte Code (FBC) from expressions
//   or programs
//
// Copyright (c) 1998--2026 Krishna Myneni, 
// <krishna.myneni@ccreweb.org>
//
// Contributors:
//
//   David P. Wallace
//   Brad Knotwell
//   David N. Williams
//
// This software is provided under the terms of the GNU
// Affero General Public License (AGPL), v 3.0 or later.
//
#include <iostream>
#include <fstream>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <vector>
#include <stack>
using namespace std;
#include "fbc.h"
#include "ForthCompiler.h"
#include "VMerrors.h"
#include "kfmacros.h"

const int IMMEDIATE   = PRECEDENCE_IMMEDIATE;
const int NONDEFERRED = PRECEDENCE_NON_DEFERRED;

#include "ForthWords.h"

size_t NUMBER_OF_INTRINSIC_WORDS =
   sizeof(ForthWords) / sizeof(ForthWords[0]);
size_t NUMBER_OF_ROOT_WORDS =
   sizeof(RootWords) / sizeof(RootWords[0]);

extern bool debug;

// Provided by ForthVM.cpp

extern vector<char*> StringTable;
extern SearchList SearchOrder;
void ClearControlStacks();
void OpsCopyInt (long int, long int);
void OpsPushInt (long int);
void OpsPushTwoInt (long int, long int);
void OpsPushDouble (double);
void PrintVM_Error (int);
int ForthVM (vector<byte>*, long int**, byte**);
void RemoveLastWord();

extern "C" {

  // Provided by ForthVM.cpp

  int CPP_then();
  int CPP_immediate();
  int CPP_nondeferred();
  int CPP_source();
  int CPP_refill();
  int CPP_find_name();
  int CPP_compilename();
  int CPP_compile_to_current();
  int CPP_dots();
  int CPP_interpret();

  // Provided by vmc.c
  char* strupr (char*);
  char* ExtractName(char*, char*);
  int   IsFloat(char*, double*);
  int   IsInt(char*, long int*);
  int   C_parsename();
}
  
// Provided by ForthVM.cpp
extern "C"  long int* GlobalSp;
extern "C"  long int* GlobalRp;
#ifndef __NO_FPSTACK__
extern "C"  void* GlobalFsp;
#endif
extern "C"  long int Base;
extern "C"  long int State;  // TRUE = compile, FALSE = interpret
#ifndef __NO_FPSTACK__
extern "C"  long int FpSize;
#endif
extern "C"  char* pTIB; 
extern "C"  char TIB[];  // contains current line of input
#ifndef __FAST__
extern "C"  byte*     GlobalTp;
#endif

// Provided by vm-common.s
extern "C"  long int JumpTable[];


// stacks for keeping track of nested control structures

stack<int> ifstack;	// stack for if-then constructs
stack<int> beginstack;	// stack for begin ... constructs
stack<int> whilestack;	// stack for while jump holders
stack<int> dostack;    // stack for do loops
stack<int> querydostack; // stack for conditional do loops
stack<int> leavestack; // stack for leave jumps
stack<int> recursestack; // stack for recursion
stack<int> casestack;  // stack for case jumps
stack<int> ofstack;   // stack for of...endof constructs

stack<WordListEntry*> PendingDefStack;
stack<vector<byte>*> PendingOps;
WordListEntry* pNewWord;   // current definition (word or anonymous)
vector<byte>* pCurrentOps; // current opcode vector

long int linecount;

// The global input and output streams

istream* pInStream ;
ostream* pOutStream ;

//---------------------------------------------------------------

WordListEntry* IsForthWord (char* name)
{
// Locate and return a copy of the dictionary entry
//   with the specified name.  Return True if found,
//   False otherwise. A copy of the entry is returned
//   in *pE.
    WordListEntry* pWord = SearchOrder.LocateWord (name);
    return( pWord );
}
//---------------------------------------------------------------

void OutputForthByteCode (vector<byte>* pFBC)
{
// Output opcode vector to an output stream for use in
//   debugging the compiler.

    int i, n = pFBC->size();
    byte* bp = (byte*) &(*pFBC)[0]; // ->begin();

    *pOutStream << "\nOpcodes:\n";
    for (i = 0; i < n; i++)
    {
        *pOutStream << ((int) *bp) << ' ';
        if (((i + 1) % 8) == 0) *pOutStream << '\n';
        ++bp;
    }
    *pOutStream << '\n';
    return;
}
//---------------------------------------------------------------

void SetForthInputStream (istream& SourceStream)
{
  // Set the input stream for the Forth Compiler and Virtual Machine

  pInStream = &SourceStream;
}
//--------------------------------------------------------------

void SetForthOutputStream (ostream& OutStream)
{
  // Set the output stream for the Forth Compiler and Virtual Machine

  pOutStream = &OutStream;
}
//---------------------------------------------------------------
// Return an ID for execution semantics of a recognized name, 
// based on STATE and the word's precedence (for single xt systems).

int GetExecutionSemantics (WordListEntry* nt)
{
    int sem_id = -1;
    if ((State & 1) == 0) {
      // INTERPRET
      switch (nt->Precedence) {
        case 0:                    // state 0, prec 0
          sem_id = ID_SEM_COMPILE; // compile, defer execution
          break;
        case IMMEDIATE:           // state 0, prec 1
          sem_id = ID_SEM_EXECUTE_NAME;  // execute xt for name
	  break;
	case NONDEFERRED:         // state 0, prec 2
	  // no break
	case (IMMEDIATE + NONDEFERRED): // state 0, prec 3
          sem_id = ID_SEM_EXECUTE_ALL;  // execute deferred + current xt
	  break;
	default:
	  sem_id = -1;  // unrecognized semantics
	  break;
	} // end switch precedence
    }
    else {  
      // COMPILE
      switch (nt->Precedence) {
        case 0:
          sem_id = ID_SEM_COMPILE_NAME;  // compile name into current def
          break;
	case IMMEDIATE:
	case (IMMEDIATE+NONDEFERRED):
          sem_id = ID_SEM_EXECUTE_NAME;  // execute xt for name
	  break;
	case NONDEFERRED:
	  sem_id = ID_SEM_COMPILE_ND;   // compile a nondeferred word;
	  break;                        // make new def nondeferred
        default:
          sem_id = -1;  // unrecognized
          break;
      } // end switch(nt->Precedence)
    } // end if (State & 1)

    return( sem_id );
}
//----------------------------------------------------------------

int ForthCompiler (vector<byte>* pOpCodes, long int* pLc)
{
// The FORTH Compiler
//
// Execute the interpreter, initializing the global
// pointers to the current opcodes and the line count.
//
  if (debug) cout << ">Compiler Sp: " << GlobalSp << " Rp: " << GlobalRp << endl;

  linecount = *pLc;
  pCurrentOps = pOpCodes;

  int ecode = CPP_interpret();
  
  if ((ecode != E_V_NOERROR) && (ecode != E_V_END_OF_STREAM))
    {
      // A compiler or vm error occurred; reset to interpreter mode and
      //   clear all flow control stacks.
      State = FALSE;
      ClearControlStacks();
    }
  if (debug) 
    {
      *pOutStream << "Error: " << ecode << " State: " << State << endl;
      *pOutStream << "<Compiler Sp: " << GlobalSp << " Rp: " << GlobalRp << endl;
    }
  *pLc = linecount;
  return ecode;
}


