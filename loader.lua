local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CurrentCamera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

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

do -- Aimbot (WIP)

end

do -- esp
    local espTab = Window:AddTab("Esp")

    local playersGroup = espTab:AddLeftGroupbox("Players")

    local boxCheckBox = playersGroup:AddToggle("Box", {
        Text = "Box",
        Default = false,
        Tooltip = "Enables Box Esp.",
    }):AddColorPicker('BoxColor', {
        Default = Color3.new(1, 1, 1), 
        Title = 'Box Color', 
    })

    local healthBarCheckBox = playersGroup:AddToggle("HealthBar", {
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

    local nameTagCheckBox = playersGroup:AddToggle("NameTag", {
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
            players = {}

            for _, v in pairs(Players:GetPlayers()) do
                table.insert(players, v.Name)
            end
        
            playersDropDown.Values = players
            playersDropDown:SetValues()
        end)

        Players.PlayerRemoving:Connect(function(player)
            players = {}

            for _, v in pairs(Players:GetPlayers()) do
                table.insert(players, v.Name)
            end
        
            playersDropDown.Values = players
            playersDropDown:SetValues()
            
            if playersDropDown.Value == player.Name then
                playersDropDown:SetValue(players[1])
            end 
        end)
    end
    
    local miscGroup = espTab:AddRightGroupbox("Misc")

    local teamColorsCheckBox = miscGroup:AddToggle("TeamColors", {
        Text = "Team Colors",
        Default = false,
        Tooltip = "Esp color will be taken from the players team.",
    })

    local distanceSlider = miscGroup:AddSlider("Distance", {
        Text = "Render Distance",

        Default = 0,
        Min = 0,
        Max = 10000,
        Rounding = 1,
    
        Compact = false,
    })

    do
        local expectionObjects = {
            [596894229] = {
                game = "Elemental Adventure",
                objects = {
                    _level = {
                        type = "Text",
                        Text = "level: 0",
                        Size = 18,
                        Color = Color3.fromRGB(255, 255, 255),
                        Center = true,
                        ui = {
                            type = "AddToggle",
                            properties = {
                                Text = "Level",
                                Default = false,
                                Tooltip = "Enables Level Text."
                            },
                            hasColorPicker = true
                        }
                    }
                }
            }
        }

        local currentExpection = expectionObjects[placeID] or {}
        local gameGroup = espTab:AddLeftGroupbox(currentExpection.game)

        for objectName, v in pairs(currentExpection.objects) do
            local clearObjectName = string.gsub(objectName, "_", "")
            local ui = v.ui

            local uiObject = gameGroup[ui.type](gameGroup, clearObjectName .. "Toggle", ui.properties)

            if ui.hasColorPicker then
                uiObject:AddColorPicker(clearObjectName .. "Color", {
                    Default = Color3.new(1, 1, 1), 
                    Title = clearObjectName .. " Color", 
                })
            end
        end

        local PlayerEsp = {}
        PlayerEsp.__index = PlayerEsp

        function PlayerEsp.new(player)
            local self = setmetatable({}, PlayerEsp)

            local box = Drawing.new("Square")
            box.Color = Options.BoxColor.Value
            box.Filled = false
            box.Thickness = 1

            local playerName = Drawing.new("Text")
            playerName.Color = Options.NameColor.Value
            playerName.Size = 18
            playerName.Text = player.Name
            playerName.Center = true

            local healthBar = Drawing.new("Square")
            healthBar.Color = Options.HealthColor.Value
            healthBar.Filled = false
            healthBar.Thickness = 1

            for name, properties in pairs(currentExpection.objects) do
                local object = Drawing.new(properties.type)

                for property, value in pairs(properties) do
                    if typeof(value) == "table" then
                        if property ~= "type" and property ~= "ui" then
                            object[property] = value
                        end
                    end
                end

                self[name] = object
            end

            local function OnCharacterAdded(character)
                self._character = character
            end

            self._player = player
            self._character = player.Character

            self._box = box
            self._playerName = playerName
            self._healthBar = healthBar

            self._characterAdded = player.CharacterAdded:Connect(OnCharacterAdded)

            return self
        end

        function PlayerEsp:Refresh()
            local character = LocalPlayer.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart")

            local foePlayer = self._player
            local foeCharacter = self._character

            local foeHead = foeCharacter and foeCharacter:FindFirstChild("Head")
            local foeRootPart = foeCharacter and foeCharacter:FindFirstChild("HumanoidRootPart")
            local foeHumanoid = foeCharacter and foeCharacter:FindFirstChild("Humanoid")

            if foeRootPart and foeHead and foeHumanoid then
                local health = foeHumanoid.Health
                local maxHealth = foeHumanoid.MaxHealth
                    
                local distance = rootPart and (rootPart.CFrame.p - foeRootPart.CFrame.p).Magnitude or 0
                local renderDistance = (distanceSlider.Value == 0 or distance < distanceSlider.Value)

                local box = self._box
                local playerName = self._playerName
                local healthBar = self._healthBar

                local rootViewPort, isRendered = CurrentCamera:worldToViewportPoint(foeRootPart.Position)
                local headViewPort = CurrentCamera:worldToViewportPoint(foeHead.Position + Vector3.new(0, 1, 0))
                local legViewPort = CurrentCamera:worldToViewportPoint(foeRootPart.Position - Vector3.new(0, 2.5, 0))
                
                local filter = Options.FilterDropDown.Value
                local filterPlayers = Options.PlayersDropDown:GetActiveValues()

                isRendered = filter == "Whitelist" and table.find(filterPlayers, foePlayer.Name) and isRendered
                                or filter == "Blacklist" and not table.find(filterPlayers, foePlayer.Name) and isRendered
                                    or filter == "Off" and isRendered

                if isRendered then
                    local healthPrecentage = health / maxHealth

                    box.Color = (teamColorsCheckBox.Value and foePlayer.TeamColor.Color) or Options.BoxColor.Value
                    playerName.Color = (teamColorsCheckBox.Value and foePlayer.TeamColor.Color) or Options.NameColor.Value

                    healthBar.Color = Color3.new(
                        healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.R > 0 and math.clamp(Options.HealthLowColor.Value.R * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.R > 0 and math.clamp(Options.HealthMediumColor.Value.R * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.R * healthPrecentage, 0, 1), 
                        healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.G > 0 and math.clamp(Options.HealthLowColor.Value.G * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.G > 0 and math.clamp(Options.HealthMediumColor.Value.G * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.G * healthPrecentage, 0, 1), 
                        healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.B > 0 and math.clamp(Options.HealthLowColor.Value.B * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.B > 0 and math.clamp(Options.HealthMediumColor.Value.B * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.B * healthPrecentage, 0, 1))

                    box.Size = Vector2.new(CurrentCamera.ViewportSize.X / rootViewPort.Z, headViewPort.Y - legViewPort.Y)
                    box.Position = Vector2.new(rootViewPort.X - box.Size.X / 2, (rootViewPort.Y - box.Size.Y / 2) + 2)

                    playerName.Size = math.clamp(CurrentCamera.ViewportSize.X / rootViewPort.Z, 0, 14)

                    playerName.Position =
                        box.Position
                        + Vector2.new(
                            (box.Size.X - playerName.Size + playerName.TextBounds.Y) / 2, 
                            (box.Size.Y - playerName.Size + playerName.TextBounds.Y / 2) - playerName.Size / 2)
                        
                    healthBar.Position = box.Position - Vector2.new(3, 0)
                    healthBar.Size = Vector2.new(2, (headViewPort.Y - legViewPort.Y) / (maxHealth / math.clamp(health, 0, maxHealth)))
                    
                    if currentExpection then
                        if placeID == 596894229 then
                            local level = self._level

                            level.Size = math.clamp(CurrentCamera.ViewportSize.X / rootViewPort.Z, 0, 14)

                            level.Position =
                                box.Position
                                + Vector2.new(
                                    (box.Size.X + level.TextBounds.Y / 2 - level.Size / 2 + 2), 
                                    (box.Size.Y - level.Size + level.TextBounds.Y / 1.5))

                            level.Color = Options.levelColor.Value

                            if foePlayer:FindFirstChild("PlayerData") then
                                level.Text = "Level: " .. foePlayer.PlayerData.Stats.Level.Value
                            end
                        end
                    end
                end

                box.Visible = (boxCheckBox.Value and isRendered and renderDistance) or false
                playerName.Visible = (nameTagCheckBox.Value and isRendered and renderDistance) or false
                healthBar.Visible = (healthBarCheckBox.Value and isRendered and renderDistance) or false

                for name, _ in pairs(currentExpection.objects) do
                    local uiName = string.gsub(name, "_", "") .. "Toggle"

                    self[name].Visible = (Toggles[uiName].Value and isRendered and renderDistance) or false
                end
            end
        end

        local EspController = {}
        EspController.__index = EspController

        function EspController.new()
            local self = setmetatable({}, EspController)

            local players = {}

            self._players = players

            local playerAdded = Players.PlayerAdded:Connect(function(player)
                self:AddPlayer(player)
            end)

            local playerRemoving = Players.PlayerRemoving:Connect(function(player)
                self:RemovePlayer(player)
            end)

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    self:AddPlayer(player)
                end
            end

            local _renderStepped = RunService.RenderStepped:Connect(function()
                for _, esp in pairs(players) do
                    esp:Refresh()
                end
            end)

            self._playerAdded = playerAdded
            self._playerRemoving = playerRemoving
            self._renderStepped = _renderStepped

            return self
        end

        function EspController:AddPlayer(player)
            local players = self._players

            if not players[player] then
                players[player] = PlayerEsp.new(player)
            end
        end

        function EspController:RemovePlayer(player)
            local players = self._players
            local esp = players[player]
                
            if esp then
                players[player] = nil

                esp._characterAdded:Disconnect()

                esp._box:Remove()
                esp._playerName:Remove()
                esp._healthBar:Remove()

                for name, _ in pairs(currentExpection.objects) do
                    esp[name]:Remove()
                end

                setmetatable(esp, nil)
                table.clear(esp)
            end
        end

        EspController.new()
    end
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
