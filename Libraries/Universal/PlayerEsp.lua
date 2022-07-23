
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character
local rootPart = character.PrimaryPart

getgenv().PlayerEsp = {
    _players = {},
}

PlayerEsp.__index = PlayerEsp

function PlayerEsp.new(player)
    local objects = {}

    local self = setmetatable({
        _objects = objects
    }, PlayerEsp)

    local expection = self._expection

    local box = Drawing.new("Square")
    box.Color = Options.BoxColor.Value
    box.Filled = false
    box.Thickness = 1
    
    local playerName = Drawing.new("Text")
    playerName.Color = Options.NameColor.Value
    playerName.Size = 18
    playerName.Text = player.Name
    playerName.Center = true

    local healthBar = Drawing.new("Square")
    healthBar.Color = Options.HealthColor.Value
    healthBar.Filled = false
    healthBar.Thickness = 1

    local chams = Instance.new("Highlight", player.Character)
    chams.Enabled = false

    if expection then
        expection:Build()
    end
    
    local function OnCharacterAdded(character)
        self._character = character
    end

    self._player = player
    self._character = player.Character
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
        local renderDistance = (Options.distanceSlider.Value == 0 or distance < Options.distanceSlider.Value)

        local objects = self._objects

        local box = objects._box
        local playerName = objects._playerName
        local healthBar = objects._healthBar
        local chams = objects._chams

        local rootViewPort, isRendered = CurrentCamera:worldToViewportPoint(targetRoot.Position)
        local headViewPort = CurrentCamera:worldToViewportPoint(targetHead.Position + Vector3.new(0, 1, 0))
        local legViewPort = CurrentCamera:worldToViewportPoint(targetRoot.Position - Vector3.new(0, 2.5, 0))

        local textSize = math.clamp(CurrentCamera.ViewportSize.X / rootViewPort.Z, 0, Options.textSizeSlider.Value)

        local filter = Options.FilterDropDown.Value
        local filterPlayers = Options.PlayersDropDown:GetActiveValues()

        isRendered = filter == "Whitelist" and table.find(filterPlayers, target.Name) and isRendered
                        or filter == "Blacklist" and not table.find(filterPlayers, target.Name) and isRendered
                            or filter == "Off" and isRendered

        local expection = self._expection

        if isRendered then
            local healthPrecentage = health / maxHealth

            healthBar.Color = Color3.new(
                healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.R > 0 and math.clamp(Options.HealthLowColor.Value.R * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.R > 0 and math.clamp(Options.HealthMediumColor.Value.R * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.R * healthPrecentage, 0, 1), 
                healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.G > 0 and math.clamp(Options.HealthLowColor.Value.G * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.G > 0 and math.clamp(Options.HealthMediumColor.Value.G * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.G * healthPrecentage, 0, 1), 
                healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.B > 0 and math.clamp(Options.HealthLowColor.Value.B * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.B > 0 and math.clamp(Options.HealthMediumColor.Value.B * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.B * healthPrecentage, 0, 1))
            
            box.Size = Vector2.new(CurrentCamera.ViewportSize.X / rootViewPort.Z, headViewPort.Y - legViewPort.Y)
            box.Position = Vector2.new(rootViewPort.X - box.Size.X / 2, (rootViewPort.Y - box.Size.Y / 2) + 2)
            box.Color = (Toggles.teamColorsCheckBox.Value and target.TeamColor.Color) or Options.BoxColor.Value


            playerName.Size = textSize
            playerName.Position = box.Position + Vector2.new((box.Size.X - textSize + playerName.TextBounds.Y) / 2, (box.Size.Y - textSize + playerName.TextBounds.Y / 2) - textSize / 2)
       
            playerName.Color = (Toggles.teamColorsCheckBox.Value and target.TeamColor.Color) or Options.NameColor.Value
            
            healthBar.Position = box.Position - Vector2.new(3, 0)
            healthBar.Size = Vector2.new(2, (headViewPort.Y - legViewPort.Y) / (maxHealth / math.clamp(health, 0, maxHealth)))
        end

        box.Visible = Toggles.boxCheckBox.Value and isRendered and renderDistance
        playerName.Visible = Toggles.nameTagCheckBox.Value and isRendered and renderDistance
        healthBar.Visible = Toggles.healthBarCheckBox.Value and isRendered and renderDistance
        chams.Visible = Toggles.chamsCheckBox.Value and renderDistance

        if expection then
            expection:Refresh()
        end
    end
end

function PlayerEsp:Destroy()
    self._players[self._player] = nil

    self._characterAdded:Disconnect()

    self._box:Remove()
    self._playerName:Remove()
    self._healthBar:Remove()

    setmetatable(self, nil)
    table.clear(self)
end

return PlayerEsp
