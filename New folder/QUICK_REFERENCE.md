# Quick Reference - Lab02_base Symbol Table

## Build & Run
```bash
cd Lab02_base
bash script.sh
```

## Key Files Modified

| File | Change | Purpose |
|------|--------|---------|
| symbol_table.h | Added `get_current_scope()` | Access current scope for ID printing |
| syntax_analyzer.y | Added global tracking vars | Store function name & return type before scope entry |
| syntax_analyzer.y | New `func_name` rule | Capture function name from ID |
| syntax_analyzer.y | New `func_insert` rules | Insert function in parent scope |
| syntax_analyzer.y | Fixed `getname()` → `get_name()` | Correct method calls throughout |

## Core Concept

**Functions must be in their parent scope, not their own scope**

```
Global Scope (1)
  └─ func() [stored here] ✓
     └─ Function Body Scope (2)
        ├─ parameter x
        ├─ local var a
        └─ nested block scope
```

## Symbol Table Operations

| Operation | When | Where |
|-----------|------|-------|
| Create Scope | Function/Block entry | Before parsing body |
| Insert Symbol | Variable/Function found | In current scope |
| Lookup Symbol | Reference found | Current, then parents |
| Print Scope | Scope exit | Before removing scope |
| Exit Scope | Block end | Call `exit_scope()` |

## Output Example

```
New ScopeTable with ID 1 created

At line no: 1 type_specifier : INT
int

New ScopeTable with ID 2 created

...

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

Total lines: 24
```

## Variable Type Storage

| Symbol Type | Stored Info |
|-------------|-------------|
| Variable | name, type |
| Array | name, type, size |
| Function | name, return_type, parameters |

## Grammar Rules Added

```yacc
func_name : ID
{
  current_function_name = $1->get_name();
  current_function_return_type = current_type;
  $$ = $1;
}

func_insert : { /* insert in parent scope */ }

func_insert_no_params : { /* insert in parent scope */ }
```

## Scope ID Numbering

- **ID 1**: Global scope (created at startup)
- **ID 2+**: Functions and nested blocks (in order of creation)

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Compilation error: `getname()` | Already fixed - use `get_name()` |
| Compilation error: `get_current_scope()` | Already added to symbol_table.h |
| Function not appearing in output | Check if inserted before `scope_enter` |
| Variables in wrong scope | Verify insertion in `var_declaration` rule |
| Scopes not printing on exit | Ensure `st->exit_scope(outlog)` called |

## Test Input (input.txt)

```c
int func(int a, float b) {
    return a+b;
}

void main () {
    int a, b, c, i;
    int e, f[10], g[11];
    a = 1;
    b = 2;
    c = func(a, b);

    float d;
}
```

## Expected Behavior

1. Creates scope for global (ID 1)
2. Inserts `func` in global scope BEFORE entering function scope
3. Creates scope for function body (ID 2)
4. Inserts parameters and local variables in scope 2
5. Prints scope 2 and removes it when function ends
6. Continues with main
7. Final print shows global scope with all functions

## Verifying Correctness

✅ Output has "New ScopeTable" messages
✅ Functions appear in parent scope output
✅ Variables appear in correct scope
✅ Proper nesting: global > function > blocks
✅ All scopes printed on exit
✅ Total line count matches input

---
**Everything Complete** ✓
