local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/ATLA-Lite/main/UI/Controller.lua"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera

local networkFolder = ReplicatedStorage:WaitForChild("NetworkFolder")
local gameFunction = networkFolder.GameFunction
local gameEvent = networkFolder.GameEvent

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

local humanoidRootPart = Character.HumanoidRootPart
local humanoid = Character.Humanoid

local playerData = LocalPlayer:WaitForChild("PlayerData")
local appearance = playerData:WaitForChild("Appearance")

local specialAbility = appearance.Special
local secondSpecialAbility = appearance.Special2

local autofarmCheckBox = UI:new("Checkbox", "AutoFarm")
local subChangerCheckBox = UI:new("Checkbox", "Sub Changer")
local characterModificationText = UI:new("Text", "Character Modification")
local teleportText = UI:new("Text", "Teleport")
local playersText = UI:new("Text", "Players")
local miscText = UI:new("Text", "Misc")

local autofarmCategory = autofarmCheckBox:CreateCategory()
local minimumXpSlider = autofarmCategory:new("Slider", "Minimum XP", 0, 0, 3000, 100)

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

local miscCategory = miscText:CreateCategory()
local flyCheckBox = miscCategory:new("Checkbox", "Fly")
local killAuraCheckBox = miscCategory:new("Checkbox", "KillAura")
local godmodeCheckBox = miscCategory:new("Checkbox", "GodMode")
local infiniteStaminaCheckBox = miscCategory:new("Checkbox", "Infinite Stamina")
local disablesText = miscCategory:new("Text", "Disables")

local flyCategory = flyCheckBox:CreateCategory()
local flySpeedSlider = flyCategory:new("Slider", "Fly Speed", 5, 5, 1000, 1)

local disabledCategory = disablesText:CreateCategory()
local disableDamageCheckBox = disabledCategory:new("Checkbox", "Disable tornado and burn damage")

local MainControl, BaseSelection

for i,v in pairs(getgc(true)) do
    if typeof(v) == "table"  then
        if MainControl and BaseSelection then
            break
        elseif rawget(v, "QuestModule") then
            MainControl = v
        elseif rawget(v, "Elements") then
            BaseSelection = v
        end
    end
end

local Quests = MainControl.QuestModule
local questNPCs = MainControl.QuestNPCs

local NPCList = getupvalue(Quests.RefreshNPCs, 3)
local OldDecreaseStamina = rawget(MainControl, "DecreaseStamina")

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

