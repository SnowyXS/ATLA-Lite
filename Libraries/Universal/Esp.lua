local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character
local primaryPart = character.PrimaryPart

local CurrentCamera = workspace.CurrentCamera

local cache = {}
local Esp = {
    _cache = cache,
}
Esp.__index = Esp

function Esp.new(player)
    local objects = {}
    local character = player.Character

    local box = Drawing.new("Square")
    box.Filled = false
    box.Thickness = 2
    
    local playerName = Drawing.new("Text")
    playerName.Size = 24
    playerName.Text = player.Name
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

    local PlayerESP = setmetatable({
        objects = objects,
        player = player,
        character = character,
    }, Esp)

    local function OnCharacterAdded(character)
        chams.Adornee = character

        PlayerESP.character = character
    end

    PlayerESP.characterAdded = player.CharacterAdded:Connect(OnCharacterAdded)

    cache[player] = PlayerESP

    return PlayerESP
end

function Esp:Render()
    local target = self.player
    local targetChar = self.character
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetChar and not targetRoot then return self:HideObjects() end 

    local targetRootPos = targetRoot.Position

    local distance = (primaryPart.CFrame.p - targetRootPos).Magnitude
    local isInRenderDistance = Esp:IsInRenderDistance(distance)
    
    local rootViewPort, isRendered = CurrentCamera:worldToViewportPoint(targetRootPos)
    if not isRendered or not isInRenderDistance then return self:HideObjects() end

    self:UpdateObjects(rootViewPort)
end

function Esp:IsInRenderDistance(distance)
    return Options.DistanceSlider.Value == 0 or distance < Options.DistanceSlider.Value
end

function Esp:HideObjects() 
    local objects = self.objects
    objects.box.Visible = false
    objects.playerName.Visible = false
    objects.healthBar.Visible = false
    objects.chams.Enabled = false
end

function Esp:GetHealthPercentage()
    local targetChar = self.character
    local targetHumanoid = targetChar.Humanoid
    
    local health = targetHumanoid.Health
    local maxHealth = targetHumanoid.MaxHealth

    return health / maxHealth
end

function Esp:UpdateObjects(rootViewPort)
    local objects = self.objects
    local targetChar = self.character

    local targetRoot = targetChar.HumanoidRootPart
    local targetRootPos = targetRoot.Position
    
    local targetHead = targetChar.Head
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

function Esp:GetCache()
    return self._cache
end

function Esp:Destroy()
    local players = self.players
    local player = self.player

    local objects = self.objects
    local cache = self:GetCache()

    for _, object in pairs(objects) do
        object:Remove()
    end
    
    self.characterAdded:Disconnect()
    
    setmetatable(self, nil)
    table.clear(self)

    cache[player] = nil
end

getgenv().Esp = Esp

return Esp
