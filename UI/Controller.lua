local Controller

local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local arrow = Drawing.new("Text")
arrow.Text = ">"
arrow.Size = 25
arrow.Color = Color3.fromRGB(255, 255,255)
arrow.Position = Vector2.new(0, 0.5 * camera.ViewportSize.Y)
arrow.Visible = true

local SubCategories do
	SubCategories = {}
	SubCategories.__index = SubCategories

	function SubCategories:CreateCategory()
		local _object = self._object

		_object.Text = _object.Text .. " (+)"

		local Category = setmetatable({
			_objects = {}
		}, Controller)

		function Category:_opencategory()
			local _openedCategories = self._openedCategories
			local previousCategory = _openedCategories[#_openedCategories] or Controller

			previousCategory:SetVisible(false)

			table.insert(self._openedCategories, self)

			self:SetVisible(true)
		end
	
		function Category:_closecategory()
			local _openedCategories = self._openedCategories
			local previousCategory = _openedCategories[#_openedCategories - 1] or Controller

			self:SetVisible(false)

			table.remove(self._openedCategories, table.find(_openedCategories, self))

			previousCategory:SetVisible(true)
		end

		self._isValidCategory = true
		self._CategoryClass = Category

		table.insert(Category._categories, Category)

		return Category
	end

	function SubCategories:HasCategory()
		return self._isValidCategory ~= nil
	end

	function SubCategories:GetCategoryClass()
		return self._CategoryClass or {}
	end
end

local Button do 
	Button = {}
	Button.__index = Button

	function Button:_new(name)
		local _objects = self._objects

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._object.TextBounds.Y / 2 + 3) or (0.5 * camera.ViewportSize.Y)

		local buttonObject = Drawing.new("Text")
		buttonObject.Text = name
		buttonObject.Size = 24
		buttonObject.Color = Color3.fromRGB(255,255,255)
		buttonObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		buttonObject.Visible = self._objects == Controller._objects
	
		local button = setmetatable({
			_object = buttonObject,
			_position = buttonObject.Position
		}, self)

		table.insert(self._objects, button)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if input.KeyCode == Enum.KeyCode.Return and buttonObject.Visible and arrow.Position.Y == buttonObject.Position.Y then
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

	function Button:OnChanged(callback)
		self._callback = callback
	end
end

local Checkbox do 
	Checkbox = {}
	Checkbox.__index = Checkbox

	function Checkbox:_new(name)
		local _objects = self._objects

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._object.TextBounds.Y / 2 + 3) or (0.5 * camera.ViewportSize.Y)

		local buttonObject = Drawing.new("Text")
		buttonObject.Text = name
		buttonObject.Size = 24
		buttonObject.Color = Color3.fromRGB(255,0,0)
		buttonObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		buttonObject.Visible = self._objects == Controller._objects
	
		local checkbox = setmetatable({
			_isToggled = false,
			_object = buttonObject,
			_position = buttonObject.Position
		}, self)

		table.insert(self._objects, checkbox)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if input.KeyCode == Enum.KeyCode.Return and buttonObject.Visible and arrow.Position.Y == buttonObject.Position.Y then
				checkbox._isToggled = not checkbox._isToggled

                if checkbox._callback then
                    task.spawn(checkbox._callback)
                end

				buttonObject.Color = (checkbox._isToggled and Color3.fromRGB(0, 255, 0)) or Color3.fromRGB(255, 0, 0)
			end
		end)

		return checkbox
	end

	function Checkbox:IsToggled()
		return self._isToggled
	end
	
	function Checkbox:OnChanged(callback)
		self._callback = callback
	end
end

