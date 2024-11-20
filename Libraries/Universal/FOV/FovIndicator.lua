local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local FovIndicator = {}
FovIndicator.__index = FovIndicator

local TargetFinder = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Universal/FOV/TargetFinder.lua"))()

function FovIndicator.new(isMouse)
    local circle = Drawing.new("Circle")
    local newFovIndicator = setmetatable({
        circle = circle,
        isMouse = isMouse
    }, FovIndicator)
    
    if isMouse then
        UserInputService.InputChanged:Connect(function(input, gameprocessed)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation()
                newFovIndicator:SetPosition(mousePos.x, mousePos.y)
            end
        end)
    end

    return setmetatable(TargetFinder, {__index = newFovIndicator})
end

function FovIndicator:SetPosition(x, y)
    local circle = self.circle
    circle.Position = Vector2.new(x, y)
end

function FovIndicator:IsVisible()
    local circle = self.circle
    return circle.Visible
end

function FovIndicator:SetVisibility(bool)
    local circle = self.circle
    circle.Visible = bool
end

function FovIndicator:UpdateRadius(fov)
    local circle = self.circle

    local screenWidth = Camera.ViewportSize.X
    local radius = math.tan(math.rad(fov / 2)) * screenWidth

    circle.Radius = radius / 2
end

return FovIndicator