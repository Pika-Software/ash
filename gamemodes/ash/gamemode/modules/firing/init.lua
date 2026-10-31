MODULE.ClientFiles = {
	"cl_init.lua",
}

MODULE.Networks = {
	"input",
	"hitbox"
}

---@class ash.firing
local firing = include "shared.lua"

import "ash.player"

---@type ash.nw3
local ash_nw3 = import "ash.nw3"

local bit_band = bit.band

local CurTime = CurTime
local Entity_GetHitBoxBone = Entity.GetHitBoxBone
local Entity_GetHitBoxBounds = Entity.GetHitBoxBounds
local Entity_GetBonePosition = Entity.GetBonePosition
local Entity_GetHitBoxCount = Entity.GetHitBoxCount

local Player_GetShootPos = Player.GetShootPos
local Player_GetActiveWeapon = Player.GetActiveWeapon

local tick_count = math.floor( 1 / engine.TickInterval( ) )
local math_randomseed = _G.math.randomseed

local players_snapshots = firing.players_snapshots

local table_remove = table.remove

---@param pl Player
hook.Add( "PlayerPostThink", "LagCompensation", function( pl )
	local ct = CurTime()
    local poseses = { }

    for j = 0, Entity_GetHitBoxCount( pl, 0 ) - 1 do
        local mins, maxs = Entity_GetHitBoxBounds( pl, j, 0 )
        local pos, ang = Entity_GetBonePosition( pl, Entity_GetHitBoxBone( pl, j, 0 ) )

        poseses[ j + 1 ] = { pos, ang, mins, maxs, pl:GetHitBoxHitGroup( j, 0 ) }
    end

    local snapshots = players_snapshots[ pl ]
    local snapshots_count = snapshots[ 0 ]

    ---@cast snapshots_count number

    if snapshots_count + 1 > tick_count then
        table_remove( snapshots, 1 )
        snapshots_count = snapshots_count - 1
    end

    snapshots_count = snapshots_count + 1
    snapshots[ snapshots_count ] = { ct, poseses }

    snapshots[ 0 ] = snapshots_count
end )

local IN_ATTACK = _G.IN_ATTACK
local IN_ATTACK2 = _G.IN_ATTACK2
local IN_RELOAD = _G.IN_RELOAD

local in_list = {
	IN_ATTACK,
	IN_ATTACK2,
	IN_RELOAD,
}

local in_list_count = #in_list

net.Receive( "input", function( _, pl )
	local time = net.ReadDouble()
	local in_mask = net.ReadUInt( 16 )
	local position = Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() )
	local angle = Angle( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() )

	local wep = Player_GetActiveWeapon( pl )

	---@wep cast ash_weapon_base

	if ( wep ~= nil and wep:IsValid() and wep.IsAshWeapon ) then
		firing.sharedFiring( pl, wep, in_mask, position, angle, time )
	end
end )



return firing