local Slider do 
	Slider = {}
	Slider.__index = Slider

	function Slider:_new(name, value, minimumValue, maxValue, jumps)
		local _objects = self._objects

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._object.TextBounds.Y / 2 + 3) or (0.5 * camera.ViewportSize.Y)

		local sliderObject = Drawing.new("Text")
		sliderObject.Text = name .. ": " .. math.clamp(tonumber(value) or 0, minimumValue, maxValue)
		sliderObject.Size = 24
		sliderObject.Color = Color3.fromRGB(255,255,255)
		sliderObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		sliderObject.Visible = self._objects == Controller._objects
	
		local slider = setmetatable({
            _value = math.clamp(tonumber(value) or 0, minimumValue, maxValue),
            _maxValue = tonumber(maxValue) or 10,
            _minimumValue = tonumber(minimumValue) or 0,
			_object = sliderObject,
			_position = sliderObject.Position
		}, self)

		table.insert(self._objects, slider)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if sliderObject.Visible and arrow.Position.Y == sliderObject.Position.Y then
                local count = 0.1

                while (UserInputService:IsKeyDown(Enum.KeyCode.Right) and slider:SetValue(slider._value + (jumps or 1))) or (UserInputService:IsKeyDown(Enum.KeyCode.Left) and slider:SetValue(slider._value - (jumps or 1))) do
                    task.wait(count)
                    count = math.clamp(count - 0.005, 0, 0.1)
                end
            end
		end)

		return slider
	end

    function Slider:GetValue()
        return self._value
    end

    function Slider:SetValue(value)
        local sliderObject = self._object
        local shouldCallBack = self._callback and task.spawn(self._callback)

        local oldValue = self._value
        local newValue = math.clamp(value, self._minimumValue, self._maxValue)

        self._value = newValue

        sliderObject.Text = sliderObject.Text:gsub(oldValue, newValue)

        return oldValue, newValue
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

        assert(list and #list >= 1, "Illegal list.")

		local preivousObject = _objects[#_objects]
		local position = (preivousObject and preivousObject._position.Y + preivousObject._object.TextBounds.Y / 2 + 3) or (0.5 * camera.ViewportSize.Y)

        print(list[selected or 1], selected or 1, #list)
		local listObject = Drawing.new("Text")
		listObject.Text = list[selected or 1] .. " (" .. (selected or 1) .. "/" .. #list .. ")"
		listObject.Size = 24
		listObject.Color = Color3.fromRGB(255,255,255)
		listObject.Position = Vector2.new(arrow.Position.X + arrow.TextBounds.X + 3, position)
		listObject.Visible = self._objects == Controller._objects
	
		local listSelector = setmetatable({
            _list = list,
            _selected = selected or 1,
			_object = listObject,
			_position = listObject.Position
		}, self)

		table.insert(self._objects, listSelector)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if listObject.Visible and arrow.Position.Y == listObject.Position.Y then
                local count = 0.25

                while (UserInputService:IsKeyDown(Enum.KeyCode.Right) and listSelector:SetSelected(listSelector._selected + 1)) or (UserInputService:IsKeyDown(Enum.KeyCode.Left) and listSelector:SetSelected(listSelector._selected - 1)) do
                    task.wait(count)
                    count = math.clamp(count - 0.005, 0, 0.25)
                end
            end
		end)

		return listSelector
	end

    function ListSelector:SetSelected(newSelectedIndex)
        local listObject = self._object
        local shouldCallBack = self._callback and task.spawn(self._callback)
        local list = self._list

        local oldSelectedIndex = self._selected
        local oldSelected = list[oldSelectedIndex]

        local newSelectedIndex = math.clamp(newSelectedIndex, 1, #list)
        local newSelected = list[newSelectedIndex]

        self._selected = newSelectedIndex

        print(oldSelectedIndex, newSelectedIndex)

        listObject.Text = listObject.Text:gsub(oldSelected, newSelected):gsub(oldSelectedIndex .. "/", newSelectedIndex .. "/")

        return oldSelected, newSelected
    end

	function ListSelector:OnChanged(callback)
		self._callback = callback
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

    function Controller:new(type, ...)
        local item = Controller[type]
        local _objects = self._objects

        assert(item and item._new, "Couldn't create item")

        local ItemClass = setmetatable(item, SubCategories)
        ItemClass._objects = _objects
        ItemClass.__index = ItemClass

        return ItemClass:_new(...)
    end

    function Controller:GetSelectedObject()
        for i, v in pairs(self._objects) do
            if v._object.Visible == true and arrow.Position.Y == v._position.Y then
                return v
            end
        end
    end

    function Controller:SelectNextObject()
        local _objects = self._objects
        local nextObject

        for i, v in pairs(_objects) do
            if v._object.Visible == true and arrow.Position.Y == v._position.Y then
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
            if v._object.Visible == true and arrow.Position.Y == v._position.Y then
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
            v._object.Visible = bool
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	local Category = Controller:GetOpenedCategory()
	local selectedObject = Category:GetSelectedObject()

	if input.KeyCode == Enum.KeyCode.Up then
		Category:SelectPreviousObject()
	elseif input.KeyCode == Enum.KeyCode.Down then
		Category:SelectNextObject()
	elseif (input.KeyCode == Enum.KeyCode.LeftAlt and UserInputService:IsKeyDown(Enum.KeyCode.Right)) or (input.KeyCode == Enum.KeyCode.Right and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)) then

        if selectedObject:HasCategory() then
			local newCategory = selectedObject:GetCategoryClass()
			local _objects = newCategory._objects
			local newArrowPosition = (#_objects >= table.find(Category._objects, selectedObject) and arrow.Position.Y) or _objects[#_objects]._position.Y

			arrow.Position = Vector2.new(arrow.Position.X, newArrowPosition)
			newCategory:_opencategory()
		end
	elseif input.KeyCode == Enum.KeyCode.Backspace then
		if Category._closecategory then
			local previousCategory = Controller:GetPreviousCategory()
			local _objects = previousCategory._objects
			local newArrowPosition = (#_objects >= table.find(Category._objects, selectedObject) and arrow.Position.Y) or _objects[#_objects]._position.Y

			arrow.Position = Vector2.new(arrow.Position.X, newArrowPosition)

			Category:_closecategory()
		end
	elseif input.keyCode == Enum.KeyCode.Delete then
		arrow.Visible = not arrow.Visible
		Category:SetVisible(arrow.Visible)
	end
end)

return Controller
