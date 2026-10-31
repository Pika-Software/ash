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

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result = { }

---@type table<Entity, boolean>
local players_skip_trace = { }

---@type ash.trace.Params
local trace = {
    output = trace_result,
    mask = MASK_SHOT,
    filter = function( entity )
        if players_skip_trace[ entity ] then
            return false
        end

        return ash_nw3_get( entity, "ash.firing.LagCompensation", false )
    end
}

if CLIENT then
    trace.filter = nil
end

local math_randomseed = _G.math.randomseed

local Entity_EntIndex = Entity.EntIndex

local nw3_seqname = "ash.firing.Sequence"
ash_nw3.register( nw3_seqname, "uint16", ash_nw3.SEND_PVS )
ash_nw3.register( "ash.firing.Seed", "uint16", ash_nw3.SEND_PVS )
ash_nw3.register( "ash.firing.FireDelay", "float", ash_nw3.SEND_PVS )
ash_nw3.register( "ash.firing.Attacking1", "boolean", ash_nw3.SEND_PVS )
ash_nw3.register( "ash.firing.Attacking2", "boolean", ash_nw3.SEND_PVS )
ash_nw3.register( "ash.firing.Reloading", "boolean", ash_nw3.SEND_PVS )

ash_nw3.register( "ash.firing.LagCompensation", "boolean", ash_nw3.SEND_PVS )

local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local bit_bxor = bit.bxor
local bit_band = bit.band

local function xorshift32( x )
    x = bit_bxor( x, bit_lshift( x, 13 ))
    x = bit_bxor( x, bit_rshift( x, 17 ))
    x = bit_bxor( x, bit_lshift( x, 5 ))
    return x
end

local players_snapshots = setmetatable({ }, {
    __index = function( self, entity )
        local tbl = {[ 0 ] = 0 }

        rawset( self, entity, tbl )

        return tbl
    end
})

gc.setTableRules( players_snapshots, true )
gc.setup( players_snapshots, "Entity" )

firing.players_snapshots = players_snapshots

do
    local uint_max = 2 ^ 16

    ---@param pl Player
    ---@param min number
    ---@param max number
    function firing.randomNumber( pl, min, max )
        local seq = ash_nw3_get( pl, nw3_seqname, 1 ) + 1

        if seq > uint_max then
            seq = 1
        end

        ash_nw3_set( pl, nw3_seqname, seq )

        return min + ((( xorshift32( xorshift32( xorshift32( bit_bxor( seq, bit_lshift( ash_nw3_get( pl, "ash.firing.Seed", Entity_EntIndex( pl )), 22 )))))) % 4294967296 ) / 4294967296 ) * ( max - min )
    end
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

---@param pl Player
---@param wep ash_weapon_base
---@param in_mask number
---@param position Vector
---@param angle Angle
---@param time number
function firing.sharedFiring( pl, wep, in_mask, position, angle, time )
    if bit_band( in_mask, IN_ATTACK ) ~= 0 then
        if wep:getAutomatic( ) then
            if CurTime( ) >= wep:getDelayFire( ) then
                wep:primaryAttack( pl, position, angle, time )
            end
        else
            if not ash_nw3_get( pl, "ash.firing.Attacking1", false ) then
                if CurTime( ) >= wep:getDelayFire( ) then
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
            wep:secondaryAttack( pl, position, angle )
            ash_nw3_set( pl, "ash.firing.Attacking2", true )
        end
    else
        ash_nw3_set( pl, "ash.firing.Attacking2", false )
    end

    if bit_band( in_mask, IN_RELOAD ) ~= 0 then
        if not ash_nw3_get( pl, "ash.firing.Reloading", false ) then
            wep:reload( pl )
            ash_nw3_set( pl, "ash.firing.Reloading", true )
        end
    else
        ash_nw3_set( pl, "ash.firing.Reloading", false )
    end
end

