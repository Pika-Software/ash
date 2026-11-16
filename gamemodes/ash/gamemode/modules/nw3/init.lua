---@class ash.nw3
local nw3 = include "shared.lua"

MODULE.ClientFiles = {
	"cl_init.lua",
}

MODULE.Networks = {
	"send",
}

---@type ash.player
local ash_player = import "player"

---@type ash.bsp
local ash_bsp = import "ash.bsp"

local entity_values = nw3.entity_values

local registered_vars = nw3.registered_vars

local checkType = nw3.checkType
local getOwner = nw3.getOwner

local Entity_EntIndex = Entity.EntIndex

--- [SERVER]
---
--- Send key value data to clients.
---
---@param entity Entity
---@param key string
---@param value any
---@param pl? Player
---@param force? boolean send even if the receiver is excluded as the owner ( full sync )
function nw3.send( entity, key, value, pl, force )
	local data = registered_vars[ key ]
	if not data then
		error( "[NW3] Unregisterd key" )
	end

	if not checkType( data, value ) then
		error( "[NW3] Wrong type: " .. type( value ) )
	end

	local send_id = data[ 4 ]
	local has_target = pl ~= nil and pl:IsValid()

	if has_target and not force then
		---@cast pl Player

		-- owner predicts these values by himself, server value must never overwrite it
		if send_id == nw3.SEND_PVS_OTHERS and getOwner( entity ) == pl then
			return
		end

		if send_id == nw3.SEND_LOCAL and getOwner( entity ) ~= pl then
			return
		end
	end

	net.Start( "send" )
	net.WriteUInt( Entity_EntIndex( entity ), 32 )
	net.WriteString( key )

	data[ 1 ][ 1 ]( entity, value )

	if has_target then
		---@cast pl Player
		net.Send( pl )
	else
		data[ 3 ]( entity )
	end
end

--- [SERVER]
---
--- Sends all SEND_PVS_OTHERS values of the entity to its owner.
--- Owner never receives them on change, so call it when the owner gets the entity ( weapon deploy ).
---
---@param entity Entity
function nw3.syncOwner( entity )
	local owner = getOwner( entity )

	if owner == nil then
		return
	end

	local data = entity_values[ entity ]

	for j = 1, data[ 0 ] do
		local kv = data[ j ]
		local data_for_key = registered_vars[ kv[ 1 ] ]

		if data_for_key and data_for_key[ 4 ] == nw3.SEND_PVS_OTHERS then
			nw3.send( entity, kv[ 1 ], kv[ 2 ], owner, true )
		end
	end
end

local entity_list = nw3.entity_list

local map = ash_bsp.CurrentMap

local Entity_GetPos = Entity.GetPos

--- Player entered new cluster: send him only what he can see now, and only to him.
hook.Add( "ash.bsp.PlayerChangeCluster", "PVSSend", function( pl, position )
	for i = 1, entity_list[ 0 ] do
		local entity = entity_list[ i ]

		---@diagnostic disable-next-line: cast-type-mismatch
		---@cast entity Entity

		if entity ~= nil and entity:IsValid() then
			local data = entity_values[ entity ]
			local position_entity = Entity_GetPos( entity )

			for j = 1, data[ 0 ] do
				local kv = data[ j ]
				local key = kv[ 1 ]

				local data_for_key = registered_vars[ key ]

				if data_for_key then
					local typ = data_for_key[ 4 ]

					if ( typ == nw3.SEND_PVS or typ == nw3.SEND_PVS_OTHERS ) and map:PVSCheck( position, position_entity ) then
						nw3.send( entity, key, kv[ 2 ], pl )
					elseif typ == nw3.SEND_PAS and map:PASCheck( position, position_entity ) then
						nw3.send( entity, key, kv[ 2 ], pl )
					end
				end
			end
		end
	end
end )

do
	concommand.Add( "nw3_trace", function( pl, _, args )
		pl:PrintMessage( HUD_PRINTCONSOLE, tostring( pl:GetEyeTrace().Entity ) )
	end )

	concommand.Add( "nw3_kv", function( pl, _, args )
		if not pl:IsSuperAdmin() then
			return
		end

		local entity = Entity( tonumber( args[ 1 ] or "-1" ) or -1 )

		if entity ~= nil and entity:IsValid() then
			local key = args[ 2 ]
			if key then
				local value = tonumber( args[ 3 ] or "0" ) or 0

				nw3.set( entity, key, value )
			end
		end
	end )
end

---@type table<Player, boolean>
local player_requested = {}
gc.setTableRules( player_requested, true )
gc.setup( player_requested, "Player" )

net.Receive( "send", function( _, pl )
	if player_requested[ pl ] then
		return
	end

	player_requested[ pl ] = true

	for i = 1, entity_list[ 0 ] do
		local entity = entity_list[ i ]

		---@diagnostic disable-next-line: cast-type-mismatch
		---@cast entity Entity

		if entity ~= nil and entity:IsValid() then
			local data = entity_values[ entity ]

			for j = 1, data[ 0 ] do
				local kv = data[ j ]
				local key = kv[ 1 ]

				local data_for_key = registered_vars[ key ]

				if data_for_key then
					local tp = data_for_key[ 4 ]

					if tp == nw3.SEND_ALL then
						nw3.send( entity, key, kv[ 2 ], pl )
					end
				end
			end
		end
	end
end )


return nw3
