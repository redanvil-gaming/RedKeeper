--[[
    module for wrapping functions in tables 
    for easy documentation and maybe smth else

    TODO(temik): add tableWrapper for table documentation
]]

local tablefunc = {}

local unpack = table.unpack or unpack -- LUA 5.2 change

local function tableFunctionToString(tab)
    local mt = getmetatable(tab)
    local str = mt.__doc
    if(str)then
        return str 
    end
        return tab.name or "type : tablefunc"
end


local function funcWrapper(func, docStr) -- function func , string docStr
    if (func) then
    local tab = {}
    local function newFunc(_, self,  ...) -- trash first element (because __call is called by ':')
        return func(self, ...)
    end
    
    setmetatable(tab, {
        __call = newFunc,
        __doc = docStr,
        __tostring = tableFunctionToString
        __type = 'tablefunc'
    })
    return tab
    end
    return --nil
end

local function extendedType(var)
    mt = getmetatable(var)
    if (not mt) then 
        retrun type(var)
    end
    if (not mt.__type) then 
        retrun type(var)
    end
    return mt.__type
end

function tableWalk(tab, ...) --key1, key2, key3, ... key_n
    local runtable = tab
    if(type(runtable) ~= 'table') then
       return _, "input_Table", "inputTable is not \'table\'" 
    end
    arg = {...}
    local depth = #arg
    for i = 1, (depth-1) do
        if(type(arg[i]) ~= 'string') then
            return _, arg[i], "not a \'string\'"
        end
        local nextVal = runtable[arg[i]]
        if(type(nextVal) ~= 'table')then
            return _, arg[i], "no table at this key"
        end
        runtable = nextVal
    end
        
    if(type(arg[#arg]) ~= 'string') then
        return _, arg[#arg], "not a \'string\'"
    end
    local nextVal = runtable[arg[#arg]]
    if(not nextVal)then
        return _, arg[#arg], "no value at this key"
    end
    return nextVal
end



tablefunc.funcWrapper = funcWrapper(funcWrapper, 
[[function=(function func [, string documentation])
wraps function in table __call, discarding first argument for 'operator:' method use
second argument "documentation" provides this string for metamethod __tostring]])

tablefunc.exType = funcWrapper(extendedType,
[[function=(var) extended type() function
returns normal type(var) for vanila lua variables
returns 'tablefunc' for tablefunc variables
]])

tablefunc.tableWalk = funcWrapper(tableWalk,
[[function=(table tab, key1 [, key2 ... key_n])
returns tab.key1.key2...key_n
allows to check for key path with error check
in case of error return {nil, key_at_witch_error_acure, error_message}
]])

return tablefunc