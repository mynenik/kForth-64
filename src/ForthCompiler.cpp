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
#include <sstream>
#include <string>
#include <vector>
#include <stack>
using namespace std;

extern "C" {
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
}
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
extern void* GlobalFp;
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
  int CPP_evaluate();
  int CPP_refill();
  int CPP_find_name();
  int CPP_compilename();
  int CPP_compile_name_bc();
  int CPP_name_to_interpret();
  int CPP_execute();
  int CPP_dots();

  // Provided by vmc.c
  char* strupr (char*);
  char* ExtractName(char*, char*);
  int   isBaseDigit(char);
  int   IsFloat(char*, double*);
  int   C_parsename();
  int   C_numberquery();
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

// Recognizer translation table
byte** _translation_table  [8] [3] = {
//  post  comp  int      // use order in reference implementation
  { NULL, NULL, NULL },  // row 0: xt's for TRANSLATE-NAME
  { NULL, NULL, NULL },  // row 1: xt's for TRANSLATE-CELL 
  { NULL, NULL, NULL },  // row 2: xt's for TRANSLATE-DCELL
  { NULL, NULL, NULL },  // row 3: xt's for TRANSLATE-FLOAT
  { NULL, NULL, NULL },  // row 4: xt's for TRANSLATE-NONE
  { NULL, NULL, NULL },  // future use
  { NULL, NULL, NULL },  //  :
  { NULL, NULL, NULL }   //  :
};

// Arrays for use by TRANSLATE-XXX words, to isolate
// users from directly accessing the translation table
// instead of the standard interface.
byte** _translate_name  [3] = {NULL, NULL, NULL};
byte** _translate_cell  [3] = {NULL, NULL, NULL};
byte** _translate_dcell [3] = {NULL, NULL, NULL};
byte** _translate_float [3] = {NULL, NULL, NULL};
byte** _translate_none  [3] = {NULL, NULL, NULL};

// Possible semantics for _translate_name entries:
vector<byte>* p_sem_execute_up_to;
vector<byte>* p_sem_execute_name;
vector<byte>* p_sem_defer_name;
vector<byte>* p_sem_compile_nd;
vector<byte>* p_sem_compile_name;
vector<byte>* p_sem_undefined;

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

int InitNameTranslations ()
{
    p_sem_execute_name  = new vector<byte>; 
    p_sem_execute_up_to = new vector<byte>;
    p_sem_defer_name    = new vector<byte>;
    p_sem_compile_name  = new vector<byte>;
    p_sem_compile_nd    = new vector<byte>;
    p_sem_undefined     = new vector<byte>;

    char s[128];
    long int xt, offset;

    // Assume stack diagram for the semantics are ( nt -- )

    vector<byte>* pSaveOps = pCurrentOps;

    // Note we cannot use a string containing a :NONAME
    // definition, passed to EVALUATE to obtain the
    // name translation vectors (xt s) because INTERPRET
    // requires these vectors to function.

    pCurrentOps = p_sem_execute_name; // NAME>INTERPRET EXECUTE
    strcpy(s, "NAME>INTERPRET");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_compile_name_bc();
    pCurrentOps->push_back(OP_EXECUTE);
    pCurrentOps->push_back(OP_RET);

    pCurrentOps = p_sem_compile_name; // NAME>COMPILE EXECUTE
    strcpy(s, "NAME>COMPILE");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_compile_name_bc();
    pCurrentOps->push_back(OP_EXECUTE);
    pCurrentOps->push_back(OP_RET);
    
    pCurrentOps = p_sem_compile_nd;
    // MY-NAME offset + DUP @ prec_non_deferred OR SWAP ! ( -- nt)
    // p_sem_compile_name EXECUTE ( -- ) 
    strcpy(s, "MY-NAME");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_compile_name_bc();
    offset = (long int) (offsetof(struct WordListEntry, Precedence));
    pCurrentOps->push_back(OP_IVAL);
    OpsPushInt(offset);
    pCurrentOps->push_back(OP_ADD);
    pCurrentOps->push_back(OP_DUP);
    pCurrentOps->push_back(OP_SWFETCH);
    pCurrentOps->push_back(OP_IVAL);
    OpsPushInt(PRECEDENCE_NON_DEFERRED);
    pCurrentOps->push_back(OP_OR);
    pCurrentOps->push_back(OP_SWAP);
    pCurrentOps->push_back(OP_WSTORE);
    pCurrentOps->push_back(OP_ADDR);
    OpsPushInt( (long int) p_sem_compile_name );
    pCurrentOps->push_back(OP_EXECUTE);
    pCurrentOps->push_back(OP_RET);

    pCurrentOps = p_sem_defer_name;
    // COMPILE-NAME-BC
    strcpy(s, "COMPILE-NAME-BC");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_compile_name_bc();
    pCurrentOps->push_back(OP_RET);

    pCurrentOps = p_sem_undefined;
    pCurrentOps->push_back(OP_IVAL);
    OpsPushInt(-13);
    strcpy(s, "VMTHROW");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_compile_name_bc();
    pCurrentOps->push_back(OP_RET);
   
    pCurrentOps = p_sem_execute_up_to;
    pCurrentOps->push_back(OP_ADDR);
    OpsPushInt( ((long int) &pCurrentOps) );
    pCurrentOps->push_back(OP_AFETCH);
    pCurrentOps->push_back(OP_EXECUTE);
    pCurrentOps->push_back(OP_RET);

    pCurrentOps = pSaveOps;
    return 0;
}
//--------------------------------------------------------------- 

