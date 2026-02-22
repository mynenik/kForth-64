// ForthCompiler.h
//
// Copyright (c) 1998--2026 Krishna Myneni,
//   <krishna.myneni@ccreweb.org>
//
// This software is provided under the terms of the GNU
// Affero General Public License (AGPL), v3.0 or later.
//

#ifndef __FORTHCOMPILER_H__
#define __FORTHCOMPILER_H__

#define WSIZE 8

#define byte unsigned char
#define word unsigned short int

#define PRECEDENCE_NONE         0
#define PRECEDENCE_IMMEDIATE    1
#define PRECEDENCE_NON_DEFERRED 2
// obsolete
// #define EXECUTE_NONE            0
// #define EXECUTE_UP_TO           1
// #define EXECUTE_CURRENT_ONLY    2

// Execution Semantics ID
#define ID_SEM_COMPILE             0
#define ID_SEM_EXECUTE_NAME        1
#define ID_SEM_EXECUTE_ALL         2
#define ID_SEM_COMPILE_NAME        3
#define ID_SEM_COMPILE_ND          4

#define TRUE -1
#define FALSE 0

struct WordTemplate
{
    const char* WordName;
    word WordCode;
    byte Precedence;
};

struct WordListEntry
{
  char WordName[128];
  word WordCode;
  byte Precedence;
  void* Cfa;
  void* Pfa;
};


class WordList : public vector<WordListEntry*> 
{
public:
   WordListEntry* GetFromName( const char* );
   WordListEntry* GetFromCfa( void* );
   void RemoveLastWord( void );
};

class Vocabulary : public WordList
{
public:
   const char* Name;
   Vocabulary (const char* );
   int Initialize (WordTemplate [], int);
};

class SearchList : public vector<Vocabulary*>
{
public:
   WordListEntry* LocateWord( const char* );
   WordListEntry* LocateCfa( void*  );
};


WordListEntry* IsForthWord (char*);
int  ForthCompiler (vector<byte>*, long int*);
int  GetExecutionSemantics (WordListEntry*);
// void CompileWord (WordListEntry*);
void OutputForthByteCode (vector<byte>*);
void SetForthInputStream (istream&);
void SetForthOutputStream (ostream&);

#endif
