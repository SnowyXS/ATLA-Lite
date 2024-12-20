local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local screengui = Instance.new("ScreenGui", CoreGui)

local Windows = {}
Windows.__index = Windows

function Windows.new(title)
    local outerFrame = Instance.new("Frame", screengui)
    outerFrame.Position = UDim2.new(0, 35, 0, 24)
    outerFrame.Size = UDim2.new(0, 170, 0, 20)
    outerFrame.BorderColor3 = Color3.new(0, 0, 0)
    outerFrame.BorderSizePixel = 3
    outerFrame.Visible = false

    local innerFrame = Instance.new("Frame", outerFrame)
    innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    innerFrame.Size = UDim2.new(1, 0, 1, 0)
    innerFrame.BackgroundColor3 = Color3.new(0.109804, 0.109804, 0.109804)
    innerFrame.BorderColor3 = Color3.new(0.196078, 0.196078, 0.196078)
    innerFrame.BorderSizePixel = 2

    local titleLabel = Instance.new("TextLabel", innerFrame)
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.Code
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title

    local padding = Instance.new("UIPadding", titleLabel)
    padding.PaddingLeft = UDim.new(0, 4)

    local contentFrame = Instance.new("Frame", innerFrame)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Position = UDim2.new(0, 0, 0, 20)
    contentFrame.Size = UDim2.new(1, 0, 1, -20)

    Instance.new("UIListLayout", contentFrame)

    local isDragging = false
    local startPos

    local function IsInBounds(input)
        local position = input.Position
        local mousePos = Vector2.new(position.X, position.Y)
        
        local absPos = outerFrame.AbsolutePosition
        local absSize = outerFrame.AbsoluteSize
        
        local bottomPos = absPos + absSize 
        
        return mousePos.X >= absPos.X and mousePos.X <= bottomPos.X and mousePos.Y >= absPos.Y and mousePos.Y <= bottomPos.Y
    end

    local InputBegan = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not IsInBounds(input) then return end
            
            local position = input.Position
            local mousePos = Vector2.new(position.X, position.Y)
            startPos = mousePos - outerFrame.AbsolutePosition
            
            isDragging = true
        end
    end)

    local InputChanged = UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local position = input.Position
            local mousePos = Vector2.new(position.X, position.Y)
            local offset = mousePos - startPos
            
            outerFrame.Position = UDim2.new(0, offset.X, 0, offset.Y)	
        end
    end)

    local InputEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    local Window = setmetatable({
        _frame = outerFrame,
        _contentFrame = contentFrame,
        _objects = {},
        _connections = {
            InputBegan,
            InputChanged,
            InputEnded
        }
    }, Windows)

    return Window
end

function Windows:AddText(text, color)
    local objects = self._objects
    local outerFrame = self._frame
    local contentFrame = self._contentFrame

    local label = Instance.new("TextLabel", contentFrame)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.TextColor3 = color
    label.Font = Enum.Font.DenkOne
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text

    local padding = Instance.new("UIPadding", label)
    padding.PaddingLeft = UDim.new(0, 4)
        
    outerFrame.Size = outerFrame.Size + UDim2.new(0, 0, 0, 20)
    objects[text] = label
end

function Windows:SetVisibility(bool)
    local outerFrame = self._frame
    outerFrame.Visible = bool
end

function Windows:UpdateTextColor(text, color)
    local objects = self._objects
    local object = objects[text]
    
    assert(object, "Text doesn't exist")
    
    object.TextColor3 = color
end

function Windows:RemoveText(text)
    local objects = self._objects
    local object = objects[text]
    
    assert(object, "Text doesn't exist")
    
    object:Destroy()
    objects[text] = nil
end

function Windows:Remove()
    local objects = self._objects
    local connections = self._connections
    
    for _, object in pairs(objects) do
        object:Destroy()
    end

    for _, connection in pairs(connections) do
        connection:Disconnect()
    end

    table.clear(self)
end

return Windows