int InitTranslationTable()
{
    vector<byte>* pSaveOps = pCurrentOps;
    char s[128];
    byte** xt;

    // Construct byte code sequences and xt's for translation
    // This code is temporary working code; it needs factoring.

    InitNameTranslations();

    // TRANSLATE-CELL
    strcpy(s, "LITERAL");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_name_to_interpret();
    DROP
    xt = (byte**) TOS;
    _translation_table[1][0] = NULL; // Postponing
    _translation_table[1][1] = xt;   // State -1
    _translation_table[1][2] = xt;   // State  0

    // TRANSLATE-DCELL
    strcpy(s, "2LITERAL");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_name_to_interpret();
    DROP
    xt = (byte**) TOS;
    _translation_table[2][0] = NULL; // Postponing
    _translation_table[2][1] = xt;   // State -1
    _translation_table[2][2] = xt;   // State 0

    // TRANSLATE-FLOAT
    strcpy(s, "FLITERAL");
    PUSH_CSTRING(s);
    CPP_find_name();
    CPP_name_to_interpret();
    DROP
    xt = (byte**) TOS;
    _translation_table[3][0] = NULL; // Postponing
    _translation_table[3][1] = xt;   // State -1
    _translation_table[3][2] = xt;   // State  0

    // TRANSLATE-NONE
    _translation_table[4][0] = (byte**) p_sem_undefined;
    _translation_table[4][1] = (byte**) p_sem_undefined;
    _translation_table[4][2] = (byte**) p_sem_undefined;

    // Copy the first five rows of the translation table
    // to arrays for use by TRANSLATE-XXX words, for isolation
    int i;
    for (i=0; i<3; i++) _translate_name[i]  = _translation_table[0][i];
    for (i=0; i<3; i++) _translate_cell[i]  = _translation_table[1][i];
    for (i=0; i<3; i++) _translate_dcell[i] = _translation_table[2][i];
    for (i=0; i<3; i++) _translate_float[i] = _translation_table[3][i];
    for (i=0; i<3; i++) _translate_none[i]  = _translation_table[4][i];

    pCurrentOps = pSaveOps;
    return 0;
}
//----------------------------------------------------------------

