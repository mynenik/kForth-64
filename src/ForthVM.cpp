// ForthVM.cpp
//
// The C++ portion of the kForth Virtual Machine to 
// execute Forth byte code.
//
// Copyright (c) 1996--2024 Krishna Myneni,
//   <krishna.myneni@ccreweb.org>
//
// This software is provided under the terms of the GNU
// Affero General Public License, (AGPL), v3.0 or later.

const char* dir_env_var=DIR_ENV_VAR;

#include <string.h>
#include <stddef.h>
#include <stdlib.h>
#include <math.h>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <vector>
#include <stack>
using namespace std;

#include "fbc.h"
#include "ForthCompiler.h"
#include "ForthVM.h"
#include "VMerrors.h"
#include "kfmacros.h"

#define STACK_SIZE 32768
#define RETURN_STACK_SIZE 4096
#ifndef __NO_FPSTACK__
#define FP_STACK_SIZE 16384
#endif

extern bool debug;

// Provided by ForthCompiler.cpp

extern WordTemplate RootWords[];
extern WordTemplate ForthWords[];
extern const char* C_ErrorMessages[];
extern long int linecount;
extern istream* pInStream ;    // global input stream
extern ostream* pOutStream ;   // global output stream
extern stack<int> ifstack;
extern stack<int> beginstack;
extern stack<int> whilestack;
extern stack<int> dostack;
extern stack<int> querydostack;
extern stack<int> leavestack;
extern stack<int> recursestack;
extern stack<int> casestack;
extern stack<int> ofstack;
extern stack<WordListEntry*> PendingDefStack;
extern stack<vector<byte>*> PendingOps;
extern WordListEntry* pNewWord;
extern vector<byte>* pCurrentOps;

extern size_t NUMBER_OF_INTRINSIC_WORDS;

extern "C" {

  // functions provided by vmc.c

  void  set_start_time(void);
  void  save_term(void);
  void  restore_term(void);
  void  strupr (char*);
  char* ExtractName(char*, char*);
  int   IsFloat(char*, double*);
  int   IsInt(char*, int*);
  int   isBaseDigit(int);
  int   C_bracketsharp(void);
  int   C_sharps(void);
  int   C_sharpbracket(void);
  int   C_word(void);

  // vm functions provided by vm.s/vm-fast.s

  int L_initfpu();
  int L_depth();
#ifndef __NO_FPSTACK__
  int L_fdepth();
#endif
  int L_abort();
  int L_ret();
  int L_dabs();
  int vm (byte*);     // the machine code virtual machine

  // global pointers exported to other modules

  long int* GlobalSp;  // the typed global stack pointer
#ifndef __NO_FPSTACK__
  void* GlobalFp;      // the untyped floating point stack pointer
#endif
  byte* GlobalIp;      // the global instruction pointer
  long int* GlobalRp;      // the global return stack pointer
  long int* BottomOfStack;
  long int* BottomOfReturnStack;
#ifndef __NO_FPSTACK__
  void* BottomOfFpStack;
#endif

#ifndef __FAST__
  byte* GlobalTp;     // the global type stack pointer
  byte* GlobalRtp;    // the global return type stack pointer
  byte* BottomOfTypeStack;
  byte* BottomOfReturnTypeStack;
#endif

  long int* vmEntryRp;
  long int Base;
  long int State;
  long int Precision;
#ifndef __NO_FPSTACK__
  long int FpSize;
#endif
  char* pTIB;
  long int NumberCount;
  char WordBuf[256];
  char TIB[256];
  char NumberBuf[256];
}
extern "C" long int JumpTable[];
extern "C" void dump_return_stack(void); 

const char* V_ThrowMessages[] = {
  "",                                    // E_V_NOERROR
  "",                                    // E_V_ABORT
  "",                                    // E_V_ABORTQUOTE
  "Stack overflow",                      // E_V_STK_OVERFLOW
  "Stack underflow",                     // E_V_STK_UNDERFLOW
  "Return stack overflow",               // E_V_RET_STK_OVERFLOW
  "Return stack underflow",              // E_V_RET_STK_UNDERFLOW
  "Do-Loop nesting too deep",            // E_V_DO_NESTING
  "Dictionary overflow",                 // E_V_DICT_OVERFLOW
  "Invalid memory address",              // E_V_INVALID_ADDR
  "Division by zero",                    // E_V_DIV_ZERO
  "Result out of range",                 // E_V_OUT_OF_RANGE
  "Argument type mismatch",              // E_V_ARGTYPE_MISMATCH
  "Undefined word",                      // E_V_UNDEFINED_WORD
  "Interpreting a compile-only word",    // E_V_COMPILE_ONLY
  "Invalid FORGET",                      // E_V_INVALID_FORGET
  "Attempt to use zero-length string as a name", // E_V_ZEROLENGTH_NAME
  "Pictured numeric output string overflow", // E_V_OUTSTR_OVERFLOW
  "Parsed string overflow",              // E_V_PARSE_OVERFLOW
  "Definition name too long",            // E_V_DEFNAME_TOOLONG
  "Write to a read-only location",       // E_V_READONLY
  "Unsupported operation",               // E_V_UNSUPPORTED
  "Control structure mismatch",          // E_V_CONTROL_MISMATCH
  "Address alignment exception",         // E_V_ADDR_ALIGN
  "Invalid numeric argument",            // E_V_INVALID_ARG
  "Return stack imbalance",              // E_V_RET_STK_BALANCE
  "Loop parameters unavailable",         // E_V_LOOP_PARAMS
  "Invalid recursion",                   // E_V_INVALID_RECURSE
  "User interrupt",                      // E_V_USER_INTERRUPT
  "Compiler nesting",                    // E_V_COMPILER_NESTING
  "Obsolescent feature",                 // E_V_OBSCOLESCENT
  ">BODY used on non-CREATEd definition", // E_V_TOBODY
  "Invalid name argument",               // E_V_INVALID_NAMEARG
  "Block read exception",                // E_V_BLK_READ
  "Block write exception",               // E_V_BLK_WRITE
  "Invalid block number",                // E_V_INVALID_BLKNUM
  "Invalid file position",               // E_V_INVALID_FILEPOS
  "File I/O exception",                  // E_V_FILE_IO
  "Non-existent file",                   // E_V_FILE_NOEXIST
  "Unexpected end of file",              // E_V_EOF
  "Invalid BASE for floating point conversion", // E_V_INVALID_BASE
  "Loss of precision",                   // E_V_PRECISION_LOSS
  "Floating-point divide by zero",       // E_V_FDIVZERO
  "Floating-point result out of range",  // E_V_FPRANGE
  "Floating-point stack overflow",       // E_V_FP_STK_OVERFLOW
  "Floating-point stack underflow",      // E_V_FP_STK_UNDERFLOW
  "Floating-point invalid argument",     // E_V_FP_INVALID_ARG
  "Compilation word list deleted",       // E_V_WLCOMP_DELETED
  "Invalid POSTPONE",                    // E_V_INVALID_POSTPONE
  "Search-order overflow",               // E_V_SO_OVERFLOW
  "Search-order underflow",              // E_V_SO_UNDERFLOW
  "Compilation word list changed",       // E_V_WLCOMP_CHANGED
  "Control-flow stack overflow",         // E_V_CF_STK_OVERFLOW
  "Exception stack overflow",            // E_V_EX_STK_OVERFLOW
  "Floating-point underflow",            // E_V_FP_UNDERFLOW
  "Floating-point unidentified fault",   // E_V_FP_FAULT
  "",                                    // E_V_QUIT
  "Exception in sending or receiving a character", // E_V_EXC_TXRXCHAR
  "[IF], [ELSE], or [THEN] exception",   // E_V_EXC_BRACKETCTL
  "ALLOCATE",                            // E_V_ALLOCATE
  "FREE",                                // E_V_FREE
  "RESIZE",                              // E_V_RESIZE
  "CLOSE-FILE",                          // E_V_CLOSE_FILE
  "CREATE-FILE",                         // E_V_CREATE_FILE
  "DELETE-FILE",                         // E_V_DELETE_FILE
  "FILE-POSITION",                       // E_V_FILE_POSITION
  "FILE-SIZE",                           // E_V_FILE_SIZE
  "FILE-STATUS",                         // E_V_FILE_STATUS
  "FLUSH-FILE",                          // E_V_FLUSH_FILE
  "OPEN-FILE",                           // E_V_OPEN_FILE
  "READ-FILE",                           // E_V_READ_FILE
  "READ-LINE",                           // E_V_READ_LINE
  "RENAME-FILE",                         // E_V_RENAME_FILE
  "REPOSITION-FILE",                     // E_V_REPOSITION_FILE
  "RESIZE-FILE",                         // E_V_RESIZE_FILE
  "WRITE-FILE",                          // E_V_WRITE_FILE
  "WRITE-LINE",                          // E_V_WRITE_LINE
  "Malformed xchar",                     // E_V_BAD_XCHAR
  "SUBSTITUTE",                          // E_V_SUBSTITUTE
  "REPLACES"                             // E_V_REPLACES
};

const char* V_SysDefinedMessages[] =  {
  "Not data type ADDR",                  // E_V_NOT_ADDR
  "Not data type IVAL",                  // E_V_NOT_IVAL
  "Return stack corrupt",                // E_V_RET_STK_CORRUPT
  "Invalid opcode",                      // E_V_BAD_OPCODE
  "Allot failed -- cannot reassign pfa", // E_V_REALLOT
  "Cannot create word",                  // E_V_CREATE
  "End of string not found",             // E_V_NO_EOS
  "No matching DO",                      // E_V_NO_DO
  "No matching BEGIN",                   // E_V_NO_BEGIN
  "ELSE without matching IF",            // E_V_ELSE_NO_IF
  "THEN without matching IF",            // E_V_THEN_NO_IF
  "ENDOF without matching OF",           // E_V_ENDOF_NO_OF
  "ENDCASE without matching CASE",       // E_V_NO_CASE
  "Address outside of stack space",      // E_V_BAD_STACK_ADDR
  "Division overflow",                   // E_V_DIV_OVERFLOW
  "Unsigned double number overflow",     // E_V_DBL_OVERFLOW
  "Incomplete IF...THEN structure",      // E_V_INCOMPLETE_IF
  "Incomplete BEGIN structure",          // E_V_INCOMPLETE_BEGIN
  "Incomplete DO loop",                  // E_V_INCOMPLETE_LOOP
  "Incomplete CASE structure",           // E_V_INCOMPLETE_CASE
  "End of definition with no beginning", // E_V_END_OF_DEF
  "Not allowed inside colon definition", // E_V_NOT_IN_DEF
  "Unexpected end of input stream",      // E_V_END_OF_STREAM
  "Unexpected end of string",            // E_V_END_OF_STRING
  "VM returned unknown error",           // E_V_VM_UNKNOWN_ERROR
  "No pending definition"                // E_V_NOPENDING_DEF
};

// The Dictionary

vector<Vocabulary*> Dictionary;          // a collection of vocabularies
SearchList SearchOrder;                  // the search order for wordlists/vocabularies
Vocabulary Voc_Root( "Root" );           // the minimum search order vocabulary
Vocabulary Voc_Forth( "Forth" );         // the Forth vocabulary
Vocabulary Voc_Assembler( "Assembler" ); // the assembler vocabulary
WordList *pCompilationWL = &Voc_Forth;   // the current compilation wordlist

// Tables
vector<char*> StringTable;               // table for persistent strings

// stacks; these are global to this module

long int ForthStack[STACK_SIZE];                  // the stack
long int ForthReturnStack[RETURN_STACK_SIZE];     // the return stack

#ifndef __FAST__
byte ForthTypeStack[STACK_SIZE];             // the value type stack
byte ForthReturnTypeStack[RETURN_STACK_SIZE];// the return value type stack
#endif


bool FileOutput = FALSE;
vector<byte> tempOps;          // temporary opcode vector for [ and ]
//---------------------------------------------------------------

