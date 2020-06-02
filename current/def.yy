%{
	#include <string.h>
	#include <stdio.h>
	#include <iostream>
	#include <string>
	#include <stack>
	#include <vector>
	#include <algorithm>
	#include <map>
	#include <sstream>
	#include <fstream>
	#include <list>
	#define INFILE_ERROR 1
	#define OUTFILE_ERROR 2
	extern "C" int yylex();
	extern "C" int yyerror(const char *msg,...);
	extern FILE* yyin;
	using namespace std;

	stack <string> token_stack;
	stack <int>	type_stack;
	stack <string> clause_stack;
	stack <string> label_stack;
	stack <string> while_stack;

	stringstream output;
	stringstream code;

	map<string, int> symbols;
	map<string, string> strings;
	map<string, float> floats;

	vector<string> label_list;
	vector<vector<string>> elses;
	
	const int NONE_TYPE = 0;
	const int INT_TYPE = 1;
	const int FLOAT_TYPE = 2;

	void insert_symbol(string, int);
	void make_op(char,string);
	void printString(string);
	void printID(string);
	void readVar(string);
	void createString(string,string);
	void beginif();
	void beginelse();
	void beginwhile();
%}
%union
{
	char *text;
	int ival;
	float dval;
	char *str;
};

%token <text> ID
%token <ival> LC
%token <dval> LZ
%token <str> STR
%token PRT RD INCR DECR EQ NEQ GEQ LEQ GT LT SET INT FLOAT STRING FOR WHILE IF ELSE FI ROF ELIHW COM
%type <text> line expression term priorterm
%left '+' '-'
%left '*' '/'
%start block
%%
block		:line											{printf("\n");}
			|block line										{printf("\n");}
			;

line		:COM											{printf(" ");}
			|clause											{;} //todo
			|crtStr											{;}
			|crtVar											{;}
			|expression										{;}
			;

crtStr		:STRING ID 										{insert_symbol($2,NONE_TYPE);strings.insert(pair<string,string>($2,""));}
			|STRING ID SET STR 								{createString($2,$4);}	//todo

crtVar 		:type ID SET expression							{printf("="); token_stack.push($2); insert_symbol($2,type_stack.top()); type_stack.pop(); make_op('=',"sw");}
			|type ID 										{insert_symbol($2,type_stack.top()); type_stack.pop();}
			;

type		:INT 											{type_stack.push(INT_TYPE);}
			|FLOAT											{type_stack.push(FLOAT_TYPE);}
			;

clause		:IF'('term condition term')'					{clause_stack.push(token_stack.top());token_stack.pop();clause_stack.push(token_stack.top());token_stack.pop();beginif();}
			|FOR'('ID';'term condition term';' dosmth')' 	{;} //todo
			|FOR'('crtVar';'term condition term';'dosmth')'	{;}	//todo
			|WHILE'('term condition term')'					{clause_stack.push(token_stack.top());token_stack.pop();clause_stack.push(token_stack.top());token_stack.pop();beginwhile();}
			|ELSE											{beginelse();}
			|FI 											{code << label_stack.top() << ": " << endl; label_stack.pop(); elses.erase(elses.end()-1);}
			|ROF											{;}	//todo
			|ELIHW											{code << "j " << while_stack.top() << endl; while_stack.pop(); code << while_stack.top() << ": " << endl; while_stack.pop();}
			|PRT'('ID')'									{printID($3);}
			|PRT'('STR')'									{printString($3);}
			|RD'('ID')'										{readVar($3);}
			;

dosmth		:ID INCR										{;}	//todo
			|ID DECR										{;}	//todo

condition	:EQ												{clause_stack.push("bne");}
			|NEQ											{clause_stack.push("beq");}
			|GEQ											{clause_stack.push("blt");}
			|LEQ											{clause_stack.push("bgt");}
			|GT												{clause_stack.push("ble");}
			|LT 											{clause_stack.push("bge");}
			;

expression	:term											{;}
			|ID SET STR 									{createString($1,$3);}
			|ID SET expression								{token_stack.push($1);make_op('=',"sw");}
			|expression '*' term							{make_op('*',"MUL");}
			|expression '/' term							{make_op('/',"DIV");}
			|expression '+' priorterm						{make_op('+',"ADD");}
			|expression '-' priorterm						{make_op('-',"SUB");}
			;

priorterm	:priorterm '*' term								{make_op('*',"MUL");}
			|priorterm '/' term								{make_op('/',"DIV");}
			|term											{printf(" ");}
			;

term		:ID 											{token_stack.push($1);}
			|LC												{token_stack.push(to_string($1));}
			|LZ												{token_stack.push(to_string($1));}
			|'('expression')'								{printf(" ");}
			;
%%

