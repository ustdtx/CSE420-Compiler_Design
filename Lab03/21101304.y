%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here.
// You can store the pointer to your symbol table in a global variable
// or you can create an object

int lines = 1;

ofstream outlog;
ofstream errlog;
symbol_table *st;
int error_count = 0;

string current_type = "";
vector<pair<string, int>> current_declarations;  // (name, array_size) where array_size = -1 for non-arrays
vector<pair<string, string>> current_parameters;  // (type, name) for function parameters
string current_function_name = "";  // To track function name before entering scope
string current_function_return_type = "";  // To track return type before entering scope
vector<string> current_call_arguments;  // To track function call argument types
string current_call_function_name = "";  // To track which function is being called

// Helper functions for semantic analysis
void log_error(string msg) {
	errlog << "At line no: " << lines << " " << msg << endl;
	error_count++;
}

string get_expression_type(symbol_info* expr);
bool is_numeric_type(string type) {
	return type == "int" || type == "float";
}

// you may declare other necessary variables here to store necessary info
// such as current variable type, variable list, function name, return type, function parameter types, parameters names etc.

void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;

    // you may need to reinitialize variables if you find an error
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		// Print your whole symbol table here
		st->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"program");
	}
	;

unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
     ;

func_definition : type_specifier func_name LPAREN parameter_list RPAREN func_insert scope_enter param_insert compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"("+$4->get_name()+")\n"<<$9->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")\n"+$9->get_name(),"func_def");	
			
			current_parameters.clear();
			current_function_name = "";
			current_function_return_type = "";
		}
		| type_specifier func_name LPAREN RPAREN func_insert_no_params scope_enter compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"()\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"()\n"+$7->get_name(),"func_def");	
			
			current_function_name = "";
			current_function_return_type = "";
		}
 		;

func_name : ID
		{
			current_function_name = $1->get_name();
			current_function_return_type = current_type;
			$$ = $1;
		}
		;

func_insert : 
		{
			// Insert function in parent scope before entering new scope
			symbol_info *func_sym = new symbol_info(current_function_name, "ID");
			func_sym->set_symbol_type("Function");
			func_sym->set_return_type(current_function_return_type);
			
			// Check for duplicate declaration (either function or variable with same name)
			symbol_info *existing = st->lookup(func_sym);
			if (existing != NULL) {
				log_error("Multiple declaration of function " + current_function_name);
			}
			
			for (auto param : current_parameters) {
				func_sym->add_parameter(param.first, param.second);
			}
			st->insert(func_sym);
		}
		;

func_insert_no_params :
		{
			// Insert function in parent scope before entering new scope
			symbol_info *func_sym = new symbol_info(current_function_name, "ID");
			func_sym->set_symbol_type("Function");
			func_sym->set_return_type(current_function_return_type);
			
			// Check for duplicate declaration (either function or variable with same name)
			symbol_info *existing = st->lookup(func_sym);
			if (existing != NULL) {
				log_error("Multiple declaration of function " + current_function_name);
			}
			
			st->insert(func_sym);
		}
 		;

param_insert :
		{
			// Insert all parameters into the current function scope
			for (auto param : current_parameters) {
				symbol_info *param_sym = new symbol_info(param.second, "ID");
				param_sym->set_symbol_type("Variable");
				param_sym->set_return_type(param.first);
				st->insert(param_sym);
			}
		}
		;

scope_enter :
		{
			outlog << "New ScopeTable with ID " << (st->get_current_scope()->get_unique_id() + 1) << " created" << endl << endl;
			st->enter_scope();
		}
 		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;
					
			$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			
			// Check for duplicate parameter names
			for (auto param : current_parameters) {
				if (param.second == $4->get_name()) {
					log_error("Multiple declaration of variable " + $4->get_name() + " in parameter of " + current_function_name);
					break;
				}
			}
			current_parameters.push_back(make_pair($3->get_name(), $4->get_name()));
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			current_parameters.push_back(make_pair($1->get_name(), $2->get_name()));
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
		}
 		;

