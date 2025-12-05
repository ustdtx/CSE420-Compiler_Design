# Lab02_base - Symbol Table Implementation

## Overview
This is a complete implementation of a symbol table for a subset of C language compiler. The symbol table maintains scope information and handles:
- Variable declarations (simple variables and arrays)
- Function definitions with parameters
- Nested scopes (global, function, blocks)

## Files in This Directory

### Headers
- **symbol_info.h**: Data structure for storing symbol information (name, type, symbol_type, return_type, parameters, array_size)
- **scope_table.h**: Hash table implementation for a single scope with parent pointer
- **symbol_table.h**: Stack of scope tables for managing nested scopes

### Lexer & Parser
- **lex_analyzer.l**: Lexical analyzer (tokenizer)
- **syntax_analyzer.y**: YACC grammar file with symbol table actions

### Build & Run
- **script.sh**: Bash script to compile and run the compiler

### Input & Output
- **input.txt**: Sample C program input
- **21101304_log.txt**: Output log file (generated)

## How to Compile and Run

```bash
cd Lab02_base
bash script.sh
```

This will:
1. Run `yacc` to generate parser from `syntax_analyzer.y`
2. Run `flex` to generate lexer from `lex_analyzer.l`
3. Compile everything with `g++`
4. Execute with `input.txt`
5. Display the output from `21101304_log.txt`

## Implementation Details

### Symbol Table Structure
```
Symbol Table
├── Scope 1 (Global)
│   ├── func [bucket 8]: Function, return type int, 0 parameters
│   └── ...
├── Scope 2 (Function body)
│   ├── a [bucket 7]: Variable, type int
│   └── ...
└── Scope 3 (if block)
    ├── a [bucket 7]: Variable, type float
    └── ...
```

### Key Features
1. **Scope Management**: Each scope has a unique ID and maintains parent reference
2. **Hashing**: Uses simple character sum modulo bucket_count
3. **Nested Lookups**: Searches current scope, then parent scopes
4. **Symbol Information**: Stores name, type, symbol_type, and extra details for arrays/functions
5. **Logging**: Comprehensive output showing scope creation/removal and symbol table state

### Global Scope (ID 1)
Created at program startup, contains global variables and function definitions

### Function Scopes
- Created when function definition is encountered
- Function name and signature stored in parent scope BEFORE entering
- Function parameters stored in function scope
- Local variables stored in function scope

### Nested Block Scopes
- Created for if/while/for statement blocks
- Local variables shadow outer scope variables
- Removed after block ends

## Output Format

```
New ScopeTable with ID 1 created

At line no: 1 type_specifier : INT 
int

New ScopeTable with ID 2 created

At line no: 3 var_declaration : type_specifier declaration_list SEMICOLON 
int a;

... (more rules)

################################

ScopeTable # 2
7 --> 
< a : ID >
Variable
Type: int

ScopeTable # 1
8 --> 
< func : ID >
Function Definition
Return Type: int
Number of Parameters: 0
Parameter Details: 

################################

Scopetable with ID 2 removed

... (more output)

Total lines: 24
```

## Key Modifications from Base

1. **Added `get_current_scope()` method** to `symbol_table` class to allow access to current scope for printing IDs

2. **Added function tracking variables**:
   - `current_function_name`
   - `current_function_return_type`

3. **New grammar rules**:
   - `func_name`: Captures function name and sets tracking variables
   - `func_insert`: Inserts function in parent scope before entering
   - `func_insert_no_params`: Inserts function with no parameters

4. **Fixed all method calls**: Changed `getname()` to `get_name()` throughout

## Testing

The implementation has been tested to:
- ✅ Correctly parse C function and variable declarations
- ✅ Create and manage nested scopes
- ✅ Insert symbols with proper type information
- ✅ Handle arrays with size information
- ✅ Store function parameters
- ✅ Print complete symbol table on scope exit
- ✅ Match expected output format

## Troubleshooting

If compilation fails:
1. Ensure `flex` and `yacc` (or `bison` with `-y` flag) are installed
2. Check that all header files are in the same directory
3. Verify `input.txt` exists and has valid C-like code

If output is incorrect:
1. Check `21101304_log.txt` for details
2. Verify grammar rules are being matched
3. Ensure scopes are created and destroyed in correct order
