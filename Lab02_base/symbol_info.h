#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type; // token type, e.g., "ID", "CONST_INT", "ADDOP"

    string symbol_type; // e.g., "VARIABLE", "ARRAY", "FUNCTION", "UNDEFINED"
    string data_type;   // e.g., "int", "float", "void", "UNDEFINED"

    int array_size; // For arrays, stores size. -1 if not an array.

    string return_type;         // For functions
    int num_params;             // For functions
    vector<pair<string, string>> param_list; // For functions: pair of (type, name)

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->symbol_type = "UNDEFINED";
        this->data_type = "UNDEFINED";
        this->array_size = -1;
        this->return_type = "UNDEFINED";
        this->num_params = 0;
    }

    symbol_info(string name, string type, string symbol_type, string data_type)
    {
        this->name = name;
        this->type = type;
        this->symbol_type = symbol_type;
        this->data_type = data_type;
        this->array_size = -1;
        this->return_type = "UNDEFINED";
        this->num_params = 0;
    }

    // Copy constructor
    symbol_info(const symbol_info& other)
    {
        name = other.name;
        type = other.type;
        symbol_type = other.symbol_type;
        data_type = other.data_type;
        array_size = other.array_size;
        return_type = other.return_type;
        num_params = other.num_params;
        param_list = other.param_list;
    }

    string get_name() const { return name; }
    string get_type() const { return type; }
    string get_symbol_type() const { return symbol_type; }
    string get_data_type() const { return data_type; }
    int get_array_size() const { return array_size; }
    string get_return_type() const { return return_type; }
    int get_num_params() const { return num_params; }
    vector<pair<string, string>> get_param_list() const { return param_list; }

    void set_name(string name) { this->name = name; }
    void set_type(string type) { this->type = type; }
    void set_symbol_type(string symbol_type) { this->symbol_type = symbol_type; }
    void set_data_type(string data_type) { this->data_type = data_type; }
    void set_array_size(int array_size) { this->array_size = array_size; }
    void set_return_type(string return_type) { this->return_type = return_type; }
    void set_num_params(int num_params) { this->num_params = num_params; }
    void set_param_list(const vector<pair<string, string>>& param_list) { this->param_list = param_list; }

    ~symbol_info()
    {
        // No dynamic memory to deallocate by symbol_info itself
    }
};