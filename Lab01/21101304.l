%option noyywrap

%{
#include <bits/stdc++.h>

#include "symbol_info.h"

#define YYSTYPE symbol_info*

#include "y.tab.h"

extern YYSTYPE yylval;

using namespace std;

void yyerror(char *);

string loglist;

extern int lines;

extern ofstream outlog;
%}

/* Regular Definitions */
delim       [ \t\v\r]
ws          {delim}+
newline     \n
letter_     [A-Za-z_]
digit       [0-9]
id          {letter_}({letter_}|{digit})*
integer     {digit}+
floating    ({digit}*\.{digit}+|{digit}+\.)([Ee][+-]?{digit}+)?|{digit}+[Ee][+-]?{digit}+

relop       (<=|>=|<|>|==|!=)
addop       (\+|\-)
mulop       (\*|\/|%)
assignop    =
logicop     (&&|\|\|)

%%

{ws}        { /* ignore whitespace */ }
{newline}   { lines++; }

"if"        {
                loglist = "Line no " + to_string(lines) + ": Token <IF> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return IF;
            }

"else"      {
                loglist = "Line no " + to_string(lines) + ": Token <ELSE> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return ELSE;
            }

"while"     {
                loglist = "Line no " + to_string(lines) + ": Token <WHILE> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return WHILE;
            }

"for"       {
                loglist = "Line no " + to_string(lines) + ": Token <FOR> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return FOR;
            }

"int"       {
                loglist = "Line no " + to_string(lines) + ": Token <INT> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return INT;
            }

"float"     {
                loglist = "Line no " + to_string(lines) + ": Token <FLOAT> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return FLOAT;
            }

"void"      {
                loglist = "Line no " + to_string(lines) + ": Token <VOID> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return VOID;
            }

"printf"    {
                loglist = "Line no " + to_string(lines) + ": Token <PRINTLN> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return PRINTLN;
            }

"return"    {
                loglist = "Line no " + to_string(lines) + ": Token <RETURN> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return RETURN;
            }

{integer}   {
                symbol_info *s = new symbol_info((string)yytext, "CONST_INT");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <CONST_INT> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return CONST_INT;
            }

{floating}  {
                symbol_info *s = new symbol_info((string)yytext, "CONST_FLOAT");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <CONST_FLOAT> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return CONST_FLOAT;
            }

{id}        {
                symbol_info *s = new symbol_info((string)yytext, "ID");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <ID> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return ID;
            }

{relop}     {
                symbol_info *s = new symbol_info((string)yytext, "RELOP");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <RELOP> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return RELOP;
            }

{addop}     {
                symbol_info *s = new symbol_info((string)yytext, "ADDOP");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <ADDOP> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return ADDOP;
            }

{mulop}     {
                symbol_info *s = new symbol_info((string)yytext, "MULOP");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <MULOP> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return MULOP;
            }

{assignop}  {
                symbol_info *s = new symbol_info((string)yytext, "ASSIGNOP");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <ASSIGNOP> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return ASSIGNOP;
            }

{logicop}   {
                symbol_info *s = new symbol_info((string)yytext, "LOGICOP");
                yylval = s;
                loglist = "Line no " + to_string(lines) + ": Token <LOGICOP> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return LOGICOP;
            }

"("         {
                loglist = "Line no " + to_string(lines) + ": Token <LPAREN> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return LPAREN;
            }

")"         {
                loglist = "Line no " + to_string(lines) + ": Token <RPAREN> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return RPAREN;
            }

"{"         {
                loglist = "Line no " + to_string(lines) + ": Token <LCURL> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return LCURL;
            }

"}"         {
                loglist = "Line no " + to_string(lines) + ": Token <RCURL> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return RCURL;
            }

","         {
                loglist = "Line no " + to_string(lines) + ": Token <COMMA> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return COMMA;
            }

";"         {
                loglist = "Line no " + to_string(lines) + ": Token <SEMICOLON> Lexeme " + yytext + " found\n\n";
                outlog << loglist;
                return SEMICOLON;
            }

.           {
                loglist = "Line no " + to_string(lines) + ": Unrecognized token " + yytext + "\n\n";
                outlog << loglist;
            }

%%

