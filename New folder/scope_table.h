#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        // Simple hash function using sum of characters modulo bucket_count
        int hash_value = 0;
        for (char c : name) {
            hash_value += (int)c;
        }
        return hash_value % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info* symbol);
    bool insert_in_scope(symbol_info* symbol);
    bool delete_from_scope(symbol_info* symbol);
    void print_scope_table(ofstream& outlog);
    ~scope_table();

    // you can add more methods if you need
};

// complete the methods of scope_table class
scope_table::scope_table()
{
    this->bucket_count = 10;
    this->unique_id = 0;
    this->parent_scope = NULL;
    this->table.assign(bucket_count, list<symbol_info*>());
}

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;
    this->table.assign(bucket_count, list<symbol_info*>());
}

scope_table *scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}

symbol_info *scope_table::lookup_in_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());
    for (auto it = table[index].begin(); it != table[index].end(); ++it) {
        if ((*it)->get_name() == symbol->get_name()) {
            return *it;
        }
    }
    return NULL;
}

bool scope_table::insert_in_scope(symbol_info* symbol)
{
    // Check if symbol already exists in this scope
    if (lookup_in_scope(symbol) != NULL) {
        return false;  // Already exists
    }
    
    int index = hash_function(symbol->get_name());
    table[index].push_back(symbol);
    return true;
}

bool scope_table::delete_from_scope(symbol_info* symbol)
{
    int index = hash_function(symbol->get_name());
    for (auto it = table[index].begin(); it != table[index].end(); ++it) {
        if ((*it)->get_name() == symbol->get_name()) {
            table[index].erase(it);
            return true;
        }
    }
    return false;
}

void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # " << unique_id << endl;

    // Iterate through the current scope table and print the symbols and all relevant information
    for (int i = 0; i < bucket_count; i++) {
        if (!table[i].empty()) {
            outlog << i << " --> ";
            for (auto symbol : table[i]) {
                outlog << "< " << symbol->get_name() << " : " << symbol->get_type() << " >";
                
                if (symbol->get_symbol_type() == "Variable") {
                    outlog << "\nVariable\nType: " << symbol->get_return_type();
                } else if (symbol->get_symbol_type() == "Array") {
                    outlog << "\nArray\nType: " << symbol->get_return_type() << "\nSize: " << symbol->get_array_size();
                } else if (symbol->get_symbol_type() == "Function") {
                    outlog << "\nFunction Definition\nReturn Type: " << symbol->get_return_type() 
                           << "\nNumber of Parameters: " << symbol->get_parameters().size() 
                           << "\nParameter Details: ";
                    for (auto param : symbol->get_parameters()) {
                        outlog << param.first << " " << param.second << ", ";
                    }
                }
                outlog << endl << endl;
            }
        }
    }

    outlog << endl;
}

scope_table::~scope_table()
{
    // table will be automatically cleaned up when the vector is destroyed
}