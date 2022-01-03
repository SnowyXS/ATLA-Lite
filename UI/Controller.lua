local Controller

local UserInputService = game:GetService("UserInputService")
local CurrentCamera = workspace.CurrentCamera

local arrow = Drawing.new("Text")
arrow.Text = ">"
arrow.Size = 25
arrow.Color = Color3.fromRGB(255, 255,255)
arrow.Position = Vector2.new(0, 0.5 * CurrentCamera.ViewportSize.Y)
arrow.Visible = true

local SubCategories do
	SubCategories = {}
	SubCategories.__index = SubCategories

	function SubCategories:CreateCategory()
		local _instance = self._instance

		_instance.Text = _instance.Text .. " (+)"

		local Category = setmetatable({
			_objects = {},
			OpenCategory = self.OpenCategory,
			CloseCategory = self.CloseCategory
		}, Controller)

		self.Category = Category

		table.insert(Category._categories, Category)

		return Category
	end

	function SubCategories:OpenCategory()
		local _openedCategories = self._openedCategories
		local previousCategory = _openedCategories[#_openedCategories] or Controller

		previousCategory:SetVisible(false)

		table.insert(self._openedCategories, self)

		self:SetVisible(true)
	end

	function SubCategories:CloseCategory()
		local _openedCategories = self._openedCategories
		local previousCategory = _openedCategories[#_openedCategories - 1] or Controller

		self:SetVisible(false)

		table.remove(self._openedCategories, table.find(_openedCategories, self))

		previousCategory:SetVisible(true)
	end

	function SubCategories:HasCategory()
		return self.Category ~= nil
	end

	function SubCategories:GetCategoryClass()
		return self.Category or {}
	end
end

local Button do 
	Button = {}
	Button.__index = Button

	function Button:_new(name)
		local _objects = self._objects

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._instance.TextBounds.Y / 2 + 4) or (0.5 * CurrentCamera.ViewportSize.Y)

		local buttonObject = Drawing.new("Text")
		buttonObject.Text = name
		buttonObject.Size = 24
		buttonObject.Color = Color3.fromRGB(255,255,255)
		buttonObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		buttonObject.Visible = Controller:GetOpenedCategory()._objects == _objects
	
		local button = setmetatable({
			_instance = buttonObject,
			_position = buttonObject.Position,
		}, self)

		table.insert(self._objects, button)

		button._input = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadFive) and buttonObject.Visible and arrow.Position.Y == buttonObject.Position.Y then
                if button._callback then
                    task.spawn(button._callback)
                end

				buttonObject.Color = Color3.fromRGB(0, 255, 0)

                task.wait(0.2)

                buttonObject.Color = Color3.fromRGB(255, 255, 255)
			end
		end)

		return button
	end

	function Button:Destroy(shouldDestroyDescendants)
		return (shouldDestroyDescendants and Controller.DestroyDescendants(self)) or Controller.DestroyObject(self)
	end

	function Button:OnPressed(callback)
		self._callback = callback
	end
end

local Checkbox do 
	Checkbox = {}
	Checkbox.__index = Checkbox

	function Checkbox:_new(name, toggle)
		local _objects = self._objects

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._instance.TextBounds.Y / 2 + 4) or (0.5 * CurrentCamera.ViewportSize.Y)

		local checkboxObject = Drawing.new("Text")
		checkboxObject.Text = name
		checkboxObject.Size = 24
		checkboxObject.Color = toggle and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		checkboxObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		checkboxObject.Visible = Controller:GetOpenedCategory()._objects == _objects
	
		local checkbox = setmetatable({
			_isToggled = toggle or false,
			_instance = checkboxObject,
			_position = checkboxObject.Position
		}, self)

		table.insert(self._objects, checkbox)

		checkbox._input = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadFive) and checkboxObject.Visible and arrow.Position.Y == checkboxObject.Position.Y then
				checkbox:SetToggle(not checkbox._isToggled)
			end
		end)

		return checkbox
	end

	function Checkbox:SetToggle(bool, shouldSkipCallBack)
		self._isToggled = bool

		self._instance.Color = (self._isToggled and Color3.fromRGB(0, 255, 0)) or Color3.fromRGB(255, 0, 0)

		return self._isToggled, self._callback and not shouldSkipCallBack and task.spawn(self._callback)
	end

	function Checkbox:IsToggled()
		return self._isToggled
	end
	
	function Checkbox:Destroy(shouldDestroyDescendants)
		return (shouldDestroyDescendants and Controller.DestroyDescendants(self)) or Controller.DestroyObject(self)
	end

	function Checkbox:OnChanged(callback)
		self._callback = callback
	end
