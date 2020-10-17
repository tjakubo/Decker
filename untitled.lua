PlayerZone = {}
PlayerZone.__index = PlayerZone

function PlayerZone:new(someData)
    local obj = {
        someData = someData
    }

    setmetatable(obj, self)
    return obj
end

setmetatable(PlayerZone, {__call = function(_, ...) return PlayerZone:new(...) end})

function PlayerZone:getData()
    return self.someData
end

PlayerZone('test')
local t = PlayerZone:new()
t('test')