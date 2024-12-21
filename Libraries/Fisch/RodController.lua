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
    local bindableEvent = BindableEvents:Create()
    local Controller = setmetatable({
        _rod = rodObject,
        _castRemote = castRemote,
        _resetRemote = reset,
        _isEquipped = isEquipped,
        _bindableEvent = bindableEvent
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

    local function OnBackPackChildAdded(instance)
        if Controller._rod == instance or not IsRod(instance) then return end

        local events = instance:WaitForChild("events")
        Controller._rod = instance
        Controller._castRemote = events.cast
        Controller._resetRemote = events.reset

        bindableEvent:Fire(instance)
    end
    
    local function OnCharacterAdded(newCharacter)
        humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
        humanoid = newCharacter:WaitForChild("Humanoid")
        
        backpack = LocalPlayer.Backpack
        character = newCharacter

        backpack.ChildAdded:Connect(OnBackPackChildAdded)
    end

    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and method == "FireServer" then
            if self.Name == "equip" then
                local args = {...}
                
                if args[1].Parent == backpack then
                    Controller._isEquipped = true
                else
                    Controller._isEquipped = false
                end
            end
        end
    
        return OldNamecall(self, ...)
    end)


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
    local bindableEvent = self._bindableEvent

    bindableEvent:Connect(callback)
end

return RodController