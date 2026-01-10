
MODULE.ClientFiles = {
    "cl_init.lua",
    "shared.lua"
}

---@class flame.player
local flame_player = include( "shared.lua" )
local hook_Run = hook.Run

hook.Add( "CanPlayerSuicide", "Defaults", function( pl )
    return true
end )

hook.Add( "PlayerCanPickupWeapon", "Defaults", function( pl, wep )
    return true
end )

---@type ash.model
local ash_model = require( "ash.model" )

---@type ash.player
local ash_player = require( "ash.player" )

---@type ash.player.voice.phrases
local ash_phrases = require( "ash.player.voice.phrases" )

---@type ash.entity
local ash_entity = require( "ash.entity" )

do

    ---@param pl Player
    ---@param trans boolean
    hook.Add( "PrePlayerSpawn", "Default", function( pl, trans )
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
        hook.Add( "PlayerSetupModel", "Default", function( pl )
            ash_entity.setPlayerColor( pl, Color( flame_player.StoRGB( pl:GetInfo( "flame_player_color" ) ) ) )

            local model_info = ash_model.get( pl:GetInfo( "flame_player_model" ) )
            pl:SetModel( model_info.model )

            pl:SetSkin( math.clamp( pl:GetInfoNum( "flame_player_skin", 0 ), 0, model_info.skin_count ) )

            local scale = model_info.scale
            pl:SetNW2Float( "m_fModelScale", scale )

            local mins, maxs = model_info.mins, model_info.maxs

            local maxs_x, maxs_y, maxs_z = maxs:Unpack()
            local mins_z = mins[ 3 ]

            local width = math_floor( ( math_abs( maxs_x ) + math_abs( maxs_y ) ) * 0.5 )
            local height = math_floor( math_abs( maxs_z ) )

            local bottom = math_floor( math_abs( mins_z ) )
            if mins_z < 0 then
                bottom = -bottom
            end

            local hull_mins = Vector( -width, -width, bottom )
            local hull_maxs = Vector( width, width, height )

            ash_player.setHull( pl, false, hull_mins, hull_maxs )

            height = height * 0.5 -- 0.75
            hull_maxs[ 3 ] = height

            ash_player.setHull( pl, true, hull_mins, hull_maxs )

            local bone_count = model_info.bone_count
            local bones = model_info.bones

            local root_height = 16

            for i = 1, bone_count, 1 do
                local bone_info = bones[ i ]
                if bone_info.id == 0 then
                    root_height = bone_info.postion[ 3 ] * 0.5
                    break
                end
            end

            pl:SetStepSize( root_height )
            pl:SetJumpPower( 250 * scale )

            if model_info.type == "female" then
                ash_phrases.setVoice( pl, "female01" )
            else
                ash_phrases.setVoice( pl, "male01" )
            end

            -- ash_player.setHullSize( pl, false, 32, 32, 96 )
            -- ash_player.setHullSize( pl, true, 32, 32, 32 )
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

do

    local player_isDead = ash_player.isDead
    local math_ceil = math.ceil
    local math_max = math.max

    local temp_vector = Vector( 0, 0, 0 )

    hook.Add( "PlayerLanded", "Defaults", function( pl, fall_speed, in_water, trace_result )
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

        local fraction = pl:GetNW2Float( "m_fModelScale", 1 )
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

---@param pl Player
---@param ragdoll_entity Entity
hook.Add( "PlayerSetupRagdoll", "Defaults", function( pl, ragdoll_entity )
    pl:SpectateEntity( ragdoll_entity )
    pl:Spectate( OBS_MODE_CHASE )
end )

do

    ---@type table<Player, number>
    local death_times = {}
    gc.setTableRules( death_times, true )

    hook.Add( "ShouldPlayerSpawn", "Defaults", function( pl )
        if ( CurTime() - ( death_times[ pl ] or 0 ) ) > 3 then return end
        return false
    end )

    hook.Add( "PostPlayerDeath", "Defaults", function( pl )
        death_times[ pl ] = CurTime()
    end, PRE_HOOK )

end

return flame_player
