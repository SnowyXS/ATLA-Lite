assert(not libLoaded, "SLite was already loaded.")

local ATLA

task.spawn(function()
    ATLA = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Games/749703080.lua"))()
end)

local Players = game:GetService("Players")

local CurrentCamera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.PlayerAdded:wait()

local humanoid = Character:WaitForChild("Humanoid")
local head = Character:WaitForChild("Head")

do -- Loading
    local count = 1

    local loadingSquare = Drawing.new("Square")
    loadingSquare.Visible = true
    loadingSquare.Filled = true
    loadingSquare.Color = Color3.fromRGB(25, 25, 25)
    loadingSquare.Size = Vector2.new(CurrentCamera.ViewportSize.X / 5, CurrentCamera.ViewportSize.Y / 4)
    loadingSquare.ZIndex = 1
    loadingSquare.Position = Vector2.new(0.5 * CurrentCamera.ViewportSize.X - loadingSquare.Size.X / 2, 0.5 * CurrentCamera.ViewportSize.Y - loadingSquare.Size.Y / 2)

    local brandText = Drawing.new("Text")
    brandText.Visible = true
    brandText.Size = 32
    brandText.ZIndex = 2
    brandText.Color = Color3.fromRGB(255, 255, 255)
    brandText.Text = "SLite"
    brandText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - brandText.TextBounds.X / 2, 0)

    local loadingText = Drawing.new("Text")
    loadingText.Visible = true
    loadingText.Size = 32
    loadingText.ZIndex = 2
    loadingText.Color = Color3.fromRGB(255, 0, 0)
    loadingText.Text = "Waiting for modules."
    loadingText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - loadingText.TextBounds.X / 2, loadingSquare.Size.Y - 32)

    local loadingImage = Drawing.new("Image")
    loadingImage.Data = game:HttpGet("https://i.ibb.co/4RLhfFx/605705a9df9070fb407eb909a5e09d28.webp")
    loadingImage.Rounding = 4
    loadingImage.Size = Vector2.new(loadingSquare.Size.X / 2, loadingSquare.Size.Y / 1.5)
    loadingImage.Position = loadingSquare.Position + loadingSquare.Size / 2 - loadingImage.Size / 2
    loadingImage.ZIndex = 2
    loadingImage.Visible = true

    while not (ATLA and LocalPlayer:FindFirstChild("PlayerData")) and task.wait(0.25) do
        loadingText.Color = Color3.fromRGB(255, 0, 0)
        loadingText.Text = ((not LocalPlayer:FindFirstChild("PlayerData") and "Waiting for modules") or (not ATLA and "Waiting for SLite module") or "") .. string.rep(".", count) 

        loadingSquare.Position = Vector2.new(0.5 * CurrentCamera.ViewportSize.X - loadingSquare.Size.X / 2, 0.5 * CurrentCamera.ViewportSize.Y - loadingSquare.Size.Y / 2)
        brandText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - brandText.TextBounds.X / 2, 0)
        loadingText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - loadingText.TextBounds.X / 2, loadingSquare.Size.Y - 32)
        loadingImage.Position = loadingSquare.Position + loadingSquare.Size / 2 - loadingImage.Size / 2

        count = count < 3 and count + 1 or 1
    end

    loadingText.Color = Color3.fromRGB(0, 255, 0)
    loadingText.Text = "Loaded version " .. ATLA.version .. "."
    loadingText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - loadingText.TextBounds.X / 2, loadingSquare.Size.Y - 32)
    
    task.wait(0.5)

    loadingSquare:Remove()
    brandText:Remove()
    loadingText:Remove()
    loadingImage:Remove()
end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/UI/Controller.lua"))()

local nameTag = head:WaitForChild("Nametag")
local playerData = LocalPlayer:WaitForChild("PlayerData")

local Settings = ATLA.GetSettings()
local Quests = ATLA:GetQuests()

local autofarmCheckBox = UI:new("Checkbox", "AutoFarm")
local subChangerCheckBox = UI:new("Checkbox", "Sub Changer")
local characterModificationText = UI:new("Text", "Character Modification")
local teleportText = UI:new("Text", "Teleport")
local playersText = UI:new("Text", "Players")
local miscText = UI:new("Text", "Misc")