void WordList::RemoveLastWord ()
{
// Remove the last entry in the current wordlist

	vector<WordListEntry*>::iterator i = end() - 1;
	WordListEntry* pWord = *i;
	if (pWord->Pfa) delete [] (byte*) pWord->Pfa;	// free memory
	if (pWord->Cfa) delete [] (byte*) pWord->Cfa;
	pop_back();
	delete pWord;
}

WordListEntry* WordList::GetFromName (const char* name)
{
   vector<WordListEntry*>::iterator i;
   if (size()) {
     WordListEntry* pWord;
     for (i = end()-1; i >= begin(); --i) {
       pWord = *i;
       if (*((word*) name) == *((word*) pWord->WordName))  // pre-compare
         if (strcmp(name, pWord->WordName) == 0) return( pWord );
     }
   }
   return NULL;
}

WordListEntry* WordList::GetFromCfa (void* cfa)
{
   vector<WordListEntry*>::iterator i;
   if (size()) {
     WordListEntry* pWord;
     for (i = end()-1; i >= begin(); --i) {
       pWord = *i;
       if (cfa == pWord->Cfa)  return( pWord );
     }
   }
   return NULL;
}

//---------------------------------------------------------------

Vocabulary::Vocabulary( const char* name )
{
    int n = strlen(name);
    char *cp = new char [n+1];
    strcpy( cp, name );
    StringTable.push_back(cp);
    Name = cp;
}

int Vocabulary::Initialize( WordTemplate wt[], int n )
{
   int i, wcode;

   for (i = 0; i < n; i++)
   {
     pNewWord = new WordListEntry;   
     strcpy(pNewWord->WordName, wt[i].WordName);
     wcode = wt[i].WordCode;
     pNewWord->WordCode = wcode;
     pNewWord->Precedence = wt[i].Precedence;
     pNewWord->Cfa = new byte[WSIZE+2];
     pNewWord->Pfa = NULL;
     byte* bp = (byte*) pNewWord->Cfa;
     if (wcode >> 8) {
       bp[0] = OP_CALLADDR;
       *((long int*) (bp+1)) = (long int) JumpTable[wcode];
       bp[WSIZE+1] = OP_RET;
     }
     else {
       bp[0] = wcode;
       bp[1] = OP_RET;
     }
	
     push_back(pNewWord);
   }
   return 0;
}
//---------------------------------------------------------------

WordListEntry* SearchList::LocateWord (const char* name)
{
// Iterate through the search list, to look for an entry
//   with the specified name. If found, return the pointer
//   to the WordListEntry. Return NULL if not found.

   vector<Vocabulary*>::iterator j;
   WordListEntry* pWord;
   for (j = begin(); j < end(); ++j) {
     pWord = (*j)->GetFromName( name );
     if (pWord) return pWord;
   }
   return NULL;
}

WordListEntry* SearchList::LocateCfa (void* cfa)
{
// Iterate through the search list, to look for an entry
//   with the specified Cfa. If found, return the pointer
//   to the WordListEntry. Return NULL if not found.

   vector<Vocabulary*>::iterator j;
   WordListEntry* pWord;
   for (j = begin(); j < end(); ++j) {
     pWord = (*j)->GetFromCfa( cfa );
     if (pWord) return pWord;
   }
   return NULL;
}
//---------------------------------------------------------------

int InitSystemVars ()
{
// Initialize the Forth system variables, and set the Pfa's for
//   their words.

    Base = 10;
    State = FALSE;
    Precision = 15;  // Default FP output precision
#ifndef __NO_FPSTACK__
    FpSize = 8;      // Default FP size in bytes
#endif

    WordListEntry* pWord;
    pWord = Voc_Forth.GetFromName("STATE");
    if (pWord->Pfa == NULL) pWord->Pfa = &State;  
    pWord = Voc_Forth.GetFromName("BASE");
    if (pWord->Pfa == NULL) pWord->Pfa = (void*) &Base;
    pWord = Voc_Forth.GetFromName("PRECISION");
    if (pWord->Pfa == NULL) pWord->Pfa = (void*) &Precision;
    return 0;
}
//--------------------------------------------------------------- 

int NullSystemVars ()
{
// Set Pfa's of system vars to NULL to prevent Forth system
// shutdown from trying to free their memory.
    (Voc_Forth.GetFromName("STATE"))->Pfa = NULL;
    (Voc_Forth.GetFromName("BASE"))->Pfa = NULL;
    (Voc_Forth.GetFromName("PRECISION"))->Pfa = NULL;
    return 0;
}
//--------------------------------------------------------------- 

int InitFpStack ()
{
// Allocate the Floating Point stack and set the relevant
// stack pointers.

    unsigned u = FP_STACK_SIZE*FpSize;
    void* p = (void*) new byte [u];  // == fixme ==> null ptr check
    BottomOfFpStack = (void*)( (byte*) p + u - FpSize );
    GlobalFp = BottomOfFpStack;
    return 0;
}

int OpenForth ()
{
// Initialize the Forth system, and return the total number of words
//   in the dictionary.

    // The Dictionary initially contains the Root, Forth, and Assembler 
    // wordlists.
    Voc_Root.Initialize(RootWords, 5);
    Dictionary.push_back(&Voc_Root);
    Voc_Forth.Initialize(ForthWords, NUMBER_OF_INTRINSIC_WORDS);
    Dictionary.push_back(&Voc_Forth);
    Dictionary.push_back(&Voc_Assembler); 

    // The SearchOrder initially provides the Root and Forth wordlists
    // and the initial compilation wordlist is Forth
    SearchOrder.push_back(&Voc_Forth);
    SearchOrder.push_back(&Voc_Root);
    pCompilationWL = &Voc_Forth;

    // Initialize the global stack pointers
    // Floating point stack pointers initialized by InitFpStack()
    BottomOfStack = ForthStack + STACK_SIZE - 1;
    BottomOfReturnStack = ForthReturnStack + RETURN_STACK_SIZE - 1;
    GlobalSp = BottomOfStack;
    GlobalRp = BottomOfReturnStack;
#ifndef __FAST__
    BottomOfTypeStack = ForthTypeStack + STACK_SIZE - 1;
    BottomOfReturnTypeStack = ForthReturnTypeStack + RETURN_STACK_SIZE - 1;
    GlobalTp = BottomOfTypeStack;
    GlobalRtp = BottomOfReturnTypeStack;
#endif

   // Other initialization
    vmEntryRp = BottomOfReturnStack;
    InitSystemVars();
#ifndef __NO_FPSTACK__
    InitFpStack();
#endif
    set_start_time();
    save_term();
    L_initfpu();

    return( Voc_Forth.size() + Voc_Root.size() );
}
//---------------------------------------------------------------

void CloseForth ()
{

    NullSystemVars();

    // Clean up the compiled words
    Vocabulary* pVoc;

    while (Dictionary.size())
    {
        pVoc = *(Dictionary.end() - 1);
    	while (pVoc->size())
    	{
        	pVoc->RemoveLastWord();
    	}
	Dictionary.pop_back();
   }

    // Remove the search order
    SearchOrder.clear();

    // Clean up the string table

    vector<char*>::iterator j = StringTable.begin();

    while (j < StringTable.end())
    {
        if (*j) delete [] *j;
        ++j;
    }
    StringTable.clear();

#ifndef __NO_FPSTACK__
    // Delete the floating point stack
    delete [] (((byte*) BottomOfFpStack) + FpSize - FP_STACK_SIZE*FpSize) ;
#endif

    restore_term();
}

//---------------------------------------------------------------

bool InStringTable(char *s)
{
    // Search for a string pointer in the StringTable
    vector<char*>::iterator j = StringTable.begin();

    // *pOutStream << "Checking StringTable for pointer " << (int) s << " ... ";
    while (j < StringTable.end())
    {
        if (*j == s) {
	  // *pOutStream << " found\n";
	  return(true);
	}
        ++j;
    }
    // *pOutStream << " NOT found\n";
    return(false);
}
//---------------------------------------------------------------

void ClearControlStacks ()
{
  // Clear the flow control stacks

  if (debug) cout << "Clearing all flow control stacks" << endl; 
  while (!ifstack.empty())    ifstack.pop();
  while (!beginstack.empty()) beginstack.pop();
  while (!whilestack.empty()) whilestack.pop();
  while (!dostack.empty())    dostack.pop();
  while (!querydostack.empty()) querydostack.pop();
  while (!leavestack.empty()) leavestack.pop();
  while (!ofstack.empty())    ofstack.pop();
  while (!casestack.empty())  casestack.pop();
}
//---------------------------------------------------------------

void OpsCopyInt (long int offset, long int i)
{
  // Copy integer into the current opcode vector at the specified offset 

  vector<byte>::iterator ib = pCurrentOps->begin() + offset;
  byte* ip = (byte*) &i;
  for (unsigned int j = 0; j < WSIZE; j++) *(ib+j) = *(ip + j);

}
//---------------------------------------------------------------

void OpsPushInt (long int i)
{
  // push an integer into the current opcode vector

  byte* ip = (byte*) &i;
  for (int j = 0; j < WSIZE; j++) pCurrentOps->push_back(*(ip + j));
}
//---------------------------------------------------------------

void OpsPushTwoInt (long int nl, long int nh)
{
   // push a double integer into the current opcode vector
  OpsPushInt( nl ); OpsPushInt( nh );
}
//---------------------------------------------------------------

void OpsPushDouble (double f)
{
  // push a floating point double into the current opcode vector

  byte* fp = (byte*) &f;
  for (unsigned int j = 0; j < sizeof(double); j++) pCurrentOps->push_back(*(fp + j));
}
//---------------------------------------------------------------

int OpsCompileByte ()
{
  // push a byte value from the stack into the current opcode vector

  int endian = 1;
  DROP
  byte* ip = (byte*) GlobalSp;
  ip += (*((byte*) &endian)) ? 0 : sizeof(long int)-1; // handle big or little endian
  pCurrentOps->push_back(*ip);
  return 0;
}
//---------------------------------------------------------------

int OpsCompileInt ()
{
  // push an int value from the stack into the current opcode vector

  DROP
  OpsPushInt(TOS);
  return 0;
}
//---------------------------------------------------------------

int OpsCompileDouble ()
{
  // push a double value from the stack into the current opcode vector

  DROP
  OpsPushInt(TOS);
  DROP
  OpsPushInt(TOS);
  return 0;
}
//----------------------------------------------------------------

void PrintVM_Error (long int ec)
{
    if (ec) {
      const char *pMsg = "?";
      if (ec < 0) {
        int ei = labs(ec);
	bool b = ei > 255;
        int imax = b ? MAX_V_SYS_DEFINED : MAX_V_RESERVED;
	int ioffs = b ? ei - 256 : ei;
        if (ioffs < imax)
          pMsg = b ? V_SysDefinedMessages[ioffs] : 
              V_ThrowMessages[ioffs];
      }
      *pOutStream << " VM Error(" << ec << "): " << pMsg << endl;
    }
}
//---------------------------------------------------------------
// The FORTH Virtual Machine
//
// Arguments:
//
//      pFBC        pointer to vector of Forth byte codes
//      pStackPtr   receives pointer to the top item on the stack at exit
//      pTypePtr    receives pointer to the top item on the type stack at exit
//
// Return value: error code (see ForthVM.h)
//
int ForthVM (vector<byte>* pFBC, long int** pStackPtr, byte** pTypePtr)
{
  if (pFBC->size() == 0) return 0;  // null opcode vector

  // Initialize the instruction ptr and error code

  byte *ip = (byte *) &(*pFBC)[0];
  long int ecode = 0;

if (debug)  {
	cout << ">ForthVM Sp: " << GlobalSp << " Rp: " << GlobalRp << endl;
	cout << "  Ip: " << (long int) ip << " *Ip: " << (long int) *ip << endl;
	}
  // Execute the virtual machine; return when error occurs or
  //   the return stack is exhausted.

  ecode = vm (ip);

  if (ecode)
    {
      if (debug) cout << "vm Error: " << ecode << endl; // "  Offending OpCode: " << ((int) *(GlobalIp-1)) << endl;
      ClearControlStacks();
      GlobalRp = BottomOfReturnStack;        // reset the return stack ptrs
#ifndef __FAST__
      GlobalRtp = BottomOfReturnTypeStack;
#endif  
    }
  else if (GlobalSp > BottomOfStack)
  {
      ecode = E_V_STK_UNDERFLOW;
  }
  else if (GlobalRp > BottomOfReturnStack)
  {
      ecode = E_V_RET_STK_CORRUPT;
  }
  else
      ;

  // On stack underflow, update the global stack pointers.

  if ((ecode == E_V_STK_UNDERFLOW) || (ecode == E_V_RET_STK_CORRUPT))
  {
      L_abort();
  }

  // Set up return information

  *pStackPtr = GlobalSp + 1;
#ifndef __FAST__
  *pTypePtr = GlobalTp + 1;
#endif
if (debug)  cout << "<ForthVM Sp: " << GlobalSp << " Rp: " << GlobalRp << 
	      "  vmEntryRp: " << vmEntryRp << endl;
  return ecode;
}
//---------------------------------------------------------------

