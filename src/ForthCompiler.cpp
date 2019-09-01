// ForthCompiler.cpp
//
// A compiler to generate kForth Byte Code (FBC) from expressions
//   or programs
//
// Copyright (c) 1998--2019 Krishna Myneni, 
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
using std::cout;
using std::endl;
using std::istream;
using std::ostream;
using std::ifstream;
using std::ofstream;
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "fbc.h"
#include <vector>
#include <stack>
using std::vector;
using std::stack;
#include "ForthCompiler.h"

const int IMMEDIATE   = PRECEDENCE_IMMEDIATE;
const int NONDEFERRED = PRECEDENCE_NON_DEFERRED;

#include "ForthWords.h"

size_t NUMBER_OF_INTRINSIC_WORDS =
   sizeof(ForthWords) / sizeof(ForthWords[0]);


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

  // Provided by vmc.c
  void strupr (char*);
  char* ExtractName(char*, char*);
  int   IsFloat(char*, double*);
  int   IsInt(char*, long int*);

}
  
// Provided by ForthVM.cpp
extern "C"  long int* GlobalSp;
extern "C"  long int* GlobalRp;
extern "C"  long int Base;
extern "C"  long int State;  // TRUE = compile, FALSE = interpret
extern "C"  char* pTIB; 
extern "C"  char TIB[];  // contains current line of input

// Provided by vm-common.s
extern "C"  long int JumpTable[];


// stacks for keeping track of nested control structures

vector<int> ifstack;	// stack for if-then constructs
vector<int> beginstack;	// stack for begin ... constructs
vector<int> whilestack;	// stack for while jump holders
vector<int> dostack;    // stack for do loops
vector<int> querydostack; // stack for conditional do loops
vector<int> leavestack; // stack for leave jumps
vector<int> recursestack; // stack for recursion
vector<int> casestack;  // stack for case jumps
vector<int> ofstack;   // stack for of...endof constructs

long int linecount;

// The global input and output streams

istream* pInStream ;
ostream* pOutStream ;

// Global ptr to current opcode vector

vector<byte>* pCurrentOps;

// The word currently being compiled (needs to be global)

WordListEntry* pNewWord;
//---------------------------------------------------------------


const char* C_ErrorMessages[] =
{
	"",
	"",
	"End of definition with no beginning",
	"End of string",	 
        "Not allowed inside colon definition",
	"Error opening file",
	"Incomplete IF...THEN structure",
	"Incomplete BEGIN structure",
	"Unknown word",
	"No matching DO",
	"Incomplete DO loop",
	"Incomplete CASE structure",
	"VM returned error"
};
//---------------------------------------------------------------

