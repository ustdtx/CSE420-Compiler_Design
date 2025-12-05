%{
#include <bits/stdc++.h>
#include "symbol_info.h"

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

int lines = 1; // Initialize line counter
ofstream outlog;

void yyerror(char *s) {
    outlog << "Error at line " << lines << ": " << s << "\n\n";
}

%}

%union {
    symbol_info* symbol;
}

/* Tokens from lexer */
%token <symbol> ID CONST_INT CONST_FLOAT
%token <symbol> ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT
%token <symbol> LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD
%token <symbol> SEMICOLON COMMA
%token IF ELSE FOR WHILE INT FLOAT VOID RETURN PRINTLN

/* Precedence and associativity */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

/* Expression precedence (lowest to highest) */
%right ASSIGNOP
%left LOGICOP
%left RELOP
%left ADDOP
%left MULOP
%right UNARY NOT
%right INCOP DECOP

/* Rule types */
%type <symbol> start program unit func_definition parameter_list compound_statement
%type <symbol> var_declaration type_specifier declaration_list statements statement
%type <symbol> expression_statement variable expression logic_expression rel_expression
%type <symbol> simple_expression term unary_expression factor argument_list arguments

%%

start : program {
    $$ = $1;
    outlog << "At line no: " << lines << " start : program \n\n" << $1->getname() << "\n\n";
}
;

