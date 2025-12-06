local Vector = Vector
local util = util

--- [SHARED]
---
--- ash Utils Library (FFUL)
---
---@class ash.utils
local utils = {}
ash.utils = utils

do

    local prop_class_names = list.GetForEdit( "ash.prop.classnames" )

    prop_class_names.prop_physics_multiplayer = true
	prop_class_names.prop_physics_override = true
	prop_class_names.prop_dynamic_override = true
	prop_class_names.prop_dynamic = true
	prop_class_names.prop_ragdoll = true
	prop_class_names.prop_physics = true
	prop_class_names.prop_detail = true
	prop_class_names.prop_static = true

    --- [SHARED]
    ---
    --- Checks if the class name is a prop class.
    ---
    ---@param class_name string
    ---@return boolean is_prop
    function utils.isPropClass( class_name )
        return prop_class_names[ class_name ] == true
    end

end

do

    local ragdoll_class_names = list.GetForEdit( "ash.ragdoll.classnames" )

    ragdoll_class_names.prop_ragdoll = true
    ragdoll_class_names.C_ClientRagdoll = true
    ragdoll_class_names.C_HL2MPRagdoll = true
    ragdoll_class_names.hl2mp_ragdoll = true

    --- [SHARED]
    ---
    --- Checks if the class name is a ragdoll class.
    ---
    ---@param class_name string
    ---@return boolean is_ragdoll
    function utils.isRagdollClass( class_name )
        return ragdoll_class_names[ class_name ] == true
    end

end

do

    local button_class_names = list.GetForEdit( "ash.button.classnames" )

    button_class_names.momentary_rot_button = true
    button_class_names.func_rot_button = true
    button_class_names.func_button = true
    button_class_names.gmod_button = true

    --- [SHARED]
    ---
    --- Checks if the class name is a button class.
    ---
    ---@param class_name string
    ---@return boolean is_button
    function utils.isButtonClass( class_name )
        return button_class_names[ class_name ] == true
    end

end

do

    local door_class_names = list.GetForEdit( "ash.door.classnames" )

    door_class_names.prop_door_rotating_checkpoint = true
    door_class_names.prop_testchamber_door = true
    door_class_names.prop_door_rotating = true
    door_class_names.func_door_rotating = true
    door_class_names.func_door = true

    --- [SHARED]
    ---
    --- Checks if the class name is a door class.
    ---
    ---@param class_name string
    ---@return boolean is_door
    function utils.isDoorClass( class_name )
        return door_class_names[ class_name ] == true
    end

end

do

    local breakable_class_names = list.GetForEdit( "ash.breakable.classnames" )

    breakable_class_names.func_breakable_surf = true
    breakable_class_names.func_breakable = true
    breakable_class_names.func_physbox = true

    --- [SHARED]
    ---
    --- Checks if the class name is a breakable class.
    ---
    ---@param class_name string
    ---@return boolean is_breakable
    function utils.isBreakableClass( class_name )
        return breakable_class_names[ class_name ] == true
    end

end

do

    local spawnpoint_class_names = list.GetForEdit( "ash.spawnpoint.classnames" )

    -- Garry's Mod
    spawnpoint_class_names.info_player_start = true

    -- Garry's Mod (old)
    spawnpoint_class_names.gmod_player_start = true

    -- Half-Life 2: Deathmatch
    spawnpoint_class_names.info_player_deathmatch = true
    spawnpoint_class_names.info_player_combine = true
    spawnpoint_class_names.info_player_rebel = true

    -- Counter-Strike: Source & Counter-Strike: Global Offensive
    spawnpoint_class_names.info_player_counterterrorist = true
    spawnpoint_class_names.info_player_terrorist = true

    -- Day of Defeat: Source
    spawnpoint_class_names.info_player_axis = true
    spawnpoint_class_names.info_player_allies = true

    -- Team Fortress 2
    spawnpoint_class_names.info_player_teamspawn = true

    -- Insurgency
    spawnpoint_class_names.ins_spawnpoint = true

    -- AOC
    spawnpoint_class_names.aoc_spawnpoint = true

    -- Dystopia
    spawnpoint_class_names.dys_spawn_point = true

    -- Pirates, Vikings, and Knights II
    spawnpoint_class_names.info_player_pirate = true
    spawnpoint_class_names.info_player_viking = true
    spawnpoint_class_names.info_player_knight = true

    -- D.I.P.R.I.P. Warm Up
    spawnpoint_class_names.diprip_start_team_blue = true
    spawnpoint_class_names.diprip_start_team_red = true

    -- OB
    spawnpoint_class_names.info_player_red = true
    spawnpoint_class_names.info_player_blue = true

    -- Synergy
    spawnpoint_class_names.info_player_coop = true

    -- Zombie Panic! Source
    spawnpoint_class_names.info_player_human = true
    spawnpoint_class_names.info_player_zombie = true

    -- Zombie Master
    spawnpoint_class_names.info_player_zombiemaster = true

    -- Fistful of Frags
    spawnpoint_class_names.info_player_fof = true
    spawnpoint_class_names.info_player_desperado = true
    spawnpoint_class_names.info_player_vigilante = true

    -- Left 4 Dead & Left 4 Dead 2
    spawnpoint_class_names.info_survivor_rescue = true
    -- spawnpoint_class_names.info_survivor_position = true

    --- [SHARED]
    ---
    --- Checks if the class name is a spawnpoint class.
    ---
    ---@param class_name string
    ---@return boolean is_spawnpoint
    function utils.isSpawnpointClass( class_name )
        return spawnpoint_class_names[ class_name ] == true
    end

end

return utils
