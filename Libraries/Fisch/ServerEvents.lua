local Windows = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/refs/heads/main/Libraries/Universal/Interface/Windows.lua"))()
local BindableEvents = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/refs/heads/main/Libraries/Dependencies/BindableEvents.lua"))()

local zones = workspace.zones
local fishing = zones.fishing
local red, green = Color3.new(0.67451, 0, 0), Color3.new(0, 0.67451, 0)
local list = {
    "Megalodon",
    "The Depths - Serpent",
    "Isonade",
    "Great White Shark",
    "Great Hammerhead Shark",
    "Whale Shark"
}

local ServerEvents = {}
ServerEvents.__index = ServerEvents

local function IsEventActive(event)
    for _, object in pairs(fishing:GetChildren()) do
        local name = object.Name

        if name == event or name:find(event) then return object, true end
    end

    return nil, false
end

function ServerEvents.new()
    local active = {
        objects = {},
        array = {}
    }
    local bindableEvent = BindableEvents:Create()
    local Window = Windows.new("Server Events")

    local objects = active.objects
    local array = active.array

    for _, event in pairs(list) do
        local object, isActive = IsEventActive(event)
        local color = red

        if isActive then 
            objects[event] = object
            array[event] = event

            color = green
        end

        Window:AddText(event, color)
    end        

    bindableEvent:Fire(active)

    local ChildAdded = fishing.ChildAdded:Connect(function(object)
        local name = object.Name

        for _, event in pairs(list) do
            if event == name or event:find(name) then 
                Window:UpdateTextColor(event, green)

                objects[event] = object
                array[event] = event

                bindableEvent:Fire(object)
            end
        end

    end)
    
    local ChildRemoved = fishing.ChildRemoved:Connect(function(object)
        local name = object.Name
        
        for _, event in pairs(array) do
            if event == name or event:find(name) then 
                Window:UpdateTextColor(event, red)

                objects[event] = nil
                array[event] = nil

                bindableEvent:Fire(object, true)
            end
        end
    end)

    local ServerEvent = setmetatable({
        _active = active,
        _bindableEvent = bindableEvent,
        _window = Window,
    }, ServerEvents)

    return ServerEvent
end

function ServerEvents:GetEventList()
    return list
end

function ServerEvents:GetActiveEvents()
    local activeEvents = self._active

    return activeEvents
end

function ServerEvents:SetVisibility(bool)
    local Window = self._window

    Window:SetVisibility(bool)
end

function ServerEvents:OnChanged(callback)
    local bindableEvent = self._bindableEvent

    bindableEvent:Connect(callback)
end

return ServerEvents