local autofarmCategory = autofarmCheckBox:CreateCategory()
local minimumXpSlider = autofarmCategory:new("Slider", "Minimum XP", 0, 0, 3000, 100)
local extraDelaySlider = autofarmCategory:new("Slider", "Extra Delay", Settings:Get("delayPercentage") * 100, 0, 100, 1, "%")

local subChangerCategory = subChangerCheckBox:CreateCategory()
local elementSelector = subChangerCategory:new("ListSelector", {"Air", "Water", "Fire", "Earth"})
local specialSelector = subChangerCategory:new("ListSelector", {"Flight"})
local secondSpecialSelector = subChangerCategory:new("ListSelector", {"None"})
local farmAfterSubCheckBox = subChangerCategory:new("Checkbox", "Auto-Toggle AutoFarm")

local playersCategory = playersText:CreateCategory()

local teleportCategory = teleportText:CreateCategory()
local mapTeleportText = teleportCategory:new("Text", "Map")

local mapTeleportCategory = mapTeleportText:CreateCategory()

local characterModificationCategory = characterModificationText:CreateCategory()
local walkSpeedSpeedSlider = characterModificationCategory:new("Slider", "WalkSpeed", 16, 16, 1000, 1)
local jumpPowerSlider = characterModificationCategory:new("Slider", "JumpPower", 50, 50, 1000, 1)
local sprintSpeedSlider = characterModificationCategory:new("Slider", "Sprint Speed", 25, 25, 1000, 1)
local maxStaminaSlider = characterModificationCategory:new("Slider", "Max Stamina", playerData.Stats.Stamina.Value + 25, 25, 1000, 1)

local miscCategory = miscText:CreateCategory()
local flyCheckBox = miscCategory:new("Checkbox", "Fly")
local autoText = miscCategory:new("Text", "Auto")
local disablesText = miscCategory:new("Text", "Disables")

local autoCategory = autoText:CreateCategory()
local autoStaminaRefillCheckBox = autoCategory:new("Checkbox", "Auto Stamina Refill (WIP)")

local disabledCategory = disablesText:CreateCategory()
local staminaCheckBox = disabledCategory:new("Checkbox", "Stamina Usage", true)
local disableDamageCheckBox = disabledCategory:new("Checkbox", "Tornado And Burn Damage", true)

local flyCategory = flyCheckBox:CreateCategory()
local flySpeedSlider = flyCategory:new("Slider", "Fly Speed", 5, 5, 1000, 1)

do -- AutoFarm 
    autofarmCheckBox:OnChanged(function()
        while autofarmCheckBox:IsToggled() and task.wait() do
            for quest, questData in pairs(Quests) do
                local lastQuest = ATLA:GetLastQuest()
                local minimumXP = minimumXpSlider:GetValue()
                
                if autofarmCheckBox:IsToggled() and not Settings:Get("shouldStopFarm") and typeof(questData) == "table" and quest ~= lastQuest and questData.Rewards.Experience >= minimumXP then
                    local icon = nameTag.Icon.Image

                    quest = minimumXP < 2000 and quest
                            or (icon == "" or icon == "rbxassetid://869158044") and "WhiteLotus1"
                            or icon == "rbxassetid://87177558" and "RedLotus1"
                    
                    ATLA:CompleteQuest(quest)
                end
            end
        end
        
        ATLA:StopQuest()
    end)

    extraDelaySlider:OnChanged(function()
        Settings:Set("delayPercentage", extraDelaySlider:GetValue() / 100)
    end)
end

do -- Sub changer
    local specialElements = {
        Air = {"Flight"},
        Water = {"Ice", "Plant"},
        Fire = {"Lightning", "Combustion"},
        Earth = {"Lava", "Metal", "Sand"}
    }
    
    local secondSpecialElements = {
        Ice = {"None", "Healing"},
        Plant = {"None", "Healing"},
        Lava = {"None", "Lava Seismic"},
        Metal = {"None", "Metal Seismic"},
        Sand = {"None", "Sand Seismic"},
    }

    elementSelector:OnChanged(function()
        specialSelector:ChangeList(specialElements[elementSelector:GetSelected()])
        secondSpecialSelector:ChangeList(secondSpecialElements[specialSelector:GetSelected()] or secondSpecialElements[elementSelector:GetSelected()] or {"None"})
    end)
    
    specialSelector:OnChanged(function()
        secondSpecialSelector:ChangeList(secondSpecialElements[specialSelector:GetSelected()] or secondSpecialElements[elementSelector:GetSelected()] or {"None"})
    end)

    subChangerCheckBox:OnChanged(function()
        if subChangerCheckBox:IsToggled() then
            humanoid.Health = 0
        end
    end)    

    LocalPlayer.CharacterAdded:Connect(function(character)
        if subChangerCheckBox:IsToggled() then
            local shouldContinue = ATLA:ChangeElement(elementSelector:GetSelected(), specialSelector:GetSelected(), secondSpecialSelector:GetSelected())
    
            if shouldContinue then
                local humanoid = character:WaitForChild("Humanoid")
    
                if subChangerCheckBox:IsToggled() then
                    humanoid.Health = 0
    
                    return
                end
            elseif farmAfterSubCheckBox:IsToggled() then
                autofarmCheckBox:SetToggle(true)
            end
    
            subChangerCheckBox:SetToggle(false)
        end
    end)
