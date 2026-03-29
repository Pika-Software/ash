---@class ash.entity
local ash_entity = include( "shared.lua" )

local Entity_IsValid = Entity.IsValid
local hook_Run = hook.Run

do

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

end

do

    ---@type table<Entity, boolean>
    local pvs = {}

    do

        local Entity_IsDormant = Entity.IsDormant

        setmetatable( pvs, {
            __index = function( self, entity )
                return Entity_IsDormant( entity )
            end,
            __mode = "k"
        } )

    end

    --- [CLIENT]
    ---
    --- Checks if an entity is in the client's potential visibility set.
    ---
    ---@param entity Entity A valid entity to check if it is in the PVS.
    ---@return boolean is_in_pvs `true` if the entity is in the PVS, otherwise `false`.
    function ash_entity.isInPVS( entity )
        return pvs[ entity ]
    end

    hook.Add( "NotifyShouldTransmit", "PotentialVisibilitySetHandler", function( entity, shouldTransmit )
        pvs[ entity ] = shouldTransmit

        if entity:IsPlayer() then
            hook_Run( "ash.player.PVS", entity, shouldTransmit )
        else
            hook_Run( "ash.entity.PVS", entity, shouldTransmit )
        end
    end, PRE_HOOK )

end

return ash_entity
