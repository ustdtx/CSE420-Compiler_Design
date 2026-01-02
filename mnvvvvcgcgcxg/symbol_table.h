#include "scope_table.h"

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count);
    ~symbol_table();
    void enter_scope();
    void exit_scope(ofstream& outlog);
    bool insert(symbol_info* symbol);
    bool remove(symbol_info* symbol);
    symbol_info* lookup(symbol_info* symbol);
    void print_current_scope(ofstream& outlog);
    void print_all_scopes(ofstream& outlog);
    scope_table* get_current_scope();

    // you can add more methods if you need 
};

// complete the methods of symbol_table class
symbol_table::symbol_table(int bucket_count)
{
    this->bucket_count = bucket_count;
    this->current_scope_id = 1;
    this->current_scope = new scope_table(bucket_count, current_scope_id, NULL);
}

symbol_table::~symbol_table()
{
    // Clean up all scopes
    while (current_scope != NULL) {
        scope_table *parent = current_scope->get_parent_scope();
        delete current_scope;
        current_scope = parent;
    }
}

void symbol_table::enter_scope()
{
    current_scope_id++;
    scope_table *new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
    current_scope = new_scope;
}

void symbol_table::exit_scope(ofstream& outlog)
{
    if (current_scope != NULL) {
        scope_table *parent = current_scope->get_parent_scope();
        outlog << "Scopetable with ID " << current_scope->get_unique_id() << " removed" << endl << endl;
        
        outlog << "################################" << endl << endl;
        current_scope->print_scope_table(outlog);
        outlog << "################################" << endl << endl;

        delete current_scope;
        current_scope = parent;
    }
}

bool symbol_table::insert(symbol_info *symbol)
{
    if (current_scope != NULL) {
        return current_scope->insert_in_scope(symbol);
    }
    return false;
}

bool symbol_table::remove(symbol_info *symbol)
{
    if (current_scope != NULL) {
        return current_scope->delete_from_scope(symbol);
    }
    return false;
}

symbol_info *symbol_table::lookup(symbol_info *symbol)
{
    scope_table *scope = current_scope;
    while (scope != NULL) {
        symbol_info *found = scope->lookup_in_scope(symbol);
        if (found != NULL) {
            return found;
        }
        scope = scope->get_parent_scope();
    }
    return NULL;
}

void symbol_table::print_current_scope(ofstream& outlog)
{
    if (current_scope != NULL) {
        current_scope->print_scope_table(outlog);
    }
}

void symbol_table::print_all_scopes(ofstream& outlog)
{
    outlog << "################################" << endl << endl;
    
    // Collect all scopes in a vector
    vector<scope_table*> scope_stack;
    scope_table *temp = current_scope;
    while (temp != NULL) {
        scope_stack.push_back(temp);
        temp = temp->get_parent_scope();
    }
    
    // Print in reverse order (from global to current)
    for (int i = scope_stack.size() - 1; i >= 0; i--) {
        scope_stack[i]->print_scope_table(outlog);
    }
    
    outlog << "################################" << endl << endl;
}

scope_table* symbol_table::get_current_scope()
{
    return current_scope;
}