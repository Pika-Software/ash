---@class ash
local ash = ash

if ash.Loaded then return end
ash.Loaded = true

AddCSLuaFile( ash.ChainFile )
AddCSLuaFile( "ash/shared.lua" )
AddCSLuaFile( "ash/cl_init.lua" )

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

include( "shared.lua" )

do

    local timer_Remove = _G.timer.Remove
    local hook_Remove = _G.hook.Remove

    -- garrysmod/gamemodes/sandbox/gamemode/persistence.lua
    hook_Remove( "InitPostEntity", "PersistenceInit" )
    hook_Remove( "ShutDown", "SavePersistenceOnShutdown" )

    hook_Remove( "PersistenceSave", "PersistenceSave" )

    hook_Remove( "PersistenceLoad", "PersistenceLoad" )
    hook_Remove( "PostCleanupMap", "GMod_Sandbox_PersistanceLoad" )

    timer_Remove( "sbox_persist_change_timer" )

    -- garrysmod/lua/includes/extensions/player_auth.lua
    hook_Remove( "PlayerInitialSpawn", "PlayerAuthSpawn" ) -- purified piece of crap

    -- garrysmod/lua/includes/extensions/util/worldpicker.lua
    hook_Remove( "VGUIMousePressAllowed", "WorldPickerMouseDisable" )

end

logger:info( "Ashes calls you, %s. %s awaits.", cvars.String( "hostname", "unknown" ), ash.Chain[ 1 ].title )
