#include "scope_table.h"
#include <fstream>
#include <iostream> // For cerr

extern std::ofstream outlog; // Declare outlog as extern

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int next_scope_id; // Renamed from current_scope_id to avoid confusion and better reflect its purpose

public:
    symbol_table(int bucket_count)
    {
        this->bucket_count = bucket_count;
        this->next_scope_id = 1; // Global scope will be ID 1
        current_scope = nullptr;
        enter_scope(); // Create the global scope immediately
    }

    ~symbol_table()
    {
        // Delete all scope tables
        while (current_scope != nullptr)
        {
            scope_table *temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }

    void enter_scope()
    {
        scope_table *new_scope = new scope_table(bucket_count, next_scope_id, current_scope);
        current_scope = new_scope;
        outlog << "New ScopeTable with ID " << next_scope_id << " created" << endl << endl;
        next_scope_id++;
    }

    void exit_scope()
    {
        if (current_scope == nullptr)
        {
            // Should not happen if logic is correct
            return;
        }

        outlog << "Scopetable with ID " << current_scope->get_unique_id() << " removed" << endl << endl;

        // Print current state of the symbol table AFTER removing current scope conceptually,
        // but before actually deleting it. The spec says "when you exit a scope print the
        // current state of the symbol table", which implies the state _after_ this scope is gone.
        // So we'll print the parent scope and its ancestors.
        
        // Temporarily move current_scope back to parent to print the "remaining" scopes
        scope_table *scope_to_delete = current_scope;
        current_scope = current_scope->get_parent_scope();
        
        if (current_scope != nullptr) { // Don't print if it was the last scope
             print_all_scopes(outlog);
        } else {
            // If global scope is being removed, print an empty symbol table representation
            // or just the separators if no scopes remain.
            outlog<<"################################"<<endl<<endl;
            outlog<<"################################"<<endl<<endl;
        }

        delete scope_to_delete; // Actually delete the exited scope table
    }

    bool insert(symbol_info *symbol)
    {
        if (current_scope == nullptr)
        {
            return false; // No active scope
        }
        return current_scope->insert_in_scope(symbol);
    }

    bool remove(string name)
    {
        if (current_scope == nullptr)
        {
            return false; // No active scope
        }
        return current_scope->delete_from_scope(name);
    }

    symbol_info *lookup(string name)
    {
        scope_table *temp_scope = current_scope;
        while (temp_scope != nullptr)
        {
            symbol_info *sym = temp_scope->lookup_in_scope(name);
            if (sym != nullptr)
            {
                return sym;
            }
            temp_scope = temp_scope->get_parent_scope();
        }
        return nullptr; // Not found in any scope
    }

    void print_current_scope()
    {
        if (current_scope != nullptr)
        {
            outlog << endl << "Current Scope: " << current_scope->get_unique_id() << endl;
            current_scope->print_scope_table(outlog);
        }
    }

    void print_all_scopes(ofstream &outlog)
    {
        outlog << "################################" << endl << endl;
        scope_table *temp = current_scope;
        while (temp != nullptr)
        {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
        outlog << "################################" << endl << endl;
    }
    
    // Getter for current scope ID, useful for debugging
    int get_current_scope_id() const {
        if (current_scope) return current_scope->get_unique_id();
        return 0; // Or some indicator for no current scope
    }
};