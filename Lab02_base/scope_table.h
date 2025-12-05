#include "symbol_info.h"
#include <vector>
#include <list>
#include <string>
#include <fstream>
#include <utility> // for std::pair

using namespace std;

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope;
    vector<list<symbol_info *>> table;

    // A simple hash function: sum of ASCII values modulo bucket_count
    int hash_function(string name)
    {
        long long sum = 0;
        for (char c : name)
        {
            sum = (sum + c) % bucket_count;
        }
        return (int)sum;
    }

public:
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
    }

    scope_table *get_parent_scope() const { return parent_scope; }
    int get_unique_id() const { return unique_id; }

    symbol_info *lookup_in_scope(string name)
    {
        int index = hash_function(name);
        for (symbol_info *sym : table[index])
        {
            if (sym->get_name() == name)
            {
                return sym;
            }
        }
        return nullptr;
    }

    bool insert_in_scope(symbol_info *symbol)
    {
        if (lookup_in_scope(symbol->get_name()) != nullptr)
        {
            // Symbol already exists in this scope
            return false;
        }

        int index = hash_function(symbol->get_name());
        table[index].push_back(symbol);
        return true;
    }

    bool delete_from_scope(string name)
    {
        int index = hash_function(name);
        for (auto it = table[index].begin(); it != table[index].end(); ++it)
        {
            if ((*it)->get_name() == name)
            {
                delete *it; // Deallocate symbol_info object
                table[index].erase(it);
                return true;
            }
        }
        return false;
    }

    void print_scope_table(ofstream &outlog)
    {
        outlog << "ScopeTable # " << unique_id << endl;
        for (int i = 0; i < bucket_count; ++i)
        {
            outlog << i << " --> ";
            bool first_symbol = true;
            for (symbol_info *sym : table[i])
            {
                if (!first_symbol)
                {
                    outlog << " "; // Space between symbols in the same bucket
                }
                outlog << "< " << sym->get_name() << " : " << sym->get_type() << " >";
                first_symbol = false;
            }
            outlog << endl;
            for (symbol_info *sym : table[i])
            {
                outlog << "    "; // Indentation for symbol details
                if (sym->get_symbol_type() == "VARIABLE")
                {
                    outlog << "Variable" << endl;
                    outlog << "    Type: " << sym->get_data_type() << endl;
                }
                else if (sym->get_symbol_type() == "ARRAY")
                {
                    outlog << "Array" << endl;
                    outlog << "    Type: " << sym->get_data_type() << endl;
                    outlog << "    Size: " << sym->get_array_size() << endl;
                }
                else if (sym->get_symbol_type() == "FUNCTION")
                {
                    outlog << "Function Definition" << endl;
                    outlog << "    Return Type: " << sym->get_return_type() << endl;
                    outlog << "    Number of Parameters: " << sym->get_num_params() << endl;
                    outlog << "    Parameter Details: ";
                    bool first_param = true;
                    for (const auto& param : sym->get_param_list())
                    {
                        if (!first_param) outlog << ", ";
                        outlog << param.first << " " << param.second;
                        first_param = false;
                    }
                    outlog << endl;
                }
                else
                {
                    // For tokens like ADDOP, MULOP etc. or unclassified symbols
                    outlog << "Token Type: " << sym->get_type() << endl;
                }
            }
        }
        outlog << endl;
    }

    ~scope_table()
    {
        for (int i = 0; i < bucket_count; ++i)
        {
            for (symbol_info *sym : table[i])
            {
                delete sym; // Deallocate all symbol_info objects
            }
            table[i].clear();
        }
    }
};