end

do -- stamina crap
    maxStaminaSlider:OnChanged(function()
        ATLA.SetMaxStamina(maxStaminaSlider:GetValue())
    end)

    staminaCheckBox:OnChanged(function()
        ATLA.ToggleStamina(staminaCheckBox:IsToggled())
    end)

    playerData.Stats.Stamina.Changed:connect(function(number)
        maxStaminaSlider:SetValue(number + 25)
    end)
end

do -- Disable Tornado and Lava
    OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if not checkcaller() and method == "FireServer" and not disableDamageCheckBox:IsToggled() and (args[2] and (args[2].Key == "Burn" or args[2].Ability == "TornadoPush")) then
            return
        end
    
        return OldNameCall(self, ...) 
    end)    
end

do -- WalkSpeed
    walkSpeedSpeedSlider:OnChanged(function()
        humanoid.WalkSpeed = walkSpeedSpeedSlider:GetValue()
    end)
    
    jumpPowerSlider:OnChanged(function()
        humanoid.JumpPower = jumpPowerSlider:GetValue()
    end)

    OldNewIndex = hookmetamethod(game, "__newindex", function(self, index, value)
        if not checkcaller() then
            if index == "WalkSpeed" then
                if value == 25 and sprintSpeedSlider:GetValue() > 25 then
                    return OldNewIndex(self, index, sprintSpeedSlider:GetValue()) 
                elseif walkSpeedSpeedSlider:GetValue() > 16 then
                    return OldNewIndex(self, index, walkSpeedSpeedSlider:GetValue()) 
                end
            elseif index == "JumpPower" then
                return OldNewIndex(self, index, jumpPowerSlider:GetValue()) 
            end
        end
        
        return OldNewIndex(self, index, value)
    end)
end

do -- fly
    flyCheckBox:OnChanged(function()
        ATLA.ToggleFlight(flyCheckBox:IsToggled())
    end)

    flySpeedSlider:OnChanged(function()
        local MenuControl = ATLA.GetGameModule()
        
        setconstant(MenuControl.startRealFlying, 66, flySpeedSlider:GetValue())
    end)
end

do -- Auto Stamina Refill (WIP)

end

