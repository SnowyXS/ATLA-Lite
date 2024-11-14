local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local FovCircle = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Universal/FovCircle.lua"))()

return function(Window)
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
        
        local FovSlider = SilentAimGroup:AddSlider('FovSlider', {
            Text = 'FOV',
            Default = 15,
            Min = 0,
            Max = 180,
            Rounding = 0,
            Compact = false,
        })

        local Circle = FovCircle.new()

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
                }
                {
                    "Class - D",
                    "Chaos Insurgency"
                }
            }
    
            function Circle.ExpectionCheck(target)
                local character = target.Character
    
                local team = LocalPlayer.Team.Name
                local targetTeam = target.Team.Name
    
                local firstTeam, secondTeam = teams[1], teams[2]

                return table.find(firstTeam, team) and table.find(firstTeam, targetTeam) 
                       or table.find(secondTeam, team) and table.find(secondTeam, targetTeam) 
            end

            local function UpdateFov(value)
                Circle:UpdateRadius(value)
            end

            FovSlider:OnChanged(UpdateFov)

            local OldEquipGun
            OldEquipGun = hookfunction(senv.EquipGun, function(...)
                local returnValues = OldEquipGun(...)
                Circle:SetPosition(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                Circle:SetVisibility(true)

                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                return returnValues
            end)

            local OldUnEquipGun
            OldUnEquipGun = hookfunction(senv.UnequipGun, function(...)
                local returnValues = OldUnEquipGun(...)
                Circle:SetVisibility(false)

                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                return returnValues
            end)
        end

        local OldFunction
        OldFunction = hookfunction(senv.BulletHit, function(...)
            local args = {...}

            if args[4].Name == "Bullet" and SilentAimToggle.Value then
                local Target = Circle:GetClosestTarget()

                if Target then
                    local targetChar = Target.Character

                    if targetChar:FindFirstChild("Head") then
                        local oldCastInfo = args[1]

                        local rayOrigin = WallBangToggle.Value and targetChar.Head.Position + Vector3.new(0, 1, 0) or Camera.CFrame.p
                        local rayDestination = targetChar.Head.Position

                        local rayDirection = rayDestination - rayOrigin

                        local parameters = oldCastInfo.RayInfo.Parameters

                        args[2] = workspace:Raycast(rayOrigin, rayDirection, parameters)
                    end
                end
            end

            return OldFunction(unpack(args))
        end)
    end
end