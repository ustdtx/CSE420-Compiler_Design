# Pre-Execution Checklist

Run this checklist before executing the script to ensure everything is ready.

## Required Files Present

- [ ] `symbol_info.h` - exists and readable
- [ ] `scope_table.h` - exists and readable
- [ ] `symbol_table.h` - exists and readable
- [ ] `lex_analyzer.l` - exists and readable
- [ ] `syntax_analyzer.y` - exists and readable
- [ ] `input.txt` - exists and readable
- [ ] `script.sh` - exists and executable

## File Contents Verification

### symbol_table.h
- [ ] Contains `scope_table* get_current_scope();` declaration
- [ ] Contains `scope_table* symbol_table::get_current_scope()` implementation

### syntax_analyzer.y
- [ ] Contains `string current_function_name = "";`
- [ ] Contains `string current_function_return_type = "";`
- [ ] Contains `func_name : ID` rule
- [ ] Contains `func_insert :` rule
- [ ] Contains `func_insert_no_params :` rule
- [ ] Contains `func_insert` in func_definition rule (before scope_enter)
- [ ] All instances changed from `->getname()` to `->get_name()`
- [ ] Main function opens file "21101304_log.txt"

## No Syntax Errors
- [ ] syntax_analyzer.y has no red squiggles
- [ ] symbol_table.h has no red squiggles
- [ ] scope_table.h has no red squiggles
- [ ] symbol_info.h has no red squiggles

## Ready to Build
- [ ] yacc/bison command available
- [ ] flex command available
- [ ] g++ compiler available
- [ ] bash shell available

## Build Steps
```
[ ] Run: yacc -d -y --debug --verbose syntax_analyzer.y
[ ] Run: flex lex_analyzer.l
[ ] Run: g++ -w -c -o y.o y.tab.c
[ ] Run: g++ -fpermissive -w -c -o l.o lex.yy.c
[ ] Run: g++ y.o l.o -o a.exe
```

## Execution
```
[ ] Run: ./a.exe input.txt
```

## Output Verification
After execution, check `21101304_log.txt`:

- [ ] Contains "New ScopeTable with ID 1 created"
- [ ] Contains "New ScopeTable with ID 2 created"
- [ ] Contains grammar rules with line numbers
- [ ] Contains "ScopeTable # 1"
- [ ] Contains "ScopeTable # 2" (or higher)
- [ ] Contains symbol information with types
- [ ] Contains "Scopetable with ID X removed" messages
- [ ] Contains "Total lines: 24" (or correct count)
- [ ] Functions appear in global scope
- [ ] Variables appear in correct scopes

## Quick Test

### Command
```bash
cd Lab02_base
bash script.sh
```

### Expected Output (end of console)
```
logfile
New ScopeTable with ID 1 created

At line no: 1 type_specifier : INT
...
```

### Expected Log File (21101304_log.txt)
Should exist and contain symbol table information.

## Success Indicators

✅ Script runs without errors
✅ 21101304_log.txt is created
✅ Output contains scope information
✅ Functions are in parent scope
✅ Variables are in correct scopes
✅ Arrays show size information
✅ Total lines count is shown

---

## If Something Goes Wrong

### Issue: "command not found: yacc"
**Solution:** Install `bison` package, then add `-y` flag to yacc command

### Issue: "No members named 'get_name'"
**Solution:** Check that symbol_info.h has `get_name()` method (not `getname()`)

### Issue: "No members named 'get_current_scope'"
**Solution:** Check symbol_table.h line 20 - should have the declaration

### Issue: "func_insert not recognized"
**Solution:** Check syntax_analyzer.y has `func_insert :` rule definition

### Issue: Output missing scopes
**Solution:** Verify `func_insert` comes before `scope_enter` in func_definition

### Issue: Functions not in parent scope
**Solution:** Ensure `st->insert()` is called in `func_insert` action

---

## All Clear? ✓

If all checkboxes above are checked, proceed with:

```bash
cd Lab02_base
bash script.sh
```

The output should automatically appear, and `21101304_log.txt` will be created.

---

**Last Updated:** December 5, 2025
**Status:** Ready for Execution