compound_statement : scope_enter LCURL statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$4->get_name()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$4->get_name()+"\n}","comp_stmnt");
				
                // The compound statement is complete.
                // Print the symbol table here and exit the scope
                // Note that function parameters should be in the current scope
				st->exit_scope(outlog);
 		    }
 		    | scope_enter LCURL RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				// The compound statement is complete.
                // Print the symbol table here and exit the scope
				st->exit_scope(outlog);
 		    }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");
			
			// Insert necessary information about the variables in the symbol table
			for (auto decl : current_declarations) {
				// Check if variable type is void
				if (current_type == "void") {
					log_error("variable type can not be void");
				}
				
				symbol_info *sym = new symbol_info(decl.first, "ID");
				sym->set_return_type(current_type);
				if (decl.second == -1) {
					sym->set_symbol_type("Variable");
				} else {
					sym->set_symbol_type("Array");
					sym->set_array_size(decl.second);
				}
				
				// Check for duplicate declaration in current scope
				if (!st->insert(sym)) {
					log_error("Multiple declaration of variable " + decl.first);
				}
			}
			current_declarations.clear();
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
			$$ = new symbol_info("int","type");
			current_type = "int";
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
			$$ = new symbol_info("float","type");
			current_type = "float";
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			
			$$ = new symbol_info("void","type");
			current_type = "void";
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			current_declarations.push_back(make_pair($3->get_name(), -1));  // -1 for non-array
			
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<"["<<$5->get_name()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			current_declarations.push_back(make_pair($3->get_name(), stoi($5->get_name())));
			
 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			current_declarations.push_back(make_pair($1->get_name(), -1));  // -1 for non-array
			
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
            current_declarations.push_back(make_pair($1->get_name(), stoi($3->get_name())));
            
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
	   }
	   ;
	   
statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl; 
			
			// Check if variable is declared
			symbol_info *sym = new symbol_info($3->get_name(), "ID");
			symbol_info *found = st->lookup(sym);
			if (found == NULL) {
				log_error("Undeclared variable " + $3->get_name());
			}
			
			$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->get_name()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->get_name()+";","expr_stmt");
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		// Check if variable is declared
		symbol_info *sym = new symbol_info($1->get_name(), "ID");
		symbol_info *found = st->lookup(sym);
		if (found == NULL) {
			log_error("Undeclared variable " + $1->get_name());
		} else if (found->get_symbol_type() == "Array") {
			// Variable is an array but used without index
			log_error("variable is of array type : " + $1->get_name());
		}
		
		$$ = new symbol_info($1->get_name(),"varbl");
		if (found != NULL) {
			$$->set_return_type(found->get_return_type());
			$$->set_symbol_type(found->get_symbol_type());
		}
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;
		
		// Check if variable is declared
		symbol_info *sym = new symbol_info($1->get_name(), "ID");
		symbol_info *found = st->lookup(sym);
		if (found == NULL) {
			log_error("Undeclared variable " + $1->get_name());
		} else if (found->get_symbol_type() != "Array") {
			// Variable is not an array but index is used
			log_error("variable is not of array type : " + $1->get_name());
		} else {
			// Check if index is integer
			string idx_type = $3->get_return_type();
			if (idx_type != "" && idx_type != "int") {
				log_error("array index is not of integer type : " + $1->get_name());
			}
		}
		
		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");
		if (found != NULL) {
			$$->set_return_type(found->get_return_type());
		}
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"expr");
			$$->set_return_type($1->get_return_type());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;

			string left_type = $1->get_return_type();
			string right_type = $3->get_return_type();
			
			// Check if right side is void type
			if (right_type == "void") {
				log_error("operation on void type");
			}
			
			// Type checking for assignment - only report specific mismatches
			if (left_type != "" && right_type != "") {
				if (left_type == "int" && right_type == "float") {
					log_error("Warning: Assignment of float value into variable of integer type");
				}
				// Note: Other type mismatches are only reported if explicitly required by spec
			}

			$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");
			$$->set_return_type(left_type);
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"lgc_expr");
			$$->set_return_type($1->get_return_type());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
			$$->set_return_type("int");  // Result of logical operation is int
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"rel_expr");
			$$->set_return_type($1->get_return_type());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
			$$->set_return_type("int");  // Result of relational operation is int
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"simp_expr");
			$$->set_return_type($1->get_return_type());
	      }
	  | simple_expression ADDOP term 
	  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			string left_type = $1->get_return_type();
			string right_type = $3->get_return_type();
			
			// Check if either operand is void type
			if (left_type == "void" || right_type == "void") {
				log_error("operation on void type");
			}
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");
			// Result type of addition - promote to float if any operand is float
			if (left_type == "float" || right_type == "float") {
				$$->set_return_type("float");
			} else {
				$$->set_return_type("int");
			}
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"term");
			$$->set_return_type($1->get_return_type());
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			string op = $2->get_name();
			string left_type = $1->get_return_type();
			string right_type = $3->get_return_type();
			
			// Check if either operand is void type
			if (left_type == "void" || right_type == "void") {
				log_error("operation on void type");
			}
			
			if (op == "%") {
				// Modulus operator - both operands must be integer
				if (left_type != "" && left_type != "int") {
					log_error("Modulus operator on non integer type");
				}
				if (right_type != "" && right_type != "int") {
					log_error("Modulus operator on non integer type");
				}
				
				// Check if divisor is 0
				if (right_type == "int" && $3->get_name() == "0") {
					log_error("Modulus by 0");
				}
			} else if (op == "/") {
				// Division operator - check if divisor is 0
				if (right_type == "int" && $3->get_name() == "0") {
					log_error("Division by 0");
				}
			}
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");
			$$->set_return_type("int");  // Result of modulus/arithmetic is int
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
			$$->set_return_type($2->get_return_type());
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->get_name(),"un_expr");
			$$->set_return_type("int");
	     }
		 | factor 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"un_expr");
			$$->set_return_type($1->get_return_type());
	     }
		 ;
	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;

		// Check if function is declared
		symbol_info *func_sym = new symbol_info($1->get_name(), "ID");
		symbol_info *found = st->lookup(func_sym);
		
		if (found == NULL) {
			log_error("Undeclared function: " + $1->get_name());
		} else if (found->get_symbol_type() != "Function") {
			log_error("A function call cannot be made with non-function type identifier");
		}
		
		// Check argument count and types
		if (found != NULL && found->get_symbol_type() == "Function") {
			vector<pair<string, string>>& params = found->get_parameters();
			if (current_call_arguments.size() != params.size()) {
				log_error("Inconsistencies in number of arguments in function call: " + $1->get_name());
			} else {
				// Check argument types
				for (size_t i = 0; i < params.size(); i++) {
					string param_type = params[i].first;
					string arg_type = current_call_arguments[i];
					if (arg_type != "" && param_type != arg_type) {
						log_error("argument " + to_string(i+1) + " type mismatch in function call: " + $1->get_name());
					}
				}
			}
		}
		
		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");
		if (found != NULL) {
			$$->set_return_type(found->get_return_type());
		}
		
		current_call_arguments.clear();
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->get_name()+")","fctr");
		$$->set_return_type($2->get_return_type());
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_return_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_return_type("float");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"++","fctr");
		$$->set_return_type($1->get_return_type());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"--","fctr");
		$$->set_return_type($1->get_return_type());
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;
						
					$$ = new symbol_info($1->get_name(),"arg_list");
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");
				current_call_arguments.push_back($3->get_return_type());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name(),"arg");
				current_call_arguments.push_back($1->get_return_type());
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("21101304_log.txt", ios::trunc);
	errlog.open("21101304_error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	
	// Create and initialize symbol table
	st = new symbol_table(10);
	outlog << "New ScopeTable with ID 1 created" << endl << endl;

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	
	outlog.close();
	
	// Write error count to error file
	errlog << "Total errors: " << error_count << endl;
	errlog.close();
	
	fclose(yyin);
	
	delete st;
	
	return 0;
}
