%{

#include "symbol_table.h"
#include <vector>
#include <string>
#include <sstream> // For std::ostringstream

using namespace std;

// create your symbol table here.
symbol_table *sym_table; // Global symbol table instance

extern int lines; // Declared in lex_analyzer.l
ofstream outlog;

// Global variables to store necessary info during parsing
string current_var_type; // To store "int", "float", etc.
// Temporary storage for declaration list IDs
vector<pair<string, int>> current_declaration_list_items; // pair of (name, array_size or -1)

// For function parameters
string current_func_return_type;
string current_func_name;
vector<pair<string, string>> current_func_params_temp; // vector of (type, name) for function parameters

// Global variable to store current type specifier for parameter lists
string current_param_type_specifier;


void yyerror(char *s)
{
    outlog << "At line " << lines << ": Error: " << s;
    if (sym_table) {
        outlog << " (Current Scope ID: " << sym_table->get_current_scope_id() << ")";
    }
    outlog << endl << endl;

    // You may need to reinitialize variables if you find an error
    current_declaration_list_items.clear();
    current_func_params_temp.clear();
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		// Outlog output for start rule for $1->getname() is removed here as it leads to incorrect output format.
		// The previous version was attempting to print $1->getname() which is 'program' and 'unit' names
		// and this is not what log1.txt shows.
		
		// Print your whole symbol table here at the end of parsing
        outlog << endl << "Symbol Table" << endl << endl;
        if (sym_table) {
            sym_table->print_all_scopes(outlog);
        }
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		// outlog output for $1->getname() and $2->getname() removed as per log1.txt
		
		// The `$$ = new symbol_info(...)` lines in program rules are unnecessary
        // since the `program` non-terminal just groups `unit`s. The actual semantic
        // value (code representation) is built by its children.
		// If these were kept, they would need proper memory management (deletion).
        // Since they are not used downstream, we can remove them.
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		// outlog output for $1->getname() removed as per log1.txt
	}
	;

unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		delete $1; // Free memory for temp symbol_info used for display
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		delete $1; // Free memory for temp symbol_info used for display
	 }
     ;