// Use C linkage for all of the VM functions

extern "C" {

// COLD  ( -- )
// Restart the Forth environment
// Non-standard, appeared in LMI UR/Forth 
int CPP_cold ()
{
    CloseForth();
    OpenForth();
    return 0;
}

// WORDLIST  ( -- wid )
// Create a new empty wordlist
// Forth 2012 Search-Order Wordset 16.6.1.2460
int CPP_wordlist()
{   // create an unnamed vocabulary
    Vocabulary* pVoc = new Vocabulary("");
    PUSH_ADDR( (long int) pVoc )
    Dictionary.push_back(pVoc); 
    return 0;
}

// FORTH-WORDLIST ( -- wid )  
// Return the Forth wordlist identifier
// Forth 2012 Search-Order Wordset 16.6.1.1595
int CPP_forthwordlist()
{
    PUSH_ADDR( (long int) &Voc_Forth )
    return 0;
}

// GET-CURRENT ( -- wid )  
// Return the compilation (current) wordlist
// Forth 2012 Search-Order Wordset 16.6.1.1643
int CPP_getcurrent()
{
    PUSH_ADDR( (long int) pCompilationWL )
    return 0;
}

// SET-CURRENT ( wid -- )
// Set the compilation (current) wordlist
// Forth 2012 Search-Order Wordset 16.6.1.2195
int CPP_setcurrent()
{
    DROP
    CHK_ADDR
    pCompilationWL = (WordList*) TOS;
    return 0;
}

// GET-ORDER  ( -- widn ... wid1 n)
// Return the current search order
// Forth 2012 Search-Order Wordset 16.6.1.1647
int CPP_getorder()
{
    vector<Vocabulary*>::iterator i;

    if (SearchOrder.size()) {
      for ( i = SearchOrder.end()-1; i >= SearchOrder.begin(); i--) {
        PUSH_ADDR( (long int) (*i) )
      }
    }
    PUSH_IVAL( SearchOrder.size() )
    return 0;
}

// SET-ORDER  ( widn ... wid1 n -- )
// Set the search order
// Forth 2012 Search-Order Wordset 16.6.1.2197
int CPP_setorder()
{
    DROP
    long int nWL = TOS;
    if (nWL == -1) 
      CPP_only();
    else
    {
      SearchOrder.clear();
      for (int i = 0; i < nWL; i++) {
        DROP
        CHK_ADDR
	SearchOrder.push_back((Vocabulary*) TOS);
      }
    }
    return 0;
}

// SEARCH-WORDLIST  ( c-addr u wid -- 0 | xt 1 | xt -1)
// Search for the word in the specified wordlist
// Forth 2012 Search-Order Wordset 16.6.1.2192
int CPP_searchwordlist()
{
    DROP
    CHK_ADDR
    WordList* pWL = (WordList*) TOS;
    DROP
    long int len = TOS;
    DROP
    CHK_ADDR
    char* cp = (char*) TOS;
    if (len > 0) {
      char* name = new char [len+1];
      strncpy(name, cp, len);
      name[len] =  0;
      strupr(name);
      WordListEntry* pWord = pWL->GetFromName( name );
      delete [] name;
      if (pWord) {
        byte* p = (byte*) pWord + offsetof(struct WordListEntry, Cfa);
        PUSH_ADDR( ((long int) p) )
        PUSH_IVAL( (pWord->Precedence & PRECEDENCE_IMMEDIATE) ? 1 : -1 )
        return 0;
      }
    }
    PUSH_IVAL(0)
    return 0;
}

// DEFINITIONS  ( -- )
// Make the compilation wordlist the same as the first search order wordlist
// Forth 2012 Search-Order Wordset 16.6.1.1180
int CPP_definitions()
{
    if (SearchOrder.size()) pCompilationWL = SearchOrder.front();
    return 0;
}

// VOCABULARY  ( "name" -- )
// Make a new vocabulary
// Forth 83
int CPP_vocabulary()
{
    CPP_create();
    WordListEntry* pWord = *(pCompilationWL->end() - 1);
    Vocabulary* pVoc = new Vocabulary(pWord->WordName);
    Dictionary.push_back(pVoc);

    pWord->Precedence = PRECEDENCE_NON_DEFERRED;
    pWord->Pfa = NULL;
    byte* bp = new byte[3*WSIZE+6];
    pWord->Cfa = bp;
    pWord->WordCode = OP_DEFINITION;
    
    // Execution behavior of new word:
    // get-order nip pVoc swap set-order
    bp[0] = OP_CALLADDR;
    *((long int*)(bp+1)) = (long int) JumpTable[OP_GETORDER]; 
    bp[WSIZE+1] = OP_NIP;
    bp[WSIZE+2] = OP_ADDR;
    *((long int*)(bp+WSIZE+3)) = (long int) pVoc;
    bp[2*WSIZE+3] = OP_SWAP;
    bp[2*WSIZE+4] = OP_CALLADDR;
    *((long int*) (bp+2*WSIZE+5)) = (long int) JumpTable[OP_SETORDER];
    bp[3*WSIZE+5] = OP_RET;

    return 0;
}

// ONLY  ( -- )
// Set the minimum search order: Root
// Forth 2012 Search-Order Extension Wordset 16.6.2.1965
int CPP_only()
{
    SearchOrder.clear();
    SearchOrder.push_back(&Voc_Root);
    return 0;
}

// ALSO  ( -- )
// Add the first wordlist in the search order to the search order  
// Forth 2012 Search-Order Extension Wordset 16.6.2.0715
int CPP_also()
{
    SearchOrder.insert(SearchOrder.begin(), SearchOrder.front());
    return 0;
}

// ORDER  ( -- )
// Display the wordlist search order, denoting the current compilation
// wordlist in brackets
// Forth 2012 Search-Order Extension Wordset 16.6.2.1985
int CPP_order()
{
    Vocabulary* pVoc;
    vector<Vocabulary*>::iterator i;
    const char* cp;
    const char* pUnnamed = "Unnamed";

    for ( i = SearchOrder.begin(); i < SearchOrder.end(); i++) {
      pVoc = *i;
      cp = pVoc->Name;
      if (! *cp) cp = pUnnamed; 
      if (pVoc == pCompilationWL)
        *pOutStream << "[" << cp << "]  ";
      else         
        *pOutStream << cp << "  ";
    }
    return 0;
}

// PREVIOUS  ( -- )
// Remove the first wordlist in the search order
// Forth 2012 Search-Order Extension Wordset 16.6.2.2037
int CPP_previous()
{
    SearchOrder.erase(SearchOrder.begin());
    return 0;
}

// FORTH  ( -- )
// Replace first wordlist in search with the Forth wordlist.
// Ensure that the Root wordlist remains in the search order
// Forth 2012 Search-Order Extension Wordset 16.6.2.1590
int CPP_forth()
{
    if (SearchOrder.size() == 1) CPP_also();
    SearchOrder[0] = &Voc_Forth;
    return 0;
}

// ASSEMBLER ( -- )
// Replace first wordlist in search order with Assembler wordlist.
// Forth 2012 Programming Tools Extension Wordset 15.6.2.0740
int CPP_assembler()
{
    SearchOrder[0] = &Voc_Assembler;
    return 0;
}

// TRAVERSE-WORDLIST  ( i*x xt wid -- j*x )
// Execute xt for every word in wordlist.
// Execution of xt has stack effect ( k*x nt -- l*x flag )
// Forth 2012 Programming Tools Wordset 15.6.2.2297
int CPP_traverse_wordlist()
{
    DROP
    CHK_ADDR
    WordList* pWL = (WordList*) TOS;
    DROP
    CHK_ADDR
    void** pCfa = (void**) TOS;  // xt is a pointer to Cfa
    vector<WordListEntry*>::iterator i;
    WordListEntry* pWord;
    int e = 0;
    if (pWL->size()) {
      for (i = pWL->end()-1; i >= pWL->begin(); --i) {
        pWord = *(i);  // this is the head token, ht (also nt)
        PUSH_ADDR( (long int) pWord )
        e = vm((byte*)(*pCfa));  // vm() requires Cfa
        DROP
        long int b = (long int) TOS;
        if (b == 0) break;
      }
    }
    return e;
}

// NAME>STRING  ( nt -- c-addr u )
// Return the name string associated with the named-word token, "nt".
// Forth 2012 Tools Wordset 15.6.2.1909.40
int CPP_name_to_string()
{
    DROP
    CHK_ADDR
    WordListEntry* pWord = (WordListEntry*) TOS;  // get nt from stack
    char* cp = (char*) pWord->WordName;
    PUSH_ADDR( (long int) cp )
    size_t len = strlen(cp);
    PUSH_IVAL( (long int) len )
    return 0;	
}

// NAME>INTERPRET  ( nt -- xt|0 )
// Return xt for interpretation semantics of named-word.
// Forth 2012 Tools Wordset 15.6.2.1909.20
int CPP_name_to_interpret()
{
    DROP
    CHK_ADDR
    WordListEntry* pWord = (WordListEntry*) TOS;
    void** xt = (void**) ((byte*) pWord + offsetof(struct WordListEntry, Cfa));
    PUSH_ADDR( (long int) xt )
    return 0;
}

// NAME>COMPILE  ( nt -- xt-word|nt-word xt1|xt2 )
// Return the compilation semantics for nt
// Forth 2012 Tools Wordset
int CPP_name_to_compile()
{
    DROP
    CHK_ADDR
    WordListEntry* nt = (WordListEntry*) TOS;
    DEC_DSP
    DEC_DTSP
    WordListEntry* p;
    if (nt->Precedence & PRECEDENCE_IMMEDIATE) {
      CPP_name_to_interpret(); // nt -- xt-word
      p = SearchOrder.LocateWord( "EXECUTE" );
    }
    else {
      p = SearchOrder.LocateWord( "COMPILE-NAME" );
    }
    PUSH_ADDR( (long int) p )  // ( -- xt-word nt_execute ) or
	                       // ( -- nt nt_compile-name ) 
    CPP_name_to_interpret();   // ( -- xt-word xt-execute ) or
                               // ( -- nt xt_compile-name )

    return 0;
}

// CREATE ( "name" -- )
// Parse name and create a definition with default execution semantics
// Forth 2012 Core Wordset 6.1.1000
int CPP_create ()
{
    char token[128];
    pTIB = ExtractName(pTIB, token);
    int nc = strlen(token);

    if (nc)
    {
      pNewWord = new WordListEntry;
      strupr(token);
      strcpy (pNewWord->WordName, token);
      pNewWord->WordCode = OP_ADDR;
      pNewWord->Pfa = NULL;
      pNewWord->Cfa = NULL;
      pNewWord->Precedence = 0;

      pCompilationWL->push_back(pNewWord);
      return 0;
    }
    else
    {
      return E_V_CREATE;  // create failed
    }
}

// :NONAME ( -- )
// Compile an anonymous definition
// Forth 2012 Core Extensions Wordset 6.2.0455
int CPP_noname()
{
    PendingOps.push(pCurrentOps);
    pCurrentOps = new vector<byte>;
// fixme: push recursion stack and allocate new one
    while (!recursestack.empty())  recursestack.pop(); 
    State = TRUE;

    pNewWord = NULL;
    PendingDefStack.push(pNewWord);
    return 0;
}

// : (colon)  ( "name" -- )
// Parse name and create a named definition
// Forth 2012 Core Wordset 6.1.0450
int CPP_colon()
{
    PendingOps.push(pCurrentOps);
    pCurrentOps = new vector<byte>;
// fixme: push recursion stack and allocate new one
    while (!recursestack.empty()) recursestack.pop();
    State = TRUE;

    char WordToken[256];
    pTIB = ExtractName (pTIB, WordToken);
    strupr(WordToken);

    pNewWord = new WordListEntry;
    strcpy (pNewWord->WordName, WordToken);
    pNewWord->WordCode = OP_DEFINITION;
    pNewWord->Precedence = PRECEDENCE_NONE;
    pNewWord->Pfa = NULL;
    pNewWord->Cfa = NULL;

    PendingDefStack.push(pNewWord);
    return 0;
}

// ; (semicolon)  ( -- )
// End the current definition
// Forth 2012 Core Wordset 6.1.0460
int CPP_semicolon()
{
  int ecode = 0;

  pCurrentOps->push_back(OP_RET);

  if (State)
    {
      // Check for incomplete control structures
      if (pNewWord) {		    
        if (ifstack.size())                          ecode = E_V_INCOMPLETE_IF;
        if (beginstack.size() || whilestack.size())  ecode = E_V_INCOMPLETE_BEGIN;
        if (dostack.size()    || leavestack.size())  ecode = E_V_INCOMPLETE_LOOP;
        if (casestack.size()  || ofstack.size())     ecode = E_V_INCOMPLETE_CASE;
        if (ecode) return ecode;
      }
      if (debug) OutputForthByteCode (pCurrentOps);
      int nalloc = max( (int) pCurrentOps->size(), 2*WSIZE );
      byte* lambda = new byte[ nalloc ];
      void* pLambda;

      if (pNewWord) {
        // Add a new entry into the dictionary
        pNewWord->Cfa = lambda;
        if (IsForthWord(pNewWord->WordName)) {
            WordListEntry* wi = pCompilationWL->GetFromName( pNewWord->WordName );
            if (wi)
	        *pOutStream << pNewWord->WordName << " is redefined\n";
        }
        pCompilationWL->push_back(pNewWord);
        pLambda = ((byte*) pNewWord + offsetof(struct WordListEntry, Cfa));
      }
      else {
        // noname definition
        pLambda = new byte* ;
        *((byte**) pLambda) = lambda;
        PUSH_ADDR( (long int) pLambda )
      }

      // Resolve any self references (recursion)

      byte *bp = (byte*) pLambda;
      unsigned long int i;
      vector<byte>::iterator ib;

      while (recursestack.size())
      {
         i = recursestack.top();
         ib = pCurrentOps->begin() + i;
         for (i = 0; i < sizeof(void*); i++) *ib++ = *(bp + i);
         recursestack.pop();
      }

// fixme: delete recursion stack and pop old one back.

      bp = (byte*) &(*pCurrentOps)[0]; // ->begin();
      while ((vector<byte>::iterator) bp < pCurrentOps->end()) *lambda++ = *bp++;
      pNewWord = PendingDefStack.top();
      PendingDefStack.pop();
      if (PendingDefStack.size()) {
         delete pCurrentOps;
         pCurrentOps = PendingOps.top();
         PendingOps.pop();
      }
      else {
         pCurrentOps->erase(pCurrentOps->begin(), pCurrentOps->end());
      }
      State = FALSE;
    }
  else
    {
      ecode = E_V_END_OF_DEF;
    }
  return ecode;
}

// COMPILE, ( xt -- )
// Append the execution semantics of xt to the current definition.
// Forth 2012 Core Wordset 6.2.0945
int CPP_compilecomma ()
{
    vector<byte>* pSaveOps = pCurrentOps;
    if (State == 0) pCurrentOps = PendingOps.top();
    CPP_literal();
    pCurrentOps->push_back(OP_EXECUTE);
    if (State == 0) pCurrentOps = pSaveOps;
    return 0;  
}

int CPP_compile_to_current ()
{
    DROP
    CHK_ADDR
    WordListEntry* p = (WordListEntry*) TOS;
    byte* bp;

    int wc = (p->WordCode >> 8) ? OP_CALLADDR : p->WordCode;
    pCurrentOps->push_back(wc);
    switch (wc) 
    {
      case OP_CALLADDR:
        bp = (byte*) p->Cfa;
        OpsPushInt(*((long int*)(bp+1)));
        break;

      case OP_PTR:
      case OP_ADDR:
        OpsPushInt((long int) p->Pfa);
        break;
	  
      case OP_DEFINITION:
        OpsPushInt((long int) p->Cfa);
        break;

      case OP_IVAL:
        OpsPushInt(*((long int*)p->Pfa));			
        break;

      case OP_2VAL:
        OpsPushInt(*((long int*)p->Pfa));
        OpsPushInt(*((long int*)p->Pfa + 1));
        break;

      case OP_FVAL:
        OpsPushDouble(*((double*) p->Pfa));
        break;

      default:
        ;
    }
    return 0;
}

// COMPILE-NAME ( nt -- )
// Perform the compilation semantics of the word referenced by nt.
// Non-standard word used by the Forth Compiler.
int CPP_compilename ()
{
    vector<byte>* pSaveOps = pCurrentOps;
    if ( (State == 0) && PendingDefStack.size() ) pCurrentOps = PendingOps.top();
    CPP_compile_to_current();
    pCurrentOps = pSaveOps;
    return 0;
}

// POSTPONE ( "name" -- )
// Parse name, find name, and append compilation semantics of name
//   to the current definition.
// Forth 2012 Core wordset 6.1.2033
int CPP_postpone ()
{
    char token[128];

    pTIB = ExtractName (pTIB, token);
    strupr(token);
    WordListEntry* pWord = SearchOrder.LocateWord(token);
    if (pWord) {
      if (pWord->Precedence & PRECEDENCE_IMMEDIATE) {
        PUSH_ADDR( (long int) pWord )
	CPP_compilename();
      }
      else {
        pCurrentOps->push_back(OP_ADDR);
        OpsPushInt((long int) pWord);
        pCurrentOps->push_back(OP_CALLADDR);
        OpsPushInt((long int) CPP_compilename);
      }
      if (State && (pWord->Precedence & PRECEDENCE_NON_DEFERRED)) {
        if (pNewWord) 
	  pNewWord->Precedence |= PRECEDENCE_NON_DEFERRED;
      }
    }
    return 0;  
}


// WORDS ( -- ) 
// List the definition names in the first wordlist of the search order
// Forth 2012 Programming Tools wordset 15.6.1.2465
int CPP_words ()
{
    char *cp, field[64];
    int nc;
    Vocabulary* pVoc = SearchOrder.front();
    *pOutStream << pVoc->size() << " words.\n";
    vector<WordListEntry*>::iterator i;
    WordListEntry* pWord;
    int j = 0;
    for (i = pVoc->begin(); i < pVoc->end(); i++)
    {
      pWord = *(i);
      memset (field, 32, 64);
      field[15] = '\0';
      cp = pWord->WordName;
      nc = strlen(cp);
      strncpy (field, cp, (nc > 15) ? 15 : nc);
      *pOutStream << field;
      if ((++j) % 5 == 0) *pOutStream << '\n';
    }
    return 0;
}

// (  ( "text" -- )
// Parse comment text delimited by right parenthesis and discard.
// pTIB is advanced past end of the comment.
// Forth 2012 Core Wordset 6.1.0080
int CPP_lparen()
{
  while (TRUE)
    {
      while ((pTIB < (TIB + 255)) && (! (*pTIB == ')')) && *pTIB) ++pTIB;
      if (*pTIB == ')')
	{
	  ++pTIB;
	  break;
	}
      else
	{
	  pInStream->getline(TIB, 255);
	  if (pInStream->fail()) return E_V_NO_EOS;
	  ++linecount;
	  pTIB = TIB;
	}
    }

  return 0;
}

// .(  ( "text" -- )
// Parse and display text delimited by right parenthesis.
// Forth 2012 Core Extensions Wordset 6.2.0200
int CPP_dotparen()
{
  while (TRUE)
    {
      while ((pTIB < (TIB + 255)) && (! (*pTIB == ')')) && *pTIB) 
	{
	  *pOutStream << *pTIB;
	  ++pTIB; 
	}

      if (*pTIB == ')')
	{
	  pOutStream->flush();
	  ++pTIB;
	  break;
	}
      else
	{
	  *pOutStream << endl;
	  pInStream->getline(TIB, 255);
	  if (pInStream->fail()) return E_V_NO_EOS;
	  ++linecount;
	  pTIB = TIB;
	}
    }

  return 0;
}

// .  ( n -- )
// Display n in current base
// Forth 2012 Core Wordset 6.1.0180
int CPP_dot ()
{
  DROP
  if (GlobalSp > BottomOfStack) 
    return E_V_STK_UNDERFLOW;
  else
    {
      long int n = TOS;
      if (n < 0)
	{
	  *pOutStream << '-';
	  TOS = labs(n);
	}
      DEC_DSP
      DEC_DTSP
      return CPP_udot();
    }
  return 0;
}

// .R  ( n1 n2 -- )
// Display n1 in current base, right justified in field width n2.
// Forth 2012 Core Extension Wordset 6.2.0210
int CPP_dotr ()
{
  DROP
  if (GlobalSp > BottomOfStack) return E_V_STK_UNDERFLOW;
  
  long int i, n, ndig, nfield;
  long unsigned int u, utemp, uscale;

  nfield = TOS;
  DROP

  if (GlobalSp > BottomOfStack) return E_V_STK_UNDERFLOW;

  // km 2023-12-14
  // The following commented line is not consistent with the Forth standard.
  // if (nfield <= 0) return 0;  // don't print anything if field width <= 0

  n = TOS;
  u = labs(n);
  ndig = 1;
  uscale = 1;
  utemp = u;

  while (utemp /= Base) {++ndig; uscale *= Base;}
  int ntot = (n < 0) ? ndig + 1 : ndig;

  if (ntot <= nfield)
    {
      for (i = 0; i < (nfield - ntot); i++) *pOutStream << ' ';
    }

  if (n < 0) *pOutStream << '-';
  PUSH_IVAL( u )

  i = CPP_udot0();
  pOutStream->flush();
  return i;
}

// U.R  ( u n -- )
// Print unsigned single in current base, right-justified in field width n.
// Forth 2012 Core Extensions Wordset 6.2.2330 
int CPP_udotr ()
{
  if ((GlobalSp+2) > BottomOfStack) return E_V_STK_UNDERFLOW;
  DROP
  long int i, ndig, nfield;
  nfield = TOS;
  DROP

  // km, 2023-12-14
  // The following commented line is not consistent with the Forth standard.
  // if (nfield <= 0) return 0;  // don't print anything if field width <= 0

  unsigned long int u, utemp, uscale;
  u = TOS;
  ndig = 1;
  uscale = 1;
  utemp = u;

  while (utemp /= Base) {++ndig; uscale *= Base;}

  if (ndig <= nfield)
    {
      for (i = 0; i < (nfield - ndig); i++) *pOutStream << ' ';
    }
  PUSH_IVAL( u )

  i = CPP_udot0();
  pOutStream->flush();
  return i;
}
//---------------------------------------------------------------

int CPP_udot0 ()
{
  // stack: ( u -- | print unsigned single in current base )

  DROP
  if (GlobalSp > BottomOfStack) return E_V_STK_UNDERFLOW;
  
  long int i, ndig, nchar;
  unsigned long int u, utemp, uscale;

  u = TOS;
  ndig = 1;
  uscale = 1;
  utemp = u;

  while (utemp /= Base) {++ndig; uscale *= Base;}

  for (i = 0; i < ndig; i++) 
    {
      utemp = u/uscale;
      nchar = (utemp < 10) ? (utemp + 48) : (utemp + 55);
      *pOutStream << (char) nchar;
      u -= utemp*uscale;
      uscale /= Base;
    }
  return 0;
}

// U.  ( u -- )
// Display unsigned single in current base, followed by space
// Forth 2012 Core Wordset 6.1.2320
int CPP_udot ()
{
  int e = CPP_udot0();
  if (e)
    return e;
  else
    {
      *pOutStream << ' ';
      pOutStream->flush();
    }
  return 0;
}

// UD.  ( ud -- )
// Print unsigned double in current base
// Non-standard
int CPP_uddot ()
{
  if ((GlobalSp + 2) > BottomOfStack) return E_V_STK_UNDERFLOW;
  
  unsigned long int u1 = *(GlobalSp + 1);
  if (u1 == 0)
    {
      DROP
      return CPP_udot();
    }
  else
    {
      C_bracketsharp();
      C_sharps();
      C_sharpbracket();
      CPP_type();
      *pOutStream << ' ';
      pOutStream->flush();
    }
  return 0;
}

// UD.R  ( ud n -- )
// Display unsigned double, right-justified in field of width n
// Non-standard
int CPP_uddotr ()
{
  if ((GlobalSp + 3) > BottomOfStack) return E_V_STK_UNDERFLOW;
  DROP
  long int nfield = TOS;
  C_bracketsharp();
  C_sharps();
  C_sharpbracket();  // ( -- caddr ndig )
  int ndig = *(GlobalSp + 1);
  if (ndig <= nfield)
    for (int i = 0; i < (nfield - ndig); i++) *pOutStream << ' ';
  CPP_type();
  pOutStream->flush();
  return 0;
}
 
// D.  ( d -- )
// Print signed double length number in current base.
// Forth 2012 Double Number Wordset 8.6.1.1060
int CPP_ddot ()
{
  if ((GlobalSp + 2) > BottomOfStack) 
    return E_V_STK_UNDERFLOW;
  else
    {
      long int n = *(GlobalSp+1);
      if (n < 0)
	{
	  *pOutStream << '-';
	  L_dabs();
	}
      return CPP_uddot();
    }
  return 0;
}

// D.R ( d n -- )
// Print signed double length number, right justified in field width n
// Forth 2012 Double Number Wordset 8.6.1.1070
int CPP_ddotr ()
{
  if ((GlobalSp + 3) > BottomOfStack) return E_V_STK_UNDERFLOW;
  DROP
  int nfield = TOS;
  if (nfield <= 0) return 0;  // don't print anything if field with <= 0
  long int n = *(GlobalSp+1);
  L_dabs();
  C_bracketsharp();
  C_sharps();
  C_sharpbracket();  // ( -- caddr ndig )
  int ndig, ntot;
  ndig = *(GlobalSp + 1);  
  ntot = (n < 0) ? ndig + 1 : ndig;
  if (ntot <= nfield)
      for (int i = 0; i < (nfield - ntot); i++) *pOutStream << ' ';
  if (n < 0) *pOutStream << '-';
  CPP_type();
  pOutStream->flush();
  return 0;
}

// F.  ( F: r -- )
// Print floating point number from the stack.
// Forth-2012 Floating Point Extensions Wordset 12.6.2.1427
int CPP_fdot ()
{
  if (GlobalFp > BottomOfFpStack)
    return E_V_STK_UNDERFLOW;
  else
    {
      INC_FSP
      switch( FpSize ) {
        case 4:
	  *pOutStream << *((float*) GlobalFp) << ' ';
	  break;
	case 8:
          *pOutStream << *((double*) GlobalFp) << ' ';
	  break;
	case 16:
	  *pOutStream << "qfloat" << ' ';
	  break;
      }
      (*pOutStream).flush();
    }
  return 0;
}

// FS.  ( F: r -- )
// Print floating point number in scientific notation.
// Forth-2012 Floating Point Extensions Wordset 12.6.2.1613
int CPP_fsdot ()
{
  if (GlobalFp > BottomOfFpStack)
    return E_V_STK_UNDERFLOW;
  else
    {
      INC_FSP
      ios_base::fmtflags origFlags = cout.flags();
      int origPrec = cout.precision();
      *pOutStream << setprecision(Precision-1) << scientific << 
		*((double*) GlobalFp) << ' ';
      (*pOutStream).flush();
      cout.flags(origFlags);
      cout.precision(origPrec);
    }
  return 0;
}

// .S  ( i*x -- i*x )
// Display the contents of the data stack
// Forth 2012 Programming Tools Wordset 15.6.1.0220
int CPP_dots ()
{
  if (GlobalSp > BottomOfStack) return E_V_STK_UNDERFLOW;

  L_depth();  
  DROP
  long int depth = TOS;
  DROP

  if (debug)
    {
      *pOutStream << "\nTop of Stack = " << ((long int)ForthStack);
      *pOutStream << "\nBottom of Stack = " << ((long int)BottomOfStack);
      *pOutStream << "\nStack ptr = " << ((long int)GlobalSp);
      *pOutStream << "\nDepth = " << depth;
    }
 
  if (depth > 0)
    {
      int i;
      byte* bptr;

      for (i = 0; i < depth; i++)
        {
#ifndef __FAST__
	  if (*(GlobalTp + i) == OP_ADDR)
            {
                bptr = *((byte**) (GlobalSp + i));
                *pOutStream << "\n\taddr\t" << ((long int)bptr);
            }
            else
            {
                *pOutStream << "\n\t\t" << *(GlobalSp + i);
            }
#else
	  *pOutStream << "\n\t\t" << *(GlobalSp + i);
#endif
        }
    }
  else
    {
        *pOutStream << "<empty>";
    }
  *pOutStream << '\n';
  DEC_DSP
  DEC_DTSP

  return 0;
}

// F.S ( F: i*r -- i*r )
int CPP_fdots ()
{
   if (GlobalFp > BottomOfFpStack) return E_V_STK_UNDERFLOW;
   L_fdepth();
   DROP
   long int fdepth = TOS;
   
   if (fdepth > 0 ) {
     float f;
     double d;
     byte* bptr = ((byte*) GlobalFp + FpSize);
     ios_base::fmtflags origFlags = cout.flags();
     int origPrec = cout.precision();

     for (int i = 0; i < fdepth; i++) {
       *pOutStream << "\n\t\t";
       switch( FpSize ) {
	 case 4:
	   f = *((float*) bptr);
           *pOutStream << setprecision(Precision-1) << 
		   scientific << f;
	   break;
	 case 8:
	   d = *((double*) bptr);
	   *pOutStream << setprecision(Precision-1) << 
              scientific << d;
	   break;
	 case 16:
	   *pOutStream << "qfloat";
	   break;
       }
       (*pOutStream).flush();
       bptr += FpSize;
     }
     cout.flags(origFlags);
     cout.precision(origPrec);
   }
   else {
     *pOutStream << "fs: <empty>";
   }
   *pOutStream << endl;
   return 0;
}

// ' (tick) ( "name" -- xt )
// Find "name" and return its execution token. If not found, throw exception.
// Forth 2012 Core Wordset 6.1.0070
int CPP_tick ()
{
    char name[128];
    pTIB = ExtractName(pTIB, name);
    strupr(name);
    int e = 0;
    WordListEntry* pWord = SearchOrder.LocateWord( name );
    if ( pWord )
    {
      byte* p = (byte*) pWord + offsetof(struct WordListEntry, Cfa);
        PUSH_ADDR( ((long int) p) )
    }
    else
	e = E_V_UNDEFINED_WORD;
    
    return e;
}

// >BODY  ( xt -- pfa | 0 )
// Return parameter field address corresponding to xt.
// Forth 2012 Core Wordset 6.1.0550
// System-specific: if xt is not for a CREATEd word, return 0.
int CPP_tobody ()
{
   INC_DSP
   void** pCfa = (void**) TOS;
   void** pPfa = ++pCfa;
   TOS = (long int) (*pPfa);
   DEC_DSP
   return 0;
}

// [DEFINED]  ( "name" -- flag )
// Return true if "name" can be found in search order.
// Forth 2012 Programming Tools Extensions 15.6.2.2530.30
int CPP_defined ()
{
   int not_found = CPP_tick();
   if ( ! not_found ) { DROP }
   PUSH_IVAL( not_found ? FALSE : TRUE )
   return 0;
}

// [UNDEFINED]  ( "name" -- flag )
// Return true if "name" cannot be found in search order.
// Forth 2012 Programming Tools Extensions 15.6.2.2534
int CPP_undefined ()
{
   int not_found = CPP_tick();
   if ( ! not_found ) { DROP }
   PUSH_IVAL( not_found ? TRUE : FALSE )
   return 0;
}

// FIND  ( ^str -- ^str 0 | xt 1 | xt -1 )
// Find dictionary word represented by counted string. 
// If found return execution token and either 1 for an
// immediate word or -1 for default compilation semantics;
// Return ^str and 0 if word cannot be found in search order.
// Forth 2012 Core Wordset 6.1.1550
int CPP_find ()
{
  DROP
  CHK_ADDR
  unsigned char* s = *((unsigned char**) GlobalSp);
  char name [128];
  int len = *s;
  strncpy (name, (char*) s+1, len);
  name[len] = 0;
  strupr(name);
  WordListEntry* pWord = SearchOrder.LocateWord( name );
  if (pWord) {
      byte* p = (byte*) pWord + offsetof( struct WordListEntry, Cfa );
      PUSH_ADDR( ((long int) p) )
      PUSH_IVAL( (pWord->Precedence & PRECEDENCE_IMMEDIATE) ? 1 : -1 )
    }
  else
    {
      DEC_DSP
      DEC_DTSP
      PUSH_IVAL(0)
    }
  return 0;
}

// FIND-NAME-IN  ( caddr u wid -- nt | 0 )
// Find word in wordlist wid, represented by string. 
// If word is found return valid name token nt, or 0 if
// word cannot be found in the specified wordlist.
// Forth 2012 (standardized on September 2018).
int CPP_find_name_in ()
{
  DROP
  CHK_ADDR
  WordList* WList = *((WordList**) GlobalSp);
  DROP
  unsigned long int len = TOS;
  if (len > 128) len = 128;
  DROP
  CHK_ADDR
  char name [128];
  char* s = *((char**) GlobalSp);
  strncpy (name, (char*) s, len);
  name[len] = 0;
  strupr(name);
  WordListEntry* pWord = WList->GetFromName( name );
  if (pWord) {
      PUSH_ADDR( (long int) pWord )
    }
  else
    {
      PUSH_IVAL(0)
    }
  return 0;
}

// FIND-NAME  ( caddr u -- nt | 0 )
// Find dictionary word represented by string. 
// If found return valid name token nt, or 0 if
// word cannot be found in the current search order.
// Forth 2012 (standardized on September 2018).
int CPP_find_name ()
{
  DROP
  unsigned long int len = TOS;
  if (len > 128) len = 128;
  DROP
  CHK_ADDR
  char name [128];
  char* s = *((char**) GlobalSp);
  strncpy (name, (char*) s, len);
  name[len] = 0;
  strupr(name);
  WordListEntry* pWord = SearchOrder.LocateWord( name );
  if (pWord) {
      PUSH_ADDR( (long int) pWord ) 
    }
  else
    {
      PUSH_IVAL(0)
    }
  return 0;
}

// EMIT  ( n -- )
// Display character with ASCII code n
// Forth 2012 Core Wordset 6.1.1320
int CPP_emit ()
{
  DROP
  if (GlobalSp > BottomOfStack)
    return E_V_STK_UNDERFLOW;
  else
    {
      *pOutStream << (char) TOS;
      (*pOutStream).flush();
    }
  return 0;
}

// CR  ( -- )
// Begin output on a new line.
// Forth 2012 Core Wordset 6.1.0990
int CPP_cr ()
{
  *pOutStream << '\n';
  return 0;
}

// SPACES  ( n -- )
// Display n spaces
// Forth 2012 Core Wordset 6.1.2230
int CPP_spaces ()
{
  DROP
  if (GlobalSp > BottomOfStack) 
    return E_V_STK_UNDERFLOW;
  else
    {
      int n = TOS;
      if (n > 0)
	for (int i = 0; i < n; i++) *pOutStream << ' ';
      (*pOutStream).flush();
    }
  return 0;
}

// TYPE  ( c-addr u -- )
// Display character string 
// Forth 2012 Core Wordset 6.1.2310
int CPP_type ()
{
  DROP
  if (GlobalSp > BottomOfStack) 
    return E_V_STK_UNDERFLOW;
  else
    {
      int n = TOS;
      DROP
      if (GlobalSp > BottomOfStack) 
	return E_V_STK_UNDERFLOW;
      CHK_ADDR
      char* cp = *((char**) GlobalSp);
      for (int i = 0; i  < n; i++) *pOutStream << *cp++;
      (*pOutStream).flush();
    }
  return 0;
}

// ALLOCATE  ( u -- a ior )
// Allocate u bytes and return address and i/o result 
// Forth 2012 Memory Allocation Wordset 14.6.1.0707
int CPP_allocate()
{
  DROP
  if (GlobalSp > BottomOfStack) 
    return E_V_STK_UNDERFLOW;

#ifndef __FAST__
  if (*GlobalTp != OP_IVAL)
    return E_V_NOT_IVAL;  // need an int
#endif

  unsigned long requested = TOS;
  byte *p = new (nothrow) byte[requested];
  PUSH_ADDR( (long int) p )
  PUSH_IVAL( p ? 0 : -1 )
  return 0;
}

// FREE  ( a -- ior )
// Free the previously allocated region at address a; return i/o result.
// Forth 2012 Memory Allocation Wordset 14.6.1.1605
int CPP_free()
{
    DROP
    CHK_ADDR
    byte *p = (byte*) TOS; 
    delete [] p;
    PUSH_IVAL( 0 )
    return 0;
}

// RESIZE  ( a unew -- anew ior )
// Change allocation size of region at address a to unew bytes.
// Forth 2012 Memory Allocation Wordset 14.6.1.2145
int CPP_resize()
{
    DROP
    unsigned long unew = TOS;
    DROP
    void* pOld = (void*) TOS;
    CHK_ADDR
    void* pNew = realloc(pOld, unew);
    if (pNew) TOS = (long int) pNew;
    DEC_DSP
    DEC_DTSP
    TOS = (pNew == NULL); 
    DEC_DSP
    DEC_DTSP

    return 0;
}

// ALLOT  ( n -- )
// Reserve n bytes of memory
// Forth 2012 Core Wordset 6.1.0710
// System-specific: if n <= 0, ALLOT does not do anything.
// All memory is dynamically allocated in kForth (see ALLOT?).
// ALLOT must only be used following CREATE.
int CPP_allot ()
{
  DROP
  if (GlobalSp > BottomOfStack) 
    return E_V_STK_UNDERFLOW;
#ifndef __FAST__
  if (*GlobalTp != OP_IVAL)
    return E_V_NOT_IVAL;  // need an int
#endif

  WordListEntry* pWord = *(pCompilationWL->end() - 1);
  long int n = TOS;
  if (n > 0)
    {
      if (pWord->Pfa == NULL)
	{ 
	  pWord->Pfa = new byte[n];
	  if (pWord->Pfa) memset (pWord->Pfa, 0, n); 

	  // Provide execution code to the word to return its Pfa
  	  byte *bp = new byte[WSIZE+2];
  	  pWord->Cfa = bp;
  	  bp[0] = OP_ADDR;
  	  *((long int*) &bp[1]) = (long int) pWord->Pfa;
  	  bp[WSIZE+1] = OP_RET;
	}
      else 
	return E_V_REALLOT;
    }
  else
    pWord->Pfa = NULL;

  return 0;
}

// ALLOT?  ( n -- a )
// Perform ALLOT and return starting address of allotted region.
// Non-standard
int CPP_queryallot ()
{
  int e = CPP_allot();
  if (!e)
    {
      // Get last word's Pfa and leave on the stack

      WordListEntry* pWord = *(pCompilationWL->end() - 1);
      PUSH_ADDR((long int) pWord->Pfa)
    }
  return e;
}

// SYNONYM ( "<newname>" "<oldname>" -- )
// Create a word NewName with the same with the same interpretation
// and compilation semantics of the existing word, OldName.
// Forth 2012 Tools Ext 15.6.2.2264
int CPP_synonym ()
{
    char NewName[256], OldName[256], s[256];
    int ncNew, ncOld, ecode = 0;

    pTIB = ExtractName( pTIB, NewName );
    pTIB = ExtractName( pTIB, OldName );
    strcpy(s, pTIB);  // remaining part of input line in TIB

    strupr(NewName);
    strupr(OldName);
    ncNew = strlen(NewName);
    ncOld = strlen(OldName);

    if (ncOld) { 
      WordListEntry* nt = SearchOrder.LocateWord(OldName);
      if (nt) {
        if (ncNew) {
          pNewWord = new WordListEntry;
          strcpy (pNewWord->WordName, NewName);
          pNewWord->WordCode = OP_DEFINITION;
          pNewWord->Pfa = NULL;
          pNewWord->Precedence = nt->Precedence;
	  byte* p = new byte[3*WSIZE];
          pNewWord->Cfa = p;
          p[0] = OP_ADDR;
	  *((long int*) &p[1]) = (long int) nt->Cfa;
	  p[WSIZE+1] = OP_EXECUTE_BC;
	  p[WSIZE+2] = OP_RET; 
          pCompilationWL->push_back(pNewWord);
        } 
        else
          ecode = E_V_CREATE;
      }
      else
        ecode = E_V_UNDEFINED_WORD;
    }
    else
      ecode = E_V_INVALID_NAMEARG;

    strcpy(TIB, s);  // restore TIB with remaining input line
    pTIB = TIB;      // restore ptr
    
    return ecode;
}

// ALIAS  ( xt "name" -- )
// Create a new dictionary entry for "name" with execution
// semantics defined by xt.
// Non-standard
int CPP_alias ()
{
    DROP
    void** pCfa = (void**) TOS;
    CHK_ADDR
    WordListEntry* pWord = SearchOrder.LocateCfa(*pCfa);
    if (pWord) {
      CPP_create();
      WordListEntry* pLastWord = *(pCompilationWL->end() - 1);
      byte* bp = new byte[WSIZE+2];
      pLastWord->Cfa = bp;
      pLastWord->Pfa = NULL;
      pLastWord->Precedence = pWord->Precedence;
      pLastWord->WordCode = OP_DEFINITION;
      bp[0] = OP_DEFINITION;
      *((long int*)(bp+1)) = (long int) pWord->Cfa;
      bp[WSIZE+1] = OP_RET;
    }
    else
      return E_V_UNDEFINED_WORD;

    return 0;
}

// VARIABLE ( "name" -- )
// Create a dictionary entry for "name" and allot 1 cell.
// Forth 2012
int CPP_variable ()
{
  if (CPP_create()) return E_V_CREATE;
  PUSH_IVAL( sizeof(long int) )  
  return( CPP_allot() );
}

// 2VARIABLE ( "name" -- )
// Create a dictionary entry for "name" and allot 2 cells.
// Forth 2012
int CPP_twovariable ()
{
  if (CPP_create()) return E_V_CREATE;
  PUSH_IVAL( 2*sizeof(long int) )  
  return( CPP_allot() );
}

// FVARIABLE  ( "name" -- )
// Create dictionary entry for "name" and allot space for 1 dfloat.
// Forth 2012
int CPP_fvariable ()
{
  if (CPP_create()) return E_V_CREATE;
  PUSH_IVAL( sizeof(double) )  
  return( CPP_allot() );
}
//------------------------------------------------------------------

int CPP_constant ()
{
  // stack: ( n -- | create dictionary entry and store n as constant )
  if (CPP_create()) return E_V_CREATE;
  WordListEntry* pWord = *(pCompilationWL->end() - 1);
  DROP
  pWord->WordCode = IS_ADDR ? OP_PTR : OP_IVAL;
  pWord->Pfa = new long int[1];
  *((long int*) (pWord->Pfa)) = TOS;
  byte *bp = new byte[WSIZE+3];
  pWord->Cfa = bp;
  bp[0] = OP_ADDR;
  *((long int*) &bp[1]) = (long int) pWord->Pfa;
  bp[WSIZE+1] = (pWord->WordCode == OP_PTR) ? OP_AFETCH : OP_FETCH;
  bp[WSIZE+2] = OP_RET;
  return 0;
}
//------------------------------------------------------------------

int CPP_twoconstant ()
{
  // create dictionary entry and store n1 and n2 as a 2constant
  // stack: ( n1 n2 -- )
  if (CPP_create()) return E_V_CREATE;
  WordListEntry* pWord = *(pCompilationWL->end() - 1);
  // pWord->WordCode = OP_2VAL;
  pWord->Pfa = new long int[2];
  DROP
  *((long int*) pWord->Pfa) = TOS;
  bool b2 = IS_ADDR;
  DROP
  *((long int*) pWord->Pfa + 1) = TOS;
  bool b1 = IS_ADDR;
  if (!(b1 || b2)) {
    pWord->WordCode = OP_2VAL;
    byte *p = new byte[WSIZE+3];
    pWord->Cfa = p;
    p[0] = OP_ADDR;
    *((long int*) &p[1]) = (long int) pWord->Pfa;
    p[WSIZE+1] = OP_2FETCH;
    p[WSIZE+2] = OP_RET;
  }
  else {
    pWord->WordCode = OP_DEFINITION;
    byte *p = new byte[3*WSIZE];
    pWord->Cfa = p;
    p[0] = OP_ADDR;
    long int *pval = (long int *) pWord->Pfa;
    *((long int*) &p[1]) = (long int) (pval + 1);
    p[WSIZE+1] = OP_FETCH;
    p[WSIZE+2] = OP_ADDR;
    *((long int*) &p[WSIZE+3]) = (long int) pval;
    p[2*WSIZE+3] = OP_FETCH;
    p[2*WSIZE+4] = OP_RET;
    if (b1 && (!b2)) {
      p[WSIZE+1]   = OP_AFETCH;
    }
    else if ((!b1) && b2) {
      p[2*WSIZE+3] = OP_AFETCH;
    }
    else {
      p[WSIZE+1]   = OP_AFETCH;
      p[2*WSIZE+3] = OP_AFETCH;
    }
  }
  return 0;
}
//------------------------------------------------------------------

int CPP_fconstant ()
{
  // stack: ( f -- | create dictionary entry and store f )
  if (CPP_create()) return E_V_CREATE;
  WordListEntry* pWord = *(pCompilationWL->end() - 1);
  pWord->WordCode = OP_FVAL;
  pWord->Pfa = new double[1];
  INC_FSP
  *((double*) (pWord->Pfa)) = *((double*) GlobalFp);
  byte *bp = new byte[WSIZE+3];
  pWord->Cfa = bp;
  bp[0] = OP_ADDR;
  *((long int*) &bp[1]) = (long int) pWord->Pfa;
  bp[WSIZE+1] = OP_DFFETCH;
  bp[WSIZE+2] = OP_RET;
  return 0;
}
//------------------------------------------------------------------

int CPP_char ()
{
  // stack: ( -- n | parse next word in input stream and return first char )
  PUSH_IVAL(32)
  C_word();
  char* cp = *((char**) ++GlobalSp) + 1;
  *GlobalSp-- = *cp;
#ifndef __FAST__
  *(GlobalTp + 1) = OP_IVAL ;
#endif
  return 0;
}
//-----------------------------------------------------------------

int CPP_bracketchar ()
{
  CPP_char();
  return CPP_literal();
}

int CPP_brackettick ()
{
  int e = CPP_tick ();
  if (e) return e; else return CPP_literal();  
}
//-------------------------------------------------------------------
// experimental non-standard word MY-NAME
int CPP_myname()
{
  int e = 0;

  if (pNewWord) {
    PUSH_ADDR( ((long int) pNewWord) )
  }
  else
    e = E_V_INVALID_NAMEARG;

  return e;
}

//-------------------------------------------------------------------
// FORGET  ( "<spaces>name" -- )
// Parse "name", find "name" in the compilation wordlist, then delete 
//   "name" from the dictionary along with all words added to the 
//   compilation wordlist after "name".
// Forth 2012 Tools Extensions Wordset 15.6.2.1580
int CPP_forget ()
{
  char token[128];

  pTIB = ExtractName (pTIB, token);
  strupr(token);
  WordListEntry* pWord = pCompilationWL->GetFromName( token );

  if (pWord) {
    vector<WordListEntry*>::iterator i = pCompilationWL->begin();
    vector<WordListEntry*>::iterator j = pCompilationWL->end() - 1;

    while (j > i) {
      if (pWord == *j) break;
      --j;
    }
    i = j;
    j = pCompilationWL->end();
    // Remove all words from end() to i
    while (i < j) {
      --j;
      pCompilationWL->RemoveLastWord();
    }
  }
  else
  {
      *pOutStream << "No such word in the current wordlist: " << token << '\n';
  }
  return 0;
}
//-------------------------------------------------------------------

int CPP_bye ()
{
  // stack: ( -- | close Forth and exit the process )

  CloseForth();
  *pOutStream << "Goodbye.\n";
  exit(0);

  return 0;
}
//--------------------------------------------------------------------

int CPP_tofile ()
{
  char filename[128];
  *filename = 0;

  pTIB = ExtractName (pTIB, filename);
  if (*filename == 0)
    {
      strcpy (filename, DEFAULT_OUTPUT_FILENAME);
      // cout << "Output redirected to " << filename << '\n';
    }
  ofstream *pFile = new ofstream (filename);
  if (! pFile->fail())
    {
      if (FileOutput)
	{ 
	  (*((ofstream*) pOutStream)).close();  // close current file output stream
	  delete pOutStream;
	} 
      pOutStream = pFile;
      FileOutput = TRUE;
    }
  else
    {
      *pOutStream << "Failed to open output file stream.\n";
    }
  return 0;  
}
//--------------------------------------------------------------------

int CPP_console ()
{
  if (FileOutput)
    {
      (*((ofstream*) pOutStream)).close();  // close the current file output stream
      delete pOutStream;
    }     
  pOutStream = &cout;  // make console the new output stream
  FileOutput = FALSE;

  return 0;
}
//--------------------------------------------------------------------

int CPP_literal ()
{
  // stack: ( n -- | remove item from the stack and place in compiled opcodes )
  DROP
#ifndef __FAST__
  pCurrentOps->push_back(*GlobalTp);
#else
  pCurrentOps->push_back(OP_IVAL);
#endif
  OpsPushInt(TOS);
  return 0;
}
//-------------------------------------------------------------------

int CPP_twoliteral ()
{
  // stack: ( n1 n2 -- | remove items from the stack and place in compiled opcodes )

  GlobalSp += 2;
#ifndef __FAST__
  GlobalTp += 2;
  pCurrentOps->push_back(*GlobalTp);
#else
  pCurrentOps->push_back(OP_IVAL);
#endif

  OpsPushInt(TOS);
#ifndef __FAST__
  pCurrentOps->push_back(*(GlobalTp - 1));
#else
  pCurrentOps->push_back(OP_IVAL);
#endif
  OpsPushInt(*(GlobalSp - 1));  
  return 0;
}
//-------------------------------------------------------------------

int CPP_sliteral ()
{
  // stack: ( c-addr u -- | store copy of string and compile string literal )
  DROP
  unsigned long int u = TOS;
  DROP
  CHK_ADDR
  char *cp = (char*) TOS;
  char* str = new char[u + 1];
  strncpy(str, cp, u);
  str[u] = '\0';
  StringTable.push_back(str);
  pCurrentOps->push_back(OP_ADDR);
  OpsPushInt((long int) str);
  pCurrentOps->push_back(OP_IVAL);
  OpsPushInt(u);

  return 0;
}
//-------------------------------------------------------------------

int CPP_fliteral ()
{
  // stack: ( F: r -- | place fp in compiled opcodes )

  INC_FSP
  pCurrentOps->push_back(OP_FVAL);
  double d = *((double*) GlobalFp);
  OpsPushDouble(d);
  return 0;
}
//-------------------------------------------------------------------

int CPP_cquote ()
{
  // compilation stack: ( -- | compile a counted string into the string table )
  // runtime stack: ( -- ^str | place address of counted string on stack )

  char* begin_string = pTIB;
  char* end_string = strchr(begin_string, '"');
  if (end_string == NULL)
    {
      return E_V_NO_EOS;
    }
  pTIB = end_string + 1;
  int nc = (int) (end_string - begin_string);
  char* str = new char[nc + 2];
  *((byte*)str) = (byte) nc;
  strncpy(str+1, begin_string, nc);
  str[nc+1] = '\0';
  StringTable.push_back(str);
  pCurrentOps->push_back(OP_ADDR);
  OpsPushInt((long int) str);

  return 0;
}
//-------------------------------------------------------------------

int CPP_squote ()
{
  // compilation stack: ( -- | compile a string into the string table )
  // runtime stack: ( -- a count )

  int e = CPP_cquote();
  if (e) return e;
  char* s = *(StringTable.end() - 1);
  long int v = (byte) s[0];
  pCurrentOps->push_back(OP_INC);
  pCurrentOps->push_back(OP_IVAL);
  OpsPushInt(v);

  return 0;
}
//-------------------------------------------------------------------

int CPP_dotquote ()
{
  // stack: ( -- | display a string delimited by quote from the input stream)

  int e = CPP_cquote();
  if (e) return e;

  pCurrentOps->push_back(OP_COUNT);
  pCurrentOps->push_back(OP_TYPE);

  return 0;
}
//------------------------------------------------------------------

int CPP_do ()
{
  // stack: ( -- | generate opcodes for beginning of loop structure )

  pCurrentOps->push_back(OP_PUSH);
  pCurrentOps->push_back(OP_PUSH);
  pCurrentOps->push_back(OP_PUSHIP);

  dostack.push(pCurrentOps->size());
  return 0;
}
//------------------------------------------------------------------

int CPP_querydo ()
{
  // stack: ( -- | generate opcodes for beginning of conditional loop )
  
  pCurrentOps->push_back(OP_2DUP);
  pCurrentOps->push_back(OP_EQ);
  CPP_if();
  pCurrentOps->push_back(OP_2DROP);
  CPP_else();
  CPP_do();

  querydostack.push(pCurrentOps->size());
  return 0;
}
//------------------------------------------------------------------

int CPP_loop ()
{
  if (dostack.empty()) return( E_V_NO_DO );
  pCurrentOps->push_back(OP_RTLOOP);  // run-time loop

  int i, j, ival;
  i = dostack.top();
  if (leavestack.size()) {
    do {
      j = leavestack.top();
      if (j > i) {
        ival = pCurrentOps->size() - j + 1;
        OpsCopyInt(j, ival); // write relative jump count
        leavestack.pop();
      }
    } while ((j > i) && (leavestack.size())) ;
  }
  dostack.pop();

  if (querydostack.size()) {
    j = querydostack.top();
    if (j >= i) {
      CPP_then();
      querydostack.pop();
    }
  }
  return 0;  
}

int CPP_plusloop ()
{
  if (dostack.empty()) return( E_V_NO_DO );
  pCurrentOps->push_back(OP_RTPLUSLOOP);  // run-time +loop

  int i, j, ival;
  i = dostack.top();
  if (leavestack.size()) {
    do {
      j = leavestack.top();
      if (j > i) {
        ival = pCurrentOps->size() - j + 1;
        OpsCopyInt(j, ival); // write relative jump count
        leavestack.pop();
      }
    } while ((j > i) && (leavestack.size())) ;
  }
  dostack.pop();

  if (querydostack.size()) {
    j = querydostack.top();
    if (j >= i) {
      CPP_then();
      querydostack.pop();
    }
  }
  return 0;
}

int CPP_unloop ()
{
  if (dostack.empty()) return( E_V_NO_DO );
  pCurrentOps->push_back(OP_RTUNLOOP);  // run-time unloop
  return 0;
}

int CPP_leave ()
{
  // stack: ( -- | generate opcodes to jump out of the current loop )

  if (dostack.empty()) return E_V_NO_DO;
  pCurrentOps->push_back(OP_RTUNLOOP);
  pCurrentOps->push_back(OP_JMP);
  leavestack.push(pCurrentOps->size());
  OpsPushInt(0);
  return 0;
}
//------------------------------------------------------------------

int CPP_abortquote ()
{
  // stack: ( -- | generate opcodes to print message and abort )

  char* str = NULL;
  int nc;
  if (pNewWord) {
    nc = strlen(pNewWord->WordName);
    str = new char[nc + 3];
    strcpy(str, pNewWord->WordName);
    strcat(str, ": ");
    StringTable.push_back(str);
  }
  else {
    nc = -2;
  }
  pCurrentOps->push_back(OP_JZ);
  OpsPushInt(4*WSIZE+9);   // relative jump count                       

// the relative jump count (above) must be modified if the 
// instructions below are updated!

  pCurrentOps->push_back(OP_ADDR);
  OpsPushInt((long int) str);
  pCurrentOps->push_back(OP_IVAL);
  OpsPushInt(nc+2);
  pCurrentOps->push_back(OP_TYPE);
  int e = CPP_dotquote();
  pCurrentOps->push_back(OP_CR);
  pCurrentOps->push_back(OP_ABORT);
  return e;
}
//------------------------------------------------------------------

int CPP_begin()
{
  // stack: ( -- | mark the start of a begin ... structure )

  beginstack.push(pCurrentOps->size());
  return 0;
}
//------------------------------------------------------------------

int CPP_while()
{
  // stack: ( -- | build the begin ... while ... repeat structure )	      

  if (beginstack.empty()) return E_V_NO_BEGIN;

  pCurrentOps->push_back(OP_JZ);
  if (!whilestack.empty()) {
    int i = whilestack.top();
    if (i > beginstack.top()) {   // convert last while to if
      ifstack.push( i );
      whilestack.pop();
    }
  }
  whilestack.push(pCurrentOps->size());
  OpsPushInt(0);
  return 0;
}
//------------------------------------------------------------------

int CPP_repeat()
{
  // stack: ( -- | complete begin ... while ... repeat block )

  if (beginstack.empty()) return E_V_NO_BEGIN;  // no matching BEGIN

  int i = beginstack.top();
  beginstack.pop();

  long int ival;

  if (whilestack.size())
    {
      int j = whilestack.top();
      if (j > i)
	{
	  whilestack.pop();
	  ival = pCurrentOps->size() - j + WSIZE + 2;
	  OpsCopyInt (j, ival);  // write the relative jump count
	}
    }

  ival = i - pCurrentOps->size();
  pCurrentOps->push_back(OP_JMP);
  OpsPushInt(ival);   // write the relative jump count

  return 0;
}
//-------------------------------------------------------------------

int CPP_until()
{
  // stack: ( -- | complete begin ... until block )

  if (beginstack.empty()) return E_V_NO_BEGIN;  // no matching BEGIN

  int i = beginstack.top();
  beginstack.pop();
  if (!whilestack.empty()) {
    int j = whilestack.top();
    if (j > i) {   // convert last while to if
      ifstack.push( j );
      whilestack.pop();
    }
  }
  long int ival = i - pCurrentOps->size();
  pCurrentOps->push_back(OP_JZ);
  OpsPushInt(ival);   // write the relative jump count

  return 0;
}
//-------------------------------------------------------------------

int CPP_again()
{
  // stack: ( -- | complete begin ... again block )

  if (beginstack.empty()) return E_V_NO_BEGIN;  // no matching BEGIN

  int i = beginstack.top();
  beginstack.pop();
  if (!whilestack.empty()) {
    int j = whilestack.top();
    if (j > i) {   // convert last while to if
      ifstack.push( j );
      whilestack.pop();
    }
  }
  long int ival = i - pCurrentOps->size();
  pCurrentOps->push_back(OP_JMP);
  OpsPushInt(ival);   // write the relative jump count

  return 0;
}
//--------------------------------------------------------------------

int CPP_if()
{
  // stack: ( -- | generate start of an if-then or if-else-then block )

  pCurrentOps->push_back(OP_JZ);
  ifstack.push(pCurrentOps->size());
  OpsPushInt(0);   // placeholder for jump count
  return 0;
}

// ELSE  ( -- )
// Build IF ... ELSE ... THEN block
// Forth 2012 
int CPP_else()
{
  pCurrentOps->push_back(OP_JMP);
  OpsPushInt(0);  // placeholder for jump count

  if (ifstack.empty()) return E_V_ELSE_NO_IF;  // ELSE without matching IF
  int i = ifstack.top();
  ifstack.pop();
  ifstack.push(pCurrentOps->size() - sizeof(long int));
  long int ival = pCurrentOps->size() - i + 1;
  OpsCopyInt (i, ival);  // write the relative jump count

  return 0;
}

// THEN  ( -- )
// Complete the current IF ... THEN or IF ... ELSE ... THEN block.
// Forth 2012
int CPP_then()
{
  if (ifstack.empty()) 
    return E_V_THEN_NO_IF;  // THEN without matching IF or IF-ELSE

  int i = ifstack.top();
  ifstack.pop();
  long int ival = (long int) (pCurrentOps->size() - i) + 1;
  OpsCopyInt (i, ival);   // write the relative jump count

  return 0;
}

// CASE  ( n -- )
// Begin a CASE ... ENDCASE control structure
// Forth 2012
int CPP_case()
{
  casestack.push(-1);
  return 0;
}

// ENDCASE  ( -- )
// Terminate a CASE ... ENDCASE control structure
// Forth 2012
int CPP_endcase()
{
  if (casestack.size() == 0) return E_V_NO_CASE;  // ENDCASE without matching CASE
  pCurrentOps->push_back(OP_DROP);

  // fix up all absolute jumps

  int i; long int ival;
  do
    {
      i = casestack.top();
      casestack.pop();
      if (i == -1) break;
      ival = (long int) (pCurrentOps->size() - i) + 1;
      OpsCopyInt (i, ival);   // write the relative jump count
    } while (casestack.size()) ;

  return 0;
}

// OF  ( -- )
// Begin an OF ... ENDOF control block.
// Forth 2012
int CPP_of()
{
  pCurrentOps->push_back(OP_OVER);
  pCurrentOps->push_back(OP_EQ);
  pCurrentOps->push_back(OP_JZ);
  ofstack.push(pCurrentOps->size());
  OpsPushInt(0);   // placeholder for jump count
  pCurrentOps->push_back(OP_DROP);
  return 0;
}

// ENDOF  ( -- )
// Complete an OF ... ENDOF control block.
// Forth 2012
int CPP_endof()
{
  pCurrentOps->push_back(OP_JMP);
  casestack.push(pCurrentOps->size());
  OpsPushInt(0);   // placeholder for jump count

  if (ofstack.empty())
    return E_V_ENDOF_NO_OF;  // ENDOF without matching OF

  int i = ofstack.top();
  ofstack.pop();
  long int ival = (long int) (pCurrentOps->size() - i) + 1;
  OpsCopyInt (i, ival);   // write the relative jump count

  return 0;
}

// RECURSE  ( -- )
//
// Forth 2012
int CPP_recurse()
{
  pCurrentOps->push_back(OP_ADDR);
  if (State)
    {
      recursestack.push(pCurrentOps->size());
      OpsPushInt(0);
    }
  else
    {
      long int ival = (long int) &(*pCurrentOps)[0]; // ->begin();
      OpsPushInt(ival);
    }
  pCurrentOps->push_back(OP_EXECUTE_BC);
  return 0;
}

// [  "left-bracket" ( -- )
// Enter interpretation state.
// Forth 2012 Core Wordset 6.1.2500
int CPP_lbracket()
{
  PendingOps.push(pCurrentOps);
  State = FALSE;
  tempOps.clear();
  pCurrentOps = &tempOps;
  return 0;
}

// ]  "right-bracket" ( -- )
// Enter compilation state.
// Forth 2012 Core Wordset 6.1.2540
int CPP_rbracket()
{
  int ecode = 0;
  State = TRUE;
  if (PendingOps.size()) {
     pCurrentOps->clear();
     pCurrentOps = PendingOps.top();
     PendingOps.pop();
  }
  if (PendingDefStack.size()) {
    pNewWord = PendingDefStack.top();
  }
  else {
    pNewWord = NULL;
    ecode = E_V_NOPENDING_DEF;
  }
  return ecode;
}

// DOES>  ( -- )
//
// Forth 2012 
int CPP_does()
{
  // Allocate new opcode array

  byte* p = new byte[2*WSIZE+4];

  // Insert pfa of last word in dictionary

  p[0] = OP_ADDR;
  WordListEntry* pWord = *(pCompilationWL->end() - 1);
  *((long int*)(p+1)) = (long int) pWord->Pfa;

  // Insert current instruction ptr 

  p[WSIZE+1] = OP_ADDR;
  *((long int*)(p+WSIZE+2)) = (long int)(GlobalIp + 1);

  p[2*WSIZE+2] = OP_EXECUTE_BC;
  p[2*WSIZE+3] = OP_RET;

  pWord->Cfa = (void*) p;
  pWord->WordCode = OP_DEFINITION;

  L_ret();
  return 0;
}

// IMMEDIATE  ( -- )
// Mark the most recently defined word as immediate.
// Forth 2012 Core Wordset 
int CPP_immediate ()
{
  WordListEntry* pWord = *(pCompilationWL->end() - 1);
  pWord->Precedence |= PRECEDENCE_IMMEDIATE;
  return 0;
}

// NONDEFERRED  ( -- )
// Mark the most recently defined word as non-deferred.
// Non-standard word (see kForth Manual)
int CPP_nondeferred ()
{
  WordListEntry* pWord = *(pCompilationWL->end() - 1);
  pWord->Precedence |= PRECEDENCE_NON_DEFERRED;
  return 0;
}

// EVALUATE  ( i*x c-addr u -- j*x )
// Evaluate a character string containing Forth source
// Forth 2012 Core Wordset 
int CPP_evaluate ()
{
  char s[256], s2[256];
  DROP
  long int nc = TOS; int ec = 0;
  DROP
  char *cp = (char*) TOS;
  if (nc < 256)
    {
      memcpy (s, cp, nc);
      s[nc] = 0;
      if (*s) 
	{
	  istringstream* pSS = NULL;
	  istream* pOldStream = pInStream;  // save old input stream
	  strcpy (s2, pTIB);  // save remaining part of input line in TIB
	  pSS = new istringstream(s);
	  SetForthInputStream(*pSS);

	  vector<byte>* pSaveOps = pCurrentOps;
          vector<byte> op;
          if (State == 0) pCurrentOps = &op;

	  --linecount;
	  ec = ForthCompiler(pCurrentOps, &linecount);
	  if ( State && (ec == E_V_END_OF_STREAM)) ec = 0;

	  // Restore the opcode vector, the input stream, and the input buffer

	  pCurrentOps = pSaveOps;
	  SetForthInputStream(*pOldStream);  // restore old input stream
	  strcpy(TIB, s2);  // restore TIB with remaining input line
	  pTIB = TIB;      // restore ptr
	  delete pSS;

	}
    }
  return( ec );
  
}

// INCLUDED  ( c-addr u -- )
//
// Forth 2012 
int CPP_included()
{
  // include the filename given on the stack as a counted string
  char filename[256];
  DROP
  long int nc = TOS;
  DROP
  char *cp = (char*) TOS;

  if ((nc < 0) || (nc > 255)) return E_V_OPEN_FILE;

  memcpy (filename, cp, nc);
  filename[nc] = 0;
  if (!strchr(filename, '.')) strcat(filename, ".4th");

  ifstream f(filename);
  if (!f)
    {
      if (getenv(dir_env_var))
	{
	  char temp[256]; 
	  strcpy(temp, getenv(dir_env_var));
	  strcat(temp, "/");
	  strcat(temp, filename);
	  strcpy(filename, temp);
	  f.clear();                // Clear the previous error.
	  f.open(filename);
	  if (f) 
	    {
	      *pOutStream << endl << filename << endl;
	    }
	}
    }

  if (f.fail()) 
    {
      *pOutStream << endl << filename << endl;
      return (E_V_OPEN_FILE);
    }

  vector<byte> ops, *pOldOps;
  int ecode;
	
  istream* pTempIn = pInStream;  // save input stream ptr
  SetForthInputStream(f);  // set the new input stream
  long int oldlc = linecount; linecount = 0;
  pOldOps = pCurrentOps;
  ecode = ForthCompiler (&ops, &linecount);
  f.close();
  pInStream = pTempIn;  // restore the input stream
  pCurrentOps = pOldOps; 
  if (ecode) 
    {
      *pOutStream << filename << "  " ;
      return (ecode);
    }
  linecount = oldlc;

  // Execute the code immediately
		      
  long int *sp;
  byte *tp;
  ecode = ForthVM (&ops, &sp, &tp);
  ops.clear();

  return ecode;
}

// INCLUDE ( "name" -- )
//
int CPP_include()
{
    char WordToken[256], s[256];
    int ecode;

    pTIB = ExtractName (pTIB, WordToken);
    strcpy (s, pTIB);  // save remaining part of input line in TIB

    PUSH_ADDR((long int) ((char*) WordToken))
    PUSH_IVAL(strlen(WordToken))
    ecode = CPP_included();
    if (ecode) return(ecode);

    strcpy(TIB, s);  // restore TIB with remaining input line
    pTIB = TIB;      // restore ptr
    
    return 0;
}

// SOURCE ( )
//
// Forth 2012
int CPP_source()
{
    PUSH_ADDR((long int) TIB)
    PUSH_IVAL(strlen(TIB))
    return 0;
}

// REFILL ( -- )
//
// Forth 2012
int CPP_refill()
{
    pInStream->getline(TIB, 255); 
    long int flag = (pInStream->fail()) ? FALSE : TRUE;
    if (flag) ++linecount;
    PUSH_IVAL(flag)
    pTIB = TIB;
    return 0;
}

// STATE  ( -- n )
// Return value indicating Forth state (0/1 for interpreting/compiling)
// Forth 2012
int CPP_state()
{
    PUSH_ADDR((long int)(&State))
    return 0;
}

// SP! (spstore) ( a -- )
// Set the stack pointer to address a; throw exception if a is
// outside of the stack space.
// Forth 2012
// System-specific: the "type stack" is correspondingly adjusted.
int CPP_spstore()
{
    DROP
    CHK_ADDR
    long int* p = (long int*) TOS; --p;
    if ((p > BottomOfStack) || (p < ForthStack))
	return E_V_BAD_STACK_ADDR;  // new SP must be within its stack space
    int n = (int) (p - ForthStack);

    GlobalSp = ForthStack + n;
#ifndef __FAST__
    GlobalTp = (byte *) ForthTypeStack + n;
#endif
    return 0;
}

// RP! (rpstore)  ( a -- )
// Set the return stack pointer to address a.
// Forth 2012
// System-specific: the "return type stack" is correspondingly adjusted.
int CPP_rpstore()
{
    DROP
    CHK_ADDR
    long int* p = (long int*) TOS; --p;
    if ((p > BottomOfReturnStack) || (p < ForthReturnStack))
	return E_V_BAD_STACK_ADDR;  // new RP must be within its stack space

    int n = (int) (p - ForthReturnStack);
    GlobalRp = ForthReturnStack + n;
#ifndef __FAST__
    GlobalRtp = ForthReturnTypeStack + n;
#endif
    return 0;
}

// FP! (fpstore) ( a -- )
// Set the floating point stack point to address a; throw
// exception if 'a' is outside of the stack space
// Non-standard word
int CPP_fpstore()
{
    DROP
    CHK_ADDR
    unsigned u = FP_STACK_SIZE*FpSize;
    void* p = (void*) TOS;
    p = (void*)((byte*) p - FpSize);
    if ((p > BottomOfFpStack) || 
	(p < ((byte*)BottomOfFpStack - u)))
	    return E_V_BAD_STACK_ADDR;
    GlobalFp = p;  // == fixme ==> ensure FpSize alignment
    return 0;
}

void dump_return_stack()  // for debugging purposes
{
    long int* p = GlobalRp;
    cout << endl << "Return Stack: " << endl;
    while (p < BottomOfReturnStack)
    {
	++p; 
	cout << (int)*p << endl; 
    }
}
}
