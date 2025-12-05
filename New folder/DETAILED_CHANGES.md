# Detailed Changes Made to Complete the Lab

## 1. symbol_table.h - Added get_current_scope() Method

### Location: Line 20 (declaration) and Line 119+ (implementation)

**Added Declaration:**
```cpp
public:
    scope_table* get_current_scope();  // NEW
```

**Added Implementation:**
```cpp
scope_table* symbol_table::get_current_scope()
{
    return current_scope;
}
```

**Why Needed:** The `scope_enter` action in the grammar needs to print the ID of the next scope before creating it. Without this method, we couldn't access the current scope to call `get_unique_id()` on it.

---

## 2. syntax_analyzer.y - Global Variables

### Location: Lines 21-25 (after existing variables)

**Added:**
```cpp
string current_function_name = "";  // To track function name before entering scope
string current_function_return_type = "";  // To track return type before entering scope
```

**Why Needed:** When we parse `int func(...)`, we need to:
1. Capture the function name (`func`)
2. Capture the return type (`int`)
3. Insert the function symbol into the PARENT scope
4. THEN enter a new scope for the function body

These variables maintain this information between the time we see the function signature and when we call the insertion rule.

---

## 3. syntax_analyzer.y - New Grammar Rule: func_name

### Location: Lines 111-119

**Added Rule:**
```yacc
func_name : ID
		{
			current_function_name = $1->get_name();
			current_function_return_type = current_type;
			$$ = $1;
		}
		;
```

**Purpose:** When we encounter an ID in a function definition, this rule:
1. Captures the name from the ID token
2. Captures the return type (already set by type_specifier rule)
3. Returns the ID for use in the func_definition rule
4. Saves both for use in the func_insert rule

---

## 4. syntax_analyzer.y - Modified func_definition Rules

### Location: Lines 88-109

**Before:** 
```yacc
func_definition : type_specifier ID LPAREN parameter_list RPAREN scope_enter compound_statement
```

**After:**
```yacc
func_definition : type_specifier func_name LPAREN parameter_list RPAREN func_insert scope_enter compound_statement
```

**Changes:**
- `ID` → `func_name` (allows us to capture the function name)
- Added `func_insert` before `scope_enter` (insert function before entering scope)
- Updated array indices: `$8` for compound_statement instead of `$7`

Same changes for the no-parameter variant.

---

## 5. syntax_analyzer.y - New Grammar Rules: func_insert and func_insert_no_params

### Location: Lines 121-143

**Added Rules:**
```yacc
func_insert : 
		{
			symbol_info *func_sym = new symbol_info(current_function_name, "ID");
			func_sym->set_symbol_type("Function");
			func_sym->set_return_type(current_function_return_type);
			for (auto param : current_parameters) {
				func_sym->add_parameter(param.first, param.second);
			}
			st->insert(func_sym);
		}
		;

func_insert_no_params :
		{
			symbol_info *func_sym = new symbol_info(current_function_name, "ID");
			func_sym->set_symbol_type("Function");
			func_sym->set_return_type(current_function_return_type);
			st->insert(func_sym);
		}
 		;
```

**Purpose:** These rules are executed AFTER parsing the function signature but BEFORE entering the function scope. They:
1. Create a new symbol_info object for the function
2. Set its symbol_type to "Function"
3. Set its return_type from the captured value
4. Add all collected parameters
5. Insert it into the current scope (which is still the parent scope)

This is the key to getting functions in the correct scope!

---

## 6. syntax_analyzer.y - Fixed All Method Calls

### Location: Throughout the entire file

**Changed:** All instances of `->getname()` to `->get_name()`

**Example:**
```cpp
// Before
outlog<<$1->getname()<<$2->getname()<<endl<<endl;

// After
outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;
```

**How:** Used PowerShell regex replacement:
```powershell
(Get-Content syntax_analyzer.y) -replace '->getname\(\)', '->get_name()' | Set-Content syntax_analyzer.y
```

This affects ALL grammar rules' actions where we print or use symbol information.

---

## Summary of Flow

### For a function like `int func() { ... }`

1. **type_specifier** matches `int`
   - Sets `current_type = "int"`

2. **func_name** matches `func`
   - Sets `current_function_name = "func"`
   - Sets `current_function_return_type = "int"`

3. **func_insert** action executes
   - Creates symbol_info("func", "ID")
   - Calls `st->insert()` in current (parent) scope
   - Function is now in parent scope!

4. **scope_enter** action executes
   - Creates new scope for function body
   - New scope ID becomes current

5. **compound_statement** matches `{ ... }`
   - Local variables inserted into function scope
   - At end of `}`, calls `exit_scope()`
   - Prints function scope contents
   - Removes function scope

6. Back in parent scope with function symbol present

---

## Key Design Principle

**Functions must be inserted in their PARENT scope, not in their own scope.**

This is achieved by:
1. Creating insertion rules that execute BEFORE scope entry
2. Using global variables to maintain function info between rules
3. Calling `st->insert()` while still in the parent scope

This ensures that when someone looks up a function by name, they find it in the scope where it was declared, not in its own function body scope.
