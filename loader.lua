local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CurrentCamera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local placeID = game.PlaceId

local repository = "https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/"

getgenv().Library = loadstring(game:HttpGet(repository .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repository .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repository .. "addons/SaveManager.lua"))()

local Esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Universal/PlayerEsp.lua"))()
local PlayersEsp = Esp.players

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



do -- esp
    local espTab = Window:AddTab("Esp")

    local playersGroup = espTab:AddLeftGroupbox("Players")

    playersGroup:AddToggle("BoxCheckBox", {
        Text = "Box",
        Default = false,
        Tooltip = "Enables Box Esp.",
    }):AddColorPicker('BoxColor', {
        Default = Color3.new(1, 1, 1), 
        Title = 'Box Color', 
    })

    playersGroup:AddToggle("HealthBarCheckBox", {
        Text = "Health Bar",
        Default = false,
        Tooltip = "Enables HealthBar Esp.",
    }):AddColorPicker('HealthColor', {
        Default = Color3.new(0, 1, 0), 
        Title = 'High Health Color', 
    }):AddColorPicker('HealthMediumColor', {
        Default = Color3.new(1, 0.8, 0), 
        Title = 'Medium Health Color', 
    }):AddColorPicker('HealthLowColor', {
        Default = Color3.new(1, 0, 0), 
        Title = 'Low Health Color', 
    })

    playersGroup:AddToggle("ChamsCheckBox", {
        Text = "Chams",
        Default = false,
        Tooltip = "Enables Chams.",
    }):AddColorPicker('ChamsColor', {
        Default = Color3.new(0, 0, 0), 
        Title = 'Fill Color', 
    }):AddColorPicker('ChamsOutLineColor', {
        Default = Color3.new(1, 1, 1), 
        Title = 'OutLine Color', 
    })

    playersGroup:AddToggle("NameTagCheckBox", {
        Text = "Name",
        Default = false,
        Tooltip = "Enables Name Esp.",
    }):AddColorPicker('NameColor', {
        Default = Color3.new(1, 1, 1), 
        Title = 'Text Color', 
    })

    do -- Players Drop Down Handler
        local playersGroup = espTab:AddRightGroupbox("Filtering")
        local players = {}

        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer then
                table.insert(players, v.Name)
            end
        end

        playersGroup:AddDropdown("FilterDropDown", {
            Values = {"Off", "Whitelist", "Blacklist"},
            Default = 1,
            Multi = false,
            
            Text = "Filter",
            Tooltip = "Allows you to whitelist / blacklist people",
        })

        local playersDropDown = playersGroup:AddDropdown("PlayersDropDown", {
            Values = players,
            Multi = true,
            
            Text = "Players",
            Tooltip = "Select a player to whitelist / blacklist",
        })

        Players.PlayerAdded:Connect(function(player)
            table.insert(players, player.Name)
        
            playersDropDown.Values = players
            playersDropDown:SetValues()
        end)


        Players.PlayerRemoving:Connect(function(player)
            local index = table.find(players, player.Name)
            
            table.remove(players, index)
        
            playersDropDown.Value[player] = nil
            playersDropDown.Values = players
            playersDropDown:SetValues()
        end)
    end
    
    local miscGroup = espTab:AddRightGroupbox("Misc")

    miscGroup:AddToggle("TeamColorsCheckBox", {
        Text = "Team Colors",
        Default = false,
        Tooltip = "Esp color will be taken from the players team.",
    })

    miscGroup:AddSlider("TextSizeSlider", {
        Text = "Max Text Size",

        Default = 14,
        Min = 14,
        Max = 100,
        Rounding = 1,
    
        Compact = false,
    })

    miscGroup:AddSlider("DistanceSlider", {
        Text = "Render Distance",

        Default = 0,
        Min = 0,
        Max = 10000,
        Rounding = 1,
    
        Compact = false,
    })

    miscGroup:AddSlider("ChamsTransparency", {
        Text = "Chams Transparency",

        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,
    
        Compact = false,
    })

    miscGroup:AddSlider("ChamsOutLineTransparency", {
        Text = "Chams OutLine Transparency",

        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 1,
    
        Compact = false,
    })

    local Expection = Esp.expection

    if Expection then
        Expection.CreateUI(espTab)
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            Esp.new(player)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        Esp.new(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        local PlayerEsp = PlayersEsp[player]

        PlayerEsp:Destroy()
        
        print(player.Name .. " Left and was removed from esp")
    end)

    RunService.RenderStepped:Connect(function()
        for _, PlayerEsp in pairs(PlayersEsp) do
            PlayerEsp:Refresh()
        end
    end)
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
