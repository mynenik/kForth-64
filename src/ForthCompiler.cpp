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
// Locate and Return a copy of the dictionary entry
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
// tbd: this should return the execution semantics for a
// recognized name, based on STATE and precedence. Presently
// compilation is assumed as part of the execution semantics.
int ExecutionMethod (int Precedence)
{
    // Return execution method for a word, based on its Precedence and STATE

    int ex = EXECUTE_NONE;

    switch (Precedence)
    {
      case IMMEDIATE:
        ex = EXECUTE_CURRENT_ONLY;
	break;
      case NONDEFERRED:
        if (State) {
          if (pNewWord) pNewWord->Precedence |= NONDEFERRED ;
        }
	else
          ex = EXECUTE_UP_TO;
        break;
      case (NONDEFERRED + IMMEDIATE):
        ex = State ? EXECUTE_CURRENT_ONLY : EXECUTE_UP_TO;
        break;
      default:
        ;
    }
    return( ex );
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

// int ecode = CPP_interpret();  <== uncomment this line

// tbd: factor INTERPRET
//
// INTERPRET ( -- )
// cf. Starting Forth, 2nd ed. pp 283--284.
// int CPP_interpret ()
// {
//   Return value:
//    0   no error
//    other --- see ForthCompiler.h

  int ecode = 0;
  long int *sp;
  byte *tp;

  while (TRUE) {
    // Read from input stream and parse
    pInStream->getline(TIB, 255);
    if (debug) (*pOutStream) << linecount << ": " << TIB << endl;

    if (pInStream->fail()) {
      if (State) {
        ecode = E_V_END_OF_STREAM;  // end of stream before end of definition
	break;
      }
      break;    // end of stream reached
    }
    ++linecount;

// start of line interpreter:

      pTIB = TIB;

      while (*pTIB && (pTIB < (TIB + 255))) {
        if (*pTIB == ' ' || *pTIB == '\t') 
	  ++pTIB;
        else {

          int i, j, ulen;
          unsigned long int nt;
          long int ival;
          double fval;
          char WordToken[256];

          // tbd: use PARSE-NAME here
          // pTIB = ExtractName (pTIB, WordToken);
          // if (*pTIB == ' ' || *pTIB == '\t') ++pTIB; // go past next ws char
          // ulen = strlen(WordToken);

          C_parsename();  // Forth PARSE-NAME
          if (*pTIB == ' ' || *pTIB == '\t') ++pTIB; // go past next ws char
          DROP
          ulen = (int) TOS;
          DROP
          strncpy( (char*) WordToken, (char*) TOS, (size_t) ulen );

          if (ulen) {  // parsed non-empty string
	    WordToken[ulen] = (char) 0;
	    strupr(WordToken);

	    // name recognizer

	    PUSH_ADDR( (unsigned long int) WordToken );
	    PUSH_IVAL( (long int) ulen );
            CPP_find_name();  // Forth FIND-NAME
	    DROP
	    nt = (unsigned long int) TOS;

	    if (nt) {
    
	      // tbd: move compilation to section
	      // Perform execution semantics
              //   PUSH_ADDR((long int) pWord)  
	      //	  CPP_compile_to_current();
	      PUSH_ADDR( nt );
	      CPP_compile_to_current();

	      WordListEntry* pWord = (WordListEntry*) nt;
	      int ex_meth = ExecutionMethod((int) pWord->Precedence);
	      vector<byte> SingleOp;
	      vector<byte>::iterator ib1;
  
	      switch (ex_meth) {  // Perform execution semantics
	        case EXECUTE_UP_TO:
	          // Execute the opcode vector immediately up to and
	          //   including the current opcode
	          pOpCodes->push_back(OP_RET);
	          if (debug) OutputForthByteCode (pOpCodes);
	          ecode = ForthVM (pOpCodes, &sp, &tp);
	          pOpCodes->erase(pOpCodes->begin(), pOpCodes->end());
	          if (ecode) goto endcompile;
                  pOpCodes = pCurrentOps;
	          break;

	        case EXECUTE_CURRENT_ONLY:
	          i = ((pWord->WordCode == OP_DEFINITION) || 
	               (pWord->WordCode == OP_IVAL) || 
	               (pWord->WordCode == OP_ADDR) || 
	               (pWord->WordCode >> 8)) ? WSIZE+1 : 1; 
	          ib1 = pOpCodes->end() - i;
	          for (j = 0; j < i; j++) SingleOp.push_back(*(ib1+j));
	          SingleOp.push_back(OP_RET);
	          pOpCodes->erase(ib1, pOpCodes->end());
	          ecode = ForthVM (&SingleOp, &sp, &tp);
	          SingleOp.erase(SingleOp.begin(), SingleOp.end());
	          if (ecode) goto endcompile; 
	          pOpCodes = pCurrentOps; // may have been redirected
	          break;

	        default:
	          ;
	      } // end switch(ex_meth)
	    }
	    else if (IsInt(WordToken, &ival)) {  // number recognizer
	      pOpCodes->push_back(OP_IVAL);
	      OpsPushInt(ival);
	    }
	    else if (IsFloat(WordToken, &fval)) {  // fp number recognizer
	      pOpCodes->push_back(OP_FVAL);
	      OpsPushDouble(fval);
	    }
	    else { // did not recognize token (rec-none)
	      *pOutStream << endl << WordToken << endl;
	      ecode = E_V_UNDEFINED_WORD;
	      goto endcompile; // <== change to return ecode;
	    } // end if(nt)
          } // end if(ulen)
        } // end if (*pTIB ...
      } // end while
// end of line interpreter

      if ((State == 0) && pOpCodes->size()) {
	// Execute the current line in interpretation state
	pOpCodes->push_back(OP_RET);
	if (debug) OutputForthByteCode (pOpCodes);
	ecode = ForthVM (pOpCodes, &sp, &tp);
	pOpCodes->erase(pOpCodes->begin(), pOpCodes->end());
	if (ecode) goto endcompile; // <== change to break;
      }

    } // end while(TRUE)
// return ecode;   <== uncomment this line
// }  <== uncomment this line
// end of INTERPRET

endcompile:
  
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


