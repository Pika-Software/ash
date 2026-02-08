do

    local Entity_IsValid = Entity.IsValid
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
    hook.Add( "ash.player.ShouldUse", "BasicalFilter.Pre", function( pl, entity )
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
    hook.Add( "ash.player.ShouldUse", "BasicalFilter.Post", function( arguments, pl, entity )
        local usage_allowed = arguments[ 2 ]
        if usage_allowed ~= nil then
            return usage_allowed
        end

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
    end, POST_HOOK_RETURN )

end
