---@class ash.firing
local firing = { }

---@type ash.nw3
local ash_nw3 = import "ash.nw3"

---@type ash.player
local ash_player = import "ash.player"

local ash_nw3_get = ash_nw3.get
local ash_nw3_set = ash_nw3.set

---@type ash.trace
local ash_trace = import "ash.trace"
local trace_cast = ash_trace.cast

local developer = GetConVar( "developer" )

assert( developer ~= nil, "developer convar not found" )

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result = { }

---@type Entity?
local trace_owner = nil

--- Same filter on both sides:
--- shooter is ignored, and on server players are ignored too,
--- because they are tested later against rewound hitboxes.
---@type ash.trace.Params
local trace = {
    output = trace_result,
    mask = MASK_SHOT,
    filter = function( entity )
        if entity == trace_owner then
            return false
        end

        if SERVER and ash_nw3_get( entity, "ash.firing.LagCompensation", false ) then
            return false
        end

        return true
    end
}

local Entity_EntIndex = Entity.EntIndex

-- Predicted by owner himself, so owner must never receive server values: SEND_PVS_OTHERS.
ash_nw3.register( "ash.firing.FireDelay", "float", ash_nw3.SEND_PVS_OTHERS )
ash_nw3.register( "ash.firing.Attacking1", "boolean", ash_nw3.SEND_PVS_OTHERS )
ash_nw3.register( "ash.firing.Attacking2", "boolean", ash_nw3.SEND_PVS_OTHERS )
ash_nw3.register( "ash.firing.Reloading", "boolean", ash_nw3.SEND_PVS_OTHERS )

-- Seed is set once on player creation and every client must know it.
ash_nw3.register( "ash.firing.Seed", "uint16", ash_nw3.SEND_ALL )

-- Server only, never sent.
ash_nw3.register( "ash.firing.LagCompensation", "boolean", ash_nw3.SEND_PVS )

local bit_bor = bit.bor
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local bit_bxor = bit.bxor
local bit_band = bit.band

local in_allowed = bit_bor( IN_ATTACK, IN_ATTACK2, IN_RELOAD )

--- Input bits that firing cares about.
firing.in_allowed = in_allowed

--- Set before every weapon call, used by firing.randomNumber.
firing.seq = 0
firing.rand_index = 0

local compensation_entities = { [ 0 ] = 0 }
firing.compensation_entities = compensation_entities

---@type table< Entity, boolean >
local compensation_entities_map = {  }
firing.compensation_entities_map = compensation_entities_map

local function xorshift32( x )
    x = bit_bxor( x, bit_lshift( x, 13 ))
    x = bit_bxor( x, bit_rshift( x, 17 ))
    x = bit_bxor( x, bit_lshift( x, 5 ))
    return x
end

local entities_snapshots = setmetatable({ }, {
    __index = function( self, entity )
        local tbl = {[ 0 ] = 0 }

        rawset( self, entity, tbl )

        return tbl
    end
})

gc.setTableRules( entities_snapshots, true )
gc.setup( entities_snapshots, "Entity" )

firing.entities_snapshots = entities_snapshots


--- Deterministic random: depends only on player seed, input sequence and call index,
--- so client and server get the same number for the same shot, no matter how many
--- packets were lost before it.
---
---@param pl Player
---@param min number
---@param max number
function firing.randomNumber( pl, min, max )
    local index = firing.rand_index + 1

    firing.rand_index = index

    local seed = ash_nw3_get( pl, "ash.firing.Seed", Entity_EntIndex( pl ) )
    local x = bit_bxor( firing.seq, bit_lshift( seed, 16 ), index * 2654435761, 0x9E3779B9 )

    x = xorshift32( xorshift32( xorshift32( x ) ) )

    return min + (( x % 4294967296 ) / 4294967296 ) * ( max - min )
end

---@param start_pos Vector
---@param end_pos Vector
---@param box_pos Vector
---@param box_ang Angle
---@param mins Vector
---@param maxs Vector
function firing.segmentIntersectsOBB( start_pos, end_pos, box_pos, box_ang, mins, maxs )
    local s = WorldToLocal( start_pos, angle_zero, box_pos, box_ang )
    local e = WorldToLocal( end_pos, angle_zero, box_pos, box_ang )
    local d = e - s

    local tmin, tmax = 0, 1

    for i = 1, 3 do
        local si, di = s[ i ], d[ i ]
        local lo, hi = mins[ i ], maxs[ i ]

        if math.abs( di ) < 1e-8 then
            if si < lo or si > hi then return false end
        else
            local t1 = ( lo - si ) / di
            local t2 = ( hi - si ) / di
            if t1 > t2 then t1, t2 = t2, t1 end

            if t1 > tmin then tmin = t1 end
            if t2 < tmax then tmax = t2 end

            if tmin > tmax then return false end
        end
    end

    local hitLocal = s + d * tmin
    local hitWorld = LocalToWorld( hitLocal, angle_zero, box_pos, box_ang )

    return true, hitWorld, tmin
