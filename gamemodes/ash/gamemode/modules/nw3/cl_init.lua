---@class ash.nw3
local nw3 = include "shared.lua"

local types = nw3.types
local registered_vars = nw3.registered_vars

local Entity_EntIndex = Entity.EntIndex

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
	if entity ~= nil then
		if entity ~= game.GetWorld() then
			if not entity:IsValid() then
				unknown_entity_map[ entity_id ] = { key, value }

				return
			end
		end
	end

	nw3.set( entity, key, value )
end )

hook.Add( "InitPostEntity", "RequestData", function()
	net.Start( "send" )
	net.SendToServer()
end )

hook.Add( "ash.entity.Created", "Defaults", function( entity )
	local idx = Entity_EntIndex( entity )
	local data = unknown_entity_map[ idx ]

	if data then
		nw3.set( entity, data[ 1 ], data[ 2 ] )

		unknown_entity_map[ idx ] = nil
	end
end )

hook.Add( "ash.nw3.Update", "Defaults", function( entity, key, value, value_old )
	ash.Logger:debug( "nw3 update %s, key = %s, value = %s, old_value = %s", tostring( entity ), tostring( key ), tostring( value ), tostring( value_old ) )
end )

return nw3
