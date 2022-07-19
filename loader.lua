local placeID = game.PlaceId

local repository = "https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repository .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repository .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repository .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "SLite",
    Center = true, 
    AutoShow = false,
})

local success, script = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Games/" .. placeID .. ".lua") 
end)

if success then
    print("Found script for " .. game.PlaceId)
    
    local GameScript = loadstring(script)()

    GameScript(Window)

    SaveManager:SetFolder("SLite/" .. placeID)
end

local settingsTab = Window:AddTab("Settings")
local menuGroup = settingsTab:AddLeftGroupbox("Menu")

menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
    Default = "End", 
    NoUI = false, 
    Text = "Menu keybind" 
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings() 

ThemeManager:SetFolder("SLite")

SaveManager:BuildConfigSection(settingsTab) 

ThemeManager:ApplyToTab(settingsTab)

Library.Toggle()