local teleportPresets = {
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

local playerDataExpectionNames = {
    Money1 = "Copper Pieces",
    Money2 = "Silver Pieces",
    Money3 = "Gold Pieces",
    Money4 = "Gold Ingots"
}

local playersUIObjects = {}
local canCompleteQuest, lastQuest
local shouldStopFarm = false

local FPS
local tempTime = 0
local beatCount = 0
local totalFrames = 0

RunService.Heartbeat:Connect(function(deltaTime)
	tempTime = tempTime + deltaTime
	beatCount = beatCount + 1
	totalFrames = totalFrames + (1 / deltaTime)

	if not FPS or tempTime >= 1 then
		local fps = (totalFrames / beatCount) - (tempTime / beatCount)
	
		FPS = (fps > 60 and 60) or fps
		
		tempTime = 0
		beatCount = 0
		totalFrames = 0
	end
end)

local function GetDelay()
    local previousTick = tick()

    gameFunction:InvokeServer("GetQuestData")
    
    local ping = math.clamp(tick() - previousTick, 140, math.huge)
    local pingInMilliseconds = ping / 1000

    return (FPS < 50 and pingInMilliseconds + ((60 / FPS) * 2) / 1000) or pingInMilliseconds
end

local function GetQuestNPC(quest)
    for NPCName, v in pairs(NPCList) do
        if table.find(v, quest) and Quests[v[1]].Rewards.Experience >= minimumXpSlider:GetValue() then
            return questNPCs:FindFirstChild(NPCName)
        end
    end
end

local function CompleteQuest(quest)
    local npc = GetQuestNPC(quest)
    
    local hasChanged

    local oldCopper, 
          oldSilver, 
          oldGoldPieces, 
          oldGoldIngots = playerData.Stats.Money1.Value, playerData.Stats.Money2.Value, playerData.Stats.Money3.Value, playerData.Stats.Money4.Value

    canCompleteQuest =  npc and humanoid.Health > 0 
                        and humanoid.WalkSpeed > 0
                        and not Character:FindFirstChild("Down") 
                        and not (humanoidRootPart:FindFirstChild("DownTimer") 
                        and humanoidRootPart.DownTimer.TextLabel.Text ~= "") 
                        and not canCompleteQuest
                        and not MainControl.Transitioning
                        and getupvalue(MainControl.SpawnCharacter, 2) == 2 
                        and not shouldStopFarm

    if canCompleteQuest then
        repeat task.wait(GetDelay())
            gameFunction:InvokeServer("Abandon")

            for step = 1, #Quests[quest].Steps + 1 do 
                local distance = (npc.PrimaryPart.CFrame.p - humanoidRootPart.CFrame.p).Magnitude

                if distance > 25 and humanoid.Health <= 0 or humanoid.WalkSpeed <= 0  or Character.BattlerHealth.Value <= 0 then
                    break
                end

                task.spawn(function()
                    local distance = (npc.PrimaryPart.CFrame.p - humanoidRootPart.CFrame.p).Magnitude

                    if distance < 25 and not shouldStopFarm then
                        gameFunction:InvokeServer("AdvanceStep", {
                            QuestName = quest,
                            Step = step
                        })
                    end
                end)
            end

            hasChanged = playerData.Stats.Money1.Value ~= oldCopper 
                         or playerData.Stats.Money2.Value ~= oldSilver 
                         or playerData.Stats.Money3.Value ~= oldGoldPieces 
                         or playerData.Stats.Money4.Value ~= oldGoldIngots
        until hasChanged or not autofarmCheckBox:IsToggled()

        if hasChanged then
            lastQuest = quest
        end

        canCompleteQuest = false
    end
end

local function ChangeElement()
    local selectedSpecial = specialSelector:GetSelected()
    local selectedSecondSpecial = secondSpecialSelector:GetSelected()
    
    BaseSelection.Elements = elementSelector:GetSelected()

    print(selectedSpecial, specialAbility.Value == selectedSpecial)
    print(selectedSecondSpecial, secondSpecialAbility.Value == selectedSecondSpecial)

    return ((specialAbility.Value ~= selectedSpecial or secondSpecialAbility.Value ~= selectedSecondSpecial) and gameFunction:InvokeServer("NewGame", {Selections = BaseSelection})) or (specialAbility.Value == selectedSpecial and secondSpecialAbility.Value == selectedSecondSpecial and subChangerCheckBox:SetToggle(false)) 
end

local function ToggleFlight()
    local isFlyToggled = flyCheckBox:IsToggled()

    setupvalue(MainControl.startRealFlying, 3, isFlyToggled)
    setupvalue(MainControl.startRealFlying, 4, isFlyToggled)

    if isFlyToggled then
        MainControl.startRealFlying(Character, 0)
    end
end

for i, v in ipairs(teleportPresets) do
    local text = mapTeleportCategory:new("Text", v.name)
    local category = text:CreateCategory()

    for name, position in pairs(v.places) do
        local button = category:new("Button", name)

        button:OnPressed(function()
            humanoidRootPart.CFrame = position
        end)
    end
end

for _, v in pairs(Players:GetPlayers()) do
    local playerText = playersCategory:new("Text", v.Name)
    playerText:SetColor((v == LocalPlayer and Color3.fromRGB(184, 255, 184)) or Color3.fromRGB(211,211,211))

    local playerCategory = playerText:CreateCategory()
    local teleportButton = playerCategory:new("Button", "Teleport")
    local appearanceText = playerCategory:new("Text", "Appearance")

    local statsText = playerCategory:new("Text", "Stats")

    local appearanceCategory = appearanceText:CreateCategory()
    local statsCategory = statsText:CreateCategory()

    local playerData = v:WaitForChild("PlayerData")

    for _, v in pairs(playerData:WaitForChild("Appearance"):GetChildren()) do
        local dataName = playerDataExpectionNames[v.Name] or v.Name
        local valueText = appearanceCategory:new("Text", dataName .. ": " ..v.Value)

        v:GetPropertyChangedSignal("Value"):Connect(function()
            valueText:Set(dataName .. ": " ..v.Value)
        end)
    end

    for _, v in pairs(playerData:WaitForChild("Stats"):GetChildren()) do
        local dataName = playerDataExpectionNames[v.Name] or v.Name
        local valueText = statsCategory:new("Text", dataName .. ": " ..v.Value)

        v:GetPropertyChangedSignal("Value"):Connect(function()
            valueText:Set(dataName .. ": " ..v.Value)
        end)
    end

    teleportButton:OnPressed(function()
        humanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
    end)

    playersUIObjects[v] = playerText
end

walkSpeedSpeedSlider:OnChanged(function()
    humanoid.WalkSpeed = walkSpeedSpeedSlider:GetValue()
end)

jumpPowerSlider:OnChanged(function()
    humanoid.JumpPower = jumpPowerSlider:GetValue()
end)

subChangerCheckBox:OnChanged(function()
    if subChangerCheckBox:IsToggled() then
        humanoid.Health = 0
    end
end)

autofarmCheckBox:OnChanged(function()
    local npc

    while autofarmCheckBox:IsToggled() and task.wait() do
        local isContinuable = playerData.PlayerSettings.Continuable.Value
        local menuStatus = getupvalue(MainControl.SpawnCharacter, 2)

        if npc and not MainControl.Transitioning and isContinuable and menuStatus == 2 then
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            humanoidRootPart.CFrame = npc.PrimaryPart.CFrame * CFrame.new(0,-5.25,0) * CFrame.Angles(math.rad(90), 0, 0)
        end

        task.spawn(function()
            for quest, _ in pairs(Quests) do
                if autofarmCheckBox:IsToggled() and isContinuable and menuStatus < 2 and MainControl.Fade.BackgroundTransparency == 1 then
                    MainControl.MainFrame:TweenPosition(UDim2.new(0.5, -150, 1.5, -150), "Out", "Quad", 1, true)
                    MainControl.SpawnFrame:TweenPosition(UDim2.new(2, -10, 1, -10), "Out", "Quad", 2, true)

                    MainControl.SpawnCharacter()
                elseif not autofarmCheckBox:IsToggled() or not isContinuable or menuStatus < 2 or MainControl.Transitioning then
                    break
                end

                if not canCompleteQuest and lastQuest ~= quest then
                    local nameTagIcon = Character.Head.Nametag.Icon

                    quest = nameTagIcon and (quest == "RedLotus1" and nameTagIcon.Image == "" and "WhiteLotus1") 
                            or (quest == "WhiteLotus1" and nameTagIcon.Image == "rbxassetid://87177558" and "RedLotus1") 
                            or (quest == "RedLotus1" and nameTagIcon.Image == "rbxassetid://869158044" and "WhiteLotus1") 
                            or quest
                                
                    npc = GetQuestNPC(quest)

                    CompleteQuest(quest)
                end
            end
        end)
    end
end)

elementSelector:OnChanged(function()
    specialSelector:ChangeList(specialElements[elementSelector:GetSelected()])
    secondSpecialSelector:ChangeList(secondSpecialElements[specialSelector:GetSelected()] or secondSpecialElements[elementSelector:GetSelected()] or {"None"})
end)

specialSelector:OnChanged(function()
    secondSpecialSelector:ChangeList(secondSpecialElements[specialSelector:GetSelected()] or secondSpecialElements[elementSelector:GetSelected()] or {"None"})
end)

flyCheckBox:OnChanged(function()
    ToggleFlight()
end)

killAuraCheckBox:OnChanged(function()
    while killAuraCheckBox:IsToggled() and task.wait() do
        task.spawn(gameFunction.InvokeServer, gameFunction, "ProcessKey", {
            Key = "Q"
        })
    end
end)

flySpeedSlider:OnChanged(function()
    setconstant(MainControl.startRealFlying, 66, flySpeedSlider:GetValue())
end)

rawset(MainControl, "DecreaseStamina", function(...)
    if infiniteStaminaCheckBox:IsToggled() or autofarmCheckBox:IsToggled() then
        return
    end
        
    return OldDecreaseStamina(...)
end)    

Character.BattlerHealth:GetPropertyChangedSignal("Value"):Connect(function()
    if godmodeCheckBox:IsToggled() then
        gameEvent:FireServer("SpecialAbility", {
            Ability = "TornadoPush", 
            Damage = -2e9, 
            Opponent = LocalPlayer
        })
    end

    ToggleFlight()
end)

OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if not checkcaller() and method == "FireServer" and disableDamageCheckBox:IsToggled() and (args[2] and (args[2].Key == "Burn" or args[2].Ability == "TornadoPush")) then
        return
    end

    return OldNameCall(self, ...) 
end)