program : program unit {
    $$ = new symbol_info($1->getname() + "\n" + $2->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " program : program unit \n\n" << $$->getname() << "\n\n";
}
| unit {
    $$ = $1;
    outlog << "At line no: " << lines << " program : unit \n\n" << $1->getname() << "\n\n";
}
;

unit : var_declaration {
    $$ = $1;
    outlog << "At line no: " << lines << " unit : var_declaration \n\n" << $1->getname() << "\n\n";
}
| func_definition {
    $$ = $1;
    outlog << "At line no: " << lines << " unit : func_definition \n\n" << $1->getname() << "\n\n";
}
;

func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement {
    $$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + $4->getname() + ")" + $6->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n" << $$->getname() << "\n\n";
}
| type_specifier ID LPAREN RPAREN compound_statement {
    $$ = new symbol_info($1->getname() + " " + $2->getname() + "()" + $5->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n" << $$->getname() << "\n\n";
}
;

parameter_list : parameter_list COMMA type_specifier ID {
    $$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID\n\n" << $$->getname() << "\n\n";
}
| parameter_list COMMA type_specifier {
    $$ = new symbol_info($1->getname() + "," + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier\n\n" << $$->getname() << "\n\n";
}
| type_specifier ID {
    $$ = new symbol_info($1->getname() + " " + $2->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " parameter_list : type_specifier ID\n\n" << $$->getname() << "\n\n";
}
| type_specifier {
    $$ = $1;
    outlog << "At line no: " << lines << " parameter_list : type_specifier\n\n" << $1->getname() << "\n\n";
}
;

compound_statement : LCURL statements RCURL {
    $$ = new symbol_info("{\n" + $2->getname() + "\n}", "NON_TERMINAL");
    outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL\n\n" << $$->getname() << "\n\n";
}
| LCURL RCURL {
    $$ = new symbol_info("{}", "NON_TERMINAL");
    outlog << "At line no: " << lines << " compound_statement : LCURL RCURL\n\n" << $$->getname() << "\n\n";
}
;

var_declaration : type_specifier declaration_list SEMICOLON {
    $$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "NON_TERMINAL");
    outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON\n\n" << $$->getname() << "\n\n";
}
;

type_specifier : INT {
    $$ = new symbol_info("int", "NON_TERMINAL");
    outlog << "At line no: " << lines << " type_specifier : INT\n\n" << $$->getname() << "\n\n";
}
| FLOAT {
    $$ = new symbol_info("float", "NON_TERMINAL");
    outlog << "At line no: " << lines << " type_specifier : FLOAT\n\n" << $$->getname() << "\n\n";
}
| VOID {
    $$ = new symbol_info("void", "NON_TERMINAL");
    outlog << "At line no: " << lines << " type_specifier : VOID\n\n" << $$->getname() << "\n\n";
}
;

declaration_list : declaration_list COMMA ID {
    $$ = new symbol_info($1->getname() + "," + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID\n\n" << $$->getname() << "\n\n";
}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
    $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "NON_TERMINAL");
    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n" << $$->getname() << "\n\n";
}
| ID {
    $$ = $1;
    outlog << "At line no: " << lines << " declaration_list : ID\n\n" << $1->getname() << "\n\n";
}
| ID LTHIRD CONST_INT RTHIRD {
    $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "NON_TERMINAL");
    outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n" << $$->getname() << "\n\n";
}
;

statements : statement {
    $$ = $1;
    outlog << "At line no: " << lines << " statements : statement\n\n" << $1->getname() << "\n\n";
}
| statements statement {
    $$ = new symbol_info($1->getname() + $2->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " statements : statements statement\n\n" << $$->getname() << "\n\n";
}
;

statement : var_declaration {
    $$ = $1;
    outlog << "At line no: " << lines << " statement : var_declaration\n\n" << $1->getname() << "\n\n";
}
| expression_statement {
    $$ = $1;
    outlog << "At line no: " << lines << " statement : expression_statement\n\n" << $1->getname() << "\n\n";
}
| compound_statement {
    $$ = $1;
    outlog << "At line no: " << lines << " statement : compound_statement\n\n" << $1->getname() << "\n\n";
}
| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
    $$ = new symbol_info("for(" + $3->getname() + $4->getname() + $5->getname() + ")" + $7->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n" << $$->getname() << "\n\n";
}
| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
    $$ = new symbol_info("if(" + $3->getname() + ")" + $5->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement\n\n" << $$->getname() << "\n\n";
}
| IF LPAREN expression RPAREN statement ELSE statement {
    $$ = new symbol_info("if(" + $3->getname() + ")" + $5->getname() + "else" + $7->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement ELSE statement\n\n" << $$->getname() << "\n\n";
}
| WHILE LPAREN expression RPAREN statement {
    $$ = new symbol_info("while(" + $3->getname() + ")" + $5->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " statement : WHILE LPAREN expression RPAREN statement\n\n" << $$->getname() << "\n\n";
}
| PRINTLN LPAREN ID RPAREN SEMICOLON {
    $$ = new symbol_info("printf(" + $3->getname() + ");", "NON_TERMINAL");
    outlog << "At line no: " << lines << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n" << $$->getname() << "\n\n";
}
| RETURN expression SEMICOLON {
    $$ = new symbol_info("return " + $2->getname() + ";", "NON_TERMINAL");
    outlog << "At line no: " << lines << " statement : RETURN expression SEMICOLON\n\n" << $$->getname() << "\n\n";
}
;

expression_statement : SEMICOLON {
    $$ = new symbol_info(";", "NON_TERMINAL");
    outlog << "At line no: " << lines << " expression_statement : SEMICOLON\n\n" << $$->getname() << "\n\n";
}
| expression SEMICOLON {
    $$ = new symbol_info($1->getname() + ";", "NON_TERMINAL");
    outlog << "At line no: " << lines << " expression_statement : expression SEMICOLON\n\n" << $$->getname() << "\n\n";
}
;

variable : ID {
    $$ = $1;
    outlog << "At line no: " << lines << " variable : ID\n\n" << $1->getname() << "\n\n";
}
| ID LTHIRD expression RTHIRD {
    $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "NON_TERMINAL");
    outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD\n\n" << $$->getname() << "\n\n";
}
;

expression : logic_expression {
    $$ = $1;
    outlog << "At line no: " << lines << " expression : logic_expression\n\n" << $1->getname() << "\n\n";
}
| variable ASSIGNOP logic_expression {
    $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression\n\n" << $$->getname() << "\n\n";
}
;

logic_expression : rel_expression {
    $$ = $1;
    outlog << "At line no: " << lines << " logic_expression : rel_expression\n\n" << $1->getname() << "\n\n";
}
| rel_expression LOGICOP rel_expression {
    $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression\n\n" << $$->getname() << "\n\n";
}
;

rel_expression : simple_expression {
    $$ = $1;
    outlog << "At line no: " << lines << " rel_expression : simple_expression\n\n" << $1->getname() << "\n\n";
}
| simple_expression RELOP simple_expression {
    $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression\n\n" << $$->getname() << "\n\n";
}
;

simple_expression : term {
    $$ = $1;
    outlog << "At line no: " << lines << " simple_expression : term\n\n" << $1->getname() << "\n\n";
}
| simple_expression ADDOP term {
    $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term\n\n" << $$->getname() << "\n\n";
}
;

term : unary_expression {
    $$ = $1;
    outlog << "At line no: " << lines << " term : unary_expression\n\n" << $1->getname() << "\n\n";
}
| term MULOP unary_expression {
    $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " term : term MULOP unary_expression\n\n" << $$->getname() << "\n\n";
}
;

unary_expression : ADDOP unary_expression {
    $$ = new symbol_info($1->getname() + $2->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression\n\n" << $$->getname() << "\n\n";
}
| NOT unary_expression {
    $$ = new symbol_info("!" + $2->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " unary_expression : NOT unary_expression\n\n" << $$->getname() << "\n\n";
}
| factor {
    $$ = $1;
    outlog << "At line no: " << lines << " unary_expression : factor\n\n" << $1->getname() << "\n\n";
}
;

factor : variable {
    $$ = $1;
    outlog << "At line no: " << lines << " factor : variable\n\n" << $1->getname() << "\n\n";
}
| ID LPAREN argument_list RPAREN {
    $$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "NON_TERMINAL");
    outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN\n\n" << $$->getname() << "\n\n";
}
| LPAREN expression RPAREN {
    $$ = new symbol_info("(" + $2->getname() + ")", "NON_TERMINAL");
    outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN\n\n" << $$->getname() << "\n\n";
}
| CONST_INT {
    $$ = $1;
    outlog << "At line no: " << lines << " factor : CONST_INT\n\n" << $1->getname() << "\n\n";
}
| CONST_FLOAT {
    $$ = $1;
    outlog << "At line no: " << lines << " factor : CONST_FLOAT\n\n" << $1->getname() << "\n\n";
}
| variable INCOP {
    $$ = new symbol_info($1->getname() + "++", "NON_TERMINAL");
    outlog << "At line no: " << lines << " factor : variable INCOP\n\n" << $$->getname() << "\n\n";
}
| variable DECOP {
    $$ = new symbol_info($1->getname() + "--", "NON_TERMINAL");
    outlog << "At line no: " << lines << " factor : variable DECOP\n\n" << $$->getname() << "\n\n";
}
;

argument_list : arguments {
    $$ = $1;
    outlog << "At line no: " << lines << " argument_list : arguments\n\n" << $1->getname() << "\n\n";
}
| /* empty */ {
    $$ = new symbol_info("", "NON_TERMINAL");
    outlog << "At line no: " << lines << " argument_list : \n\n" << $$->getname() << "\n\n";
}
;

arguments : arguments COMMA logic_expression {
    $$ = new symbol_info($1->getname() + "," + $3->getname(), "NON_TERMINAL");
    outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression\n\n" << $$->getname() << "\n\n";
}
| logic_expression {
    $$ = $1;
    outlog << "At line no: " << lines << " arguments : logic_expression\n\n" << $1->getname() << "\n\n";
}
;

%%

int main(int argc, char *argv[]) {
    if(argc != 2) {
        cout << "Please provide input file name and try again\n";
        return 0;
    }
    
    FILE *fin = fopen(argv[1], "r");
    if(fin == NULL) {
        cout << "Cannot open specified file\n";
        return 0;
    }

    outlog.open("log.txt");
    
    yyin = fin;
    yyparse();
    
    fclose(fin);
    outlog.close();
    
    return 0;
}
