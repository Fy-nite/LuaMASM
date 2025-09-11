-- MicroASM Macro management module
-- Handles macro definition, expansion, and unique local labels

local Macro = {}
Macro.__index = Macro

function Macro.new()
    local self = setmetatable({}, Macro)
    self.macros = {} -- name -> {params, body}
    self.expansionCount = {} -- name -> count
    return self
end

function Macro:define(name, params, body)
    if self.macros[name] then error("Duplicate macro: "..name) end
    self.macros[name] = {params = params, body = body}
    self.expansionCount[name] = 0
end

function Macro:expand(name, args)
    local macro = self.macros[name]
    if not macro then error("Macro not found: "..name) end
    if #args ~= #macro.params then error("Macro argument count mismatch for "..name) end
    self.expansionCount[name] = self.expansionCount[name] + 1
    local uniq = self.expansionCount[name]
    local expanded = {}
    for _, line in ipairs(macro.body) do
        local l = line
        -- Parameter substitution
        for i, param in ipairs(macro.params) do
            l = l:gsub(param, args[i])
        end
        -- Unique local label substitution (@@label)
        l = l:gsub("@@(%w+)", function(lbl)
            return string.format("..@%s@%d@%s", name, uniq, lbl)
        end)
        table.insert(expanded, l)
    end
    return expanded
end

return Macro
