%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "def.tab.hh"
	#define INFILE_ERROR 1
	#define OUTFILE_ERROR 2
	extern int yylineno;
	//extern int yyin;
	int yyerror(const char *msg,...);
%}
%%
"//"					{return COM;}
"++"					{return	INCR;}
"--"					{return DECR;}
"print"					{return PRT;}
"read"					{return RD;}
\;						{return ';';}
\+ 						{return '+';}
\-						{return '-';}
\*						{return '*';}
\/						{return '/';}
\(						{return '(';}
\)						{return ')';}
\{						{return '{';}
\}						{return '}';}
\==						{return EQ;}
\!=						{return NEQ;}
\>=						{return GEQ;}
\<=						{return LEQ;}
\>						{return GT;}
\<						{return LT;}
\=						{return SET;}
"int"					{return INT;}
"float"					{return FLOAT;}
"for"					{return FOR;}
"while"					{return WHILE;}
"if"					{return IF;}
"fi"					{return FI;}
"rof"					{return ROF;}
"elihw"					{return ELIHW;}
"else"					{return ELSE;}
"string"				{return STRING;}
"'".*"'"				{
							yylval.str = strdup(yytext);
							return STR;
						}
[0]						{
							yylval.ival = atoi(yytext);
							return LC;
						}
[1-9][0-9]*				{
							yylval.ival = atoi(yytext);
							return LC;
						}
[1-9]*[0-9]+"."[0-9]*	{

							yylval.dval = atof(yytext);
							return LZ;
						}
\
[A-Za-z][A-Za-z0-9]*	{
							yylval.text = strdup(yytext);
							return ID;
						}
\ |\t 					{;}
\n 						{yylineno++;}
.						{yyerror("something is no yes ");}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s: %c\n", yylineno, msg, *yytext);
	exit(1);
}