func_definition : type_specifier ID LPAREN {
                                        current_func_return_type = $1->get_name();
                                        current_func_name = $2->get_name();
                                        sym_table->enter_scope(); // Enter new scope for function parameters and body
                                        delete $1; // Free symbol_info for type_specifier
                                        delete $2; // Free symbol_info for ID
                                      } parameter_list RPAREN compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt
			// outlog output for source code segment is handled by $$.get_name()
			
			// Insert parameters into the function's new scope
            for (const auto& param : current_func_params_temp) {
                symbol_info *param_sym = new symbol_info(param.second, "ID");
                param_sym->set_symbol_type("VARIABLE");
                param_sym->set_data_type(param.first);
                if (!sym_table->insert(param_sym)) {
                    yyerror(("Redeclaration of parameter '" + param.second + "'").c_str());
                    delete param_sym;
                }
            }
            // Clear parameter list for next function
            current_func_params_temp.clear();

            // Create symbol_info for the function and insert into the PARENT scope
            symbol_info *func_sym = new symbol_info(current_func_name, "ID"); // type="ID" for function name itself
            func_sym->set_symbol_type("FUNCTION");
            func_sym->set_return_type(current_func_return_type);
            func_sym->set_num_params($4->get_num_params()); // $4 is parameter_list, which should carry num_params
            func_sym->set_param_list($4->get_param_list()); // $4 is parameter_list, which should carry param_list

            // Get the parent scope of the current scope (which is the function's parameter scope)
            scope_table *current_func_param_scope = sym_table->get_current_scope();
            scope_table *parent_of_func_param_scope = current_func_param_scope->get_parent_scope();

            // Insert function into parent's scope (which is actually the scope BEFORE function definition)
            if (!parent_of_func_param_scope->insert_in_scope(func_sym)) {
                yyerror(("Redeclaration of function '" + current_func_name + "' in parent scope").c_str());
                delete func_sym;
            }

            // Now, finally, exit the function parameter scope.
            sym_table->exit_scope(); // This will print the state before this scope is removed.
            
            // Now, assemble the string for $$
            ostringstream oss;
            oss << current_func_return_type << " " << current_func_name << "(";
            bool first_param = true;
            for (const auto& param : $4->get_param_list()) {
                if (!first_param) oss << ",";
                oss << param.first << " " << param.second;
                first_param = false;
            }
            oss << ")\n" << $6->get_name(); // $6 is compound_statement
            
            $$ = new symbol_info(oss.str(), "func_def");

            delete $4; // Free symbol_info from parameter_list
            delete $6; // Free symbol_info from compound_statement

		}
		| type_specifier ID LPAREN {
                                        current_func_return_type = $1->get_name();
                                        current_func_name = $2->get_name();
                                        sym_table->enter_scope(); // Enter new scope for function body
                                        delete $1; // Free symbol_info for type_specifier
                                        delete $2; // Free symbol_info for ID
                                      } RPAREN compound_statement
		{
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt
			// outlog output for source code segment is handled by $$.get_name()
			
            // Create symbol_info for the function and insert into the PARENT scope
            symbol_info *func_sym = new symbol_info(current_func_name, "ID");
            func_sym->set_symbol_type("FUNCTION");
            func_sym->set_return_type(current_func_return_type);
            func_sym->set_num_params(0);

            scope_table *current_func_param_scope = sym_table->get_current_scope();
            scope_table *parent_of_func_param_scope = current_func_param_scope->get_parent_scope();
            if (!parent_of_func_param_scope->insert_in_scope(func_sym)) {
                yyerror(("Redeclaration of function '" + current_func_name + "' in parent scope").c_str());
                delete func_sym;
            }

            sym_table->exit_scope(); // Exit the function's scope.
            
            ostringstream oss;
            oss << current_func_return_type << " " << current_func_name << "()\n" << $5->get_name(); // $5 is compound_statement
            
            $$ = new symbol_info(oss.str(), "func_def");

            delete $5; // Free symbol_info from compound_statement
		}
 		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt format.
			
            // Add parameter to temporary list
            current_func_params_temp.push_back({$3->get_name(), $4->get_name()});

            // Prepare symbol_info for propagation
            ostringstream oss;
            oss << $1->get_name() << "," << $3->get_name() << " " << $4->get_name();
            $$ = new symbol_info(oss.str(), "param_list");
            $$->set_num_params($1->get_num_params() + 1); // Increment count
            
            // Combine param_list from $1 and add new param
            vector<pair<string, string>> combined_params = $1->get_param_list();
            combined_params.push_back({$3->get_name(), $4->get_name()});
            $$->set_param_list(combined_params);

            delete $1; // Free symbol_info for previous parameter_list
            delete $3; // Free symbol_info for type_specifier
            delete $4; // Free symbol_info for ID
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt format.
			
            // Add first parameter to temporary list
            current_func_params_temp.push_back({$1->get_name(), $2->get_name()});

            // Prepare symbol_info for propagation
            ostringstream oss;
            oss << $1->get_name() << " " << $2->get_name();
            $$ = new symbol_info(oss.str(), "param_list");
            $$->set_num_params(1);
            $$->get_param_list().push_back({$1->get_name(), $2->get_name()});

            delete $1; // Free symbol_info for type_specifier
            delete $2; // Free symbol_info for ID
		}
        | parameter_list COMMA type_specifier
        { // Error handling for unnamed parameters - should be caught by parser
            outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
            outlog<<"Error: Parameter type without name."<<endl<<endl;
            yyerror("Parameter type without name");
            
            // To continue parsing, create a symbol_info based on previous list and current type.
            // This won't be inserted into symbol table but allows parser to proceed.
            ostringstream oss;
            oss << $1->get_name() << "," << $3->get_name();
            $$ = new symbol_info(oss.str(), "param_list");
            $$->set_num_params($1->get_num_params());
            $$->set_param_list($1->get_param_list());

            delete $1; // Free symbol_info
            delete $3; // Free symbol_info
        }
        | type_specifier
        { // Error handling for unnamed parameters - should be caught by parser
            outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
            outlog<<"Error: Parameter type without name."<<endl<<endl;
            yyerror("Parameter type without name");

            // Error state, similar to above
            $$ = new symbol_info($1->get_name(), "param_list");
            $$->set_num_params(0);
            
            delete $1; // Free symbol_info
        }
 		;

