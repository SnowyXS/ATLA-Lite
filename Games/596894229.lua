return function(Window)
    local PropertyChanged = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Dependencies/PropertyChanged.lua"))()

    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")

    local CurrentCamera = workspace.CurrentCamera 

    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character

    local humanoid = Character.Humanoid
    local humanoidRootPart = Character.PrimaryPart

    local networkStats = Stats.Network
    local serverStatsItem = networkStats.ServerStatsItem

    local dataPing = serverStatsItem["Data Ping"]

    local mainMenu = LocalPlayer.PlayerGui:WaitForChild("MainMenu")
    local menuControlInstance = mainMenu:WaitForChild("MenuControl")

    local MenuControl = getsenv(menuControlInstance)
    local BaseSelection, ValueNames, StaminaConnection

    local count = 1
        
    local loadingSquare = Drawing.new("Square")
    loadingSquare.Visible = true
    loadingSquare.Filled = true
    loadingSquare.Color = Color3.fromRGB(25, 25, 25)
    loadingSquare.Size = Vector2.new(CurrentCamera.ViewportSize.X / 8, CurrentCamera.ViewportSize.Y / 17)
    loadingSquare.ZIndex = 1
    loadingSquare.Position = Vector2.new(0.5 * CurrentCamera.ViewportSize.X - loadingSquare.Size.X / 2, 0.5 * CurrentCamera.ViewportSize.Y - loadingSquare.Size.Y / 2)

    local brandText = Drawing.new("Text")
    brandText.Visible = true
    brandText.Size = 32
    brandText.ZIndex = 2
    brandText.Color = Color3.fromRGB(255, 255, 255)
    brandText.Text = "SLite"
    brandText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - brandText.TextBounds.X / 2, 0)

    local loadingText = Drawing.new("Text")
    loadingText.Visible = true
    loadingText.Size = 32
    loadingText.ZIndex = 2
    loadingText.Color = Color3.fromRGB(255, 0, 0)
    loadingText.Text = "Waiting for modules."
    loadingText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - loadingText.TextBounds.X / 2, loadingSquare.Size.Y - 32)

    while not (MenuControl.DecreaseStamina and LocalPlayer:FindFirstChild("PlayerData")) and task.wait(0.25) do
        loadingText.Color = Color3.fromRGB(255, 0, 0)
        loadingText.Text = ((not LocalPlayer:FindFirstChild("PlayerData") and "Waiting for modules") or (not ATLA and "Waiting for SLite module") or "") .. string.rep(".", count) 

        loadingSquare.Position = Vector2.new(0.5 * CurrentCamera.ViewportSize.X - loadingSquare.Size.X / 2, 0.5 * CurrentCamera.ViewportSize.Y - loadingSquare.Size.Y / 2)
        brandText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - brandText.TextBounds.X / 2, 0)
        loadingText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - loadingText.TextBounds.X / 2, loadingSquare.Size.Y - 32)

        count = count < 3 and count + 1 or 1
    end

    loadingText.Color = Color3.fromRGB(0, 255, 0)
    loadingText.Text = "Loaded."
    loadingText.Position = loadingSquare.Position + Vector2.new(loadingSquare.Size.X / 2 - loadingText.TextBounds.X / 2, loadingSquare.Size.Y - 32)
        
    task.wait(0.5)

    loadingSquare:Remove()
    brandText:Remove()
    loadingText:Remove()

    local playerData = LocalPlayer:WaitForChild("PlayerData")

    for _, v in pairs(getgc(true)) do
        if typeof(v) == "table" then
            if rawget(v, "Elements") then
                BaseSelection = v
            elseif rawget(v, "Money4") then
                ValueNames = v.ValueNames
            end
        elseif BaseSelection and ValueNames then
            break
        end
    end

    for _, v in pairs(getconnections(playerData.Stats.Stamina.Changed)) do
        if v.Function then
            local upvalues = getupvalues(v.Function)

            if typeof(upvalues[3]) == "number" then
                StaminaConnection = v
                break
            end
        end
    end

    local gameEvent, gameFunction = MenuControl.GameEvent, MenuControl.GameFunction

    local Quests = MenuControl.QuestModule
    local RefreshNPCs = Quests.RefreshNPCs

    local NpcList = debug.getupvalue(RefreshNPCs, 3)
    local NpcModel = MenuControl.QuestNPCs

    local formattedQuests = {}

    for _, v in pairs(NpcList) do
        table.insert(formattedQuests, v[1])
    end

    local specialElements = {
        Air = {"Flight"},
        Water = {"Ice", "Plant"},
        Fire = {"Lightning", "Combustion"},
        Earth = {"Lava", "Metal", "Sand"}
    }

    local secondSpecialElements = {
        Ice = {"None", "Healing"},
        Plant = {"None", "Healing"},
        Lava = {"None", "Vibration Sense"},
        Metal = {"None", "Vibration Sense"},
        Sand = {"None", "Vibration Sense"},
    }

    local atlaTab = Window:AddTab("Elemental Adventure")

    do -- AutoFarm
        local questIndex = 1
        local autoFarmBox = atlaTab:AddLeftGroupbox("Auto-Farm")

        local autoFarmToggle = autoFarmBox:AddToggle("AutoFarmToggle", {
            Text = "Enable",
            Default = false,
            Tooltip = "Enables AutoFarm",
        })

        local questsDropDown = autoFarmBox:AddDropdown("Quests", {
            Values = formattedQuests,
            Default = 1,
            Multi = true,
            
            Text = "Quests",
            Tooltip = "Select Quests",
        })

        local function LockToNPC(npc)
            humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            
            local teleportCoroutine = coroutine.create(function()
                while autoFarmToggle.Value and canCompleteQuest and (getupvalue(MenuControl.SpawnCharacter, 2) == 2 or getupvalue(MenuControl.SpawnCharacter, 2) == 1) and humanoidRootPart do
                    humanoidRootPart.CFrame = npc.PrimaryPart.CFrame * CFrame.new(0,-8.25,0) * CFrame.Angles(math.rad(90), 0, 0)

                    task.wait() 
                end
            end)
        
            humanoidRootPart.CFrame = npc.PrimaryPart.CFrame
        
            return coroutine.resume(teleportCoroutine)
        end

        local function GetNpcByQuest(quest)
            for NPCName, v in pairs(NpcList) do
                if table.find(v, quest) then
                    return NpcModel:FindFirstChild(NPCName)
                end
            end
        end

        local function GetQuest() 
            local selectedQuests = questsDropDown:GetActiveValues() 
            local currentQuest = selectedQuests[questIndex]
            
            questIndex = questIndex + 1

            if questIndex > #selectedQuests then
                questIndex = 1
            end

            return currentQuest
        end

        local function CanFarm()
            local isContinuable = playerData.PlayerSettings.Continuable.Value
            local isTransitioning = MenuControl.Transitioning
            local menuStatus = getupvalue(MenuControl.SpawnCharacter, 2)

            return humanoid.Health > 0 and humanoid.WalkSpeed > 0
                    and not Character:FindFirstChild("Down") 
                    and not (humanoidRootPart:FindFirstChild("DownTimer") and humanoidRootPart.DownTimer.TextLabel.Text ~= "") 
                    and menuStatus == 2 
                    and isContinuable
                    and not isTransitioning
        end

        local function AdvanceStep(quest, step)
            if CanFarm() and autoFarmToggle.Value then
                gameFunction:InvokeServer("AdvanceStep", {
                    QuestName = quest,
                    Step = step
                })            
            end
        end

        autoFarmToggle:OnChanged(function()
            if autoFarmToggle.Value then
                while autoFarmToggle.Value and task.wait() do
                    local quest = GetQuest()
                    local npc = GetNpcByQuest(quest)

                    canCompleteQuest = npc and CanFarm() and not canCompleteQuest
                
                    if canCompleteQuest then
                        LockToNPC(npc)

                        task.wait(math.clamp(dataPing:GetValue() / 1000, 5.05, math.huge))

                        local AdvanceStepCoroutine

                        for step = 1, #Quests[quest].Steps + 1 do 
                            if not CanFarm() or not autoFarmToggle.Value or (npc.PrimaryPart.CFrame.p - humanoidRootPart.CFrame.p).Magnitude > 15 then
                                break
                            end
                            
                            AdvanceStepCoroutine = coroutine.create(AdvanceStep)

                            coroutine.resume(AdvanceStepCoroutine, quest, step)
                        end 
                        
                        if AdvanceStepCoroutine then
                            repeat
                                task.wait()
                            until coroutine.status(AdvanceStepCoroutine) == "dead"
                        end

                        task.wait(0.5)

                        canCompleteQuest = false
                    end
                end
            end
            
            questIndex = 1
        end)
    end

    do -- Sub changer
        local subChangerBox = atlaTab:AddLeftGroupbox("Sub-Changer")

        local subChangerToggle = subChangerBox:AddToggle("subChangerToggle", {
            Text = "Enable",
            Default = false,
            Tooltip = "Enables Sub-Changer.",
        })

        local elementsDropDown = subChangerBox:AddDropdown("elements", {
            Values = {"Air", "Water", "Fire", "Earth"},
            Default = 1, 
            Multi = false,
            
            Text = "Element",
            Tooltip = "Select element.",
        })

        local specialDropDown = subChangerBox:AddDropdown("special", {
            Values = {"Flight"},
            Default = 1,
            Multi = false,
            
            Text = "Special",
            Tooltip = "Select special element",
        })

        local secondSpecialDropDown = subChangerBox:AddDropdown("special2", {
            Values = {"None"},
            Default = 1,
            Multi = false,
            
            Text = "Second Special",
            Tooltip = "Select second special element.",
        })

        elementsDropDown:OnChanged(function()
            local specialElements = specialElements[elementsDropDown.Value]

            specialDropDown.Values = specialElements
            specialDropDown:SetValues()
            specialDropDown:SetValue(specialElements[1])

            local secondSpecialElements = secondSpecialElements[specialDropDown.Value] or {"None"}

            secondSpecialDropDown.Values = secondSpecialElements
            secondSpecialDropDown:SetValues()
            secondSpecialDropDown:SetValue(secondSpecialElements[1])
        end)
        
        specialDropDown:OnChanged(function()
            local secondSpecialElements = secondSpecialElements[specialDropDown.Value] or {"None"}

            secondSpecialDropDown.Values = secondSpecialElements
            secondSpecialDropDown:SetValues()
            secondSpecialDropDown:SetValue(secondSpecialElements[1])
        end)

        subChangerToggle:OnChanged(function()
            if subChangerToggle.Value then
                humanoid.Health = 0
            end
        end)    

        LocalPlayer.CharacterAdded:Connect(function(character)
            if subChangerToggle.Value then
                local appearance = playerData.Appearance
        
                local specialAbility = appearance.Special
                local secondSpecialAbility = appearance.Special2
            
                local selectedSpecial = specialDropDown.Value
                local selectedSecondSpecial = secondSpecialDropDown.Value
                
                BaseSelection.Elements = elementsDropDown.Value
            
                print("\n--- Element changer ---",
                    "\nElement: " .. elementsDropDown.Value, 
                    "\n\nCurrent Special: " .. specialAbility.Value, 
                    "\n -> Waiting For: " ..  selectedSpecial, 
                    "\n -> hasGotSpecial: " ..  tostring(specialAbility.Value == selectedSpecial), 
                    "\n\nCurrent Second Special: " .. secondSpecialAbility.Value, 
                    "\n -> Waiting For: " ..  selectedSecondSpecial, 
                    "\n -> hasGotSecondSpecial: " .. tostring(secondSpecialAbility.Value == selectedSecondSpecial))
            
                local shouldContinue = ((specialAbility.Value ~= selectedSpecial 
                                        or secondSpecialAbility.Value ~= selectedSecondSpecial) and gameFunction:InvokeServer("NewGame", {Selections = BaseSelection}) and true) 
                                        or (specialAbility.Value == selectedSpecial and secondSpecialAbility.Value == selectedSecondSpecial and false) 

                if shouldContinue then
                    local humanoid = character:WaitForChild("Humanoid")
        
                    if subChangerToggle.Value then
                        humanoid.Health = 0
        
                        return
                    end
                end
        
                subChangerToggle:SetValue(false)
            end
        end)
    end

    do -- Modifiers
        local modifiersBox = atlaTab:AddRightGroupbox("Modifiers")

        local staminaToggle = modifiersBox:AddToggle("StaminaToggle", {
            Text = "Disable Stamina",
            Default = false,
            Tooltip = "Disables Stamina",
        })

        local maxStaminaSlider = modifiersBox:AddSlider("MaxStamina", {
            Text = "Max Stamina",

            Default = playerData.Stats.Stamina.Value + 25,
            Min = 25,
            Max = 425,
            Rounding = 1,
        
            Compact = false,
        })

        local walkSpeedSlider = modifiersBox:AddSlider("WalkSpeed", {
            Text = "WalkSpeed",

            Default = 16,
            Min = 16,
            Max = 1000,
            Rounding = 1,
        
            Compact = false,
        })

        local jumpPowerSlider = modifiersBox:AddSlider("JumpPower", {
            Text = "JumpPower",

            Default = 50,
            Min = 50,
            Max = 1000,
            Rounding = 1,
        
            Compact = false,
        })

        local sprintSpeedSlider = modifiersBox:AddSlider("SprintSpeed", {
            Text = "Sprint Speed",

            Default = playerData.Stats.Stamina.Value + 25,
            Min = 25,
            Max = 425,
            Rounding = 1,
        
            Compact = false,
        })

        maxStaminaSlider:OnChanged(function()
            local value = maxStaminaSlider.Value

            setupvalue(MenuControl.CurrentStamina, 1, value)
        
            StaminaConnection:Fire(value - 25)
        end)

        walkSpeedSlider:OnChanged(function()
            humanoid.WalkSpeed = walkSpeedSlider.Value
        end)

        jumpPowerSlider:OnChanged(function()
            humanoid.JumpPower = jumpPowerSlider.Value
        end)

        local OldFunc
        OldFunc = hookfunc(MenuControl.DecreaseStamina, function(...)
            if canCompleteQuest or staminaToggle.Value then
                return
            end

            return OldFunc(...)
        end)

        local OldNewIndex
        OldNewIndex = hookmetamethod(game, "__newindex", function(self, index, value)
            if not checkcaller() then
                if index == "WalkSpeed" then
                    if value == 25 and sprintSpeedSlider.Value > 25 then
                        return OldNewIndex(self, index, sprintSpeedSlider.Value) 
                    elseif walkSpeedSlider.Value > 16 then
                        return OldNewIndex(self, index, walkSpeedSlider.Value) 
                    end
                elseif index == "JumpPower" then
                    return OldNewIndex(self, index, jumpPowerSlider.Value) 
                end
            end
            
            return OldNewIndex(self, index, value)
        end)
    end

    do -- Teleport
        local teleportsBox = atlaTab:AddLeftGroupbox("Teleports")
        local presets = {
            ["Western Air Temple"] = CFrame.new(7945, 183, -2050),
            ["Southern Air Temple"] = CFrame.new(1706, 396, -2256),
            ["Air Temple Shop"] = CFrame.new(1634, 457, -2370),
            ["Air Temple Vehicle Shop"] = CFrame.new(1892, 263, -2113),
            ["Northern Water Tribe"] = CFrame.new(9007, 109, 788),
            ["Southern Water Tribe"] = CFrame.new(49, 11, 480),
            ["Water Weapon Shop"] = CFrame.new(8790, 61, 957),
            ["Water Vehicle Shop"] = CFrame.new(7972, 8, 763),
            ["Inner Walls"] = CFrame.new(5915, 8, 5052),
            ["Outer Walls"] = CFrame.new(5910, 8, 4337),
            ["Earth Weapon Shop"] = CFrame.new(5636, 8, 5113),
            ["Earth Vehicle Shop"] = CFrame.new(5865, 8, 4369),
            ["Roku's Temple"] = CFrame.new(6154, 128, 199),
            ["CalderaCity"] = CFrame.new(6375, 162, -6483),
            ["Royal Plaza"] = CFrame.new(5509, 21, -3910),
            ["Fire Weapon Shop"] = CFrame.new(6201, 161, -5862),
            ["Fire Vehicle Shop"] = CFrame.new(5832, 14, 467),
            ["Kyoshi"] = CFrame.new(1795, 11, 2263),
            ["Kyoshi Shop"] = CFrame.new(1813, 11, 2199),
            ["Desert"] = CFrame.new(3512, 8, 3956),
            ["The Swamp"] = CFrame.new(3706, 7, 2744),
            ["White Lotus"] = CFrame.new(3408, 7, 4026),
            ["Red Lotus"] = CFrame.new(898, 236, -3075),
            ["Acrobats NPC"] = CFrame.new(5516, 27, -4497),
            ["Chi NPC"] = CFrame.new(-57, 12, 475)
        }

        local formattedPresets = {}

        for i, _ in pairs(presets) do
            table.insert(formattedPresets, i)
        end

        local teleportsDropDown = teleportsBox:AddDropdown("Presets", {
            Values = formattedPresets,
            Default = 1,
            Multi = false,
            
            Text = "Presets",
            Tooltip = "Select teleport place.",
        })

        local teleportButton = teleportsBox:AddButton("Teleport", function()
            humanoidRootPart.CFrame = presets[teleportsDropDown.Value]
        end)
    end

    do -- Players
        local playersBox = atlaTab:AddRightGroupbox("Players")
        local players = {}
        
        for _, v in pairs(Players:GetPlayers()) do
            table.insert(players, v.Name)
        end

        local playersDropDown = playersBox:AddDropdown("Players", {
            Values = players,
            Default = 1,
            Multi = false,
            
            Text = "List",
            Tooltip = "Select a player.",
        })

        local teleportButton = playersBox:AddButton("Teleport", function()
            local target = Players[playersDropDown.Value]

            humanoidRootPart.CFrame = target.Character.PrimaryPart.CFrame
        end)

        Players.PlayerAdded:Connect(function(player)
            players = {}

            for _, v in pairs(Players:GetPlayers()) do
                table.insert(players, v.Name)
            end
        
            playersDropDown.Values = players
            playersDropDown:SetValues()
        end)

        Players.PlayerRemoving:Connect(function(player)
            players = {}

            for _, v in pairs(Players:GetPlayers()) do
                table.insert(players, v.Name)
            end
        
            playersDropDown.Values = players
            playersDropDown:SetValues()
            
            if playersDropDown.Value == player.Name then
                playersDropDown:SetValue(players[1])
            end 
        end)
    end

    do -- Misc
        local miscBox = atlaTab:AddRightGroupbox("Misc")

        local flightToggle = miscBox:AddToggle("FlightToggle", {
            Text = "Enable Flight",
            Default = false,
            Tooltip = "Enables Air flight.",
        }):AddKeyPicker('KeyPicker', {
            Default = 'F',
            SyncToggleState = true, 
        
            Mode = 'Toggle',
        
            Text = 'Enables flight',
            NoUI = false,
        })

        local flightSlider = miscBox:AddSlider("flightSlider", {
            Text = "Flight Speed",

            Default = 5,
            Min = 5,
            Max = 1000,
            Rounding = 1,
        
            Compact = false,
        })

        flightToggle:OnChanged(function()
            local startFlying = MenuControl.startRealFlying

            setupvalue(startFlying, 3, flightToggle.Value)
            setupvalue(startFlying, 4, flightToggle.Value)
        
            if flightToggle.Value then
                startFlying(Character, 0)
            end
        end)

        flightSlider:OnChanged(function()
            setconstant(MenuControl.startRealFlying, 66, flightSlider.Value)
        end)
    end

    do -- esp 
        local expection = {}
        expection.__index = expection
        
        function expection.new(self)
            local expection = setmetatable({
                _objects = self._objects,
            }, expection)
            
            self._expection = expection

            return expection
        end
        
        function expection:Build()
            local objects = self._objects 

            local level = Drawing.new("Text")
            level.Text = "level: unknown"
            level.Size = 18
            level.Color = Color3.new(1, 1, 1)
            level.Center = true

            objects._level = level
        end

        function expection:Refresh(args)
            local target = self._player
            local objects = self._objects 

            local box = objects._box
            local level = objects._level

            local isRendered = args.isRendered
            local textSize = args.textSize
            local renderDistance = args.renderDistance

            if isRendered then
                level.Size = textSize

                level.Position = box.Position + Vector2.new((box.Size.X + textSize / 2 + level.TextBounds.X / 2 - 2), (box.Size.Y - textSize + level.TextBounds.Y / 1.5))
                
                level.Color = Options.LevelColor.Value

                level.Text = "Level: " .. (target:FindFirstChild("PlayerData") and target.PlayerData.Stats.Level.Value or "unknown")
            end

            level.Visible = Toggles.LevelCheckBox.Value and isRendered and renderDistance
        end

        function expection.CreateUI(tab)
            local elementalGroup = tab:AddLeftGroupbox("Elemental Adventure")

            elementalGroup:AddToggle("LevelCheckBox", {
                Text = "Level",
                Default = false,
                Tooltip = "Displays the level.",
            }):AddColorPicker('LevelColor', {
                Default = Color3.new(1, 1, 1), 
                Title = 'Text Color', 
            })
        end

        PlayerEsp._expection = expection
    end

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        Character = newCharacter

        humanoid = Character:WaitForChild("Humanoid")
        humanoidRootPart = Character.PrimaryPart

        humanoid.WalkSpeed = Options.WalkSpeed.Value
        humanoid.JumpPower = Options.JumpPower.Value

        local mainMenu = LocalPlayer.PlayerGui:WaitForChild("MainMenu")
        local menuControlInstance = mainMenu:WaitForChild("MenuControl")

        local MenuControlEnv = getsenv(menuControlInstance)

        repeat task.wait() until MenuControlEnv.DecreaseStamina

        MenuControl = MenuControlEnv

        for _, v in pairs(getconnections(playerData.Stats.Stamina.Changed)) do
            if v.Function then
                local upvalues = getupvalues(v.Function)

                if typeof(upvalues[3]) == "number" then
                    StaminaConnection = v
                    break
                end
            end
        end

        local OldFunc
        OldFunc = hookfunc(MenuControl.DecreaseStamina, function(...)
            if canCompleteQuest or Toggles.StaminaToggle.Value then
                return
            end

            return OldFunc(...)
        end)

        if Toggles.AutoFarmToggle.Value then
            local continueable = playerData.PlayerSettings.Continuable.Value
            local menuStatus = getupvalue(MenuControl.SpawnCharacter, 2)
        
            if continueable and menuStatus < 2 then
                MenuControl.MainFrame:TweenPosition(UDim2.new(0.5, -150, 1.5, -150), "Out", "Quad", 1, true)
                MenuControl.SpawnFrame:TweenPosition(UDim2.new(2, -10, 1, -10), "Out", "Quad", 2, true)
        
                MenuControl.MainFrame.Visible = false
                MenuControl.SpawnFrame.Visible = false
                
                MenuControl.SpawnCharacter()  
            end
        end
    end)
end
