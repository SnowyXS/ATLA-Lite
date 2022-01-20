local Garbage = {}
Garbage.__index = Garbage
Garbage.cache = {}

function Garbage.new()
    return setmetatable({}, Garbage)
end

function Garbage:ClearCache()
    table.clear(self.cache)
end

function Garbage:FetchGarbageSearch(...)
    self:ClearCache()

    local parameters = {...}
    
    local cache = self.cache
    local oldCache = #cache
    local newGarbageCount = #parameters + oldCache
    
    for _, v in pairs(getgc(true)) do
        if newGarbageCount == #cache then
            break
        end

        if typeof(v) == "table" then
            for _, parameter in pairs(parameters) do
                if rawget(v, parameter) and not self:FetchFromCache(parameter) then
                    table.insert(cache, v)
                end
            end
        end
    end


    for parameterIndex, parameter in ipairs(parameters) do
        for i, v in pairs(cache) do
            if rawget(v, parameter) and parameterIndex ~= i then
                local oldGarbage = cache[parameterIndex]
                    
                cache[parameterIndex] = v
                cache[i] = oldGarbage
            end
        end
    end

    return self:FetchFromCache(...)
end

function Garbage:FetchFromCache(...)
    local parameters = {...}
    
    local cache = self.cache
    local selectedFromCache = {}
    
    for _, v in pairs(cache) do
        for _, parameter in pairs(parameters) do
            if rawget(v, parameter) then
                table.insert(selectedFromCache, v) 
            end
        end
    end
    
    return unpack(selectedFromCache)
end

return Garbage