string gen_load_line(string op, int regno)
{
	stringstream s;
	s << "l";
	if(isdigit(op[0]))
	{
		if(op.find(".") == -1)
		{
			s << "i ";
			s << "$t" << regno << ", " << op;
		}
		else
		{
			string name = "varf";
			int counter = 0;
			while(symbols.find(name+to_string(counter)) != symbols.end())
			{
				counter++;
			}
			name= name + to_string(counter);
			insert_symbol(name,FLOAT_TYPE);
			floats.insert(pair<string,float>(name,stof(op)));
			s << ".s ";
			s << "$f" << regno << ", " << name;
		}
	}
	else
	{
		if(symbols.find(op)->second == INT_TYPE)
		{
			s << "w ";
			s << "$t" << regno << ", " << op;
		}
		else if(symbols.find(op)->second == FLOAT_TYPE)
		{
			s << ".s ";
			s << "$f" << regno << ", " << op;
		}
	}
	return s.str();
}

void beginif()
{
	string op1 = clause_stack.top();
	clause_stack.pop();
	string op2 = clause_stack.top();
	clause_stack.pop();
	string condition = clause_stack.top();
	clause_stack.pop();

	string label = "label";
	int counter = 0;
	
	while(find(label_list.begin(), label_list.end(), label+to_string(counter))!= label_list.end())
	{
		counter++;
	}

	label = label+to_string(counter);
	code << label << ": " << endl;
	label_list.push_back(label);
	code << gen_load_line(op1, 0) << endl << gen_load_line(op2,1) << endl; 

	code << condition << " "  << "$t0, " << "$t1";
	string label2 = "label";
	while(find(label_list.begin(), label_list.end(), label2+to_string(counter))!= label_list.end())
	{
		counter++;
	}
	label2 = label2 + to_string(counter);
	label_list.push_back(label2);
	code << ", " << label2 << endl;
	label_stack.push(label2);

	vector<string> vec;
	vec.push_back(condition);
	vec.push_back(op1);
	vec.push_back(op2);
	elses.push_back(vec);
}

void beginelse()
{
	code << label_stack.top() << ": " << endl;
	label_stack.pop();
	string condition = elses[elses.size()-1][0];
	string op1 = elses[elses.size()-1][1];
	string op2 = elses[elses.size()-1][2];
	string temp = "";
	if(condition == "beq")
	{
		temp = "bne";
	}
	else if(condition == "bne")
	{
		temp = "beq";
	}
	else if(condition == "bge")
	{
		temp = "blt";
	}
	else if(condition == "bgt")
	{
		temp = "ble";
	}
	else if(condition == "ble")
	{
		temp = "bgt";
	}
	else if(condition == "blt")
	{
		temp = "bge";
	}
	else
	{
		cout << "error w elsie przy zmianie condition: " << condition << endl;
		exit(1);
	}
	cout << temp << " " << op1 << " " << op2 << endl;
	clause_stack.push(temp);
	clause_stack.push(op2);
	clause_stack.push(op1);
	beginif();
}

void beginwhile()
{
	string op1 = clause_stack.top();
	clause_stack.pop();
	string op2 = clause_stack.top();
	clause_stack.pop();
	string condition = clause_stack.top();
	clause_stack.pop();

	string label = "label";
	int counter = 0;
	
	while(find(label_list.begin(), label_list.end(), label+to_string(counter))!= label_list.end())
	{
		counter++;
	}

	label = label+to_string(counter);
	code << label << ": " << endl;
	label_list.push_back(label);
	code << gen_load_line(op1, 0) << endl << gen_load_line(op2,1) << endl; 

	code << condition << " "  << "$t0, " << "$t1";
	string label2 = "label";
	while(find(label_list.begin(), label_list.end(), label2+to_string(counter))!= label_list.end())
	{
		counter++;
	}
	label2 = label2 + to_string(counter);
	label_list.push_back(label2);
	code << ", " << label2 << endl;
	while_stack.push(label2);
	while_stack.push(label);
}

void printID(string id)
{
	if(symbols.find(id)->second == INT_TYPE)
	{
		code << "li $v0 , 1" << endl;
		code << "lw $a0 , " << id << endl;
	}
	else if(symbols.find(id)->second == FLOAT_TYPE)
	{
		code << "li $v0 , 2" << endl;
		code << "l.s $f12 , " << id << endl;
	}
	else if(symbols.find(id)->second == NONE_TYPE)
	{
		code << "li $v0 , 4" << endl;
		code << "la $a0 , " << id << endl;
	}
	else
	{
		cout << "niezadeklarowano zmiennej!!! " << "printID";
		exit(1);
	}
	code << "syscall" << endl;
	code << "li $v0 , 4" << endl << "la $a0 , newline" << endl << "syscall" << endl;
}