end

--- Updates button states without running any weapon logic.
--- Used when the input can not be executed ( weapon changed, player is dead ),
--- so states do not get stuck and stay equal on both sides.
---
---@param pl Player
---@param in_mask number
function firing.updateButtons( pl, in_mask )
    ash_nw3_set( pl, "ash.firing.Attacking1", bit_band( in_mask, IN_ATTACK ) ~= 0 )
    ash_nw3_set( pl, "ash.firing.Attacking2", bit_band( in_mask, IN_ATTACK2 ) ~= 0 )
    ash_nw3_set( pl, "ash.firing.Reloading", bit_band( in_mask, IN_RELOAD ) ~= 0 )
end

--- Runs one input step. Client and server must call it with the same arguments.
---
---@param pl Player
---@param wep ash_weapon_base
---@param in_mask number
---@param position Vector
---@param angle Angle
---@param time number time of the input in shooter timeline
---@param cseq? number input sequence, used as random seed
function firing.sharedFiring( pl, wep, in_mask, position, angle, time, cseq )
    -- the whole step lives in the timeline of the shooter
    firing.time = time
    firing.seq = cseq or 0

    if bit_band( in_mask, IN_ATTACK ) ~= 0 then
        if wep:getAutomatic( ) then
            if time >= wep:getDelayFire( ) then
                firing.rand_index = 0
                wep:primaryAttack( pl, position, angle, time )
            end
        else
            if not ash_nw3_get( pl, "ash.firing.Attacking1", false ) then
                if time >= wep:getDelayFire( ) then
                    firing.rand_index = 0
                    wep:primaryAttack( pl, position, angle, time )
                end
            end
        end

        ash_nw3_set( pl, "ash.firing.Attacking1", true )
    else
        ash_nw3_set( pl, "ash.firing.Attacking1", false )
    end

    if bit_band( in_mask, IN_ATTACK2 ) ~= 0 then
        if not ash_nw3_get( pl, "ash.firing.Attacking2", false ) then
            firing.rand_index = 0
            wep:secondaryAttack( pl, position, angle )
            ash_nw3_set( pl, "ash.firing.Attacking2", true )
        end
    else
        ash_nw3_set( pl, "ash.firing.Attacking2", false )
    end

    if bit_band( in_mask, IN_RELOAD ) ~= 0 then
        if not ash_nw3_get( pl, "ash.firing.Reloading", false ) then
            firing.rand_index = 0
            wep:reload( pl )
            ash_nw3_set( pl, "ash.firing.Reloading", true )
        end
    else
        ash_nw3_set( pl, "ash.firing.Reloading", false )
    end

    local tick = wep.tick

    if tick ~= nil then
        firing.rand_index = 0
        tick( wep, in_mask, position, angle, time )
    end

    firing.time = nil
end