do
    local distance_limit = 65536

    local function findSnapshotPair( pl, time )
        local snaps = players_snapshots[ pl ]
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

    local function lerpPoses( a, b, frac )
        if frac == 0 then return a end

        local out = { }

        for j = 1, #a do
            local pa, pb = a[ j ], b[ j ]

            out[ j ] = {
                LerpVector( frac, pa[ 1 ], pb[ 1 ]),
                LerpAngle( frac, pa[ 2 ], pb[ 2 ]),
                pa[ 3 ], pa[ 4 ], pa[ 5 ]
            }
        end

        return out
    end

    local function getLerpTime( pl )
        return math.max( pl:GetInfoNum( "cl_interp", 0.1 ), pl:GetInfoNum( "cl_interp_ratio", 2 ) / pl:GetInfoNum( "cl_updaterate", 30 ))
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

    function firing.fireBullet( time, owner, start, dir, dist )
        dist = dist or distance_limit

        trace.start = start
        trace.endpos = start + dir * distance_limit

        if CLIENT then
            trace.filter = owner
        end

        players_skip_trace[ owner ] = true
        trace_cast( trace )
        players_skip_trace[ owner ] = nil

        if SERVER then
            for _, pl in ash_player.iterator( true, true ) do
                if pl ~= owner then
                    local t = { }

                    local snaps = players_snapshots[ pl ]
                    local snaps_count = snaps[ 0 ]

                    local last_tick = snaps[ snaps_count ]

                    --- compensation tick
                    local target = time - getLerpTime( owner )
                    local i0, i1, frac = findSnapshotPair( pl, target )

                    if i0 then
                        local posses = lerpPoses( snaps[ i0 ][ 2 ], snaps[ i1 ][ 2 ], frac )
                        local isBreak = false
                        net.Start( "hitbox" )
                        net.WriteEntity( pl )
                        net.WriteTable( posses )
                        net.Broadcast( )

                        for i = 1, #posses do
                            local v = posses[ i ]
                            if firing.segmentIntersectsOBB( trace_result.StartPos, trace_result.HitPos, v[ 1 ], v[ 2 ], v[ 3 ], v[ 4 ] ) then
                                trace_result.Entity = pl
                                trace_result.HitGroup = v[ 5 ]

                                isBreak = true
                                break
                            end
                        end

                        if isBreak then
                            net.Start( "hitbox" )
                            net.WriteEntity( pl )
                            net.WriteTable( posses )
                            net.Broadcast( )

                            break
                        end
                    end
                end
            end
        end

        printf( "PLAYER HIT %s, HIGROUP: %s", tostring( trace_result.Entity ), hitgroups_names[ trace_result.HitGroup ] or "UNKNOWN" )

        local entity = trace_result.Entity

        if CLIENT and not ( entity ~= nil and IsValid( entity ) and ( entity:IsNPC() or entity:IsPlayer() ) ) then
            local effectdata = EffectData()
            effectdata:SetOrigin( trace_result.HitPos )
            effectdata:SetStart( trace_result.StartPos )
            effectdata:SetSurfaceProp( trace_result.SurfaceProps ) -- For the sound
            effectdata:SetEntity( trace_result.Entity ) -- The hit entity
            effectdata:SetHitBox( trace_result.HitBoxBone or 0 ) -- For the decal
            effectdata:SetDamageType( DMG_BULLET ) -- For the decal
            util.Effect( "Impact", effectdata )

            util.Decal( decals[ trace_result.MatType ] or "Impact.Concrete", trace_result.HitPos + trace_result.HitNormal, trace_result.HitPos - trace_result.HitNormal, owner )
        end

        hook.Run( "ash.firing.Result", owner, trace_result )

        return trace_result
    end
end

hook.Add( "ash.entity.PlayerCreated", "Seed", function( pl )
    ash_nw3_set( pl, "ash.firing.Seed", Entity_EntIndex( pl ) + math.random( 1, 8192 ))
    ash_nw3_set( pl, "ash.firing.LagCompensation", true )
end )

hook.Add( "ash.player.PostDeath", "Seed", function( pl )
    ash_nw3_set( pl, "ash.firing.Seed", Entity_EntIndex( pl ) + math.random( 1, 8192 ))
end )

return firing
