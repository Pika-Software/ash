---@class ash.nw3
local nw3 = include "shared.lua"

local registered_vars = nw3.registered_vars

local Entity_EntIndex = Entity.EntIndex

--- entity index -> { [ 0 ] = count, { key, value }, ... }
---@type table<number, table>
local unknown_entity_map = {}

net.Receive( "send", function()
	local entity_id = net.ReadUInt( 32 )
	local entity = Entity( entity_id )
	local key = net.ReadString()

	local data = registered_vars[ key ]

	if not data then
		return
	end

	local value = data[ 1 ][ 2 ]( )

	if entity ~= game.GetWorld() and not entity:IsValid() then
		local pending = unknown_entity_map[ entity_id ]

		if pending == nil then
			pending = { [ 0 ] = 0 }

			unknown_entity_map[ entity_id ] = pending
		end

		local count = pending[ 0 ] + 1

		pending[ count ] = { key, value }
		pending[ 0 ] = count

		return
	end

	nw3.set( entity, key, value )
end )

hook.Add( "InitPostEntity", "RequestData", function()
	net.Start( "send" )
	net.SendToServer()
end )

hook.Add( "ash.entity.Created", "Defaults", function( entity )
	local idx = Entity_EntIndex( entity )
	local pending = unknown_entity_map[ idx ]

	if pending then
		unknown_entity_map[ idx ] = nil

		for i = 1, pending[ 0 ] do
			local kv = pending[ i ]

			nw3.set( entity, kv[ 1 ], kv[ 2 ] )
		end
	end
end )

hook.Add( "ash.nw3.Update", "Defaults", function( entity, key, value, value_old )
	ash.Logger:debug( "nw3 update %s, key = %s, value = %s, old_value = %s", tostring( entity ), tostring( key ), tostring( value ), tostring( value_old ) )
end )

return nw3
