---@class ash
local ash = ash

if ash.Loaded then return end
ash.Loaded = true

AddCSLuaFile( "ash/cl_init.lua" )
AddCSLuaFile( ash.ChainFile )
ash.resend()

ash.reload()

local logger = ash.Logger

do

    local workshop_list, workshop_length = ash.getWorkshopDL()
    local resource_AddWorkshop = _G.resource.AddWorkshop

    for i = 1, workshop_length, 1 do
        local wsid = workshop_list[ i ]
        resource_AddWorkshop( wsid )
        logger:info( "Workshop item '%s' added to content watcher list.", wsid )
    end

end

ash.rebuild( true )

AddCSLuaFile( ash.ChecksumFile )
AddCSLuaFile( ash.WorkshopFile )

logger:info( "Ashes calls you, %s. %s awaits.", cvars.String( "hostname", "unknown" ), ash.Chain[ 1 ].title )
