local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local TargetFinder = {}
TargetFinder.__index = TargetFinder

function TargetFinder:_GetDistance(destination)
    local origin = self.isMouse and UserInputService:GetMouseLocation() or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local magnitude = (origin - destination).magnitude

    return magnitude
end

function TargetFinder:_IsInFOV(position)
    local circle = self.circle  
    local magnitude = self:_GetDistance(position)

    return magnitude, magnitude <= circle.Radius
end

function TargetFinder:GetClosestTarget()
    local ClosestTarget, ClosestDist = nil, math.huge

    for _, Target in pairs(Players:GetPlayers()) do
        if Target == LocalPlayer then continue end
        
        local targetChar = Target.Character
        if not targetChar then continue end

        local head = targetChar:FindFirstChild("Head")
        if not head then continue end
        
        local expectionCheck = self.ExpectionCheck and self.ExpectionCheck(Target)
                               or not self.ExpectionCheck and false

        if not expectionCheck then continue end

        local headPos = head.Position
        local viewPortPos, onScreen = Camera:WorldToViewportPoint(headPos)
        if not onScreen then continue end

        local screenPos = Vector2.new(viewPortPos.X, viewPortPos.Y)
        local distance, isInFov = self:_IsInFOV(screenPos)
        if not isInFov then continue end

        if distance <= ClosestDist then
            ClosestTarget = Target
            ClosestDist = distance
        end
    end

    return ClosestTarget
end

return TargetFinder