local Settings = {}
Settings.__index = Settings

function Settings.new()
    return setmetatable({
        _settings = {}
    }, Settings)
end

function Settings:Set(name, value)
    self._settings[name] = value

    return self._settings[name]
end

function Settings:Get(name)
    return self._settings[name]
end

getgenv().Settings = Settings