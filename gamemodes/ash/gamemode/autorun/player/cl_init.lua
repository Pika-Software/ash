local timer_Simple = timer.Simple

local Entity = Entity
local Entity_IsValid = Entity.IsValid

local coroutine_yield = coroutine.yield
local coroutine_resume = coroutine.resume

local hook_Run = hook.Run
local Vector = Vector
local rawget = rawget
local net = net

local NULL = NULL

---@class ash.player
---@field Entity Player The local player entity.
local ash_player = include( "shared.lua" )

do

    local Player_SetHullDuck = Player.SetHullDuck
    local Player_SetHull = Player.SetHull

    --- [SERVER]
    ---
    --- Sets the player's hull.
    ---
    ---@param pl Player
    ---@param on_crouch boolean
    ---@param mins Vector
    ---@param maxs Vector
    ---@diagnostic disable-next-line: duplicate-set-field
    function ash_player.setHull( pl, on_crouch, mins, maxs )
        if on_crouch then
            Player_SetHullDuck( pl, mins, maxs )
        else
            Player_SetHull( pl, mins, maxs )
        end
    end

end

do

    local player_BitCount = ash_player.BitCount

    ---@type table<integer, function>
    local net_commands = {}

    net_commands[ 0 ] = function()
        local index = net.ReadUInt( player_BitCount )

        timer_Simple( 0, function()
            local pl = Entity( index )
            if pl ~= nil and Entity_IsValid( pl ) then
                hook.Run( "ash.player.Initialized", pl, false )
            end
        end )
    end

    -- player hull setup
    net_commands[ 1 ] = function()
        local index = net.ReadUInt( player_BitCount )
        local is_crouch = net.ReadBool()

        local mins = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
        local maxs = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )

        timer_Simple( 0, function()
            ---@type Player
            ---@diagnostic disable-next-line: assign-type-mismatch
            local pl = Entity( index )
            if pl ~= nil and Entity_IsValid( pl ) then
                ash_player.setHull( pl, is_crouch, mins, maxs )
            end
        end )
    end

    do

        local Player_AddVCDSequenceToGestureSlot = Player.AddVCDSequenceToGestureSlot
        local Player_AnimResetGestureSlot = Player.AnimResetGestureSlot
        local Player_AnimSetGestureWeight = Player.AnimSetGestureWeight
        local Player_AnimRestartGesture = Player.AnimRestartGesture

        local Entity_SelectWeightedSequence = Entity.SelectWeightedSequence
        local Entity_LookupSequence = Entity.LookupSequence

        net_commands[ 3 ] = function()
            local pl = net.ReadPlayer()
            if pl ~= nil and Entity_IsValid( pl ) then
                local slot = net.ReadUInt( 3 )
                local activity = net.ReadUInt( 32 )
                local auto_kill = net.ReadBool()

                local sequence_id = Entity_SelectWeightedSequence( pl, activity )
                if sequence_id ~= nil and sequence_id > 0 then
                    Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, ( CurTime() - net.ReadDouble() ) + net.ReadFloat(), auto_kill )
                else
                    Player_AnimRestartGesture( pl, slot, activity, auto_kill )
                end
            end
        end

        net_commands[ 4 ] = function()
            local pl = net.ReadPlayer()
            if pl ~= nil and Entity_IsValid( pl ) then
                local slot = net.ReadUInt( 3 )
                local sequence_name = net.ReadString()
                local auto_kill = net.ReadBool()

                local sequence_id = Entity_LookupSequence( pl, sequence_name )
                if sequence_id ~= nil and sequence_id > 0 then
                    Player_AddVCDSequenceToGestureSlot( pl, slot, sequence_id, ( CurTime() - net.ReadDouble() ) + net.ReadFloat(), auto_kill )
                else
                    Player_AnimResetGestureSlot( pl, slot )
                end
            end
        end

        net_commands[ 5 ] = function()
            local pl = net.ReadPlayer()
            if pl ~= nil and Entity_IsValid( pl ) then
                Player_AnimSetGestureWeight( pl, net.ReadUInt( 3 ), net.ReadFloat() )
            end
        end

    end

    net.Receive( "network", function( length )
        local cmd_fn = net_commands[ net.ReadUInt( 8 ) ]
        if cmd_fn ~= nil then
            cmd_fn( length )
        end
    end )

end

