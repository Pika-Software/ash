MODULE.ClientFiles = {
    "cl_init.lua",
    "shared.lua"
}

---@class flame.player
local flame_player = include( "shared.lua" )

---@type ash.model
local ash_model = require( "ash.model" )

---@type ash.player
local ash_player = require( "ash.player" )

---@type ash.player.phrases
local ash_phrases = require( "ash.player.phrases" )

---@type ash.entity
local ash_entity = require( "ash.entity" )

--- [SERVER]
---
--- Set the player's speed modifier.
---
---@param pl Player
function flame_player.setSpeedModifier( pl, modifier )
    pl:SetNW2Float( "m_flSpeedModifier", modifier )
end

local hook_Run = hook.Run
local math_max = math.max

hook.Add( "PlayerCanPickupWeapon", "Defaults", function( pl, wep )
    return true
end )

do

    ---@param pl Player
    ---@param trans boolean
    hook.Add( "ash.player.PreSpawn", "Default", function( pl, trans )
        pl:UnSpectate()

        pl:StripWeapons()
        pl:RemoveAllAmmo()

        pl:SetCanZoom( false )
        pl:AllowFlashlight( true )

        pl:SetLadderClimbSpeed( 150 )
    end )

    do

        local math_floor = math.floor
        local math_abs = math.abs

        ---@param pl Player
        hook.Add( "ash.player.SetupModel", "Default", function( pl )
            ash_entity.setPlayerColor( pl, Color( flame_player.StoRGB( pl:GetInfo( "flame_player_color" ) ) ) )

            local model_info = ash_model.get( pl:GetInfo( "flame_player_model" ) )
            pl:SetModel( model_info.model )

            pl:SetSkin( math.clamp( pl:GetInfoNum( "flame_player_skin", 0 ), 0, model_info.skin_count ) )

            local mins, maxs = model_info.mins, model_info.maxs

            local mins_x, mins_y, mins_z = mins:Unpack()
            local maxs_x, maxs_y, maxs_z = maxs:Unpack()

            local width = math_floor( math.min( math_abs( mins_x ) + math_abs( mins_y ), math_abs( maxs_x ) + math_abs( maxs_y ) ) * 0.5 )
            local height = math_floor( math_abs( maxs_z ) + mins_z )

            local hull_mins = Vector( -width, -width, 0 )
            local hull_maxs = Vector( width, width, height )

            ash_player.setHull( pl, false, hull_mins, hull_maxs )

            height = height * 0.5
            hull_maxs[ 3 ] = height

            ash_player.setHull( pl, true, hull_mins, hull_maxs )

            pl:SetStepSize( height * 0.5 )

            local scale = 1 + math.round( ( 1 - ( 1 / ( model_info.volume / 100 ) ) ) * 0.5, 2 )

            pl:SetJumpPower( 250 * scale )
            flame_player.setSpeedModifier( pl, scale )
            ash_player.setUseDistance( pl, math_floor( 85 * scale ) )

            if model_info.type == "female" then
                ash_phrases.setVoice( pl, "female01" )
            else
                ash_phrases.setVoice( pl, "male01" )
            end
        end )

    end

    for name, path in pairs( player_manager.AllValidModels() ) do
        ash_model.set( name, path )
    end

    hook.Add( "ScalePlayerDamage", "phrases", function( pl, hitgroup )
        if hitgroup == 4 or hitgroup == 5 then
            ash_phrases.play( pl, "my_arm" )
        elseif hitgroup == 6 or hitgroup == 7 then
            ash_phrases.play( pl, "my_leg" )
        else
            ash_phrases.play( pl, "pain" )
        end
    end )

    hook.Add( "PlayerDeathSound", "phrases", function( pl )
        ash_phrases.play( pl, "death" )
        return true
    end )

end

---@diagnostic disable-next-line: redundant-parameter
hook.Add( "PlayerSwitchFlashlight", "Defaults", function( arguments, pl, requested_state )
    return not requested_state or arguments[ 2 ] ~= false
end )

hook.Add( "PlayerCanSeePlayersChat", "Defaults", function( text, team_only, listener, speaker )
    if not ( listener and listener:IsValid() ) or not ( speaker and speaker:IsValid() ) then
        return true
    end

    if listener:Alive() ~= speaker:Alive() then
        return false
    end

    if team_only then
        return listener:Team() == speaker:Team()
    end

    return true
end )

do

    local speakers = {}

    setmetatable( speakers, {
        __mode = "k",
        __index = function( self, pl )
            local listeners = {}
            self[ pl ] = listeners
            setmetatable( listeners, { __mode = "k" } )
            return listeners
        end
    } )

    timer.Create( "VoiceChat", 0.5, 0, function()
        for _, speaker in player.Iterator() do
            local speaker_is_alive = speaker:Alive()
            local speaker_origin = speaker:EyePos()

            local listeners = speakers[ speaker ]

            for listener in pairs( listeners ) do
                listeners[ listener ] = nil
            end

            local rf = RecipientFilter()
            rf:AddPAS( speaker_origin )

            local pas_players = rf:GetPlayers()

            for j = 1, #pas_players, 1 do
                local listener = pas_players[ j ]
                listeners[ listener ] = speaker_is_alive == listener:Alive() and ( not speaker_is_alive or speaker_origin:Distance( listener:EyePos() ) <= 1500 )
            end
        end
    end )

    hook.Add( "PlayerCanHearPlayersVoice", "Default", function( listener, speaker )
        return speaker == listener or speakers[ speaker ][ listener ], true
    end )

