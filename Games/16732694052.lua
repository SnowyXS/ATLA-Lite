
local version = "v1.04"

local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerEvents = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/refs/heads/main/Libraries/Fisch/ServerEvents.lua"))()
local RodController = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/refs/heads/main/Libraries/Fisch/RodController.lua"))()

return function(Window)
    Library:Notify(`Loaded Fisch - {version}`, 5)

    local ServerEvent = ServerEvents.new()
    local Rod = RodController.new()

    local link = ReplicatedStorage:WaitForChild("Link")

    local events = link:WaitForChild("events")
    local modules = link:WaitForChild("modules")

    local CharacterModule = require(modules.character)

    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer.PlayerGui
    local backpack = LocalPlayer.Backpack

    local character = LocalPlayer.Character
    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid

    local camera = workspace.Camera
    local world = workspace.world

    local spawns = world.spawns

    local rand = Random.new()
    
    local locations = {}
    local dropDownLocations = {}
    
    for i, v in pairs(spawns.TpSpots:GetChildren()) do
        local location = v.Name

        locations[location] = v.CFrame
        table.insert(dropDownLocations, location) 
    end

    local function RandomNumber(min, max)
        return math.round(rand.NextNumber(rand, min, max))
    end    

    local fischTab = Window:AddTab("Fisch")
    
    do -- Auto Fish
        local autoTabbox = fischTab:AddLeftTabbox()

        do -- Cast
            local castTab = autoTabbox:AddTab("Cast")

            local autoCastToggle = castTab:AddToggle("AutoCastToggle", {
                Text = "Auto-Cast",
                Default = false,
                Tooltip = "Will automatically cast the bobber.",
            })
            
            local perfectSlider = castTab:AddSlider("CastPerfectSlider", {
                Text = "Perfect Chance",
                Default = 60,
                Min = 1,
                Suffix = "%",
                Max = 100,
                Rounding = 0,
                Compact = false,
            })

            local castType = castTab:AddDropdown("CastTypeDropDown", {
                Values = {"Skip", "Normal"},
                Default = 1,
                Multi = false,
            
                Text = "Type",
                Tooltip = "Skip will cast the bobber without the minigame.\nNormal will cast the bobber normally with the minigame.",
            })

            local percentage

            local function IsPerfect()
                local chance = RandomNumber(1, 100)

                return chance <= perfectSlider.Value
            end

            local OldNamecall
            OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if not checkcaller() and method == "FireServer" then
                    if Rod:IsEquipped() and autoCastToggle.Value and self.Name == "reset" then
                        local returnValue = OldNamecall(self, ...)
                        local isSkip = castType.Value == "Skip"
                        percentage = IsPerfect() and 100 or RandomNumber(82, 90)

                        setthreadidentity(3)
                        Rod:Cast(isSkip, percentage)
                        setthreadidentity(2)

                        return returnValue
                    end
                end
        
                return OldNamecall(self, ...)
            end)

            local function OnRootPartChildAdded(instance)
                if autoCastToggle.Value and castType.Value == "Skip" or instance.Name ~= "power" then return end

                local powerbar = instance:WaitForChild("powerbar")
                local bar = powerbar.bar

                local connection
                connection = bar:GetPropertyChangedSignal("Size"):Connect(function()
                    if not percentage then return end
                    local scale = percentage / 100

                    if (scale == 1 and bar.Size.Y.Scale == scale) or (scale < 1 and bar.Size.Y.Scale / scale >= 0.94) then
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        connection:Disconnect()
                    end
                end)
            end

            local function OnCharacterAdded(newCharacter)
                local humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
                backpack = LocalPlayer.Backpack
                humanoidRootPart.ChildAdded:Connect(OnRootPartChildAdded)
            end

            humanoidRootPart.ChildAdded:Connect(OnRootPartChildAdded)
            LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

            autoCastToggle:OnChanged(function(value)
                if not Rod:IsEquipped() or not value then return end 
                local isSkip = castType.Value == "Skip"
                percentage = IsPerfect() and 100 or RandomNumber(82, 90)

                Rod:Cast(isSkip, percentage)
            end)
        end

        do -- Shake
            local shakeTab = autoTabbox:AddTab("Shake")

            local autoShakeToggle = shakeTab:AddToggle("AutoShakeToggle", {
                Text = "Auto-Shake",
                Default = false,
                Tooltip = "Will automatically pass the shake minigame perfectly.",
            })

            local minDelaySlider = shakeTab:AddSlider("ShakeMinSlider", {
                Text = "Minimum Delay",
                Default = 0.2,
                Min = 0,
                Suffix = "s",
                Max = 1,
                Rounding = 1,
                Compact = false,
            })

            local maxDelaySlider = shakeTab:AddSlider("ShakeMaxSlider", {
                Text = "Maximum Delay",
                Default = 0.5,
                Min = 0,
                Suffix = "s",
                Max = 1,
                Rounding = 1,
                Compact = false,
            })
            
            local shakeType = shakeTab:AddDropdown("ShakeTypeDropDown", {
                Values = {"Navigation", "Mouse"},
                Default = 1,
                Multi = false,
            
                Text = "Type",
                Tooltip = "Mouse Click will use VirtualInputManager to click the Shake.\nNavigation will use UI Navigation to press the Shake.",
            })

            local function UIPressButton(button)
                button.Active = true
                button.Selectable = true

                GuiService.SelectedObject = button

                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end

            local function MousePressButton(button)
                local x = button.AbsolutePosition.X + (button.AbsoluteSize.X / 2)
                local y = button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2)

                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            end

            local function OnToggle(bool)
                if not bool then return end

                local shakeui = PlayerGui:FindFirstChild("shakeui")
                if not shakeui then return end

                local safezone = shakeui.safezone
                local button = safezone.button

                if shakeType.Value == "Mouse" then
                    MousePressButton(button)
                else
                    UIPressButton(button)
                end
            end


            PlayerGui.ChildAdded:Connect(function(instance)
                if instance.Name == "shakeui" then
                    local safezone = instance.safezone
                    safezone.ChildAdded:Connect(function(button)
                        if autoShakeToggle.Value and button:IsA("ImageButton") then 
                            local minDelay = minDelaySlider.Value
                            local maxDelay = maxDelaySlider.Value
                            task.wait(minDelay, maxDelay)

                            if button.Parent then
                                if shakeType.Value == "Mouse" then
                                    MousePressButton(button)
                                else
                                    UIPressButton(button)
                                end
                            end
                        end
                    end)
                end
            end)

            PlayerGui.ChildRemoved:Connect(function(instance)
                if instance.name == "shakeui" then GuiService.SelectedObject = nil end
            end)

            autoShakeToggle:OnChanged(OnToggle)
        end

        do -- Reel
            local reelTab = autoTabbox:AddTab("Reel")

            local reelFinished = events.reelfinished
    
            local autoReelToggle = reelTab:AddToggle("AutoReelToggle", {
                Text = "Auto-Reel",
                Default = false,
                Tooltip = "Will automatically pass the reel minigame perfectly.",
            })

            local instantCatch = reelTab:AddToggle("InstantCatchToggle", {
                Text = "Instant Catch (Risky)",
                Default = false,
                Tooltip = "Will instantly catch the fish by skipping the minigame.\nMay or may not result in a ban in the future. Use at your own risk!",
            })

            local perfectSlider = reelTab:AddSlider("CatchPerfectSlider", {
                Text = "Perfect Chance",
                Default = 44,
                Min = 1,
                Suffix = "%",
                Max = 100,
                Rounding = 0,
                Compact = false,
            })

            local isPerfect = true

            local OldIndex
            OldIndex = hookmetamethod(game, "__index", function(self, index, value)
                if autoReelToggle.Value then
                    if index == "Position" and self.Name == "fish" then
                        if not isPerfect then
                            isPerfect = true
                            return UDim2.new(0, 0, 0, 0)  
                        end
                            
                        return UDim2.new(0.5, 0, 0.5, 0)
                    end
                end

                return OldIndex(self, index, value)
            end)
        
            local newindex
            newindex = hookmetamethod(game, "__newindex", function(self, index, value)
                if autoReelToggle.Value then
                    if index == "Position" and self.Name == "playerbar" then
                        if instantCatch.Value then reelFinished:FireServer(100, true) end

                        return
                    end
                end 

                return newindex(self, index, value)
            end)

            PlayerGui.ChildAdded:Connect(function(instance)
                if instance.Name == "reel" then
                    local chance = RandomNumber(1, 100)
                    local perfectChance = perfectSlider.Value 
                    isPerfect = chance <= perfectChance

                    local stringResults = `\n\nRandom:{chance}\nPerfect:{perfectChance}\n\n{chance} <= {perfectChance} = {isPerfect}`

                    if isPerfect then 
                        Library:Notify(`⭐ Perfect catch {stringResults}`, 5)
                    else
                        Library:Notify(`🛡️ Missed on purpose {stringResults}`, 5)
                    end
                end
            end)
        end 
    end

    do -- Player Tab
        local playerTab = fischTab:AddRightGroupbox("Player")

        local infOxyGenToggle = playerTab:AddToggle("InfOxyGenToggle", {
            Text = "Infinite Oxygen",
            Default = false,
            Tooltip = "Breath like a fish.",
        })

        local freezeToggle = playerTab:AddToggle("FreezeToggle", {
            Text = "Freeze",
            Default = false,
            Tooltip = "Cold player. No move!",
        })

        local antiAfkToggle = playerTab:AddToggle("AntiAFKToggle", {
            Text = "Anti AFK",
            Default = false,
            Tooltip = "Want to go make some coffee? No problem. Go make some coffee.",
        })

        local walkSpeedSlider = playerTab:AddSlider("WalkSpeedSlider", {
            Text = "WalkSpeed",
            Default = 16,
            Min = 16,
            Suffix = "",
            Max = 500,
            Rounding = 0,
            Compact = false,
        })

        local jumpPowerSlider = playerTab:AddSlider("JumpPowerSlider", {
            Text = "JumpPower",
            Default = 50,
            Min = 50,
            Suffix = "",
            Max = 500,
            Rounding = 0,
            Compact = false,
        })

        local bodyPosition

        local function OnWalkSpeedChanged(value)
            humanoid.WalkSpeed = value
        end

        local function OnJumpPowerChanged(value)
            humanoid.JumpPower = value
        end

        local function OnFreezeChanged(value)
            if bodyPosition then bodyPosition:Destroy() end

            if value then
                bodyPosition = Instance.new("BodyPosition")
                bodyPosition.MaxForce = Vector3.new(400000, 400000, 400000)
                bodyPosition.D = 1000
                bodyPosition.P = 100000
                bodyPosition.Position = humanoidRootPart.Position
                bodyPosition.Parent = humanoidRootPart
            end
        end

        local function AntiAFK()
            if not antiAfkToggle.Value then return end

			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
        end

        local function OnCharacterAdded(newCharacter)
            humanoid = newCharacter:WaitForChild("Humanoid")
            humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

            humanoid.WalkSpeed = walkSpeedSlider.Value
            humanoid.JumpPower = jumpPowerSlider.Value

            Character = newCharacter
        end

        local Oldtick
        Oldtick = hookfunction(tick, function(...)
            local script = getcallingscript()
            
            if infOxyGenToggle.Value and script then
                if script.Name == "oxygen" then 
                    return 0 
                end
            end 
        
            return Oldtick(...)
        end)

        local OldNamecall
        OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local method = getnamecallmethod()

            if antiAfkToggle.Value then
                if method == "FireServer" and self.Name == "afk" then
                    args[1] = false
                end
            end

            return OldNamecall(self, unpack(args))
        end)

        local OldIndex
        OldIndex = hookmetamethod(game, "__index", function(self, index, value)
            if not checkcaller() then
                if index == "WalkSpeed" then
                    return 16
                elseif index == "JumpPower" then
                    return 50
                end
            end

            return OldIndex(self, index, value)
        end)

        local OldNewIndex
        OldNewIndex = hookmetamethod(game, "__newindex", function(self, index, value)
            if not checkcaller() then
                if index == "WalkSpeed" or index == "JumpPower" then
                    return
                end
            end

            return OldNewIndex(self, index, value)
        end)

        antiAfkToggle:OnChanged(AntiAFK)
        freezeToggle:OnChanged(OnFreezeChanged)
        walkSpeedSlider:OnChanged(OnWalkSpeedChanged)
        jumpPowerSlider:OnChanged(OnJumpPowerChanged)

        LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
        LocalPlayer.Idled:Connect(AntiAFK)
    end

    do -- Ingame Automations
        local autoTabbox = fischTab:AddLeftTabbox()

        do -- Auto Apprasie
            local apprasieTab = autoTabbox:AddTab("Apprasie")
        end

        do -- Auto Enchant
            local enchantTab = autoTabbox:AddTab("Enchant")
        end

        do -- Auto Event
            local eventTab = autoTabbox:AddTab("Event")

            local autoEventToggle = eventTab:AddToggle("AutoEventToggle", {
                Text = "Auto-Event",
                Default = false,
                Tooltip = "Will automatically go and farm selected events whenever they are active.",
            })

            local showActiveToggle = eventTab:AddToggle("ShowEventsToggle", {
                Text = "Show Active Events",
                Default = false,
                Tooltip = "Opens a window that will show currently active events.",
            })

            local eventDown = eventTab:AddDropdown("EventDropDown", {
                Values = ServerEvent:GetEventList(),
                Default = 1,
                Multi = false,
            
                Text = "Events",
                Tooltip = "This is a tooltip",
            })

            local function OnActiveToggle(value)
                ServerEvent:SetVisibility(value)
            end

            showActiveToggle:OnChanged(OnActiveToggle)
        end
    end

    do -- Teleports
        local tpTabbox = fischTab:AddLeftTabbox()

        do -- Locations
            local locationTab = tpTabbox:AddTab("Locations")

            local dropDown = locationTab:AddDropdown("LocationsDropDown", {
                Values = dropDownLocations,
                Default = 1,
                Multi = false,
            
                Text = "Locations",
                Tooltip = "This is a tooltip",
            })

            locationTab:AddButton("Teleport", function() 
                local location = dropDown.Value
                if not location then return end

                local cframe = locations[location]

                LocalPlayer:RequestStreamAroundAsync(cframe.p)

                humanoidRootPart.CFrame = cframe
            end)
        end

        do -- Players
            local playersTab = tpTabbox:AddTab("Players")

            local playersDropDown = playersTab:AddDropdown("LocationsDropDown", {
                SpecialType = "Player",
                Text = "Players",
                Tooltip = "This is a tooltip",
            })

            playersTab:AddButton("Teleport", function() 
                local player = Players:FindFirstChild(playersDropDown.Value)
                if not player then return end

                local character = player.Character
                local rootPart = character.HumanoidRootPart

                humanoidRootPart.CFrame = rootPart.CFrame
            end)
        end

        do -- Events
            local eventsTab = tpTabbox:AddTab("Events")

            local activeEvents = ServerEvent:GetActiveEvents()
            local objects = activeEvents.objects
            local array = activeEvents.array

            local eventsDown = eventsTab:AddDropdown("EventsDropDown", {
                Values = array,
                Default = 1,
                Multi = false,
            
                Text = "Events",
                Tooltip = "This is a tooltip",
            })

            eventsTab:AddButton("Teleport", function() 
                local event = eventsDown.Value
                if not event then return end

                local instance = objects[event]
                local cframe = instance.CFrame

                LocalPlayer:RequestStreamAroundAsync(cframe.p)

                humanoidRootPart.CFrame = cframe
            end)
            
            ServerEvent:OnChanged(function()
                eventsDown:BuildDropdownList()
            end)
        end
    end

    do -- Misc
        local miscTabbox = fischTab:AddRightTabbox()

        do -- Items
            local npcs = world.npcs
            local chests = world.chests
            
            local inventory = CharacterModule.PS(LocalPlayer):WaitForChild("Inventory")

            local purchaseRemote = events.purchase
            local library = modules.library

            local allRods = require(library.rods)
            local allFish = require(library.fish)

            local rods, crates = {}, {}

            for i, v in pairs(allRods) do
                if typeof(v) ~= "table" then continue end
                if v.Unpurchasable or not v.Price or v.Price == math.huge then continue end

                table.insert(rods, i)
            end

            for i, v in pairs(allFish) do
                if typeof(v) ~= "table" then continue end
                if not v.IsCrate or not v.BuyMult then continue end
                
                table.insert(crates, i)
            end

            local function clickproximityprompt(prompt)
                local part = Instance.new("Part")
                part.Size = Vector3.new(1, 1, 1) 
                part.Anchored = true
                part.CanCollide = false
                part.Position = humanoidRootPart.Position + (camera.CFrame.LookVector * 10) 
                part.Parent = workspace

                local oldParent = prompt.Parent 

                prompt.MaxActivationDistance = 2e9
                prompt.RequiresLineOfSight = false
                prompt.Parent = part
                
                prompt.PromptShown:wait()

                prompt:InputHoldBegin()
                prompt:InputHoldEnd()

                prompt.MaxActivationDistance = 7
                prompt.RequiresLineOfSight = true
                prompt.Parent = oldParent

                part:Destroy()
            end
            
            local itemsTab = miscTabbox:AddTab("Items")

            local rodsDropDown = itemsTab:AddDropdown("rodsDown", {
                Values = rods,
                Default = 1,
                Multi = false,
            
                Text = "Rods",
                Tooltip = "This is a tooltip",
            })

            itemsTab:AddButton("Buy", function() 
                local rod = rodsDropDown.Value
                purchaseRemote:FireServer(rod, "Rod", nil, 1)
            end)
            itemsTab:AddDivider()

            local cratesDropDown = itemsTab:AddDropdown("cratesDown", {
                Values = crates,
                Default = 1,
                Multi = false,
            
                Text = "Crates",
                Tooltip = "This is a tooltip",
            })

            local cratesAmount = itemsTab:AddSlider("CrateAmountSlider", {
                Text = "Amount",
                Default = 1,
                Min = 1,
                Max = 500,
                Rounding = 0,
                Compact = false,
            })

            itemsTab:AddButton("Buy", function() 
                local crate = cratesDropDown.Value
                local amount = cratesAmount.Value
                purchaseRemote:FireServer(crate, "fish", nil, amount)
            end)
            itemsTab:AddDivider()

            local sellType = itemsTab:AddDropdown("SellDropDown", {
                Values = { "Hand", "All" },
                Default = 1,
                Multi = false,
            
                Text = "Sell Type",
                Tooltip = "This is a tooltip",
            })

            do
                local firstTime = true

                itemsTab:AddButton("Sell", function() 
                    LocalPlayer:RequestStreamAroundAsync(locations.moosewood.p)
                    
                    local type = sellType.Value

                    local marc = npcs:WaitForChild("Marc Merchant")
                    local prompt = marc.dialogprompt
                    
                    local merchant = marc.merchant
                    local sell, sellall = merchant.sell, merchant.sellall

                    if firstTime then
                        clickproximityprompt(prompt)
                        firstTime = false
                    end

                    if type == "All" then return sellall:InvokeServer() end

                    sell:InvokeServer()
                end)
            end

            itemsTab:AddDivider()

            itemsTab:AddButton("Collect Treasure Chests", function() 
                for _, v in pairs(chests:GetChildren()) do
                    local prompt = v:FindFirstChild("ProximityPrompt")
                    if not prompt then continue end

                    fireproximityprompt(prompt)

                    task.wait()
                end
                --[[
                ** Alternative for the future in case it"s not always rendering the treasure chests. **
                for _, v in pairs(inventory:GetChildren()) do
                    if v.Name:find("Treasure Map") and v.Repaired.Value == true then 
                        local x,y,z = v.x.Value, v.y.Value, v.z.Value
                        local position = Vector3.new(x, y, z)
                        LocalPlayer:RequestStreamAroundAsync(position)

                        local chest = chests:WaitForChild(`TreasureChest_{x}_{y}_{z}`)
                        local prompt = chest.ProximityPrompt

                        fireproximityprompt(prompt)

                        task.wait()
                    end
                end
                ]]
            end)

            do
                local jackPos = Vector3.new(-2830.748046875, 215.2417449951172, 1518.34814453125)
                local firstTime = true

                itemsTab:AddButton("Fix Treasure Maps", function() 
                    LocalPlayer:RequestStreamAroundAsync(jackPos)
                    
                    local jack = npcs:WaitForChild("Jack Marrow")
                    local prompt = jack.dialogprompt

                    local treasure = jack.treasure
                    local repairmap = treasure.repairmap

                    if firstTime then
                        clickproximityprompt(prompt)
                        firstTime = false
                    end

                    for _, v in pairs(backpack:GetChildren()) do
                        if v.Name == "Treasure Map" then
                            humanoid:EquipTool(v)
                            repairmap:InvokeServer()
                        end
                    end
                end)
            end
        end

        do -- Bestiary
            local discoverLocation = events.discoverlocation

            local hud = PlayerGui:WaitForChild("hud")
            local safezone = hud.safezone
            local bestiary = safezone.bestiary
            local catagory = bestiary.catagory
            local scroll = catagory.scroll

            local bestiaryTab = miscTabbox:AddTab("Bestiary")

            --[[ Soon
            bestiaryTab:AddToggle("BestiaryFarmToggle", {
                Text = "AutoFarm",
                Default = false,
                Tooltip = "Completes your Bestiary!",
            })
            ]]

            bestiaryTab:AddButton("Discover all locations", function() 
                for i, v in pairs(scroll:GetChildren()) do
                    if not v:IsA("ImageButton") then continue end
                    discoverLocation:FireServer(v.Name)
                end
            end)
        end
    end
end
