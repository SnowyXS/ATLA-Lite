local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local FovCircle = {}
FovCircle.__index = FovCircle

function FovCircle.new(isMouse)
    local circle = Drawing.new("Circle")

    return setmetatable({
        circle = circle,
        isMouse = isMouse
    }, FovCircle)
end

function FovCircle:SetPosition(x, y)
    local circle = self.circle
    circle.Position = Vector2.new(x, y)
end

function FovCircle:SetVisibility(bool)
    local circle = self.circle
    circle.Visible = bool
end

function FovCircle:UpdateRadius(fov)
    local circle = self.circle

    local screenWidth = Camera.ViewportSize.X
    local radius = math.tan(math.rad(fov / 2)) * screenWidth

    circle.Radius = 300
end

function FovCircle:_GetDistance(destination)
    local origin = isMouse and UserInputService:GetMouseLocation() or Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local magnitude = (origin - destination).magnitude
    return magnitude
end

function FovCircle:_IsInFOV(position)
    local circle = self.circle

    return self:_GetDistance(Vector2.new(position.X, position.Y)) <= circle.Radius
end

function FovCircle:GetClosestTarget()
    local ClosestTarget, ClosestDist
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) 

    for _, Target in pairs(Players:GetPlayers()) do
        if Target == LocalPlayer then continue end
        
        local targetChar = Target.Character
        if not targetChar then continue end

        local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        local expectionCheck = self.ExpectionCheck and self.ExpectionCheck(Target)
                               or not self.ExpectionCheck and false

        if expectionCheck then continue end

        local rootPos = rootPart.Position
        local position, onScreen = Camera:WorldToScreenPoint(rootPos)
        
        if onScreen and self:_IsInFOV(position) then
            --[[local distance =  self:_GetDistance(Vector2.new(position.X, position.Y))
            local oldDistance = ClosestDist or math.huge

            if distance <= oldDistance then
                ClosestTarget = Target
                ClosestDist = distance
            end
            --]]
            ClosestTarget = Target
        end
    end

    return ClosestTarget
end

return FovCircle