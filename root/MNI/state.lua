-- MicroASM STATE variable management module
-- Handles parsing, storage, and scoping of STATE variables

local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self.global = {}      -- Global state variables
    self.scopes = {}      -- Stack of local scopes
    return self
end

function State:enterScope(scopeName)
    table.insert(self.scopes, {name = scopeName, vars = {}})
end

function State:leaveScope()
    table.remove(self.scopes)
end

function State:declare(name, typeStr, initial)
    local var = {type = typeStr, value = initial or 0}
    if #self.scopes > 0 then
        local scope = self.scopes[#self.scopes]
        if scope.vars[name] then error("Duplicate STATE variable in scope: "..name) end
        scope.vars[name] = var
    else
        if self.global[name] then error("Duplicate global STATE variable: "..name) end
        self.global[name] = var
    end
end

function State:get(name, scopeChain)
    -- scopeChain: array of scope names from innermost to outermost
    for i = #self.scopes, 1, -1 do
        local scope = self.scopes[i]
        if scope.vars[name] then return scope.vars[name] end
    end
    return self.global[name]
end

function State:set(name, value)
    for i = #self.scopes, 1, -1 do
        local scope = self.scopes[i]
        if scope.vars[name] then scope.vars[name].value = value; return end
    end
    if self.global[name] then self.global[name].value = value; return end
    error("STATE variable not found: "..name)
end

return State
