return function (Window)
    local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
    local ModuleLoader = require(ReplicatedStorage.LoadModule)
	
	local Network = ModuleLoader("Network")
	local MineSelection = ModuleLoader("MineSelection")
	local ChunkUtil = ModuleLoader("ChunkUtil")
	local Constants = ModuleLoader("Constants")
	local GetWorld = ModuleLoader("GetWorld")
	local GetSellTeleport = ModuleLoader("GetSellTeleport")
	local GetBackpackStatus = ModuleLoader("GetBackpackStatus")
	local Blocks = ModuleLoader("Blocks")
	local GetCurrencyMultiplier = ModuleLoader("GetCurrencyMultiplier")
	local GetRebirthCost = ModuleLoader("GetRebirthCost")
	local LocalData = ModuleLoader("LocalData")
	local Shops = ModuleLoader("Shops")
	local GetGearData = ModuleLoader("GetGearData")
	local Treasures = require(ReplicatedStorage.SharedModules.Data.Treasures)
	
	local camera = workspace.CurrentCamera
	
	local chunks = workspace.Chunks
	local chests = workspace.Chests
	
    local LocalPlayer = Players.LocalPlayer

	local character = LocalPlayer.Character
	local humanoidRootPart = character.PrimaryPart
	
	local isSmoothTpRunning = false
	local forceStop = false
	
	local function GetDistance(object)
		return (humanoidRootPart.CFrame.p - object.CFrame.p).magnitude
	end
	
	local function SmoothTP(object)
		isSmoothTpRunning = true
		
		local rootPartCFrame = humanoidRootPart.CFrame
		humanoidRootPart.CFrame = CFrame.new(rootPartCFrame.X , object.CFrame.Y, rootPartCFrame.Z)
		
		local skips = math.round(GetDistance(object) / (Options.SkipsSlider.Value / 100))
		local moveVector = (object.Position - humanoidRootPart.CFrame.p) / skips
	
	    local startPosition = CFrame.new(humanoidRootPart.CFrame.X , object.CFrame.Y, humanoidRootPart.CFrame.Z)
	
		for i=0, skips do
			if not isSmoothTpRunning then
				break 
			end
			
			startPosition = startPosition + moveVector
			
			humanoidRootPart.CFrame = startPosition
			
			task.wait()
		end
			
		while isSmoothTpRunning and object.Parent and (Toggles.OreFarmCheckbox.Value and not GetBackpackStatus().Full or true) do
			humanoidRootPart.CFrame = object.CFrame
				
			task.wait()
		end
		
		isSmoothTpRunning = false
	end
	
	local function GetInventoryValue()
		local inventory = GetBackpackStatus().Inventory
		local oreValue = 0

		for _, v in pairs(inventory) do
			local name = v[1]
			local amount = v[2]
				
			local blockValueData = Blocks[name].Value
				
			oreValue = oreValue + blockValueData[2] * amount * GetCurrencyMultiplier(game.Players.LocalPlayer, blockValueData[1])
		end 
			
		return oreValue
	end

    local ms2Tab = Window:AddTab("Mining Simulator 2")

    do -- Ore-Farm
        local formattedOres = {}

		for i, v in pairs(Blocks) do 
            table.insert(formattedOres, i .. ": $" .. v.Value[2])
		end

        local oreFarmBox = ms2Tab:AddLeftGroupbox("Ore Farm")

        local oreFarmCheckBox = oreFarmBox:AddToggle("OreFarmCheckBox", {
            Text = "Enable",
            Default = false,
            Tooltip = "Enables Ore-Farm",
        })
        
        local autoSellCheckBox = oreFarmBox:AddToggle("AutoSellCheckBox", {
            Text = "Auto-Sell",
            Default = false,
            Tooltip = "Enables Auto-Sell",
        })

        local oresDropDown = oreFarmBox:AddDropdown("Ores", {
            Values = formattedOres,
            Default = 1,
            Multi = false,
            
            Text = "Ores",
            Tooltip = "Select Ore",
        })

        local function FixOreString(block)
			local index = block:find(":")
			
			return block:sub(1, index - 1)
		end
		
		local function GetClosestOre(name)
			local closest, magnitude
			
			for _, chunk in pairs(chunks:GetChildren()) do
				for _, ore in pairs(chunk:GetChildren()) do
					if ore.Name == name or name == nil then
						local currentMagnitude = GetDistance(ore)
						
						if not closest or currentMagnitude < magnitude then
							closest = ore
							magnitude = currentMagnitude
						end
					end
				end
			end
			
			return closest
		end

        oreFarmCheckBox:OnChanged(function()
			if oreFarmCheckBox.Value then
				local closestOre = GetClosestOre(FixOreString(oresDropDown.Value))
					
				if closestOre then
					isSmoothTpRunning = false
					
					task.spawn(SmoothTP, closestOre)
				end

				while oreFarmCheckBox.Value and task.wait() do
					if forceStop then
						continue
					elseif autoSellCheckBox.Value and GetBackpackStatus().Full then
						isSmoothTpRunning = false
							
						Network:FireServer("Teleport", "The Overworld SurfaceSell")
							
						closestOre = nil
							
						continue
					elseif not closestOre or not closestOre.Parent or closestOre.Name ~= FixOreString(oresDropDown.Value) then
						isSmoothTpRunning = false
						
						closestOre = GetClosestOre(FixOreString(oresDropDown.Value))
							
						task.wait()
							
						if closestOre then
							task.spawn(SmoothTP, closestOre)
                        else
                            Network:FireServer("Teleport", "Surface")
						end
					elseif closestOre then
						Network:FireServer("MineBlock", ChunkUtil.worldToCell(closestOre.CFrame.p))
					end
				end
					
				isSmoothTpRunning = false
					
				Network:FireServer("Teleport", "Surface")
			end
        end)
    end

    do -- Chest Farm
        local formattedChests = {}

        for i, v in pairs(Treasures.Data) do
            table.insert(formattedChests, i)
		end

        local chestFarmBox = ms2Tab:AddRightGroupbox("Chest Farm")

        local chestFarmCheckBox = chestFarmBox:AddToggle("ChestFarmCheckBox", {
            Text = "Enable",
            Default = false,
            Tooltip = "Enables Chest-Farm",
        })

        local chestDropDown = chestFarmBox:AddDropdown("Chests", {
            Values = formattedChests,
            Default = 1,
            Multi = false,
            
            Text = "Ores",
            Tooltip = "Select Ore",
        })

        local function GetClosestChest(name)
			local closest, magnitude
			
			for _, chest in pairs(chests:GetChildren()) do
				local chestPart = chest.PrimaryPart

				if chestPart and chest.Name == name or name == nil then
					local currentMagnitude = GetDistance(chestPart)
						
					if not closest or currentMagnitude < magnitude then
						closest = chestPart
						magnitude = currentMagnitude
					end
				end
			end
			
			return closest
		end

        chestFarmCheckBox:OnChanged(function()
			if chestFarmCheckBox.Value then
				local closestChest = GetClosestChest(chestDropDown.Value)
					
				if closestChest then
					isSmoothTpRunning = false
					
					task.spawn(SmoothTP, closestChest)
				end

				while chestFarmCheckBox.Value and task.wait() do
					if forceStop then
						continue
					elseif not closestChest or not closestChest.Parent then
						isSmoothTpRunning = false
						
						closestChest = GetClosestChest(chestDropDown.Value)

						task.wait()
				
						if closestChest then
							task.spawn(SmoothTP, closestChest)
						end
					end
				end
					
				isSmoothTpRunning = false
					
				Network:FireServer("Teleport", "Surface")
			end
		end)
    end

    do -- Auto Rebirth
        local autoRebirthBox = ms2Tab:AddLeftGroupbox("Auto-Rebirth")

        local autoRebirthCheckBox = autoRebirthBox:AddToggle("AutoRebirthCheckBox", {
            Text = "Enable",
            Default = false,
            Tooltip = "Enables Auto-Rebirth",
        })

        local OldFunc
		OldFunc = hookfunc(string.format, function(self, string, ...)
			if autoRebirthCheckBox.Value and self:find("Value") then
				local totalValue = LocalData:GetData("Coins") + GetInventoryValue()
				local rebirthCost = GetRebirthCost(LocalData:GetData("Rebirths"), LocalData:GetData("GemEnchantments"))

				print(totalValue/rebirthCost * 100 .. "%")
				
				if totalValue >= rebirthCost then
					coroutine.resume(coroutine.create(function()
						local OldCoinValue = LocalData:GetData("Coins")
						
						forceStop = true
						
						isSmoothTpRunning = false
						
						Network:FireServer("Teleport", "The Overworld SurfaceSell")
						
						repeat task.wait() until LocalData:GetData("Coins") ~= OldCoinValue
						
						Network:FireServer("Rebirth")
						
						task.wait(0.5)
						
						forceStop = false
					end))
				end
			end
			
			return OldFunc(self, string, ...) 
		end)
    end

    do -- Auto Buy
        local autoBuyBox = ms2Tab:AddRightGroupbox("Auto-Buy")

        local toolsCheckBox = autoBuyBox:AddToggle("ToolsCheckBox", {
            Text = "Tools",
            Default = false,
            Tooltip = "Auto-Buy Tools.",
        })

        local backpacksCheckBox = autoBuyBox:AddToggle("BackpacksCheckBox", {
            Text = "Backpacks",
            Default = false,
            Tooltip = "Auto-Buy Backpacks.",
        })

		local function GetCurrentItemPrice(type)
			for i, v in pairs(Shops) do
				if i:find(type) then
					for _, item in pairs(v) do 
						local name = item[2]
						
						if item[1] == type and LocalData:GetData(type) == name then
							return GetGearData(type, name, LocalData:GetData()).Cost[2] * (LocalData:GetData("Rebirths") + 1)
						end
					end
				end
			end
		end

		local function GetBestAffordAbleItem(type)
			local selectedTool, selectedWorld, selectedPrice
			local currentTool, currentItemPrice = LocalData:GetData(type), GetCurrentItemPrice(type)

			for i, v in pairs(Shops) do
				if i:find(type) then
					for itemIndex, item in pairs(v) do 
						local itemType = item[1]
						local name = item[2]
						
						if itemType == type and name ~= currentTool then
							local costData = GetGearData(itemType, name, LocalData:GetData()).Cost
							
							if costData[1] == "Coins" then
								local coins = LocalData:GetData("Coins") + GetInventoryValue()
								local cost = costData[2] * (LocalData:GetData("Rebirths") + 1)

								if (not bestAffordAbleTool and cost > currentItemPrice and cost <= coins) or (cost <= coins and cost > currentItemPrice and cost > selectedPrice) then
									selectedTool = itemIndex
									selectedWorld = i
									selectedPrice = cost
								end
							end
						end
					end
				end
			end
			
			return selectedWorld, selectedTool, selectedPrice
		end

		local OldFunc
		OldFunc = hookfunc(string.format, function(self, string, ...)
			if self:find("Value") then
    			local coins = LocalData:GetData("Coins")
    			local totalValue = coins + GetInventoryValue()
			
    			local rebirthCost = GetRebirthCost(LocalData:GetData("Rebirths"), LocalData:GetData("GemEnchantments"))
    			local rebirthPrecentage = totalValue/rebirthCost * 100
    			
				local ignorePrecentage = Options.BuyDisablerSlider.Value
				
    			if toolsCheckBox.Value and (ignorePrecentage == 0 or rebirthPrecentage < ignorePrecentage) then
    			    coroutine.resume(coroutine.create(function()
        				local world, index, price = GetBestAffordAbleItem("Tool")
        				
        				if coins < price and totalValue > price then
        					forceStop = true
        						
        					isSmoothTpRunning = false
        						
        					Network:FireServer("Teleport", "The Overworld SurfaceSell")
        					
        					repeat task.wait() until LocalData:GetData("Coins") ~= coins
        					
        					forceStop = false
        					
        					world, index = GetBestAffordAbleItem("Tool")
        				end
        				
        				if index then
        					Network:FireServer("PurchaseShopItem", world, index) 
        				end
    				end))
    			end
    			
    			if backpacksCheckBox.Value and (ignorePrecentage == 0 or rebirthPrecentage < ignorePrecentage) then
    			    coroutine.resume(coroutine.create(function()
        				local world, index, price = GetBestAffordAbleItem("Backpack")
        				
        				if coins < price and totalValue > price then
        					forceStop = true
        						
        					isSmoothTpRunning = false
        						
        					Network:FireServer("Teleport", "The Overworld SurfaceSell")
        					
        					repeat task.wait() until LocalData:GetData("Coins") ~= coins
        					
        					forceStop = false
        					
        					world, index = GetBestAffordAbleItem("Backpack")
        				end
        				
        				if index then
        					Network:FireServer("PurchaseShopItem", world, index) 
        				end
    				end))
    			end
			end
			
			return OldFunc(self, string, ...) 
		end)
    end

    do -- Misc
        local miscBox = ms2Tab:AddLeftGroupbox("Misc")
        local teleportSpeedSlider = miscBox:AddSlider("SkipsSlider", {
            Text = "Teleport Speed",

            Default = 7,
            Min = 1,
            Max = 100,
            Rounding = 1,
        
            Compact = false,
        })

        local buyDisablerSlider = miscBox:AddSlider("BuyDisablerSlider", {
            Text = "Auto-Buy Disabler",
            Tooltip = "Disables the Auto-Buy whenever your Rebirth reaches the selected precentage",
            Suffix = "%",

            Default = 0,
            Min = 0,
            Max = 100,
            Rounding = 1,

            Compact = false,
        })

    end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
		character = newChar
		
		humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
	end)
end
