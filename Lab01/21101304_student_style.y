%{
#include"symbol_info.h"
#define YYSTYPE symbol_info*

int yyparse(void);
int yylex(void);
extern FILE *yyin;

ofstream outlog;
int lines = 1;

void yyerror(char *s) {
    outlog << "Error at line " << lines << ": " << s << endl << endl;
}

%}

%token IF ELSE FOR WHILE INT FLOAT VOID RETURN PRINTLN
%token ID CONST_INT CONST_FLOAT
%token ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD
%token SEMICOLON COMMA

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%right ASSIGNOP
%left LOGICOP
%left RELOP
%left ADDOP
%left MULOP
%right UNARY NOT
%right INCOP DECOP

%%

start : program
    {
        $$ = $1;
        outlog << "At line no: " << lines << " start : program " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    ;

program : program unit
    {
        $$ = new symbol_info($1->getname() + "\n" + $2->getname(), "program");
        outlog << "At line no: " << lines << " program : program unit " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | unit
    {
        $$ = $1;
        outlog << "At line no: " << lines << " program : unit " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    ;

unit : var_declaration
    {
        $$ = $1;
        outlog << "At line no: " << lines << " unit : var_declaration " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | func_definition
    {
        $$ = $1;
        outlog << "At line no: " << lines << " unit : func_definition " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
    {
        $$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + $4->getname() + ")" + $6->getname(), "func_def");
        outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | type_specifier ID LPAREN RPAREN compound_statement
    {
        $$ = new symbol_info($1->getname() + " " + $2->getname() + "()" + $5->getname(), "func_def");
        outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

parameter_list : parameter_list COMMA type_specifier ID
    {
        $$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "param_list");
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | parameter_list COMMA type_specifier
    {
        $$ = new symbol_info($1->getname() + "," + $3->getname(), "param_list");
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | type_specifier ID
    {
        $$ = new symbol_info($1->getname() + " " + $2->getname(), "param_list");
        outlog << "At line no: " << lines << " parameter_list : type_specifier ID " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | type_specifier
    {
        $$ = $1;
        outlog << "At line no: " << lines << " parameter_list : type_specifier " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    ;

compound_statement : LCURL statements RCURL
    {
        $$ = new symbol_info("{\n" + $2->getname() + "\n}", "compound_stmt");
        outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | LCURL RCURL
    {
        $$ = new symbol_info("{}", "compound_stmt");
        outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

var_declaration : type_specifier declaration_list SEMICOLON
    {
        $$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "var_decl");
        outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

type_specifier : INT
    {
        $$ = new symbol_info("int", "type");
        outlog << "At line no: " << lines << " type_specifier : INT " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | FLOAT
    {
        $$ = new symbol_info("float", "type");
        outlog << "At line no: " << lines << " type_specifier : FLOAT " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | VOID
    {
        $$ = new symbol_info("void", "type");
        outlog << "At line no: " << lines << " type_specifier : VOID " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

declaration_list : declaration_list COMMA ID
    {
        $$ = new symbol_info($1->getname() + "," + $3->getname(), "decl_list");
        outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");
        outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | ID
    {
        $$ = $1;
        outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");
        outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

statements : statement
    {
        $$ = $1;
        outlog << "At line no: " << lines << " statements : statement " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | statements statement
    {
        $$ = new symbol_info($1->getname() + $2->getname(), "stmts");
        outlog << "At line no: " << lines << " statements : statements statement " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

statement : var_declaration
    {
        $$ = $1;
        outlog << "At line no: " << lines << " statement : var_declaration " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | expression_statement
    {
        $$ = $1;
        outlog << "At line no: " << lines << " statement : expression_statement " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | compound_statement
    {
        $$ = $1;
        outlog << "At line no: " << lines << " statement : compound_statement " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        $$ = new symbol_info("for(" + $3->getname() + $4->getname() + $5->getname() + ")" + $7->getname(), "stmnt");
        outlog << "At line no: " << lines << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    {
        $$ = new symbol_info("if(" + $3->getname() + ")" + $5->getname(), "stmnt");
        outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        $$ = new symbol_info("if(" + $3->getname() + ")" + $5->getname() + "else" + $7->getname(), "stmnt");
        outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement ELSE statement " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | WHILE LPAREN expression RPAREN statement
    {
        $$ = new symbol_info("while(" + $3->getname() + ")" + $5->getname(), "stmnt");
        outlog << "At line no: " << lines << " statement : WHILE LPAREN expression RPAREN statement " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
        $$ = new symbol_info("printf(" + $3->getname() + ");", "stmnt");
        outlog << "At line no: " << lines << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | RETURN expression SEMICOLON
    {
        $$ = new symbol_info("return " + $2->getname() + ";", "stmnt");
        outlog << "At line no: " << lines << " statement : RETURN expression SEMICOLON " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

expression_statement : SEMICOLON
    {
        $$ = new symbol_info(";", "expr_stmt");
        outlog << "At line no: " << lines << " expression_statement : SEMICOLON " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | expression SEMICOLON
    {
        $$ = new symbol_info($1->getname() + ";", "expr_stmt");
        outlog << "At line no: " << lines << " expression_statement : expression SEMICOLON " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

variable : ID
    {
        $$ = $1;
        outlog << "At line no: " << lines << " variable : ID " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | ID LTHIRD expression RTHIRD
    {
        $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "var");
        outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

expression : logic_expression
    {
        $$ = $1;
        outlog << "At line no: " << lines << " expression : logic_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | variable ASSIGNOP logic_expression
    {
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "expr");
        outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

logic_expression : rel_expression
    {
        $$ = $1;
        outlog << "At line no: " << lines << " logic_expression : rel_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | rel_expression LOGICOP rel_expression
    {
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "logic_expr");
        outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

rel_expression : simple_expression
    {
        $$ = $1;
        outlog << "At line no: " << lines << " rel_expression : simple_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | simple_expression RELOP simple_expression
    {
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "rel_expr");
        outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

simple_expression : term
    {
        $$ = $1;
        outlog << "At line no: " << lines << " simple_expression : term " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | simple_expression ADDOP term
    {
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "simple_expr");
        outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

term : unary_expression
    {
        $$ = $1;
        outlog << "At line no: " << lines << " term : unary_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | term MULOP unary_expression
    {
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "term");
        outlog << "At line no: " << lines << " term : term MULOP unary_expression " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

unary_expression : ADDOP unary_expression
    {
        $$ = new symbol_info($1->getname() + $2->getname(), "unary_expr");
        outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | NOT unary_expression
    {
        $$ = new symbol_info("!" + $2->getname(), "unary_expr");
        outlog << "At line no: " << lines << " unary_expression : NOT unary_expression " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | factor
    {
        $$ = $1;
        outlog << "At line no: " << lines << " unary_expression : factor " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    ;

factor : variable
    {
        $$ = $1;
        outlog << "At line no: " << lines << " factor : variable " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | ID LPAREN argument_list RPAREN
    {
        $$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "factor");
        outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | LPAREN expression RPAREN
    {
        $$ = new symbol_info("(" + $2->getname() + ")", "factor");
        outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | CONST_INT
    {
        $$ = $1;
        outlog << "At line no: " << lines << " factor : CONST_INT " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | CONST_FLOAT
    {
        $$ = $1;
        outlog << "At line no: " << lines << " factor : CONST_FLOAT " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    | variable INCOP
    {
        $$ = new symbol_info($1->getname() + "++", "factor");
        outlog << "At line no: " << lines << " factor : variable INCOP " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | variable DECOP
    {
        $$ = new symbol_info($1->getname() + "--", "factor");
        outlog << "At line no: " << lines << " factor : variable DECOP " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

argument_list : arguments
    {
        $$ = $1;
        outlog << "At line no: " << lines << " argument_list : arguments " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    |
    {
        $$ = new symbol_info("", "arg_list");
        outlog << "At line no: " << lines << " argument_list : " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    ;

arguments : arguments COMMA logic_expression
    {
        $$ = new symbol_info($1->getname() + "," + $3->getname(), "args");
        outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression " << endl << endl;
        outlog << $$->getname() << endl << endl;
    }
    | logic_expression
    {
        $$ = $1;
        outlog << "At line no: " << lines << " arguments : logic_expression " << endl << endl;
        outlog << $1->getname() << endl << endl;
    }
    ;

%%

int main(int argc, char *argv[])
{
    if(argc != 2) 
    {
        cout << "Please provide input file name and try again" << endl;
        return 0;
    }
    
    yyin = fopen(argv[1], "r");
    outlog.open("my_log.txt", ios::trunc);
    
    if(yyin == NULL)
    {
        cout << "Cannot open specified file" << endl;
        return 0;
    }
    
    yyparse();
    outlog <<"Total lines:" << lines << endl;
    
    outlog.close();
    fclose(yyin);
    
    return 0;
}