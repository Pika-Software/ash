---@class ash.entity
local ash_entity = include( "shared.lua" )

local Entity_IsValid = Entity.IsValid

local net = net
local net_ReadUInt = net.ReadUInt

---@type table<integer, function>
local net_commands = {}

net_commands[ 1 ] = function()
    local entity = net.ReadEntity()
    if entity ~= nil and Entity_IsValid( entity ) then
        ash_entity.resetPoseParameters( entity, false )
    end
end

net_commands[ 2 ] = function()
    local entity = net.ReadEntity()
    if entity ~= nil and Entity_IsValid( entity ) then
        ash_entity.setPoseParameter( entity, net_ReadUInt( 16 ), net.ReadDouble(), false )
    end
end

net.Receive( "network", function()
    local cmd_fn = net_commands[ net_ReadUInt( 8 ) ]
    if cmd_fn ~= nil then
        cmd_fn()
    end
end )

return ash_entity