end

local Slider do 
	Slider = {}
	Slider.__index = Slider

	function Slider:_new(name, value, minimumValue, maxValue, jumps, extension)
		local _objects = self._objects

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._instance.TextBounds.Y / 2 + 4) or (0.5 * CurrentCamera.ViewportSize.Y)

		value = tonumber(value) or minimumValue or 0

		local sliderObject = Drawing.new("Text")
		sliderObject.Text = name .. ": " .. math.clamp(value, minimumValue, maxValue) .. extension
		sliderObject.Size = 24
		sliderObject.Color = Color3.fromRGB(255,255,255)
		sliderObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		sliderObject.Visible = Controller:GetOpenedCategory()._objects == _objects
	
		local slider = setmetatable({
            _value = math.clamp(value, minimumValue, maxValue),
            _maxValue = tonumber(maxValue) or 10,
            _minimumValue = tonumber(minimumValue) or 0,
			_instance = sliderObject,
			_position = sliderObject.Position
		}, self)

		table.insert(self._objects, slider)

		slider._input = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if sliderObject.Visible and arrow.Position.Y == sliderObject.Position.Y then
                local count = 0.1

                while not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and ((UserInputService:IsKeyDown(Enum.KeyCode.Right) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadSix)) and slider:SetValue(slider._value + (jumps or 1))) or ((UserInputService:IsKeyDown(Enum.KeyCode.Left) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadFour)) and slider:SetValue(slider._value - (jumps or 1))) do
                    task.wait(count)
                    count = math.clamp(count - 0.005, 0, 0.1)
                end
            end
		end)

		return slider
	end

    function Slider:GetValue()
        return tonumber(self._value)
    end

    function Slider:SetValue(value)
        local sliderObject = self._instance

        local oldValue = self._value
        local newValue = math.clamp(value, self._minimumValue, self._maxValue)

        self._value = newValue

        sliderObject.Text = sliderObject.Text:gsub(oldValue, newValue)

        return oldValue, newValue, self._callback and task.spawn(self._callback)
    end

	function Slider:Destroy(shouldDestroyDescendants)
		return (shouldDestroyDescendants and Controller.DestroyDescendants(self)) or Controller.DestroyObject(self)
	end

	function Slider:OnChanged(callback)
		self._callback = callback
	end
end

