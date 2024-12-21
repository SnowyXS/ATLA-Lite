local BindableEvents = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/refs/heads/main/Libraries/Dependencies/BindableEvents.lua"))()

local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local networkStats = Stats.Network
local serverStatsItem = networkStats.ServerStatsItem

local dataPing = serverStatsItem["Data Ping"]

local LocalPlayer = Players.LocalPlayer
local backpack = LocalPlayer.Backpack

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid.Animator

local RodController = {}
RodController.__index = RodController

local function IsRod(instance)
    local name = instance.Name:lower()
    return instance:IsA("Tool") and (name:find("rod") or instance:FindFirstChild("rod/client"))
end

function RodController.new()
    local rodAddedEvent = BindableEvents:Create()
    local rodEquippedEvent = BindableEvents:Create()
    local childRemovedEvent = BindableEvents:Create()

    local Controller = setmetatable({
        _isEquipped = false,
        _rodAddedEvent = rodAddedEvent,
        _rodEquippedEvent = rodEquippedEvent,
        _rodChildRemoved = childRemovedEvent
    }, RodController)

    for _, v in pairs(backpack:GetChildren()) do
        if IsRod(v) then
            local events = v.events
            Controller._rod = v
            Controller._castRemote = events.cast
            Controller._resetRemote = events.reset
    
            break
        end
    end
    
    for _, v in pairs(character:GetChildren()) do
        if IsRod(v) then
            local events = v.events
            Controller._rod = v
            Controller._castRemote = events.cast
            Controller._resetRemote = events.reset
            Controller._isEquipped = true
            
            break
        end
    end

    local function OnEquip()
        Controller._isEquipped = true
        rodEquippedEvent:Fire()
    end

    local function OnUnequip()
        Controller._isEquipped = false
    end

    local function OnChildRemoved(instance)
        childRemovedEvent:Fire(instance)
    end

    local function OnBackPackChildAdded(instance)
        if Controller._rod == instance or not IsRod(instance) then return end

        local events = instance:WaitForChild("events")
        Controller._rod = instance
        Controller._castRemote = events.cast
        Controller._resetRemote = events.reset
        
        instance.Equipped:Connect(OnEquip)
        instance.Unequipped:Connect(OnUnequip)
        instance.ChildRemoved:Connect(OnChildRemoved)

        rodAddedEvent:Fire(instance)
    end
    
    local function OnCharacterAdded(newCharacter)
        humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
        humanoid = newCharacter:WaitForChild("Humanoid")
        
        backpack = LocalPlayer.Backpack
        character = newCharacter

        backpack.ChildAdded:Connect(OnBackPackChildAdded)
    end

    local rodObject = Controller._rod
    rodObject.Equipped:Connect(OnEquip)
    rodObject.Unequipped:Connect(OnUnequip)
    rodObject.ChildRemoved:Connect(OnChildRemoved)

    backpack.ChildAdded:Connect(OnBackPackChildAdded)
    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

    return Controller
end

function RodController:Cast(skip, percentage)
    self:Reset()
    task.wait(dataPing:GetValue() / 1000)

    if not skip then return VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1) end

    local castRemote = self._castRemote
    castRemote:FireServer(percentage or 100, 1) 
end

function RodController:Reset()
    local resetRemote = self._resetRemote

    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    resetRemote.FireServer(resetRemote)

    for i, v in pairs(animator:GetPlayingAnimationTracks()) do
        if v.Name == "waiting" then
            v:Stop()
            break
        end
    end
end

function RodController:GetRod()
    return self._rod
end

function RodController:IsEquipped()
    return self._isEquipped
end

function RodController:OnAdded(callback)
    local rodAddedEvent = self._rodAddedEvent

    rodAddedEvent:Connect(callback)
end

function RodController:OnEquipped(callback)
    local rodEquippedEvent = self._rodEquippedEvent

    rodEquippedEvent:Connect(callback)
end

function RodController:OnChildRemoved(callback)
    local rodChildRemoved = self._rodChildRemoved

    rodChildRemoved:Connect(callback)
end

return RodController