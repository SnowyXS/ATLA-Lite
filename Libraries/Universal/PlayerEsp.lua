local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character
local rootPart = character.PrimaryPart

local CurrentCamera = workspace.CurrentCamera

getgenv().PlayerEsp = {
    _players = {},
}
PlayerEsp.__index = PlayerEsp

function PlayerEsp.new(player)
    local objects = {}

    local self = setmetatable({
        _objects = objects,
    }, PlayerEsp)

    local Expection = self._expection and self._expection.new(self)

    local character = player.Character

    local box = Drawing.new("Square")
    box.Filled = false
    box.Thickness = 1
    
    local playerName = Drawing.new("Text")
    playerName.Size = 18
    playerName.Text = player.Name
    playerName.Center = true

    local healthBar = Drawing.new("Square")
    healthBar.Filled = false
    healthBar.Thickness = 1

    local chams = Instance.new("Highlight", CoreGui)
    chams.Adornee = character

    if Expection then
        Expection._player = player
        Expection._character = character

        Expection:Build()
    end
    
    local function OnCharacterAdded(character)
        chams.Adornee = character

        self._character = character
    end

    self._player = player
    self._character = character
    self._characterAdded = player.CharacterAdded:Connect(OnCharacterAdded)

    objects._box = box
    objects._playerName = playerName
    objects._healthBar = healthBar
    objects._chams = chams

    self._players[player] = self

    return self
end

function PlayerEsp:Refresh()
    local target = self._player
    local targetChar = self._character

    local targetHead = targetChar and targetChar:FindFirstChild("Head")
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetChar and targetChar:FindFirstChild("Humanoid")

    if targetRoot and targetHead and targetHumanoid then
        local health = targetHumanoid.Health
        local maxHealth = targetHumanoid.MaxHealth
            
        local distance = rootPart and (rootPart.CFrame.p - targetRoot.CFrame.p).Magnitude or 0
        local renderDistance = (Options.DistanceSlider.Value == 0 or distance < Options.DistanceSlider.Value)

        local objects = self._objects

        local box = objects._box
        local playerName = objects._playerName
        local healthBar = objects._healthBar
        local chams = objects._chams

        local rootViewPort, isRendered = CurrentCamera:worldToViewportPoint(targetRoot.Position)
        local headViewPort = CurrentCamera:worldToViewportPoint(targetHead.Position + Vector3.new(0, 1, 0))
        local legViewPort = CurrentCamera:worldToViewportPoint(targetRoot.Position - Vector3.new(0, 2.5, 0))

        local textSize = math.clamp(CurrentCamera.ViewportSize.X / rootViewPort.Z, 0, Options.TextSizeSlider.Value)

        local filter = Options.FilterDropDown.Value
        local filterPlayers = Options.PlayersDropDown:GetActiveValues()

        isRendered = filter == "Whitelist" and table.find(filterPlayers, target.Name) and isRendered
                        or filter == "Blacklist" and not table.find(filterPlayers, target.Name) and isRendered
                            or filter == "Off" and isRendered

        local Expection = self._expection

        if isRendered then
            local healthPrecentage = health / maxHealth

            healthBar.Color = Color3.new(
                healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.R > 0 and math.clamp(Options.HealthLowColor.Value.R * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.R > 0 and math.clamp(Options.HealthMediumColor.Value.R * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.R * healthPrecentage, 0, 1), 
                healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.G > 0 and math.clamp(Options.HealthLowColor.Value.G * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.G > 0 and math.clamp(Options.HealthMediumColor.Value.G * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.G * healthPrecentage, 0, 1), 
                healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.B > 0 and math.clamp(Options.HealthLowColor.Value.B * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.B > 0 and math.clamp(Options.HealthMediumColor.Value.B * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.B * healthPrecentage, 0, 1))
            
            box.Size = Vector2.new(CurrentCamera.ViewportSize.X / rootViewPort.Z, headViewPort.Y - legViewPort.Y)
            box.Position = Vector2.new(rootViewPort.X - box.Size.X / 2, (rootViewPort.Y - box.Size.Y / 2) + 2)
            box.Color = (Toggles.TeamColorsCheckBox.Value and target.TeamColor.Color) or Options.BoxColor.Value

            playerName.Size = textSize
            playerName.Position = box.Position + Vector2.new((box.Size.X - textSize + playerName.TextBounds.Y) / 2, (box.Size.Y - textSize + playerName.TextBounds.Y / 2) - textSize / 2)
       
            playerName.Color = (Toggles.TeamColorsCheckBox.Value and target.TeamColor.Color) or Options.NameColor.Value
            
            healthBar.Position = box.Position - Vector2.new(3, 0)
            healthBar.Size = Vector2.new(2, box.Size.Y / (maxHealth / health))
        end

        box.Visible = Toggles.BoxCheckBox.Value and isRendered and renderDistance
        playerName.Visible = Toggles.NameTagCheckBox.Value and isRendered and renderDistance
        healthBar.Visible = Toggles.HealthBarCheckBox.Value and isRendered and renderDistance
        chams.Enabled = Toggles.ChamsCheckBox.Value and isRendered and renderDistance
        
        chams.FillColor = Options.ChamsColor.Value
        chams.OutlineColor = Options.ChamsOutLineColor.Value

        chams.FillTransparency = Options.ChamsTransparency.Value / 100
        chams.OutlineTransparency = Options.ChamsOutLineTransparency.Value / 100

        if Expection then
            Expection:Refresh({
                isRendered = isRendered,
                textSize = textSize,
                renderDistance = renderDistance
            })
        end
    end
end

function PlayerEsp:Destroy()
    self._players[self._player] = nil
	
    task.wait()

    local objects = self._objects

    for _, object in pairs(objects) do
        object:Remove()
    end

    self._characterAdded:Disconnect()
	
    setmetatable(self, nil)
    table.clear(self)
end

return PlayerEsp