void readVar(string id)
{
	if(symbols.find(id)->second == INT_TYPE)
	{
		code << "li $v0 , 5" << endl;
		code << "syscall" << endl;
		code << "sw $v0 , " << symbols.find(id)->first << endl;
	}
	else if(symbols.find(id)->second == FLOAT_TYPE)
	{
		code << "li $v0 , 6" << endl;	
		code << "syscall" << endl;
		code << "s.s $f0 , " << symbols.find(id)->first << endl;
	}
	else if(symbols.find(id)->second == NONE_TYPE)
	{
		cout << "Brak implementacji " << "readVar";
		exit(1);
	}
	else
	{
		cout << "jakis blad w readVar";
		exit(1);
	}
}

void printString(string str)
{
	string name = "str";
	int counter = 0;
	while(symbols.find(name + to_string(counter))!=symbols.end())
	{
		counter++;
	}
	name = name+to_string(counter);
	str = str + "\\n";
	insert_symbol(name,NONE_TYPE);
	strings.insert(pair<string,string>(name,str));
	code << "li $v0 , 4" << endl;
	code << "la $a0 , " << name << endl;
	code << "syscall" << endl;
}

void createString(string name,string str)
{
	if(symbols.find(name) == symbols.end())
	{
		insert_symbol(name, NONE_TYPE);
		strings.insert(pair<string,string>(name,str));
	}
	else
	{
		strings.find(name)->second = str;
	}
	
}

void make_op(char op_sign, string asmop)
{
	string op2 = token_stack.top();
	token_stack.pop();
	string op1 = token_stack.top();
	token_stack.pop();
	string result = "result";
	int type = 0;
	if(symbols.find(op2)->second == FLOAT_TYPE || symbols.find(op1)->second == FLOAT_TYPE || op1.find(".") != -1 || op2.find(".")!=-1)
	{
		result+="_float";
		type = FLOAT_TYPE;
	}
	else
	{
		result+="_int";
		type = INT_TYPE;
	}
	code << "# " << result << " = " << op1 << " " << op_sign << op2 << endl;
	token_stack.push(result);
	if (op_sign == '=')
	{
		code << gen_load_line(op1, 0) << endl;
		if(type == INT_TYPE)
		{
			code << "sw $t0 , " << op2 << endl;
		}
		else if(type == FLOAT_TYPE)
		{
			code << "s.s $f0 , " << op2 << endl;
		}
	}
	else
	{
		insert_symbol(result, type);
		token_stack.push(result);
		
		code << gen_load_line(op1, 0) << endl;
		code << gen_load_line(op2, 1) << endl;
		if(type == INT_TYPE)
		{
			code << asmop << " $t0 , $t0 , $t1" << endl;
			code << "sw $t0 , " << result << endl;
		}
		else if(type == FLOAT_TYPE)
		{
			code << asmop << ".s" << " $f0 , $f0 , $f1" << endl;
			code << "s.s $f0 , " << result << endl;
		}
	}
}

void insert_symbol(string name,int type)
{
	if(symbols.find(name) == symbols.end())
	{
		symbols.insert(pair<string,int>(name, type));
	}
	else if(symbols.find(name) != symbols.end())
	{
		if(symbols[name] != type)
		{
			cout << "redeklarowano typ zmiennej!!! " << "insert_symbol";
			exit(1);
		}
	}
}

int main(int argc, char *argv[])
{
	if(argc>1)
	{
		yyin = fopen(argv[1], "r");
		if(yyin == NULL)
		{
			printf("error\n");
			return INFILE_ERROR;
		}
	}
	//yylex();
	yyparse();

	string filename = argv[1];
	output << ".data" << endl;
	output << "newline: .asciiz \"\\n\"" << endl;
	for(auto symbol : symbols)
	{
		output << symbol.first << ": ";
		if( symbol.second == INT_TYPE)
		{
			output << " .word 0";
		}
		else if( symbol.second == FLOAT_TYPE)
		{
			output << " .float ";
			float temp;
			if(floats.find(symbol.first) != floats.end())
			{
				temp = floats.find(symbol.first)->second;
				output << temp;
			}
			else
			{
				output << "0.0";
			}
		}
		else if( symbol.second == NONE_TYPE)
		{
			output << " .asciiz";
			output << " " << '"' << strings.find(symbol.first)->second << '"';
		}
		output << endl;
	}
	output << ".text" << endl;
	output << code.str() << endl;
	filename.append("_output.txt");
	ofstream outFile(filename);
	outFile << output.rdbuf();
	ifstream inFile(filename);
	cout << inFile.rdbuf();
	return 0;
}


// znane bugi
/*
	Odejmowanie przy dluzszych fragmentach odejmuje od samego siebie i wychodzi 0
	printID wypisuje adres pamieci a nie wartosc -> naprawione
	zmienne varf float trzeba przepisac z palca bo te wygenerowane generuja jakis blad -> samo sie naprawilo
	do floata nie doda sie inta -> brak konwersji typow
	else buguje sie przy liczbie podanej z read'a
	przy duzej ilosci
*/