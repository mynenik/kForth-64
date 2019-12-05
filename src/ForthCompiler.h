// ForthCompiler.h
//
// Copyright (c) 1998--2019 Krishna Myneni,
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
#define EXECUTE_NONE            0
#define EXECUTE_UP_TO           1
#define EXECUTE_CURRENT_ONLY    2
#define TRUE -1
#define FALSE 0
#define MAX_C_ERR_MESSAGES 13

// Error codes; The corresponding error messages are given in
//   the const char* array C_ErrorMessages, in ForthCompiler.cpp

#define E_C_NOERROR         0x100
#define E_C_ENDOFSTREAM     0x101
#define E_C_ENDOFDEF        0x102
#define E_C_ENDOFSTRING     0x103
#define E_C_NOTINDEF        0x104
#define E_C_OPENFILE        0x105
#define E_C_INCOMPLETEIF    0x106
#define E_C_INCOMPLETEBEGIN 0x107
#define E_C_UNKNOWNWORD     0x108
#define E_C_NODO            0x109
#define E_C_INCOMPLETELOOP  0x10A
#define E_C_INCOMPLETECASE  0x10B
#define E_C_VMERROR         0x10C

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
   WordListEntry* GetFromName( char* );
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
   WordListEntry* LocateWord( char* );
   WordListEntry* LocateCfa( void*  );
};


WordListEntry* IsForthWord (char*);
int  ForthCompiler (vector<byte>*, long int*);
int  ExecutionMethod (int);
// void CompileWord (WordListEntry*);
void OutputForthByteCode (vector<byte>*);
void SetForthInputStream (istream&);
void SetForthOutputStream (ostream&);

#endif
