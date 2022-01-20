
local placeID = game.PlaceId

local success, script = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Games/" .. placeID .. ".lua", true) 
end)

if success then
    print("Found script for " .. game.PlaceId)
    
    loadstring(script)()
end