end

hook.Add( "PlayerEnteredVehicle", "PrisonerPod", function( pl, vehicle, role )
    if vehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" then
        pl:SetNW2Bool( "m_bInPrisonerPod", true )
    end
end )

hook.Add( "PlayerLeaveVehicle", "PrisonerPod", function( pl )
    pl:SetNW2Bool( "m_bInPrisonerPod", false )
end )

do

    local player_isDead = ash_player.isDead
    local math_ceil = math.ceil

    local temp_vector = Vector( 0, 0, 0 )

    hook.Add( "ash.player.Landed", "Defaults", function( pl, fall_speed, in_water, trace_result )
        if player_isDead( pl ) then return end
        fall_speed = -fall_speed

        local damage_amount = hook_Run( "PlayerLandedDamage", pl, fall_speed, in_water, trace_result ) or 0
        if damage_amount == 0 then return end

        local hit_pos = trace_result.HitPos
        local damage_info = DamageInfo()

        damage_info:SetAttacker( pl )
        damage_info:SetDamageType( 32 )
        damage_info:SetDamage( damage_amount )
        damage_info:SetDamagePosition( hit_pos )

        pl:TakeDamageInfo( damage_info )

        pl:EmitSound( "Player.FallDamage", 80, math.random( 80, 120 ), math.min( 1, damage_amount / pl:Health() ), CHAN_BODY, 0, 1 )

        local fraction = 1 -- pl:GetNW2Float( "m_fModelScale", 1 )
        util.ScreenShake( hit_pos, 15, 150, 0.25 * fraction, 128 * fraction, false )

        local entity = trace_result.Entity
        if entity and entity:IsValid() and entity:GetMaxHealth() > 1 then
            temp_vector[ 3 ] = fall_speed * 0.75
            pl:SetVelocity( temp_vector )

            damage_info:ScaleDamage( 0.5 )
            entity:TakeDamageInfo( damage_info )

        end
    end, PRE_HOOK )

    hook.Add( "PlayerLandedDamage", "Defaults", function( pl, fall_speed, in_water, trace_result )
        if in_water then
            return math_max( 0, math_ceil( 0.15 * fall_speed - 180 ) )
        else
        	return math_max( 0, math_ceil( 0.25 * fall_speed - 140 ) )
        end
    end )

end

-- ---@param pl Player
-- ---@param ragdoll_entity Entity
-- hook.Add( "ash.player.ragdoll.Setup", "Defaults", function( pl, ragdoll_entity )
--     if not pl:Alive() then
--         pl:SpectateEntity( ragdoll_entity )
--         pl:Spectate( OBS_MODE_CHASE )
--     end
-- end )

hook.Add( "ash.player.ragdoll.PreCreate", "Defaults", function( pl )
    ash_player.ragdollRemove( pl )
end )

do

    ---@type table<Player, number>
    local death_times = {}
    gc.setTableRules( death_times, true )

    hook.Add( "ash.player.ShouldSpawn", "Defaults", function( pl )
        if ( CurTime() - ( death_times[ pl ] or 0 ) ) > 3 then return end
        return false
    end )

    hook.Add( "ash.player.Death", "Defaults", function( pl )
        death_times[ pl ] = CurTime()
    end, PRE_HOOK )

end

hook.Add( "ash.player.footsteps.Sound", "Defaults", function( pl, sound_position, player_shoes, material_name, selected_state, bone_id )
    local sound_level, pitch, volume = 75, 100, 0.25

    -- if selected_state == "wandering" then
    --     sound_level, pitch, volume = 40, 100, 0.25
    -- elseif selected_state == "running" then
    --     sound_level, pitch, volume = 90, 100, 1.00
    -- elseif selected_state == "falling" then
    --     sound_level, pitch, volume = 100, 100, 1.25
    -- end

    return sound_level, pitch, volume, 1
end )

---@param arguments table
---@param pl Player
---@param vehicle Entity
hook.Add( "CanPlayerEnterVehicle", "Defaults", function( arguments, pl, vehicle )
    local allowed = arguments[ 2 ]
    if allowed ~= nil then
        return allowed
    end

    return pl:Alive() and vehicle:IsValid()
end, POST_HOOK_RETURN )

hook.Add( "GravGunPickupAllowed", "Defaults", function( arguments, pl, entity )
    return arguments[ 2 ] ~= false
end, POST_HOOK_RETURN )

-- do

--     local Entity_IsPlayerHolding = Entity.IsPlayerHolding
--     local Entity_GetMoveType = Entity.GetMoveType
--     local Entity_IsValid = Entity.IsValid

--     local Player_PickupObject = Player.PickupObject

--     local queue, queue_size = {}, 0

--     hook.Add( "flame.player.PickupObject", "Defaults", function( pl, entity )
--         queue_size = queue_size + 1
--         queue[ queue_size ] = { pl, entity }
--     end )

--     hook.Add( "Tick", "PickupController", function()
--         if queue_size == 0 then return end

--         local data = queue[ queue_size ]

--         queue[ queue_size ] = nil
--         queue_size = queue_size - 1

--         local pl, entity = data[ 1 ], data[ 2 ]
--         if Entity_IsValid( pl ) and Entity_IsValid( entity ) and not Entity_IsPlayerHolding( entity ) then
--             Player_PickupObject( pl, entity )
--         end
--     end, POST_HOOK )

-- end

return flame_player