do

    local player_isInitialized = ash_player.isInitialized
    local LocalPlayer = _G.LocalPlayer

    local player_entity

    local thread = coroutine.create( function()
        ::retry_loop::

        local entity = LocalPlayer()

        if entity == nil or not Entity_IsValid( entity ) then
            coroutine_yield( false )
            goto retry_loop
        end

        ash_player.Entity = entity
        player_entity = entity

        if not player_isInitialized( entity ) then
            net.Start( "network" )
            net.WriteUInt( 0, 8 )
            net.SendToServer()

            hook.Run( "ash.player.Initialized", entity, true )
        end

        coroutine_yield( true )
    end )

    local function player_find()
        local success, is_ready = coroutine_resume( thread )
        return not success or is_ready
    end

    if not player_find() then
        hook.Add( "InitPostEntity", "PlayerInit", function()
            if player_find() then
                return
            end

            timer.Create( "await", 0.05, 0, function()
                if player_find() then
                    timer.Remove( "await" )
                end
            end )
        end )
    end

    function ash_player.isLocal( pl )
        return pl == player_entity
    end

    do

        local player_Iterator = player.Iterator

        hook.Add( "Tick", "Ticking", function()
            for _, pl in player_Iterator() do
                hook_Run( "ash.player.Think", pl, pl == player_entity )
            end
        end )

    end

end

local player_isLocal = ash_player.isLocal

do

    gameevent.Listen( "player_activate" )
    gameevent.Listen( "player_spawn" )

    local Player = Player

    ---@type table<integer, boolean>
    local player_initial_spawns = {}

    ---@type integer[]
    local player_spawns = {}

    ---@type integer
    local player_spawns_count = 0

    hook.Add( "player_activate", "ClientSideInitialSpawn", function( data )
        local user_id = data.userid
        player_initial_spawns[ user_id ] = true
        player_spawns_count = player_spawns_count + 1
        player_spawns[ player_spawns_count ] = user_id
    end, PRE_HOOK )

    -- try https://wiki.facepunch.com/gmod/player.GetByID

    hook.Add( "player_spawn", "ClientSideSpawn", function( data )
        player_spawns_count = player_spawns_count + 1
        player_spawns[ player_spawns_count ] = data.userid
    end, PRE_HOOK )

    hook.Add( "Tick", "ClientSideSpawn", function()
        for i = player_spawns_count, 1, -1 do
            local user_id = player_spawns[ i ]

            local pl = Player( user_id )
            if pl ~= nil and Entity_IsValid( pl ) then
                player_spawns_count = player_spawns_count - 1
                table.remove( player_spawns, i )

                hook_Run( "ash.player.Spawn", pl, false, player_isLocal( pl ) )

                if player_initial_spawns[ user_id ] then
                    player_initial_spawns[ user_id ] = nil
                    hook_Run( "ash.player.InitialSpawn", pl, false, player_isLocal( pl ) )
                end
            end
        end
    end, PRE_HOOK )

end

do

    local Player_isSpeaking = Player.IsSpeaking

    ---@type table<Player, boolean>
    local voice_statuses = {}

    setmetatable( voice_statuses, {
        __index = function( self, pl )
            return Player_isSpeaking( pl )
        end,
        __mode = "k"
    } )

    --- [CLIENT]
    ---
    --- Checks if the player is speaking (using voice chat).
    ---
    ---@param pl Player
    ---@return boolean is_speaking
    ---@diagnostic disable-next-line: duplicate-set-field
    function ash_player.isSpeaking( pl )
        return voice_statuses[ pl ]
    end

    hook.Add( "PlayerStartVoice", "Voice", function( pl, index )
        voice_statuses[ pl ] = true
        hook_Run( "ash.player.Speaking", pl, true, player_isLocal( pl ) )
    end, PRE_HOOK )

    hook.Add( "PlayerEndVoice", "Voice", function( pl )
        voice_statuses[ pl ] = false
        hook_Run( "ash.player.Speaking", pl, false, player_isLocal( pl ) )
    end, PRE_HOOK )

end

do

    local Player_GetActiveWeapon = Player.GetActiveWeapon

    ---@type table<Player, Weapon>
    local active_weapons = {}

    setmetatable( active_weapons, {
        __index = function( self, pl )
            return Player_GetActiveWeapon( pl ) or NULL
        end,
        __mode = "k"
    } )

    hook.Add( "ash.player.Think", "WeaponLookup", function( pl, is_local )
        local active_weapon = Player_GetActiveWeapon( pl ) or NULL
        if rawget( active_weapons, pl ) ~= active_weapon then
            if hook_Run( "ash.player.SwitchedWeapon", pl, active_weapons[ pl ], active_weapon, is_local ) == false then
                input.SelectWeapon( active_weapons[ pl ] )
            else
                active_weapons[ pl ] = active_weapon
            end
        end
    end, PRE_HOOK )