bool IsForthWord (char* name, WordListEntry* pE)
{
// Locate and Return a copy of the dictionary entry
//   with the specified name.  Return True if found,
//   False otherwise. A copy of the entry is returned
//   in *pE.
    WordListEntry* pWord = SearchOrder.LocateWord (name);
    bool b = (bool) pWord;
    if (b) *pE = *pWord;
    return( b );
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

void CompileWord (WordListEntry d)
{
  // Compile a word into the current opcode vector

  byte* bp;
  int wc = (d.WordCode >> 8) ? OP_CALLADDR : d.WordCode;
  pCurrentOps->push_back(wc);
  switch (wc) 
    {
    case OP_CALLADDR:
      bp = (byte*) d.Cfa;
      OpsPushInt(*((long int*)(bp+1)));
      break;

    case OP_PTR:
    case OP_ADDR:
      OpsPushInt((long int) d.Pfa);
      break;
	  
    case OP_DEFINITION:
      OpsPushInt((long int) d.Cfa);
      break;

    case OP_IVAL:
      OpsPushInt(*((long int*)d.Pfa));			
      break;

    case OP_2VAL:
      OpsPushInt(*((long int*)d.Pfa));
      OpsPushInt(*((long int*)d.Pfa + 1));
      break;

    case OP_FVAL:
      OpsPushDouble(*((double*) d.Pfa));
      break;

    default:
      ;
    }
}
//----------------------------------------------------------------

int ForthCompiler (vector<byte>* pOpCodes, long int* pLc)
{
// The FORTH Compiler
//
// Reads and compiles the source statements from the input stream
//   into a vector of byte codes.
//
// Return value:
//
//  0   no error
//  other --- see ForthCompiler.h

  int ecode = 0;
  char WordToken[256];
  double fval;
  int i, j;
  long int ival, *sp;
  vector<byte>::iterator ib1, ib2;
  WordListEntry d;
  byte opval, *ip, *tp;

  if (debug) cout << ">Compiler Sp: " << GlobalSp << " Rp: " << GlobalRp << endl;

  ip = (byte *) &ival;

  linecount = *pLc;
  pCurrentOps = pOpCodes;

  while (TRUE)
    {
      // Read each line and parse

      pInStream->getline(TIB, 255);
      if (debug) (*pOutStream) << TIB << endl;

      if (pInStream->fail())
	{
	  if (State)
	    {
	      ecode = E_C_ENDOFSTREAM;  // reached end of stream before end of definition
	      break;
	    }
	  break;    // end of stream reached
	}
      ++linecount;
      pTIB = TIB;
      while (*pTIB && (pTIB < (TIB + 255)))
	{
	  if (*pTIB == ' ' || *pTIB == '\t')
	    ++pTIB;

	  else
	   {
	      pTIB = ExtractName (pTIB, WordToken);
	      if (*pTIB == ' ' || *pTIB == '\t') ++pTIB; // go past next ws char
	      strupr(WordToken);

	      if (IsForthWord(WordToken, &d))
		{
		  CompileWord(d);		  

		  if (d.WordCode == OP_UNLOOP)
		    {
		      if (dostack.empty())
			{
			  ecode = E_C_NODO;
			  goto endcompile;
			}
		    }
		  else if (d.WordCode == OP_LOOP || d.WordCode == OP_PLUSLOOP)
		    {
		      if (dostack.empty())
			{
			  ecode = E_C_NODO;
			  goto endcompile;
			}
		      i = dostack[dostack.size() - 1];
		      if (leavestack.size())
			{
			  do
			    {
			      j = leavestack[leavestack.size() - 1];
			      if (j > i)
				{
				  ival = pOpCodes->size() - j + 1;
				  OpsCopyInt(j, ival); // write relative jump count
				  leavestack.pop_back();
				}
			    } while ((j > i) && (leavestack.size())) ;
			}
		      dostack.pop_back();
		      if (querydostack.size())
			{
			  j = querydostack[querydostack.size() - 1];
			  if (j >= i)
			    {
			      CPP_then();
			      querydostack.pop_back();
			    }
			}
		    }
		  else
		    {
		      ;
		    }

		  int execution_method = EXECUTE_NONE;

		  switch (d.Precedence)
		    {
		      case IMMEDIATE:
			execution_method = EXECUTE_CURRENT_ONLY;
			break;
		      case NONDEFERRED:
			if (State)
			  pNewWord->Precedence |= NONDEFERRED ;
			else
			  execution_method = EXECUTE_UP_TO;
			break;
		      case (NONDEFERRED + IMMEDIATE):
			execution_method = State ? EXECUTE_CURRENT_ONLY :
			  EXECUTE_UP_TO;
			break;
		      default:
			;
		    }

		  vector<byte> SingleOp;
		  
		  switch (execution_method)
		    {
		    case EXECUTE_UP_TO:
		      // Execute the opcode vector immediately up to and
		      //   including the current opcode

		      pOpCodes->push_back(OP_RET);
		      if (debug) OutputForthByteCode (pOpCodes);
		      ecode = ForthVM (pOpCodes, &sp, &tp);
		      pOpCodes->erase(pOpCodes->begin(), pOpCodes->end());
		      if (ecode) goto endcompile; 
		      break;

		    case EXECUTE_CURRENT_ONLY:
		      i = ((d.WordCode == OP_DEFINITION) || (d.WordCode == OP_IVAL) || 
			   (d.WordCode >> 8)) ? WSIZE+1 : 1; 
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
		    }

		}  // end if (IsForthWord())

	      else if (IsInt(WordToken, &ival))
		{
		  pOpCodes->push_back(OP_IVAL);
		  OpsPushInt(ival);
		}
	      else if (IsFloat(WordToken, &fval))
		{
		  pOpCodes->push_back(OP_FVAL);
		  OpsPushDouble(fval);
		}
	      else
		{
		  *pOutStream << endl << WordToken << endl;
		  ecode = E_C_UNKNOWNWORD;  // unknown keyword
		  goto endcompile;
		}
	     }
	} // end while (*pTIB ...)
	
      if ((State == 0) && pOpCodes->size())
	{
	  // Execute the current line in interpretation state
	  pOpCodes->push_back(OP_RET);
	  if (debug) OutputForthByteCode (pOpCodes);
	  ecode = ForthVM (pOpCodes, &sp, &tp);
	  pOpCodes->erase(pOpCodes->begin(), pOpCodes->end());
	  if (ecode) goto endcompile; 
	}

    } // end while (TRUE)

endcompile:
  
  if ((ecode != E_C_NOERROR) && (ecode != E_C_ENDOFSTREAM))
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