do
    local distance_limit = 65536

    ---@return number? i0
    ---@return number? i1
    ---@return number? frac
    local function findSnapshotPair( pl, time )
        local snaps = entities_snapshots[ pl ]
        local count = snaps[ 0 ]

        if count == 0 then return end

        if time <= snaps[ 1 ][ 1 ] then
            return 1, 1, 0
        end

        if time >= snaps[ count ][ 1 ] then
            return count, count, 0
        end

        for i = count - 1, 1, -1 do
            local t0 = snaps[ i ][ 1 ]

            if t0 <= time then
                local t1 = snaps[ i + 1 ][ 1 ]
                return i, i + 1, ( time - t0 ) / ( t1 - t0 )
            end
        end
    end

    --- Poses table: [ 0 ] = count, [ i ] = { pos, ang, mins, maxs, hitgroup }
    local function lerpPoses( a, b, frac )
        if frac == 0 then return a end

        local count = a[ 0 ]
        local out = { [ 0 ] = count }

        for j = 1, count do
            local pa, pb = a[ j ], b[ j ]

            out[ j ] = {
                LerpVector( frac, pa[ 1 ], pb[ 1 ]),
                LerpAngle( frac, pa[ 2 ], pb[ 2 ]),
                pa[ 3 ], pa[ 4 ], pa[ 5 ]
            }
        end

        return out
    end

    local Player_GetInfoNum = Player.GetInfoNum
    local function getLerpTime( pl )
        return math.max( Player_GetInfoNum( pl, "cl_interp", 0.1 ), Player_GetInfoNum( pl, "cl_interp_ratio", 2 ) / Player_GetInfoNum( pl, "cl_updaterate", 30 ) )
    end

    local hitgroups_names = {
        [ HITGROUP_HEAD ] = "HITGROUP_HEAD",
        [ HITGROUP_CHEST ] = "HITGROUP_CHEST",
        [ HITGROUP_STOMACH ] = "HITGROUP_STOMACH",
        [ HITGROUP_LEFTARM ] = "HITGROUP_LEFTARM",
        [ HITGROUP_LEFTLEG ] = "HITGROUP_LEFTLEG",
        [ HITGROUP_RIGHTARM ] = "HITGROUP_RIGHTARM",
        [ HITGROUP_RIGHTLEG ] = "HITGROUP_RIGHTLEG",
    }

    local decals = {
        [ MAT_CONCRETE ] = "Impact.Concrete",
        [ MAT_METAL ] = "Impact.Metal",
        [ MAT_WOOD ] = "Impact.Wood",
        [ MAT_GLASS ] = "Impact.Glass",
        [ MAT_SAND ] = "Impact.Sand",
        [ MAT_DIRT ] = "Impact.Sand",
        [ MAT_TILE ] = "Impact.Concrete",
        [ MAT_PLASTIC ] = "Impact.Concrete",
    }

    --- Debug only. Format is read in cl_init.lua
    local function sendHitbox( pl, poses )
        local count = poses[ 0 ]

        net.Start( "hitbox" )
        net.WriteEntity( pl )
        net.WriteUInt( count, 8 )

        for i = 1, count do
            local pose = poses[ i ]

            net.WriteVector( pose[ 1 ] )
            net.WriteAngle( pose[ 2 ] )
            net.WriteVector( pose[ 3 ] )
            net.WriteVector( pose[ 4 ] )
        end

        net.Broadcast( )
    end

    ---@param time number shooter time of the shot
    ---@param owner Player
    ---@param start Vector
    ---@param dir Vector
    ---@param dist? number
    function firing.fireBullet( time, owner, start, dir, dist )
        dist = dist or distance_limit

        trace.start = start
        trace.endpos = start + dir * dist

        trace_owner = owner
        trace_cast( trace )
        trace_owner = nil

        if SERVER then
            -- what the shooter saw: his time minus interpolation
            local target = time - getLerpTime( owner )

            local start_pos = trace_result.StartPos
            local hit_pos = trace_result.HitPos

            local best_t = 2
            local best_entity = nil
            local best_poses = nil
            local best_group = 0
            local best_pos = nil

            for i = 1, compensation_entities[ 0 ] do
                local entity = compensation_entities[ i ]
                if entity ~= owner then
                    local snaps = entities_snapshots[ entity ]
                    local i0, i1, frac = findSnapshotPair( entity, target )

                    if i0 then
                        local poses = lerpPoses( snaps[ i0 ][ 2 ], snaps[ i1 ][ 2 ], frac )

                        for i = 1, poses[ 0 ] do
                            local v = poses[ i ]
                            local is_hit, hit_world, t = firing.segmentIntersectsOBB( start_pos, hit_pos, v[ 1 ], v[ 2 ], v[ 3 ], v[ 4 ] )

                            -- closest hitbox among all players, not the first one in iteration order
                            if is_hit and t < best_t then
                                best_t = t
                                best_entity = entity
                                best_poses = poses
                                best_group = v[ 5 ]
                                best_pos = hit_world
                            end
                        end
                    end
                end
            end

            if best_entity ~= nil then
                trace_result.Entity = best_entity
                trace_result.HitGroup = best_group
                trace_result.HitPos = best_pos
                trace_result.Hit = true

                if developer:GetBool() then
                    sendHitbox( best_entity, best_poses )

                    printf( "PLAYER HIT %s, HIGROUP: %s", tostring( best_entity ), hitgroups_names[ best_group ] or "UNKNOWN" )
                end
            end
        end

        local entity = trace_result.Entity

        if CLIENT and not ( entity ~= nil and IsValid( entity ) and ( entity:IsNPC() or entity:IsPlayer() ) ) then
            local effectdata = EffectData()
            effectdata:SetOrigin( trace_result.HitPos )
            effectdata:SetStart( trace_result.StartPos )
            effectdata:SetSurfaceProp( trace_result.SurfaceProps )
            effectdata:SetEntity( trace_result.Entity )
            effectdata:SetHitBox( trace_result.HitBoxBone or 0 )
            effectdata:SetDamageType( DMG_BULLET )
            util.Effect( "Impact", effectdata )

            util.Decal( decals[ trace_result.MatType ] or "Impact.Concrete", trace_result.HitPos + trace_result.HitNormal, trace_result.HitPos - trace_result.HitNormal, owner )
        end

        hook.Run( "ash.firing.Result", owner, trace_result )

        return trace_result
    end
end

---@return number time
function firing.curTime()
    return firing.time or CurTime()
end

if SERVER then
    -- Seed is set once: it reaches everybody long before the first shot.
    -- Uniqueness of every shot comes from the input sequence, not from the seed.
    hook.Add( "ash.entity.PlayerCreated", "Seed", function( pl )
        ash_nw3_set( pl, "ash.firing.Seed", ( Entity_EntIndex( pl ) + math.random( 1, 8192 ) ) % 65536 )
        ash_nw3_set( pl, "ash.firing.LagCompensation", true, true )
    end )
end

return firing