extern "C" {

// NAME>EXECUTE ( nt -- xt-int xt-comp xt-post )
// Return execution semantics for interpretation state,
// compilation state, and for postponing.
int CPP_name_to_execute()
{
    DROP
    WordListEntry* nt = (WordListEntry*) TOS;
    long int xt;
    int prec = nt->Precedence & 3;  // four values: 0--3

    // INTERPRET (State 0)
    switch (prec) {
      case 0:                   // state 0, prec 0
        xt = (long int) p_sem_defer_name; // defer execution
        break;
      case IMMEDIATE:           // state 0, prec 1
        xt = (long int) p_sem_execute_name;  // execute word
        break;
      case NONDEFERRED:         // state 0, prec 2
        // no break
      case (IMMEDIATE + NONDEFERRED):  // state 0, prec 3
        xt = (long int) p_sem_execute_up_to; // execute deferred + current xt
        break;
    } // end switch precedence
    PUSH_ADDR( xt )
    
    // COMPILE (State -1)
    switch (prec) {
      case 0:
        xt = (long int) p_sem_compile_name;  // compile name into current def
        break;
      case IMMEDIATE:
      case (IMMEDIATE+NONDEFERRED):
        xt = (long int) p_sem_execute_name; // execute xt for name
        break;
      case NONDEFERRED:
        xt = (long int) p_sem_compile_nd; // compile a nondeferred word;
        break;                            // make new def nondeferred
    }
    PUSH_ADDR( xt )

    // POSTPONing
    PUSH_ADDR( NULL )

    return 0;
}

// TRANSLATE-NONE ( -- translate-none )
// Return the translation token TRANSLATE-NONE
int CPP_translate_none ()
{
    for (int i = 0; i < 3; i++)
      _translate_none[i] = _translation_table[4][i];
    PUSH_ADDR( (long int) _translate_none );
    return 0;
}

// TRANSLATE-NAME  ( -- translate-name )
// Return the translation token TRANSLATE-NAME
int CPP_translate_name ()
{
    for (int i=0; i < 3; i++)
      _translate_name[i] = _translation_table[0][i];
    PUSH_ADDR( (long int) _translate_name );
    return 0;
}

// TRANSLATE-CELL  ( -- translate-cell )
// Return the translation token TRANSLATE-CELL
int CPP_translate_cell ()
{
    for (int i=0; i < 3; i++)
      _translate_cell[i] = _translation_table[1][i];
    PUSH_ADDR( (long int) _translate_cell );
    return 0;
}

// TRANSLATE-DCELL ( -- translate-dcell )
// Return the translation token TRANSLATE-DCELL
int CPP_translate_dcell ()
{
    for (int i=0; i < 3; i++)
      _translate_dcell[i] = _translation_table[2][i];
    PUSH_ADDR( (long int) _translate_dcell );
    return 0;
}

// TRANSLATE-FLOAT ( -- translate-float )
// Return the translation token TRANSLATE-FLOAT
int CPP_translate_float ()
{
    for (int i=0; i < 3; i++)
      _translate_float[i] = _translation_table[3][i];
    PUSH_ADDR( (long int) _translate_float );
    return 0;
}

// REC-NONE  ( c-addr u -- translate-none )
// drop the string and return TRANSLATE-NONE
int CPP_rec_none()
{
    DROP
    DROP
    CPP_translate_none();
    return 0;
}

// REC-NAME  ( c-addr u -- nt translate-name | translate_none )
// Find the word name c-addr u in the search order. If found,
// return the name token, nt, and the translation token
// TRANSLATE-NAME; otherwise return TRANSLATE-NONE.
int CPP_rec_name ()
{
    CPP_find_name();  // Forth FIND-NAME
    DROP
    long int nt = (long int) TOS;
    if (nt) {
      UNDROP
      CPP_name_to_execute();
      DROP
      _translation_table[0][0] = (byte**) TOS;  // postponing (null for now)
      DROP
      _translation_table[0][1] = (byte**) TOS;  // compiling
      DROP
      _translation_table[0][2] = (byte**) TOS;  // interpreting
      PUSH_ADDR( nt )
      CPP_translate_name();
    }
    else {
      CPP_translate_none();
    }
    return 0;
}


// REC-NUMBER ( c-addr u -- x translate-cell )  or
//            ( c-addr u -- translate-none )
// Recognize a single cell number. If success, return
// the number and the translation token TRANSLATE-CELL;
// otherwise return TRANSLATE-NONE.
int CPP_rec_number ()
{
    unsigned long int unum;
    bool b = false;
    bool dcell = false;
    DROP
    unsigned int ulen = TOS;
    DROP
    char *pStr = (char*) TOS;
    char *pStartConv = (char*) TOS;
    char *endp;
    char base_pfx_char = 0;
    int  base_prev = Base;

    if (strchr("#$%", *pStr)) {
      switch (*pStr) {
        case '%':
	  Base = 2;
	  break;
        case '#':
	  Base = 10;
	  break;
	case '$':
	  Base = 16;
	  break;
      }
      base_pfx_char = *pStr;
      ++pStr; ++pStartConv;
    }

    int ucount = 0;
    if ((*pStr == '-') || isBaseDigit(*pStr)) {
      ++pStr;
      while ((isBaseDigit(*pStr)) && (ucount < 130)) {
	  ++pStr; ++ucount;
      }

      // Check for double length : must have both trailing decimal point
      // as last char, and base prefix char
      if ((*pStr == '.') && (base_pfx_char != 0)) {
	dcell = true;
	++pStr;
      }

      if (*pStr == 0) b = true;  // recognized a cell or double cell number
    }
      
    if (b) {
      if (dcell) {
	char s[136];
	--pStr;
        ulen = (int)(pStr - pStartConv);
	strncpy(s+1, pStartConv, ulen);
	*s = (char) ulen;
	s[ulen+1] = 0;
	PUSH_ADDR( (long int) s );
	C_numberquery();
	DROP
	CPP_translate_dcell();
      }
      else {
        unum = strtoul(pStartConv, &endp, Base);
        PUSH_IVAL( unum )
        CPP_translate_cell();
      }
    }
    else {
      CPP_translate_none();
    }
    Base = base_prev;
    return 0;
}


// REC-FLOAT ( c-addr u -- translate-float ) ( F: -- r ) or
//           ( c-addr u -- translate-none )   ( F: -- )
// Recognize the string as an LMI style floating point number;
// if success, return the translation token TRANSLATE-NUMBER 
// on the data stack and the fp number on the floating point
// stack; otherwise return TRANSLATE-NONE.
int CPP_rec_float ()
{
    char *p;
    bool b;
    double r;
    DROP
    // u = TOS;
    DROP
    p = (char*) TOS;
    b = IsFloat(p, &r);
    if (b) {
      // push converted fp onto fp stack
      *((double *) GlobalFp) = r;
      DEC_FSP
      CPP_translate_float();
    }
    else {
      CPP_translate_none();
    }
    return 0;
}


// INTERPRET ( -- )
// cf. Starting Forth, 2nd ed. pp 283--284.
int CPP_interpret ()
{
//   Return value:
//    0   no error
//    other --- see ForthCompiler.h

  int ecode = 0;
  vector<byte>* pOpCodes = pCurrentOps;
  long int xt;
#ifdef __FOO__
*pOutStream << "INTERPRET: pOpCodes = " << pOpCodes << endl;
#endif
  while (true) {
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

          int ulen;
          char WordToken[256];

          C_parsename();  // Forth PARSE-NAME
          if (*pTIB == ' ' || *pTIB == '\t') ++pTIB; // go past next ws char
          DROP
          ulen = (int) TOS;
          DROP
          strncpy( (char*) WordToken, (char*) TOS, (size_t) ulen );

          if (ulen) {  // parsed non-empty string
            WordToken[ulen] = (char) 0;
            strupr(WordToken);

	    // rec-forth : start of recognizer sequence
	    //
            PUSH_CSTRING( WordToken );
	    CPP_rec_name(); // REC-NAME
            DROP
	    if (TOS == (long int) _translate_none) {
              PUSH_CSTRING( WordToken );
	      CPP_rec_number();  // ( caddr u -- ) REC-NUMBER
	      DROP
	      if (TOS == (long int) _translate_none) {
                PUSH_CSTRING( WordToken );
	        CPP_rec_float();  // ( caddr u -- ) REC-FLOAT
		DROP
	      } // end if
            } // end if ; end of recognizer sequence

            xt = (long int) *((long int*)TOS + State + 2);
	    if (xt == (long int) p_sem_execute_up_to) {
	      CPP_compile_name_bc();
	      pCurrentOps->push_back(OP_RET);
	    }

	    PUSH_ADDR( xt );
	    ecode = CPP_execute();
	    if (ecode) {
	      *pOutStream << endl << WordToken << endl;
	      break;
	    }

	    if (xt == (long int) p_sem_execute_up_to) {
	      pOpCodes->clear();
	    }
	    if ((xt == (long int) p_sem_execute_up_to) ||
	        (xt == (long int) p_sem_execute_name)) pOpCodes = pCurrentOps;

          } // end if(ulen)
        } // end if (*pTIB ...
      } // end while
// end of line interpreter

      if (ecode) return ecode;

      // Execute remaining deferred ops
      if ((State == 0) && pOpCodes->size()) {
        // Execute the current line in interpretation state
        pOpCodes->push_back(OP_RET);
        if (debug) OutputForthByteCode (pOpCodes);
        xt = (unsigned long int) pOpCodes;
        PUSH_ADDR( xt );
        ecode = CPP_execute();
        pOpCodes->clear();
        if (ecode) break;
      }

    } // end while(TRUE)
    return ecode;
}
// end of INTERPRET


} // end extern "C"
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
//  vector<byte>* pSaveOps = pCurrentOps;
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
//  pCurrentOps = pSaveOps;
  return ecode;
}