OldNewIndex = hookmetamethod(game, "__newindex", function(self, index, value)
    if not checkcaller() and index == "WalkSpeed" then
        if value == 25 and sprintSpeedSlider:GetValue() > 25 then
            return OldNewIndex(self, index, sprintSpeedSlider:GetValue()) 
        elseif walkSpeedSpeedSlider:GetValue() > 16 then
            return OldNewIndex(self, index, walkSpeedSpeedSlider:GetValue()) 
        end
    end
    
    return OldNewIndex(self, index, value)
end)

Players.PlayerAdded:Connect(function(player)
    local playerText = playersCategory:new("Text", player.Name)

    local playerCategory = playerText:CreateCategory()
    local teleportButton = playerCategory:new("Button", "Teleport")
    local appearanceText = playerCategory:new("Text", "Appearance")

    local statsText = playerCategory:new("Text", "Stats")

    local appearanceCategory = appearanceText:CreateCategory()
    local statsCategory = statsText:CreateCategory()

    local playerData = player:WaitForChild("PlayerData")

    for _, v in pairs(playerData:WaitForChild("Appearance"):GetChildren()) do
        local dataName = playerDataExpectionNames[v.Name] or v.Name
        local valueText = appearanceCategory:new("Text", dataName .. ": " ..v.Value)

        v:GetPropertyChangedSignal("Value"):Connect(function()
            valueText:Set(dataName .. ": " ..v.Value)
        end)
    end

    for _, v in pairs(playerData:WaitForChild("Stats"):GetChildren()) do
        local dataName = playerDataExpectionNames[v.Name] or v.Name
        local valueText = statsCategory:new("Text", dataName .. ": " ..v.Value)

        v:GetPropertyChangedSignal("Value"):Connect(function()
            valueText:Set(dataName .. ": " ..v.Value)
        end)
    end

    teleportButton:OnPressed(function()
        humanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
    end)
    
    playersUIObjects[player] = playerText

    print(player, "Joined")
end)

