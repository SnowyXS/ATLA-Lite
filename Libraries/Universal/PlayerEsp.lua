local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character
local rootPart = character.PrimaryPart

local CurrentCamera = workspace.CurrentCamera

local Esp = {
    players = {},
}
Esp.__index = Esp

function Esp.new(player)
    local objects = {}

    local self = setmetatable({
        objects = objects,
    }, Esp)

    local Expection = self.expection and self.expection.new(self)

    local character = player.Character

    local box = Drawing.new("Square")
    box.Filled = false
    box.Thickness = 2
    
    local playerName = Drawing.new("Text")
    playerName.Size = 18
    playerName.Text = player.Name
    playerName.Center = true
    playerName.Outline = true
    
    local healthBar = Drawing.new("Square")
    healthBar.Filled = false
    healthBar.Thickness = 1

    local chams = Instance.new("Highlight", CoreGui)
    chams.Adornee = character

    if Expection then
        Expection.player = player
        Expection.character = character

        Expection:Build()
    end
    
    local function OnCharacterAdded(character)
        chams.Adornee = character

        self.character = character
    end

    self.player = player
    self.character = character
    self.characterAdded = player.CharacterAdded:Connect(OnCharacterAdded)

    objects.box = box
    objects.playerName = playerName
    objects.healthBar = healthBar
    objects.chams = chams

    self.players[player] = self

    return self
end

function Esp:Refresh()
    local target = self.player
    local targetChar = self.character

    local objects = self.objects

    local box = objects.box
    local playerName = objects.playerName
    local healthBar = objects.healthBar
    local chams = objects.chams
    
    if targetChar then
        local targetHead = targetChar:FindFirstChild("Head")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = targetChar:FindFirstChild("Humanoid")
        
        if targetRoot and targetHead and targetHumanoid then
            local health = targetHumanoid.Health
            local maxHealth = targetHumanoid.MaxHealth
                
            local distance = rootPart and (rootPart.CFrame.p - targetRoot.CFrame.p).Magnitude or 0
            local renderDistance = (Options.DistanceSlider.Value == 0 or distance < Options.DistanceSlider.Value)
    
            local rootViewPort, isRendered = CurrentCamera:worldToViewportPoint(targetRoot.Position)
            local headViewPort = CurrentCamera:worldToViewportPoint(targetHead.Position + Vector3.new(0, 1, 0))
            local legViewPort = CurrentCamera:worldToViewportPoint(targetRoot.Position - Vector3.new(0, 2.5, 0))
    
            local textSize = math.clamp(CurrentCamera.ViewportSize.X / rootViewPort.Z, 0, Options.TextSizeSlider.Value)
    
            local filter = Options.FilterDropDown.Value
            local filterPlayers = Options.PlayersDropDown:GetActiveValues()
    
            isRendered = filter == "Whitelist" and table.find(filterPlayers, target.Name) and isRendered
                            or filter == "Blacklist" and not table.find(filterPlayers, target.Name) and isRendered
                                or filter == "Off" and isRendered
    
            local Expection = self.expection
    
            if isRendered then
                local healthPrecentage = health / maxHealth
    
                healthBar.Color = Color3.new(
                    healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.R > 0 and math.clamp(Options.HealthLowColor.Value.R * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.R > 0 and math.clamp(Options.HealthMediumColor.Value.R * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.R * healthPrecentage, 0, 1), 
                    healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.G > 0 and math.clamp(Options.HealthLowColor.Value.G * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.G > 0 and math.clamp(Options.HealthMediumColor.Value.G * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.G * healthPrecentage, 0, 1), 
                    healthPrecentage <= 0.25 and (Options.HealthLowColor.Value.B > 0 and math.clamp(Options.HealthLowColor.Value.B * healthPrecentage + 0.75, 0, 1) or 0) or healthPrecentage <= 0.5 and (Options.HealthMediumColor.Value.B > 0 and math.clamp(Options.HealthMediumColor.Value.B * healthPrecentage + 0.5, 0, 1) or 0) or math.clamp(Options.HealthColor.Value.B * healthPrecentage, 0, 1))
                
                box.Size = Vector2.new(CurrentCamera.ViewportSize.X / rootViewPort.Z, headViewPort.Y - legViewPort.Y)
                box.Position = Vector2.new(rootViewPort.X - box.Size.X / 2, (rootViewPort.Y - box.Size.Y / 2) + 2)
                box.Color = (self._customBoxColor ~= nil and self._customBoxColor) or (Toggles.TeamColorsCheckBox.Value and target.TeamColor.Color) or Options.BoxColor.Value
    
                playerName.Size = textSize
                playerName.Position = box.Position + Vector2.new((box.Size.X - textSize + playerName.TextBounds.Y) / 2, (box.Size.Y - textSize + playerName.TextBounds.Y / 2) - textSize / 2)
           
                playerName.Color = (self._customNameColor ~= nil and self._customNameColor) or (Toggles.TeamColorsCheckBox.Value and target.TeamColor.Color) or Options.NameColor.Value
                
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
        else
            box.Visible = false
            playerName.Visible = false
            healthBar.Visible = false
        end
    end
end

function Esp:Destroy()
    local objects = self.objects
    local players = self.players
    local player = self.player
    
    players[player] = nil
    
    for _, object in pairs(objects) do
        object:Remove()
    end
    
    self.characterAdded:Disconnect()

    setmetatable(self, nil)

    table.clear(self)
end

getgenv().Esp = Esp

return Esp
