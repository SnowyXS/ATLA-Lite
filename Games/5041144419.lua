local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local FovIndicator = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Universal/FOV/FovIndicator.lua"))()

return function(Window)
    local Camera = workspace.CurrentCamera

    local LocalPlayer = Players.LocalPlayer
    local PlayerScripts = LocalPlayer.PlayerScripts
    
    local SCP = Window:AddTab('SCP:RP')

    do -- Silent Aim
        local Controller = PlayerScripts.Controller
        
        local senv = getsenv(Controller)
        
        local SilentAimGroup = SCP:AddLeftGroupbox('Silent Aim')

        local SilentAimToggle = SilentAimGroup:AddToggle('SilentAimToggle', {
            Text = 'Enabled',
            Default = false,
            Tooltip = 'Makes you pro', 
        })
        
        local WallBangToggle = SilentAimGroup:AddToggle('WallBangToggle', {
            Text = 'WallBang',
            Default = false,
            Tooltip = 'Brings out your inner demon', 
        })

        local ShowTargetToggle = SilentAimGroup:AddToggle('ShowTargetToggle', {
            Text = 'Show Target',
            Default = false,
            Tooltip = 'Displays who the silent aim will target.', 
        })

        local FovSlider = SilentAimGroup:AddSlider('FovSlider', {
            Text = 'FOV',
            Default = 15,
            Min = 0,
            Max = 180,
            Rounding = 0,
            Compact = false,
        })

        local Circle = FovIndicator.new(false)

        do -- Setup's the FovCircle
            local teams = {
                {
                    "Mobile Task Force",
                    "Security Department",
                    "Intelligence Agency",
                    "Rapid Response Team",
                    "Internal Security Department",
                    "Scientific Department",
                    "Medical Department",
                    "Administrative Department"
                },
                {
                    "Class - D",
                    "Chaos Insurgency"
                }
            }
    
            function Circle.ExpectionCheck(target)
                local character = target.Character
                local head = character.Head

                local team = LocalPlayer.Team.Name
                local targetTeam = target.Team.Name
    
                local firstTeam, secondTeam = teams[1], teams[2]
                local isSameTeam = table.find(firstTeam, team) and table.find(firstTeam, targetTeam) and true
                                    or table.find(secondTeam, team) and table.find(secondTeam, targetTeam) and true

                return not isSameTeam 
                       or isSameTeam and head:FindFirstChild("Rogue")
                       or character:GetAttribute("Infection") 
                       or character:GetAttribute("409Infection")
            end

            local function UpdateFov(value)
                Circle:UpdateRadius(value)
            end

            FovSlider:OnChanged(UpdateFov)
        end

        local text = Drawing.new("Text")
        local line = Drawing.new("Line")

        RunService.RenderStepped:Connect(function(...)
            if ShowTargetToggle.Value and Circle:IsVisible() then
                local Target = Circle:GetClosestTarget()

                if Target then
                    local character = Target.Character
                    local head = character.Head
                    
                    local textWidth = text.TextBounds.X
                    local textHeight = text.TextBounds.Y

                    local viewPortWidth = Camera.ViewportSize.X 
                    local viewPortHeight = Camera.ViewportSize.Y

                    local headViewPort = Camera:worldToViewportPoint(head.Position)

                    text.Position = Vector2.new((viewPortWidth - textWidth + 9) / 2, viewPortHeight / 2)
                    text.Visible = true
                    text.Text = character.Name

                    line.From =  Vector2.new(viewPortWidth / 2, viewPortHeight / 2)
                    line.To = Vector2.new(headViewPort.X, headViewPort.Y)
                end

                line.Visible = Target ~= nil
                text.Visible = Target ~= nil
            end
        end)
        
        local OldEquipGun
        OldEquipGun = hookfunction(senv.EquipGun, function(...)
            local returnValues = OldEquipGun(...)
            Circle:SetPosition(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            Circle:SetVisibility(true)

            return returnValues
        end)

        local OldUnEquipGun
        OldUnEquipGun = hookfunction(senv.UnequipGun, function(...)
            local returnValues = OldUnEquipGun(...)
            Circle:SetVisibility(false)
            
            line.Visible = false
            text.Visible = false

            return returnValues
        end)

        local OldFunction
        OldFunction = hookfunction(senv.BulletHit, function(...)
            local args = {...}

            if args[4].Name == "Bullet" and SilentAimToggle.Value then
                local Target = Circle:GetClosestTarget()

                if Target then
                    local targetChar = Target.Character

                    local head = targetChar.Head
                    local headPos = head.Position

                    local oldCastInfo = args[1]
                    local rayOrigin = WallBangToggle.Value and headPos + Vector3.new(0, 1, 0) or Camera.CFrame.p
                    local rayDestination = headPos
                    local rayDirection = rayDestination - rayOrigin
                    local parameters = oldCastInfo.RayInfo.Parameters

                    args[2] = workspace:Raycast(rayOrigin, rayDirection, parameters)
                end
            end

            return OldFunction(unpack(args))
        end)
    end
end