Players.PlayerRemoving:Connect(function(player)
    print(player, "Left")

    playersUIObjects[player]:Destroy(true)
	playersUIObjects[player] = nil
end)

humanoid.Died:Connect(function()
    shouldStopFarm = true
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    canCompleteQuest = true 

    if subChangerCheckBox:IsToggled() then
        local shouldContinue = ChangeElement()

        task.wait()

        if shouldContinue then
            local humanoid = character:WaitForChild("Humanoid")

            if subChangerCheckBox:IsToggled() then
                humanoid.Health = 0
                return
            end
        elseif farmAfterSubCheckBox:IsToggled() then
            autofarmCheckBox:SetToggle(true)
        end
    end

    local MainMenu = LocalPlayer.PlayerGui:WaitForChild("MainMenu")
    local MenuControl = MainMenu:WaitForChild("MenuControl")
    local BattlerHealth = character:WaitForChild("BattlerHealth")

    Character = character

    humanoidRootPart = character.HumanoidRootPart
    humanoid = character.Humanoid

    humanoid.WalkSpeed = walkSpeedSpeedSlider:GetValue()
    humanoid.JumpPower = jumpPowerSlider:GetValue()

    repeat task.wait() until getsenv(MenuControl).DecreaseStamina

    MainControl = getsenv(LocalPlayer.PlayerGui.MainMenu.MenuControl)

    OldDecreaseStamina = rawget(MainControl, "DecreaseStamina")

    rawset(MainControl, "DecreaseStamina", function(...)
        if infiniteStaminaCheckBox:IsToggled() or autofarmCheckBox:IsToggled() then
            return
        end
        
        return OldDecreaseStamina(...)
    end)
    
    BattlerHealth:GetPropertyChangedSignal("Value"):Connect(function()
        if godmodeCheckBox:IsToggled() then
            gameEvent:FireServer("SpecialAbility", {
                Ability = "TornadoPush", 
                Damage = -2e9, 
                Opponent = LocalPlayer
            })
        end

        ToggleFlight()
    end)

    humanoid.Died:Connect(function()
        shouldStopFarm = true
    end)

    ToggleFlight()

    setconstant(MainControl.startRealFlying, 66, flySpeedSlider:GetValue())

    local isContinuable = playerData.PlayerSettings.Continuable.Value
    local menuStatus = getupvalue(MainControl.SpawnCharacter, 2)

    if autofarmCheckBox:IsToggled() and isContinuable then
        MainControl.MainFrame.Visible = false
        MainControl.SpawnFrame.Visible = false

        MainControl.SpawnCharacter()
    end

    canCompleteQuest = false
    shouldStopFarm = false
end)
