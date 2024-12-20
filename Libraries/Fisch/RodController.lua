local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local resources = ReplicatedStorage:WaitForChild("resources")
local animations = resources:WaitForChild("animations")
local fishingAnimations = animations:WaitForChild("fishing")

local holdAnimation = fishingAnimations.casthold
local throwAnimation = fishingAnimations.throw
local waitingAnimation = fishingAnimations.waiting

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

local function OnBackPackChildAdded(instance)
    if not IsRod(instance) then return end

    local events = instance:WaitForChild("events")
    castRemote = events.cast
end

local function OnCharacterAdded(newCharacter)
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    humanoid = newCharacter:WaitForChild("Humanoid")
    
    animator = humanoid.Animator
    character = newCharacter

    Backpack.ChildAdded:Connect(OnBackPackChildAdded)
end

function RodController.new()
    local rodObject, castRemote, reset

    for _, v in pairs(backpack:GetChildren()) do
        if IsRod(v) then
            local events = v.events
            rodObject = v
            castRemote = events.cast
            reset = events.reset
    
            break
        end
    end
    
    for _, v in pairs(character:GetChildren()) do
        if IsRod(v) then
            local events = v.events
            rodObject = v
            castRemote = events.cast
            reset = events.reset
    
            break
        end
    end

    backpack.ChildAdded:Connect(OnBackPackChildAdded)
    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

    local Controller = setmetatable({
        _rod = rodObject,
        _castRemote = castRemote,
        _resetRemote = reset
    }, RodController)

    return Controller
end

function RodController:Cast(skip, percentage)
    self:Reset()
    if not skip then return VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1) end

    local castRemote = self._castRemote
    
    local throw = animator:LoadAnimation(throwAnimation)
    local hold = animator:LoadAnimation(holdAnimation)
    local waiting = animator:LoadAnimation(waitingAnimation)
    
    hold:Play()
    task.wait(0.5)
    hold:Stop()
    
    castRemote:FireServer(percentage or 100, 1) 

    throw:Play()
    throw.Stopped:wait()

    waiting:Play()
    waiting.Stopped:wait()
end

function RodController:Reset()
    local resetRemote = self._resetRemote

    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    resetRemote:FireServer()

    for i, v in pairs(animator:GetPlayingAnimationTracks()) do
        if v.Name == "waiting" then
            v:Stop()
            break
        end
    end
end

return RodController