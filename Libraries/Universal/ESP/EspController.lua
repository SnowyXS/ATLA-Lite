local Players = game:GetService("Players")

local PlayerESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Universal/ESP/Player.lua"))()
--local Entity = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/main/Libraries/Universal/ESP/Entity.lua"))()

local Controller = {}
Controller.__index = Controller

function Controller.new(player)
    local NewController = setmetatable({
        _playerList = {},
        _entityList = {}
    }, Controller)

    Players.PlayerAdded:Connect(function(player)
        NewController:AddPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        NewController:RemovePlayer(player)
    end)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            NewController:AddPlayer(player)
        end
    end

    RunService.RenderStepped:Connect(function()
        for _, EspObject in pairs(players) do
            EspObject:Render()
        end
    end)

    return NewController
end

function Controller:AddPlayer(player)
    local players = self._playerList
    
    players[player] = Player.new(player)
end

function Controller:RemovePlayer(player)
    local players = self._playerList
    local EspObjects = players[player]

    EspObjects:Remove()

    players[player] = nil
end

function Controller:GetPlayerList()
    return self._playerList
end

return Controller