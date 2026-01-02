#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;
    string symbol_type;  // variable, array, or function
    string return_type;  // for functions
    int array_size;      // for arrays
    vector<pair<string, string>> parameters;  // for functions (parameter_type, parameter_name)

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->symbol_type = "";
        this->return_type = "";
        this->array_size = -1;
    }
    
    string get_name()
    {
        return name;
    }
    
    string get_type()
    {
        return type;
    }
    
    void set_name(string name)
    {
        this->name = name;
    }
    
    void set_type(string type)
    {
        this->type = type;
    }
    
    string get_symbol_type()
    {
        return symbol_type;
    }
    
    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }
    
    string get_return_type()
    {
        return return_type;
    }
    
    void set_return_type(string return_type)
    {
        this->return_type = return_type;
    }
    
    int get_array_size()
    {
        return array_size;
    }
    
    void set_array_size(int size)
    {
        this->array_size = size;
    }
    
    vector<pair<string, string>>& get_parameters()
    {
        return parameters;
    }
    
    void add_parameter(string param_type, string param_name)
    {
        parameters.push_back(make_pair(param_type, param_name));
    }

    ~symbol_info()
    {
        // No dynamic memory to deallocate
    }
};