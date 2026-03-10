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
int  InitNameTranslations();
int  InitTranslationTable();
void OutputForthByteCode (vector<byte>*);
void SetForthInputStream (istream&);
void SetForthOutputStream (ostream&);
extern "C" {
int CPP_interpret();
int CPP_name_to_execute();
int CPP_rec_name();
int CPP_translate_none();
int CPP_translate_cell();
int CPP_translate_float();
}

#endif