local ListSelector do 
	ListSelector = {}
	ListSelector.__index = ListSelector

	function ListSelector:_new(list, selected)
		local _objects = self._objects

        assert(list and #list >= 1 and typeof(list) == "table", "Illegal list.")

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._instance.TextBounds.Y / 2 + 4) or (0.5 * CurrentCamera.ViewportSize.Y)

		local listObject = Drawing.new("Text")
		listObject.Text = list[selected or 1] .. " (" .. (selected or 1) .. "/" .. #list .. ")"
		listObject.Size = 24
		listObject.Color = Color3.fromRGB(255,255,255)
		listObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		listObject.Visible = Controller:GetOpenedCategory()._objects == _objects 
	
		local listSelector = setmetatable({
            _list = list,
            _selected = selected or 1,
			_instance = listObject,
			_position = listObject.Position
		}, self)

		table.insert(self._objects, listSelector)

		listSelector._input = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if listObject.Visible and arrow.Position.Y == listObject.Position.Y then
                local count = 0.25

                while not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and ((UserInputService:IsKeyDown(Enum.KeyCode.Right) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadSix)) and listSelector:SetSelected(listSelector._selected + 1)) or ((UserInputService:IsKeyDown(Enum.KeyCode.Left) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadFour)) and listSelector:SetSelected(listSelector._selected - 1)) do
                    task.wait(count)
                    count = math.clamp(count - 0.005, 0, 0.25)
                end
            end
		end)

		return listSelector
	end

	function ListSelector:ChangeList(list)
		assert(typeof(list) == "table", "Illegal list.")

		local oldList = self._list
		local oldSelected = self._selected

		local newSelected = (oldSelected >= #list and #list) or oldSelected

		self._list = list
		self._selected = newSelected
		self._instance.Text = list[newSelected] .. " (" .. (newSelected) .. "/" .. #list .. ")"
	end

    function ListSelector:SetSelected(newSelectedIndex)
        local listObject = self._instance
        local list = self._list

        local oldSelectedIndex = self._selected
        local oldSelected = list[oldSelectedIndex]

        local newSelectedIndex = math.clamp(newSelectedIndex, 1, #list)
        local newSelected = list[newSelectedIndex]

        self._selected = newSelectedIndex

        listObject.Text = listObject.Text:gsub(oldSelected, newSelected):gsub(oldSelectedIndex .. "/", newSelectedIndex .. "/")

        return oldSelected, newSelected, self._callback and task.spawn(self._callback)
    end

	function ListSelector:GetSelected()
		return self._list[self._selected]
	end
	
	function ListSelector:Destroy(shouldDestroyDescendants)
		return (shouldDestroyDescendants and Controller.DestroyDescendants(self)) or Controller.DestroyObject(self)
	end

	function ListSelector:OnChanged(callback)
		self._callback = callback
	end
end


local Text do 
	Text = {}
	Text.__index = Text

	function Text:_new(name)
		local _objects = self._objects

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._instance.TextBounds.Y / 2 + 4) or (0.5 * CurrentCamera.ViewportSize.Y)

		local TextObject = Drawing.new("Text")
		TextObject.Text = tostring(name)
		TextObject.Size = 24
		TextObject.Color = Color3.fromRGB(211,211,211)
		TextObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		TextObject.Visible = Controller:GetOpenedCategory()._objects == _objects
	
		local text = setmetatable({
			_instance = TextObject,
			_position = TextObject.Position
		}, self)

		table.insert(_objects, text)

		return text
	end

	function Text:Set(text)
		self._instance.Text = text
	end

	function Text:SetColor(color)
		self._instance.Color = color
	end

	function Text:Destroy(shouldDestroyDescendants)
		return (shouldDestroyDescendants and Controller.DestroyDescendants(self)) or Controller.DestroyObject(self)
	end
end

do 
    Controller = {
        _categories = {},
        _openedCategories = {},
        _objects = {}
    }
    Controller.__index = Controller

    Controller.Button = Button
    Controller.Checkbox = Checkbox
    Controller.Slider = Slider
    Controller.ListSelector = ListSelector
	Controller.Text = Text

    function Controller:new(type, ...)
        local item = Controller[type]

        assert(item and item._new, "Couldn't create item")

        local ItemClass = setmetatable(item, SubCategories)
        ItemClass._objects = self._objects
        ItemClass.__index = ItemClass

        return ItemClass:_new(...)
    end

    function Controller:GetSelectedObject()
        for i, v in pairs(self._objects) do
            if v._instance.Visible == true and arrow.Position.Y == v._position.Y then
                return v
            end
        end
    end

    function Controller:SelectNextObject()
        local _objects = self._objects
        local nextObject

        for i, v in pairs(_objects) do
            if v._instance.Visible == true and arrow.Position.Y == v._position.Y then
                nextObject = _objects[i + 1]
                break
            end
        end

        if nextObject then
            arrow.Position = Vector2.new(arrow.Position.X, nextObject._position.Y)
        end
    end

    function Controller:SelectPreviousObject()
        local _objects = self._objects
        local previousObject

        for i, v in pairs(_objects) do
            if v._instance.Visible == true and arrow.Position.Y == v._position.Y then
                previousObject = _objects[i - 1]
                break
            end
        end

        if previousObject then
            arrow.Position = Vector2.new(arrow.Position.X, previousObject._position.Y)
        end
    end

    function Controller:GetOpenedCategory()
        return self._openedCategories[#self._openedCategories] or self
    end

    function Controller:GetPreviousCategory()
        return self._openedCategories[#self._openedCategories - 1] or self
    end

    function Controller:SetVisible(bool)
        for _, v in pairs(self._objects) do
            v._instance.Visible = bool
        end
    end

	function Controller.GetCategoryFromObject(object)
		local shouldSearch = not table.find(Controller._objects, object)

		if shouldSearch then
			for _, category in pairs(Controller._categories) do
				local _objects = category._objects

				if table.find(_objects, object) then
					return category
				end
			end
		end

		return Controller
	end

    function Controller.DestroyDescendants(object)
        assert(object:HasCategory(), "Invaild category.")
        
        local category = object:GetCategoryClass()
        local _objects = category._objects

        local _categories = Controller._categories
        local _openedCategories = Controller._openedCategories

        local openedIndex = table.find(_openedCategories, category)
        local categoriesIndex = table.find(_categories, category)
		
        for _, object in pairs(_objects) do
            if object:HasCategory() then
                Controller.DestroyDescendants(object)
            else
                object:Destroy()
            end
        end

		if openedIndex then
            category:CloseCategory()
            table.remove(_openedCategories, openedIndex)
        end

		object:Destroy()

        table.remove(_categories, categoriesIndex)
        table.clear(category)
    end

	function Controller.DestroyObject(object)
		local instance = object._instance

		if instance then
			local objectCategory = Controller.GetCategoryFromObject(object)
			local _openedCategories = Controller._openedCategories

			local _objects = objectCategory._objects
			local objectIndex = table.find(_objects, object)
			
			if object._input then
				object._input:Disconnect()
			end

			object._instance:Remove()

			table.remove(_objects, objectIndex)
			table.clear(object)

			local lastObject = _objects[#_objects]

			if lastObject then
				local currentCategory = Controller:GetOpenedCategory()

				Controller.FixPosition(_objects, false)

				arrow.Position = (lastObject._instance.Visible and not currentCategory:GetSelectedObject()) and Vector2.new(arrow.Position.X, lastObject._position.Y) or arrow.Position
			end
		end
	end

	function Controller.FixPosition(objects, shouldDeepFix)
		for i, v in ipairs(objects) do
			local _instance = v._instance
			local preivousObject = objects[i - 1]

			_instance.Position = Vector2.new(
				objects[i]._position.X, 
				(preivousObject and preivousObject._position.Y + preivousObject._instance.TextBounds.Y / 2 + 4) or (0.5 * CurrentCamera.ViewportSize.Y))

			objects[i]._position = _instance.Position

			if shouldDeepFix and v:HasCategory() then
				local Category = v:GetCategoryClass()
				local _objects = Category._objects

				Controller.FixPosition(_objects, shouldDeepFix)
			end
		end
	end
end


CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local _objects = Controller._objects
	
	local currentCategory = Controller:GetOpenedCategory()
	local currentSelected = currentCategory:GetSelectedObject()

	Controller.FixPosition(_objects, true)

	arrow.Position = Vector2.new(arrow.Position.X, (currentSelected and currentSelected._position.Y) or (0.5 * CurrentCamera.ViewportSize.Y))
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	local Category = Controller:GetOpenedCategory()
	local selectedObject = Category:GetSelectedObject()

	if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.KeypadEight then
		Category:SelectPreviousObject()
	elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.KeypadTwo then
		Category:SelectNextObject()
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and (UserInputService:IsKeyDown(Enum.KeyCode.Right) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadSix)) then
        if selectedObject:HasCategory() then
			local newCategory = selectedObject:GetCategoryClass()
			local _objects = newCategory._objects
			local objectPlace = table.find(Category._objects, selectedObject) 
			local lastObject = _objects[#_objects]

			if objectPlace and lastObject then
				local newArrowPosition = (#_objects >= objectPlace and arrow.Position.Y) or lastObject._position.Y

				arrow.Position = Vector2.new(arrow.Position.X, newArrowPosition)

				newCategory:OpenCategory()
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Backspace then
		if Category.CloseCategory then
			local previousCategory = Controller:GetPreviousCategory()
			local _objects = previousCategory._objects
			local objectPlace = table.find(Category._objects, selectedObject)
			local lastObject = _objects[#_objects]
			
			if objectPlace and lastObject then
				local newArrowPosition = (#_objects >= objectPlace and arrow.Position.Y) or lastObject._position.Y

				arrow.Position = Vector2.new(arrow.Position.X, newArrowPosition)

				Category:CloseCategory()
			end
		end
	elseif input.keyCode == Enum.KeyCode.Delete then
		arrow.Visible = not arrow.Visible

		Category:SetVisible(arrow.Visible)
	end
end)

getgenv().libLoaded = true

return Controller
