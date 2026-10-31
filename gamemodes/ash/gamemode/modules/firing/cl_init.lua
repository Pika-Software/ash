---@class ash.firing
local firing = include "shared.lua"

local bit_bor = bit.bor
local bit_band = bit.band
local Angle_Forward = Angle.Forward
local math_randomseed = _G.math.randomseed

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

---@type ash.trace
local ash_trace = import "ash.trace"
local trace_cast = ash_trace.cast

---@type ash.nw3
local ash_nw3 = import "ash.nw3"

---@type ash.player
local ash_player = import "ash.player"

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result = { }

---@type ash.trace.Params
local trace = {
    mask = MASK_SHOT,
    output = trace_result
}

local dist_limit = 65536

local IN_ATTACK = _G.IN_ATTACK
local IN_ATTACK2 = _G.IN_ATTACK2
local IN_RELOAD = _G.IN_RELOAD

local in_list = {
    IN_ATTACK,
    IN_ATTACK2,
    IN_RELOAD,
}

local in_list_count = #in_list

local is_automatic = false
local is_automatic2 = false
local is_attack1 = false
local is_attack2 = false

hook.Add( "Tick", "Prediction", function( )
    local pl = LocalPlayer( )

    if not pl:IsValid( ) then
        return
    end

    local ct = CurTime( )
    local in_mask = 0

    for i = 1, in_list_count do
        local input = in_list[ i ]
        if Player_KeyDown( pl, input ) then
            in_mask = bit_bor( in_mask, input )
        end
    end

    local angle = Entity_EyeAngle( pl )
    local position = Player_GetShootPos( pl )

    local wep = Player_GetActiveWeapon( pl )

    ---@cast wep ash_weapon_base

    if ( wep ~= nil and wep:IsValid( ) and wep.IsAshWeapon ) then
        firing.sharedFiring( pl, wep, in_mask, position, angle, ct )
    end

    net.Start( "input", true )
    net.WriteDouble( CurTime( ))
    net.WriteUInt( in_mask, 16 )

    net.WriteFloat( position[ 1 ])
    net.WriteFloat( position[ 2 ])
    net.WriteFloat( position[ 3 ])

    net.WriteFloat( angle[ 1 ])
    net.WriteFloat( angle[ 2 ])
    net.WriteFloat( angle[ 3 ])
    net.SendToServer( )
end )

local hitboxes = { }
local hitboxes_count = 0

local hitboxes_client = { }
local hitboxes_client_count = 0

local hitboxes_time = 0
net.Receive( "hitbox", function( )
    local pl = net.ReadEntity( )
    local t = net.ReadTable( )

    hitboxes_time = CurTime( ) + 30

    hitboxes_count = hitboxes_count + 1
    hitboxes[ hitboxes_count ] = t
end )


local hitgroups_names = {
    [ HITGROUP_HEAD ] = "HITGROUP_HEAD",
    [ HITGROUP_CHEST ] = "HITGROUP_CHEST",
    [ HITGROUP_STOMACH ] = "HITGROUP_STOMACH",
    [ HITGROUP_LEFTARM ] = "HITGROUP_LEFTARM",
    [ HITGROUP_LEFTLEG ] = "HITGROUP_LEFTLEG",
    [ HITGROUP_RIGHTARM ] = "HITGROUP_RIGHTARM",
    [ HITGROUP_RIGHTLEG ] = "HITGROUP_RIGHTLEG",
}

---@param owner Player
---@param result TraceResult
hook.Add( "ash.firing.Result", "ClientHits", function( owner, result )
    for _, pl in ash_player.iterator( true, true ) do
        if pl ~= owner then
            local poseses = { }

            for j = 0, Entity_GetHitBoxCount( pl, 0 ) - 1 do
                local mins, maxs = Entity_GetHitBoxBounds( pl, j, 0 )
                local pos, ang = Entity_GetBonePosition( pl, Entity_GetHitBoxBone( pl, j, 0 ) )

                local isHit = firing.segmentIntersectsOBB( result.StartPos, result.HitPos, pos, ang, mins, maxs )
                local hitgroup = pl:GetHitBoxHitGroup( j, 0 )
                local hitgroup_name = hitgroups_names[ hitgroup ]

                poseses[ j + 1 ] = { pos, ang, mins, maxs, hitgroup, isHit and Color( 255, 0, 0 ) or color_white }
            end

            hitboxes_client_count = hitboxes_client_count + 1
            hitboxes_client[ hitboxes_client_count ] = poseses
        end
    end
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

        for j = 1, #data do
            local v = data[ j ]

            render.DrawWireframeBox( v[ 1 ], v[ 2 ], v[ 3 ], v[ 4 ], v[ 6 ], true )
        end
    end

    for i = 1, hitboxes_count do
        local data = hitboxes[ i ]

        for j = 1, #data do
            local v = data[ j ]

            render.DrawWireframeBox( v[ 1 ], v[ 2 ], v[ 3 ], v[ 4 ], color_yellow, true )
        end
    end

end )

return firing
