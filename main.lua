local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/ATLA-Lite/main/UI/Controller.lua"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local networkFolder = ReplicatedStorage.NetworkFolder
local gameFunction = networkFolder.GameFunction
local gameEvent = networkFolder.GameEvent

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character

local playerData = LocalPlayer.PlayerData
local appearance = playerData.Appearance

local specialAbility = appearance.Special
local secondSpecialAbility = appearance.Special2

local autofarmCheckBox = UI:new("Checkbox", "AutoFarm")
local subChangerCheckBox = UI:new("Checkbox", "Sub Changer")
local godmodeCheckBox = UI:new("Checkbox", "GodMode")
local infiniteStaminaCheckBox = UI:new("Checkbox", "Infinite Stamina")
local sprintSpeedSlider = UI:new("Slider", "Sprint Speed", 25, 25, 1000, 1)

local autofarmCategory = autofarmCheckBox:CreateCategory()
local minimumXpSlider = autofarmCategory:new("Slider", "Minimum XP", 0, 0, 3000, 100)
local delaySlider = autofarmCategory:new("Slider", "Delay", 3, 3, 5, 1)

local subChangerCategory = subChangerCheckBox:CreateCategory()
local elementSelector = subChangerCategory:new("ListSelector", {"Air", "Water", "Fire", "Earth"})
local specialSelector = subChangerCategory:new("ListSelector", {"Flight"})
local secondSpecialSelector = subChangerCategory:new("ListSelector", {"None"})

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
    Ice = {"None", "Ice Healing"},
    Plant = {"None", "Plant Healing"},
    Earth = {"None", "Lava Seismic", "Metal Seismic", "Sand Seismic"}
}


local function CompleteQuest(quest)
    local currentNPC
    
    local expection = {RedLotus1 = CFrame.new(896.94488525391, 236.26509094238, -3067.7453613281)}
    local nameTagIcon = Character:FindFirstChild("Head"):FindFirstChild("Nametag").Icon

    assert(rawget(Quests, quest), "Quest not found.")
    
    quest = (quest == "RedLotus1" and nameTagIcon.Image == "" and "WhiteLotus1") or (quest == "WhiteLotus1" and nameTagIcon.Image == "rbxassetid://87177558" and "RedLotus1") or (quest == "RedLotus1" and nameTagIcon.Image == "rbxassetid://869158044" and "WhiteLotus1") or quest

    for NPCName, v in pairs(NPCList) do
        if table.find(v, quest) and Quests[v[1]].Rewards.Experience >= minimumXpSlider:GetValue() then
            currentNPC = questNPCs:FindFirstChild(NPCName)
            break 
        end
    end

    canCompleteQuest = (currentNPC and Character.Humanoid.Health > 0 and Character.Humanoid.WalkSpeed > 0) and not gameFunction:InvokeServer("GetQuestData").QuestName ~= "" and not Character:FindFirstChild("Down") and not (Character.HumanoidRootPart:FindFirstChild("DownTimer") and Character.HumanoidRootPart.DownTimer.TextLabel.Text ~= "") and not canCompleteQuest

    if canCompleteQuest then
        gameFunction:InvokeServer("Abandon")

        Character.PrimaryPart.CFrame = (expection[quest] or currentNPC.PrimaryPart.CFrame) + Vector3.new(0,5,0)

        task.wait(0.5)

        for step = 1, #Quests[quest].Steps + 1 do 
            local distance = (((expection[quest] and expection[quest].p) or currentNPC.PrimaryPart.CFrame.p) - Character.PrimaryPart.CFrame.p).Magnitude

            if distance > 25 or Character.Humanoid.Health <= 0 or Character.Humanoid.WalkSpeed <= 0  or Character.BattlerHealth.Value <= 0 then
                break
            end

            gameFunction:InvokeServer("AdvanceStep", {
                QuestName = quest,
                Step = step
            })
        end

        task.wait(delaySlider:GetValue())

        canCompleteQuest = false
    end
end

function ChangeElement()
    local selectedSpecial = specialSelector:GetSelected()
    local selectedSecondSpecial = secondSpecialSelector:GetSelected()
    
    BaseSelection.Elements = elementSelector:GetSelected()

    print(selectedSpecial, specialAbility.Value == selectedSpecial)
    print(selectedSecondSpecial, secondSpecialAbility.Value == selectedSecondSpecial)

    return ((specialAbility.Value ~= selectedSpecial or secondSpecialAbility.Value ~= selectedSecondSpecial) and gameFunction:InvokeServer("NewGame", {Selections = BaseSelection})) or (specialAbility.Value == selectedSpecial and secondSpecialAbility.Value == selectedSecondSpecial and subChangerCheckBox:SetToggle(false)) 
end

subChangerCheckBox:OnChanged(function()
    if subChangerCheckBox:IsToggled() then
        Character.Humanoid.Health = 0
    end
end)

autofarmCheckBox:OnChanged(function()
    while autofarmCheckBox:IsToggled() do
        for i,v in pairs(Quests) do
            if not autofarmCheckBox:IsToggled() then
                break
            end
            
            CompleteQuest(i) 
            
            task.wait()
        end
    end
end)

elementSelector:OnChanged(function()
    specialSelector:ChangeList(specialElements[elementSelector:GetSelected()])
    secondSpecialSelector:ChangeList(secondSpecialElements[specialSelector:GetSelected()] or secondSpecialElements[elementSelector:GetSelected()] or {"None"})
end)

specialSelector:OnChanged(function()
    secondSpecialSelector:ChangeList(secondSpecialElements[specialSelector:GetSelected()] or secondSpecialElements[elementSelector:GetSelected()] or {"None"})
end)

OldNewIndex = hookmetamethod(game, "__newindex", function(self, index, value)
    if not checkcaller() and index == "WalkSpeed" then
        if value == 25 then
            return OldNewIndex(self, index, sprintSpeedSlider:GetValue()) 
        end
    end
    
    return OldNewIndex(self, index, value)
end)

rawset(MainControl, "DecreaseStamina", function(...)
    if infiniteStaminaCheckBox:IsToggled() and not checkcaller() then
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
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    if subChangerCheckBox:IsToggled() then
        ChangeElement()

        task.wait()

        character:WaitForChild("Humanoid").Health = 0
    end

    local BattlerHealth = character:WaitForChild("BattlerHealth")

    repeat task.wait() until LocalPlayer.PlayerGui:FindFirstChild("MainMenu") and getsenv(LocalPlayer.PlayerGui.MainMenu.MenuControl).DecreaseStamina

    for i,v in pairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "QuestModule") then
            MainControl = v
            break
        end
    end

    OldDecreaseStamina = rawget(MainControl, "DecreaseStamina")

    rawset(MainControl, "DecreaseStamina", function(...)
        if infiniteStaminaCheckBox:IsToggled() and not checkcaller() then
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
    end)

    Character = character
end)
