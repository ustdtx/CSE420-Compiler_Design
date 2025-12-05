# Lab02_base Changes Summary

## Files Modified

### 1. **symbol_table.h**
   - Added `get_current_scope()` method declaration in public section
   - Implemented `get_current_scope()` method that returns the current scope table pointer

### 2. **syntax_analyzer.y**
   - Added global variables to track function information before entering scope:
     - `string current_function_name`
     - `string current_function_return_type`
   
   - Created new grammar rule `func_name` to capture function name and return type
   - Modified `func_definition` rules to use `func_name` instead of direct ID
   - Created `func_insert` and `func_insert_no_params` rules to insert functions in the parent scope before entering the function's scope
   
   - Fixed all method calls from `getname()` to `get_name()` throughout the file
   - Function insertion now happens in the correct scope (parent scope, not function scope)

## How It Works

### Symbol Table Creation Flow:
1. **Lexical Analysis**: Tokenizes the input using `lex_analyzer.l`
2. **Syntax Analysis**: Parses using `syntax_analyzer.y`
3. **Symbol Table Management**:
   - Global scope (ID 1) created at startup
   - When entering a block/function, a new scope is created with a new ID
   - When exiting a scope, the current scope is printed and removed

### Function Definition Handling:
1. When `func_definition` rule matches:
   - Type specifier sets `current_type`
   - `func_name` rule captures the function name and sets `current_function_name` and `current_function_return_type`
   - `func_insert` rule creates a `symbol_info` object with the function details and inserts it into the current (parent) scope
   - `scope_enter` creates a new scope for the function body
   - Function parameters are inserted into this new scope when parsed
   - `compound_statement` ends with `exit_scope()` which prints the scope table and removes it

### Variable Declaration Handling:
1. Type specifier sets `current_type`
2. Declaration list captures variable names in `current_declarations`
3. At end of `var_declaration`, all variables are inserted into the current scope with:
   - Name, type, and symbol_type (Variable/Array)
   - Array size if applicable

## Output Format
The output file `21101304_log.txt` will contain:
- Matched grammar rules with source code
- Scope creation messages with ID numbers
- Scope removal messages
- Symbol table contents when scopes are exited
- Total line count at the end

## Testing
Run the compilation script:
```bash
bash script.sh
```

This will:
1. Generate parser from yacc (syntax_analyzer.y)
2. Generate scanner from flex (lex_analyzer.l)
3. Compile to `a.exe`
4. Run with `input.txt`
5. Display `21101304_log.txt` output
