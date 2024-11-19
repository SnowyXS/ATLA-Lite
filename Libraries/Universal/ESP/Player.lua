local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character
local primaryPart = character.PrimaryPart

local CurrentCamera = workspace.CurrentCamera

local PlayerESP = {}
PlayerESP.__index = PlayerESP

function PlayerESP.new(player)
    local objects = {}
    local character = player.Character

    local box = Drawing.new("Square")
    box.Filled = false
    box.Thickness = 2
    
    local playerName = Drawing.new("Text")
    playerName.Size = 24
    playerName.Text = player.Name
    playerName.Font = Drawing.Fonts.UI
    playerName.Center = true
    playerName.Outline = true
    playerName.Font = 3
    
    local healthBar = Drawing.new("Square")
    healthBar.Filled = false
    healthBar.Thickness = 1

    local chams = Instance.new("Highlight", CoreGui)
    chams.Adornee = character

    objects.box = box
    objects.playerName = playerName
    objects.healthBar = healthBar
    objects.chams = chams

    local EspObject = setmetatable({
        objects = objects,
        player = player,
        character = character,
    }, PlayerESP)

    local function OnCharacterAdded(character)
        chams.Adornee = character

        EspObject.character = character
    end
    EspObject.characterAdded = player.CharacterAdded:Connect(OnCharacterAdded)

    return EspObject
end

function PlayerESP:Render()
    local target = self.player
    local targetChar = self.character
    if not targetChar then return self:HideObjects() end 
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return self:HideObjects() end
    
    local targetRootPos = targetRoot.Position

    local distance = (primaryPart.CFrame.p - targetRootPos).Magnitude
    local isInDistance = Options.DistanceSlider.Value == 0 or distance < Options.DistanceSlider.Value
    
    local rootViewPort, isRendered = CurrentCamera:worldToViewportPoint(targetRootPos)
    if not isRendered or not isInDistance then return self:HideObjects() end

    self:UpdateObjects(rootViewPort)
end

function PlayerESP:UpdateObjects(rootViewPort)
    local objects = self.objects
    local targetChar = self.character

    local targetRoot = targetChar.HumanoidRootPart
    local targetRootPos = targetRoot.Position
    
    local targetHead = targetChar:FindFirstChild("Head")
    if not targetHead then return self:HideObjects() end
    
    local targetHeadPos = targetChar.Head.Position

    local viewPortSize = CurrentCamera.ViewportSize
    local headViewPort = CurrentCamera:worldToViewportPoint(targetHeadPos + Vector3.new(0, 1.5, 0))
    local legViewPort = CurrentCamera:worldToViewportPoint(targetRootPos - Vector3.new(0, 2.5, 0))

    local boxWidth = (viewPortSize.X / rootViewPort.Z) * 1.5
    local boxHeight = headViewPort.Y - legViewPort.Y
    local textSize = math.clamp(boxWidth, 0, Options.TextSizeSlider.Value)

    local healthPercentage = self:GetHealthPercentage()

    local box = objects.box
    box.Size = Vector2.new(boxWidth, boxHeight)
    box.Thickness = 1.5
    box.Position = Vector2.new(
        rootViewPort.X - boxWidth / 2, 
        rootViewPort.Y - boxHeight / 2 + 2
    )
    box.Color = (Toggles.TeamColorsCheckBox.Value and self.player.TeamColor.Color) or Options.BoxColor.Value
    box.Visible = Toggles.BoxCheckBox.Value
    
    local playerName = objects.playerName
    playerName.Size = textSize
    playerName.Position = box.Position + Vector2.new(
        (boxWidth - textSize + playerName.TextBounds.Y) / 2,
        (boxHeight - textSize + playerName.TextBounds.Y / 2) - textSize / 2
    )
    playerName.Color = (Toggles.TeamColorsCheckBox.Value and self.player.TeamColor.Color) or Options.NameColor.Value
    playerName.Visible = Toggles.NameTagCheckBox.Value
    
    local healthBar = objects.healthBar
    healthBar.Position = box.Position - Vector2.new(4 + box.Thickness / 2, 0)
    healthBar.Size = Vector2.new(2, boxHeight * healthPercentage) 
    healthBar.Color = Color3.new(0, 1, 0)
    healthBar.Visible = Toggles.HealthBarCheckBox.Value

    local chams = objects.chams
    chams.FillColor = Options.ChamsColor.Value
    chams.FillTransparency = Options.ChamsTransparency.Value / 100
    chams.OutlineColor = Options.ChamsOutLineColor.Value
    chams.OutlineTransparency = Options.ChamsOutLineTransparency.Value / 100
    chams.Enabled = Toggles.ChamsCheckBox.Value
end

function PlayerESP:HideObjects() 
    local objects = self.objects
    objects.box.Visible = false
    objects.playerName.Visible = false
    objects.healthBar.Visible = false
    objects.chams.Enabled = false
end

function PlayerESP:Remove()
    for _, object in pairs(objects) do
        object:Remove()
    end
    
    self.characterAdded:Disconnect()
    
    setmetatable(self, nil)
    table.clear(self)
end

function PlayerESP:GetHealthPercentage()
    local targetChar = self.character
    local targetHumanoid = targetChar.Humanoid
    
    local health = targetHumanoid.Health
    local maxHealth = targetHumanoid.MaxHealth

    return health / maxHealth
ene

return PlayerESP
