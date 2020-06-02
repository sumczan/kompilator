CPP=g++
CC=gcc
LEX=flex
YACC=bison
LD=gcc

all:		komp

komp:		def.tab.o lex.yy.o
		$(CPP) lex.yy.o def.tab.o -std=c++11 -Wall -o komp -ll

lex.yy.o:	lex.yy.c
		$(CC) -c lex.yy.c

lex.yy.c:	scanner.l
		$(LEX) scanner.l

def.tab.o:	def.tab.cc
		$(CPP) -std=c++11 -c def.tab.cc

def.tab.cc:	def.yy
		$(YACC) -d def.yy

clean:
		rm *.o komp def.tab.cc lex.yy.c