do -- Teleporting presets
    local presets = {
        [1] = {
            name = "Air",
            places = {
                ["Western Air Temple"] = CFrame.new(7945, 183, -2050),
                ["Southern Air Temple"] = CFrame.new(1706, 396, -2256),
                ["Air Temple Shop"] = CFrame.new(1634, 457, -2370),
                ["Air Temple Vehicle Shop"] = CFrame.new(1892, 263, -2113)
            }
        },
        [2] = {
            name = "Water",
            places = {
                ["Northern Water Tribe"] = CFrame.new(9007, 109, 788),
                ["Southern Water Tribe"] = CFrame.new(49, 11, 480),
                ["Water Weapon Shop"] = CFrame.new(8790, 61, 957),
                ["Water Vehicle Shop"] = CFrame.new(7972, 8, 763)
            }
        },
        [3] = {
            name = "Earth",
            places = {
                ["Inner Walls"] = CFrame.new(5915, 8, 5052),
                ["Outer Walls"] = CFrame.new(5910, 8, 4337),
                ["Earth Weapon Shop"] = CFrame.new(5636, 8, 5113),
                ["Earth Vehicle Shop"] = CFrame.new(5865, 8, 4369)
            }
        },
        [4] = {
            name = "Fire",
            places = {
                ["Roku's Temple"] = CFrame.new(6154, 128, 199),
                ["CalderaCity"] = CFrame.new(6375, 162, -6483),
                ["Royal Plaza"] = CFrame.new(5509, 21, -3910),
                ["Fire Weapon Shop"] = CFrame.new(6201, 161, -5862),
                ["Fire Vehicle Shop"] = CFrame.new(5832, 14, 467)
            }
        },
        [5] = {
            name = "Others",
            places = {
                ["Kyoshi"] = CFrame.new(1795, 11, 2263),
                ["Kyoshi Shop"] = CFrame.new(1813, 11, 2199),
                ["Desert"] = CFrame.new(3512, 8, 3956),
                ["The Swamp"] = CFrame.new(3706, 7, 2744),
                ["White Lotus"] = CFrame.new(3408, 7, 4026),
                ["Red Lotus"] = CFrame.new(898, 236, -3075),
                ["Acrobats NPC"] = CFrame.new(5516, 27, -4497),
                ["Chi NPC"] = CFrame.new(-57, 12, 475)
            }
        }
    }
    
    for _, v in ipairs(presets) do
        local text = mapTeleportCategory:new("Text", v.name)
        local category = text:CreateCategory()
    
        for name, position in pairs(v.places) do
            local button = category:new("Button", name)
    
            button:OnPressed(function()
                Character.PrimaryPart.CFrame = position
            end)
        end
    end
end

do -- Players
    local players = {}
    local valueNames = ATLA.GetValueNames()

    function AddPlayer(player)
        local playerText = playersCategory:new("Text", player.Name)
        playerText:SetColor(player == LocalPlayer and Color3.fromRGB(184, 255, 184) or Color3.fromRGB(211,211,211))

        local playerCategory = playerText:CreateCategory()
        local teleportButton = playerCategory:new("Button", "Teleport")
        local appearanceText = playerCategory:new("Text", "Appearance")
    
        local statsText = playerCategory:new("Text", "Stats")
    
        local appearanceCategory = appearanceText:CreateCategory()
        local statsCategory = statsText:CreateCategory()
    
        local playerData = player:WaitForChild("PlayerData")
    
        for _, v in pairs(playerData:WaitForChild("Appearance"):GetChildren()) do
            local dataName = valueNames[v.Name] or v.Name
            local valueText = appearanceCategory:new("Text", dataName .. ": " ..v.Value)
    
            v:GetPropertyChangedSignal("Value"):Connect(function()
                valueText:Set(dataName .. ": " ..v.Value)
            end)
        end
    
        for _, v in pairs(playerData:WaitForChild("Stats"):GetChildren()) do
            local dataName = valueNames[v.Name] or v.Name
            local valueText = statsCategory:new("Text", dataName .. ": " ..v.Value)
    
            v:GetPropertyChangedSignal("Value"):Connect(function()
                valueText:Set(dataName .. ": " ..v.Value)
            end)
        end
    
        teleportButton:OnPressed(function()
            Character.PrimaryPart.CFrame = player.Character.PrimaryPart.CFrame
        end)
        
        players[player] = playerText
    end

    for _, player in pairs(Players:GetPlayers()) do
        AddPlayer(player)
    end

    Players.PlayerAdded:Connect(function(player)
        AddPlayer(player)
        
        print("\n--- Player List ---",
        "\nStatus: Player Joined", 
        "\n -> Name: " ..  player.Name)
    end)

    Players.PlayerRemoving:Connect(function(player)
        local UIObject = players[player]

        if UIObject then
            pcall(UIObject.Destroy, UIObject, true)
            UIObject = nil
        end

        print("\n--- Player List ---",
        "\nStatus: Player Left", 
        "\n -> Name: " ..  player.Name)
    end)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    Character = character

    head = Character:WaitForChild("Head") 
    nameTag = head:WaitForChild("Nametag")

    humanoid = Character:WaitForChild("Humanoid") 

    humanoid.WalkSpeed = walkSpeedSpeedSlider:GetValue()
    humanoid.JumpPower = jumpPowerSlider:GetValue()
        
    local oldGameModule = ATLA.GetGameModule()

    repeat task.wait() until ATLA.GetGameModule() ~= oldGameModule

    ATLA.SetMaxStamina(maxStaminaSlider:GetValue())
end)
