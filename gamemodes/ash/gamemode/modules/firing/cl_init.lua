---@class ash.firing
local firing = include "shared.lua"

local bit_bor = bit.bor

local Entity_GetHitBoxBone = Entity.GetHitBoxBone
local Entity_GetHitBoxBounds = Entity.GetHitBoxBounds
local Entity_GetBonePosition = Entity.GetBonePosition
local Entity_GetHitBoxCount = Entity.GetHitBoxCount
local Entity_EntIndex = Entity.EntIndex
local Entity_EyeAngle = Entity.EyeAngles

local Player_KeyDown = Player.KeyDown
local Player_GetShootPos = Player.GetShootPos
local Player_GetActiveWeapon = Player.GetActiveWeapon

local CurTime = CurTime

---@type ash.player
local ash_player = import "ash.player"

local developer = GetConVar( "developer" )

assert( developer ~= nil, "developer convar not found" )

local in_list = {
    IN_ATTACK,
    IN_ATTACK2,
    IN_RELOAD,
}

local in_list_count = 3

do
    local seq = 0
    local acked = 0

    --- Not acked inputs: [ 0 ] = count, [ i ] = { seq, time, in_mask, weapon_index, position, angle }
    --- Sequence is contiguous, so only the first one is sent.
    local history = { [ 0 ] = 0 }
    local history_limit = 8

    net.Receive( "input_ack", function( )
        acked = net.ReadUInt( 32 )
    end )

    ---@param shift number how many of the oldest inputs to drop
    local function historyShift( shift )
        local count = history[ 0 ]
        local new_count = count - shift

        for i = 1, new_count do
            history[ i ] = history[ i + shift ]
        end

        for i = new_count + 1, count do
            history[ i ] = nil
        end

        history[ 0 ] = new_count
    end

    hook.Add( "Tick", "Prediction", function( )
        local pl = LocalPlayer( )

        if not pl:IsValid( ) then
            return
        end

        -- server got these, no need to send them again
        local count = history[ 0 ]
        local shift = 0

        while shift < count and history[ shift + 1 ][ 1 ] <= acked do
            shift = shift + 1
        end

        if shift > 0 then
            historyShift( shift )
        end

        local wep = Player_GetActiveWeapon( pl )

        if pl:Alive( ) and wep ~= nil and wep:IsValid( ) and wep.IsAshWeapon then
            ---@cast wep ash_weapon_base

            local ct = CurTime( )
            local in_mask = 0

            for i = 1, in_list_count do
                local input = in_list[ i ]

                if Player_KeyDown( pl, input ) then
                    in_mask = bit_bor( in_mask, input )
                end
            end

            local position = Player_GetShootPos( pl )
            local angle = Entity_EyeAngle( pl )

            local weapon_angle = wep.getShootAngle

            if weapon_angle ~= nil then
                angle = weapon_angle( wep, angle ) or Entity_EyeAngle( pl )
            end

            if history[ 0 ] >= history_limit then
                historyShift( 1 )
            end

            seq = seq + 1

            local new_count = history[ 0 ] + 1

            history[ new_count ] = { seq, ct, in_mask, Entity_EntIndex( wep ), position, angle }
            history[ 0 ] = new_count

            firing.sharedFiring( pl, wep, in_mask, position, angle, ct, seq )
        end

        count = history[ 0 ]

        if count == 0 then
            return
        end

        net.Start( "input", true )
        net.WriteUInt( history[ 1 ][ 1 ], 32 )
        net.WriteUInt( count, 5 )

        for i = 1, count do
            local c = history[ i ]

            net.WriteDouble( c[ 2 ] )
            net.WriteUInt( c[ 3 ], 16 )
            net.WriteUInt( c[ 4 ], 13 )

            local pos = c[ 5 ]

            net.WriteDouble( pos[ 1 ] )
            net.WriteDouble( pos[ 2 ] )
            net.WriteDouble( pos[ 3 ] )

            local ang = c[ 6 ]

            net.WriteDouble( ang[ 1 ] )
            net.WriteDouble( ang[ 2 ] )
            net.WriteDouble( ang[ 3 ] )
        end

        net.SendToServer( )
    end )
end

--- Debug hitboxes. Each entry is { [ 0 ] = count, { pos, ang, mins, maxs, hitgroup, color }, ... }
local hitboxes = { }
local hitboxes_count = 0

local hitboxes_client = { }
local hitboxes_client_count = 0

local hitboxes_time = 0

net.Receive( "hitbox", function( )
    local pl = net.ReadEntity( )
    local count = net.ReadUInt( 8 )

    local poses = { [ 0 ] = count }

    for i = 1, count do
        poses[ i ] = { net.ReadVector( ), net.ReadAngle( ), net.ReadVector( ), net.ReadVector( ) }
    end

    hitboxes_time = CurTime( ) + 30

    hitboxes_count = hitboxes_count + 1
    hitboxes[ hitboxes_count ] = poses
end )

---@param owner Player
---@param result TraceResult
hook.Add( "ash.firing.Result", "ClientHits", function( owner, result )
    if not developer:GetBool( ) then
        return
    end

    for _, pl in ash_player.iterator( true, true ) do
        if pl ~= owner then
            local count = Entity_GetHitBoxCount( pl, 0 )
            local poses = { [ 0 ] = count }

            for j = 0, count - 1 do
                local mins, maxs = Entity_GetHitBoxBounds( pl, j, 0 )
                local pos, ang = Entity_GetBonePosition( pl, Entity_GetHitBoxBone( pl, j, 0 ) )

                local is_hit = firing.segmentIntersectsOBB( result.StartPos, result.HitPos, pos, ang, mins, maxs )

                poses[ j + 1 ] = { pos, ang, mins, maxs, pl:GetHitBoxHitGroup( j, 0 ), is_hit and Color( 255, 0, 0 ) or color_white }
            end

            hitboxes_client_count = hitboxes_client_count + 1
            hitboxes_client[ hitboxes_client_count ] = poses
        end
    end

    -- client hits are cleared by the same timer as server ones
    hitboxes_time = CurTime( ) + 30
end )

local color_yellow = Color( 255, 255, 0 )

hook.Add( "PostDrawOpaqueRenderables", "Hitbox", function( )
    if hitboxes_time > 0 then
        if CurTime( ) > hitboxes_time then
            hitboxes_time = 0

            hitboxes_client_count = 0
            hitboxes_count = 0

            table.clearIndexes( hitboxes )
            table.clearIndexes( hitboxes_client )
        end
    end

    for i = 1, hitboxes_client_count do
        local data = hitboxes_client[ i ]

        for j = 1, data[ 0 ] do
            local v = data[ j ]

            render.DrawWireframeBox( v[ 1 ], v[ 2 ], v[ 3 ], v[ 4 ], v[ 6 ], true )
        end
    end

    for i = 1, hitboxes_count do
        local data = hitboxes[ i ]

        for j = 1, data[ 0 ] do
            local v = data[ j ]

            render.DrawWireframeBox( v[ 1 ], v[ 2 ], v[ 3 ], v[ 4 ], color_yellow, true )
        end
    end
end )

return firing