end

do

    local Entity_DrawModel = Entity.DrawModel
    local player_Iterator = player.Iterator

    ---@type table<Player, boolean>
    local render_restricted = {}
    gc.setTableRules( render_restricted, true )

    local is_local = false

    hook.Add( "PostDrawTranslucentWorld", "Render", function( _, is_depth_pass )
        for _, pl in player_Iterator() do
            is_local = player_isLocal( pl )

            if hook_Run( "ash.player.ShouldDraw", pl, false, is_local ) ~= false then
                hook_Run( "ash.player.PreDraw", pl, false, is_local, is_depth_pass )

                render_restricted[ pl ] = false

                Entity_DrawModel( pl, 1 )

                local wep = pl:GetActiveWeapon()
                if wep ~= nil and Entity_IsValid( wep ) then
                    Entity_DrawModel( wep, 1 )
                end

                -- Entity_DrawModel( entity, 4 )
                render_restricted[ pl ] = true

                hook_Run( "ash.player.DrawAppearance", pl, false, is_local, is_depth_pass )
                hook_Run( "ash.player.PostDraw", pl, false, is_local, is_depth_pass )
            end
        end
    end, POST_HOOK )

    hook.Add( "PostDrawTranslucentReflection", "Render", function( _, is_depth_pass )
        for _, pl in player_Iterator() do
            is_local = player_isLocal( pl )

            if hook_Run( "ash.player.ShouldDraw", pl, true, is_local ) ~= false then
                hook_Run( "ash.player.PreDraw", pl, true, is_local, is_depth_pass )

                render_restricted[ pl ] = false

                Entity_DrawModel( pl, 1 )

                local wep = pl:GetActiveWeapon()
                if wep ~= nil and Entity_IsValid( wep ) then
                    Entity_DrawModel( wep, 1 )
                end

                -- Entity_DrawModel( entity, 4 )
                render_restricted[ pl ] = true

                hook_Run( "ash.player.DrawAppearance", pl, true, is_local, is_depth_pass )
                hook_Run( "ash.player.PostDraw", pl, true, is_local, is_depth_pass )
            end
        end
    end, POST_HOOK )

    hook.Add( "PrePlayerDraw", "Render", function( arguments, pl )
        return arguments[ 2 ] or render_restricted[ pl ]
    end, POST_HOOK_RETURN )

end

do

    local Player_ShouldDrawLocalPlayer = Player.ShouldDrawLocalPlayer

    local Entity_GetNoDraw = Entity.GetNoDraw
    local Entity_IsDormant = Entity.IsDormant

    local player_isDead = ash_player.isDead

    hook.Add( "ash.player.ShouldDraw", "Defaults", function( pl, is_reflection, is_local )
        if is_local and not Player_ShouldDrawLocalPlayer( pl ) then return false end
        if Entity_GetNoDraw( pl ) or player_isDead( pl ) then return false end
        if Entity_IsDormant( pl ) then return false end
    end )

end

hook.Add( "PlayerButtonDown", "InputCapture", function( pl, key_id )
    hook_Run( "ash.player.Input", pl, key_id, true, player_isLocal( pl ) )
end, PRE_HOOK )

hook.Add( "PlayerButtonUp", "InputCapture", function( pl, key_id )
    hook_Run( "ash.player.Input", pl, key_id, false, player_isLocal( pl ) )
end, PRE_HOOK )

hook.Add( "AdjustMouseSensitivity", "InputCapture", function( arguments, default_sensitivity, fov, default_fov )
    local fraction = arguments[ 2 ]
    if fraction ~= nil then
        return fraction
    end

    local pl = ash_player.Entity
    if pl ~= nil and Entity_IsValid( pl ) then
        local sensitivity = hook_Run( "ash.player.MouseSensitivity", pl, default_sensitivity, fov, default_fov )
        if sensitivity ~= nil then
            return sensitivity
        end

        ---@type Weapon
        local weapon = pl:GetActiveWeapon()
        ---@diagnostic disable-next-line: undefined-field
        if weapon ~= nil and weapon.AdjustMouseSensitivity ~= nil then
            ---@diagnostic disable-next-line: undefined-field
            return weapon:AdjustMouseSensitivity( pl, default_sensitivity, fov, default_fov )
        end
    end

    return -1
end, POST_HOOK_RETURN )

return ash_player