compound_statement : LCURL { sym_table->enter_scope(); } statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				
				ostringstream oss;
				oss << "{\n" << $3->get_name() << "\n}";
				$$ = new symbol_info(oss.str(),"comp_stmnt");
				
                sym_table->exit_scope();
                delete $3; // Free symbol_info from statements
 		    }
 		    | LCURL { sym_table->enter_scope(); } RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				sym_table->exit_scope();
 		    }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			
            // Insert necessary information about the variables in the symbol table
            for (const auto& item : current_declaration_list_items) {
                symbol_info *var_sym = new symbol_info(item.first, "ID"); // token type is ID
                var_sym->set_symbol_type((item.second == -1) ? "VARIABLE" : "ARRAY");
                var_sym->set_data_type(current_var_type);
                if (item.second != -1) {
                    var_sym->set_array_size(item.second);
                }
                if (!sym_table->insert(var_sym)) {
                    yyerror(("Redeclaration of variable '" + item.first + "' in the same scope").c_str());
                    delete var_sym; // Don't leak if not inserted
                }
            }
            current_declaration_list_items.clear(); // Clear for next declaration

            ostringstream oss;
            oss << $1->get_name() << " " << $2->get_name() << ";";
			$$ = new symbol_info(oss.str(),"var_dec");
            
            delete $1; // Free symbol_info for type_specifier
            delete $2; // Free symbol_info for declaration_list
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
            current_var_type = "int"; // Store current type for variable declarations
            current_param_type_specifier = "int"; // Store for parameter lists
			$$ = new symbol_info("int","type");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
            current_var_type = "float"; // Store current type for variable declarations
            current_param_type_specifier = "float"; // Store for parameter lists
			$$ = new symbol_info("float","type");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			
            current_var_type = "void"; // Store current type for variable declarations
            current_param_type_specifier = "void"; // Store for parameter lists
			$$ = new symbol_info("void","type");
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	// outlog output for grammar rule is removed as per log1.txt format.
			
            // Add ID to the list of declared items with array_size = -1 (not an array)
            current_declaration_list_items.push_back({$3->get_name(), -1});

            ostringstream oss;
            oss << $1->get_name() << "," << $3->get_name();
            $$ = new symbol_info(oss.str()); // Use default constructor then set name
            $$->set_name(oss.str());

            delete $1; // Free symbol_info for previous declaration_list
            delete $3; // Free symbol_info for ID
		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	// outlog output for grammar rule is removed as per log1.txt format.
			
            // Add Array ID and size to the list
            int array_size = stoi($5->get_name()); // Assuming CONST_INT stores string representation
            current_declaration_list_items.push_back({$3->get_name(), array_size});

            ostringstream oss;
            oss << $1->get_name() << "," << $3->get_name() << "[" << $5->get_name() << "]";
            $$ = new symbol_info(oss.str());
            $$->set_name(oss.str());

            delete $1; // Free symbol_info for previous declaration_list
            delete $3; // Free symbol_info for ID
            delete $5; // Free symbol_info for CONST_INT
		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt format.
			
            // Add single ID to the list
            current_declaration_list_items.push_back({$1->get_name(), -1});
            $$ = new symbol_info($1->get_name()); // Use default constructor then set name
            $$->set_name($1->get_name());
            
            delete $1; // Free symbol_info for ID
		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt format.
			
            // Add single Array ID and size to the list
            int array_size = stoi($3->get_name());
            current_declaration_list_items.push_back({$1->get_name(), array_size});

            ostringstream oss;
            oss << $1->get_name() << "[" << $3->get_name() << "]";
            $$ = new symbol_info(oss.str());
            $$->set_name(oss.str());

            delete $1; // Free symbol_info for ID
            delete $3; // Free symbol_info for CONST_INT
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnts");
            delete $1; // Free symbol_info from statement
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			// outlog output for $1->getname() and $2->getname() is removed here as it's part of the $$ construction
			
            ostringstream oss;
            oss << $1->get_name() << "\n" << $2->get_name();
			$$ = new symbol_info(oss.str(),"stmnts");
            
            delete $1; // Free symbol_info from statements
            delete $2; // Free symbol_info from statement
	   }
	   ;
	   
statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
            delete $1; // Free symbol_info from var_declaration
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"stmnt");
            delete $1; // Free symbol_info from func_definition
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
            delete $1; // Free symbol_info from expression_statement
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
            delete $1; // Free symbol_info from compound_statement
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt
			
            ostringstream oss;
            oss << "for(" << $3->get_name() << $4->get_name() << $5->get_name() << ")\n" << $7->get_name();
			$$ = new symbol_info(oss.str(),"stmnt");

            delete $3; delete $4; delete $5; delete $7; // Free symbol_info objects
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt
			
            ostringstream oss;
            oss << "if(" << $3->get_name() << ")\n" << $5->get_name();
			$$ = new symbol_info(oss.str(),"stmnt");

            delete $3; delete $5; // Free symbol_info objects
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt
			
            ostringstream oss;
            oss << "if(" << $3->get_name() << ")\n" << $5->get_name() << "\nelse\n" << $7->get_name();
			$$ = new symbol_info(oss.str(),"stmnt");

            delete $3; delete $5; delete $7; // Free symbol_info objects
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			// outlog output for grammar rule is removed as per log1.txt
			
            ostringstream oss;
            oss << "while(" << $3->get_name() << ")\n" << $5->get_name();
			$$ = new symbol_info(oss.str(),"stmnt");

            delete $3; delete $5; // Free symbol_info objects
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl; 
			
			$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");
            delete $3; // Free symbol_info for ID
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
            delete $2; // Free symbol_info for expression
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
                delete $1; // Free symbol_info for expression
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"varbl");
        delete $1; // Free symbol_info for ID
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		
        ostringstream oss;
        oss << $1->get_name() << "[" << $3->get_name() << "]";
		$$ = new symbol_info(oss.str(),"varbl");

        delete $1; // Free symbol_info for ID
        delete $3; // Free symbol_info for expression
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"expr");
            delete $1; // Free symbol_info for logic_expression
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			
            ostringstream oss;
            oss << $1->get_name() << "=" << $3->get_name();
			$$ = new symbol_info(oss.str(),"expr");

            delete $1; // Free symbol_info for variable
            // $2 (ASSIGNOP) is a token, no symbol_info is allocated by lexer for it, but if it was, it would be deleted.
            delete $3; // Free symbol_info for logic_expression
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"lgc_expr");
            delete $1; // Free symbol_info for rel_expression
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			
            ostringstream oss;
            oss << $1->get_name() << $2->get_name() << $3->get_name();
			$$ = new symbol_info(oss.str(),"lgc_expr");

            delete $1; // Free symbol_info for rel_expression
            // $2 (LOGICOP) is a token
            delete $3; // Free symbol_info for rel_expression
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"rel_expr");
            delete $1; // Free symbol_info for simple_expression
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			
            ostringstream oss;
            oss << $1->get_name() << $2->get_name() << $3->get_name();
			$$ = new symbol_info(oss.str(),"rel_expr");

            delete $1; // Free symbol_info for simple_expression
            // $2 (RELOP) is a token
            delete $3; // Free symbol_info for simple_expression
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"simp_expr");
            delete $1; // Free symbol_info for term
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			
            ostringstream oss;
            oss << $1->get_name() << $2->get_name() << $3->get_name();
			$$ = new symbol_info(oss.str(),"simp_expr");

            delete $1; // Free symbol_info for simple_expression
            // $2 (ADDOP) is a token
            delete $3; // Free symbol_info for term
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"term");
            delete $1; // Free symbol_info for unary_expression
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			
            ostringstream oss;
            oss << $1->get_name() << $2->get_name() << $3->get_name();
			$$ = new symbol_info(oss.str(),"term");
            
            delete $1; // Free symbol_info for term
            // $2 (MULOP) is a token
            delete $3; // Free symbol_info for unary_expression
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			
            ostringstream oss;
            oss << $1->get_name() << $2->get_name();
			$$ = new symbol_info(oss.str(),"un_expr");

            // $1 (ADDOP) is a token
            delete $2; // Free symbol_info for unary_expression
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			
            ostringstream oss;
            oss << "!" << $2->get_name();
			$$ = new symbol_info(oss.str(),"un_expr");

            // $1 (NOT) is a token
            delete $2; // Free symbol_info for unary_expression
	     }
		 | factor 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"un_expr");
            delete $1; // Free symbol_info for factor
	     }
		 ;
	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
        delete $1; // Free symbol_info for variable
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		
        ostringstream oss;
        oss << $1->get_name() << "(" << $3->get_name() << ")";
		$$ = new symbol_info(oss.str(),"fctr");

        delete $1; // Free symbol_info for ID
        delete $3; // Free symbol_info for argument_list
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		
        ostringstream oss;
        oss << "(" << $2->get_name() << ")";
		$$ = new symbol_info(oss.str(),"fctr");

        delete $2; // Free symbol_info for expression
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
        delete $1; // Free symbol_info for CONST_INT
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"fctr");
        delete $1; // Free symbol_info for CONST_FLOAT
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		
        ostringstream oss;
        oss << $1->get_name() << "++";
		$$ = new symbol_info(oss.str(),"fctr");

        delete $1; // Free symbol_info for variable
        // INCOP is a token
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		
        ostringstream oss;
        oss << $1->get_name() << "--";
		$$ = new symbol_info(oss.str(),"fctr");

        delete $1; // Free symbol_info for variable
        // DECOP is a token
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					//outlog<<$1->get_name()<<endl<<endl; // Removed as per instruction
						
					$$ = new symbol_info($1->get_name(),"arg_list");
                    delete $1; // Free symbol_info for arguments
			  }
			  | /* empty */
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

                delete $1; // Free symbol_info for arguments
                delete $3; // Free symbol_info for logic_expression
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name(),"arg");
                delete $1; // Free symbol_info for logic_expression
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
	
    // Change log file name as per student ID
    // TODO: Replace "YOUR_STUDENT_ID" with actual student ID or implement a mechanism to get it
    string student_id = "00000000"; // Placeholder student ID
    string log_file_name = student_id + "_log.txt";
	outlog.open(log_file_name, ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		outlog<<"Couldn't open input file: "<<argv[1]<<endl;
		return 0;
	}
	
    // Enter the global or the first scope here
    sym_table = new symbol_table(7); // Create symbol table with 7 buckets (arbitrary choice, could be parameter)

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	
	outlog.close();
	
	fclose(yyin);

    if (sym_table) {
        delete sym_table; // Clean up global symbol table
        sym_table = nullptr;
    }
	
	return 0;
}