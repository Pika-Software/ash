---@type ash.entity
local ash_entity = require( "ash.entity" )

---@type ash.entity.door
local ash_door = require( "ash.entity.door" )

---@type ash.view
local ash_view = require( "ash.view" )

---@type ash.player
local ash_player = require( "ash.player" )

---@type ash.trace
local ash_trace = require( "ash.trace" )
local trace_cast = ash_trace.cast

local Entity_IsValid = Entity.IsValid

hook.Add( "ash.entity.door.State", "DoorUnlocker", function( entity, state )
    if state ~= 0 and ash_door.isLocked( entity ) then
        ash_door.unlock( entity )
    end
end )

do

    ---@type table<integer, integer>
    local state2state = {
        [ 0 ] = 1,
        [ 1 ] = 0,
        [ 2 ] = 0,
        [ 3 ] = 1,
        [ 4 ] = 0
    }

    hook.Add( "ash.player.SelectsUseType", "Default", function( pl, entity )
        if entity:GetClass() == "prop_door_rotating" then
            return state2state[ ash_door.getState( entity ) ] or 0
        end
    end )

end

do

    local string_match = string.match

    local blacklist = {
        predicted_viewmodel = true,
        -- prop_dynamic = true,
        fog_volume = true,

        -- AI Entities
        aiscripted_schedule = true,
        assault_assaultpoint = true,
        assault_rallypoint = true,
        path_corner = true,
        path_corner_crash = true,
        path_track = true,
        scripted_scene = true,
        scripted_sentence = true,
        scripted_sequence = true,
        scripted_target = true,
        tanktrain_aitarget = true,
        tanktrain_ai = true,

        -- Function Entities
        func_dustmotes = true,
        func_rotating = true,
        func_brush = true,

        -- Game Entities
        worldspawn = true,
        game_player_equip = true,
        game_player_team = true,
        game_ragdoll_manager = true,
        game_score = true,
        game_text = true,
        game_ui = true,
        game_weapon_manager = true,
        game_zone_player = true,

        -- Light Entities
        light = true,

        -- Information Entities
        infodecal = true
    }

    ---@param pl Player
    ---@param entity Entity
    hook.Add( "ash.player.ShouldUse", "BasicalFilter - Pre", function( pl, entity )
        if entity:IsWeapon() then
            local owner = entity:GetOwner()
            if owner ~= nil and Entity_IsValid( owner ) then
                return false
            end
        end
    end, PRE_HOOK_RETURN )

    ---@param arguments table
    ---@param pl Player
    ---@param entity Entity
    hook.Add( "ash.player.ShouldUse", "BasicalFilter - Post", function( arguments, pl, entity )
        local usage_allowed = arguments[ 2 ]

        if usage_allowed == nil then
            local class_name = entity:GetClass()

            local usage_blocked = blacklist[ class_name ]
            if usage_blocked == nil then
                usage_blocked = string_match( class_name, "^info_" ) ~= nil or
                    string_match( class_name, "^trigger_" ) ~= nil or
                    string_match( class_name, "^point_" ) ~= nil or
                    string_match( class_name, "^logic_" ) ~= nil or
                    string_match( class_name, "^light_" ) ~= nil or
                    string_match( class_name, "^env_" ) ~= nil or
                    string_match( class_name, "^ai_" ) ~= nil

                blacklist[ class_name ] = usage_blocked
            end

            return not usage_blocked
        end

        return usage_allowed
    end, POST_HOOK_RETURN )

end

do

    local table_remove = table.remove

    ---@type Entity[]
    local button_list = {}

    ---@type integer
    local button_count = 0

    hook.Add( "ash.player.UsedEntity", "momentary_rot_button", function( pl, entity, is_used )
        if entity:GetClass() == "momentary_rot_button" then
            if is_used then
                button_count = button_count + 1
                button_list[ button_count ] = { pl, entity }
                return
            end

            for i = button_count, 1, -1 do
                if button_list[ i ][ 2 ] == entity then
                    button_count = button_count - 1
                    table_remove( button_list, i )
                    return
                end
            end
        end
    end )

    local entity_use = ash_entity.use

    ---@type ash.trace.Output
    ---@diagnostic disable-next-line: missing-fields
    local trace_result = {}

    ---@type ash.trace.Params
    local trace = {
        output = trace_result
    }

    local player_getUseDistance = ash_player.getUseDistance

    local view_getAimVector = ash_view.getAimVector

    hook.Add( "Tick", "momentary_rot_button", function()
        for i = button_count, 1, -1 do
            local data = button_list[ i ]
            local pl, entity = data[ 1 ], data[ 2 ]

            if Entity_IsValid( pl ) and Entity_IsValid( entity ) then
                local start = pl:EyePos()

                trace.start = start
                trace.endpos = start + view_getAimVector( pl ) * player_getUseDistance( pl )
                trace.filter = pl

                trace_cast( trace )

                if trace_result.Hit and not trace_result.HitWorld and trace_result.Entity == entity then
                    entity_use( entity, pl, pl )
                else
                    button_count = button_count - 1
                    table_remove( button_list, i )
                end
            else
                button_count = button_count - 1
                table_remove( button_list, i )
            end
        end
    end )

end
