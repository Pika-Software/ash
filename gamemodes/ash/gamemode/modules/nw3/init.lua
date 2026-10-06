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

local entity_values = nw3.entity_values

local registered_vars = nw3.registered_vars

---@table table<Player, boolean>
local players_delay_request = {}

local Entity_EntIndex = Entity.EntIndex

--- [SERVER]
---
--- Send key value data to clients.
---
---@param entity Entity
---@param key string
---@param value any
---@param pl? Player
function nw3.send( entity, key, value, pl )
	local data = registered_vars[ key ]
	if not data then
		error( "[NW3] Unregisterd key" )
	end

	local key_type = type( value )
	if key_type ~= data[ 1 ][ 3 ] then
		error( "[NW3] Unregisterd type: " .. key_type )
	end

	net.Start( "send" )
	net.WriteUInt( Entity_EntIndex( entity ) , 32 )
	net.WriteString( key )

	data[ 1 ][ 1 ]( entity, value )
	if pl ~= nil and pl:IsValid() then
		net.Send( pl )
	else
		data[ 3 ]( entity, pl )
	end
end

local entity_list = nw3.entity_list

timer.Create( "ash.nw3.pvs_pas", 2, 0, function()
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
					if tp == nw3.SEND_PAS or tp == nw3.SEND_PVS then
						nw3.send( entity, key, kv[ 2 ] )
					end
				end
			end
		end
	end
end )

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
