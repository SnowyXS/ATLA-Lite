local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local FovCircle = {}
FovCircle.__index = FovCircle

function FovCircle.new(fov)
    local circle = Drawing.new("Circle")

    return setmetatable({
        circle = circle
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
    local screenWidth = Camera.ViewportSize.X
    local screenHeight = Camera.ViewportSize.Y

    local horizontalFovSize = math.tan(math.rad(fov / 2)) * screenWidth
    local verticalFovSize = math.tan(math.rad(fov / 2)) * screenHeight

    local circle = self.circle

    circle.Radius = (horizontalFovSize + verticalFovSize) / 4
end

function FovCircle:_IsInFOV(character)
    local circle = self.circle
    local mousePos = UserInputService:GetMouseLocation()

    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local position = Camera:WorldToScreenPoint(part.Position)
            local magnitude = (mousePos - Vector2.new(position.X, position.Y)).magnitude

            if magnitude <= circle.Radius then return true end
        end
    end
    
    return false
end

function FovCircle:GetClosestTarget()
	local ClosestTarget, ClosestDist
	local mousePos = UserInputService:GetMouseLocation()

	for _, Target in pairs(Players:GetPlayers()) do
        if Target == LocalPlayer then continue end
        
        local targetChar = Target.Character
        if not targetChar then continue end

        local rootPart = targetChar:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        local expectionCheck = self.ExpectionCheck and self.ExpectionCheck(Target)
                               or not self.ExpectionCheck and false
        print(expectionCheck)
        if expectionCheck then continue end

        local rootPos = rootPart.Position
        local vector, onScreen = Camera:WorldToScreenPoint(rootPos)

        if onScreen and self:_IsInFOV(targetChar) then
            local distance = (mousePos - Vector2.new(vector.X, vector.Y)).Magnitude
            local oldDistance = ClosestDist or math.huge

            if distance <= oldDistance then
                ClosestTarget = Target
                ClosestDist = distance
            end
        end
	end

	return ClosestTarget
end

return FovCircle