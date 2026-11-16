---@class ash.nw3
local nw3 = {}

local registered_vars = {}
nw3.registered_vars = registered_vars


local math_clamp = math.clamp
local math_clamp = math.clamp
local types = {
	[ "uint8" ] = {
		--Write
		function( _, value )
			net.WriteUInt( math_clamp( value, 0, 255 ), 8 )
		end,

		--Read
		function( _ )
			return net.ReadUInt( 8 )
		end,
		"number",
	},
	[ "uint16" ] = {
		--Write
		function( _, value )
			net.WriteUInt( math_clamp( value, 0, 65535 ), 16 )
		end,

		--Read
		function( _ )
			return net.ReadUInt( 16 )
		end,
		"number",
	},
	[ "uint32" ] = {
		--Write
		function( _, value )
			net.WriteUInt( math_clamp( value, 0, 4294967295 ), 32 )
		end,

		--Read
		function( _ )
			return net.ReadUInt( 32 )
		end,
		"number",
	},
	[ "int8" ] = {
		--Write
		function( _, value )
			net.WriteInt( math_clamp( value, -128, 127 ), 8 )
		end,

		--Read
		function( _ )
			return net.ReadInt( 8 )
		end,
		"number",
	},
	[ "int16" ] = {
		--Write
		function( _, value )
			net.WriteInt( math_clamp( value, -32768, 32767 ), 16 )
		end,

		--Read
		function( _ )
			return net.ReadInt( 16 )
		end,
		"number",
	},
	[ "int32" ] = {
		--Write
		function( _, value )
			net.WriteInt( math_clamp( value, -2147483648, 2147483647 ), 32 )
		end,

		--Read
		function( _ )
			return net.ReadInt( 32 )
		end,
		"number",
	},
	[ "float" ] = {
		--Write
		function( _, value )
			net.WriteFloat( value )
		end,

		--Read
		function( _ )
			return net.ReadFloat( )
		end,
		"number",
	},
	[ "double" ] = {
		--Write
		function( _, value )
			net.WriteDouble( value )
		end,

		--Read
		function( )
			return net.ReadDouble( )
		end,
		"number",
	},
	[ "string" ] = {
		--Write
		function( _, value )
			net.WriteString( value )
		end,

		--Read
		function( )
			return net.ReadString( )
		end,
		"string",
	},
	[ "vector" ] = {
		--Write
		function( _, value )
			net.WriteFloat( value[ 1 ] )
			net.WriteFloat( value[ 2 ] )
			net.WriteFloat( value[ 3 ] )
		end,

		--Read
		function( )
			return Vector( net.ReadFloat( ), net.ReadFloat( ), net.ReadFloat( ) )
		end,
		"Vector",
	},
	[ "angle" ] = {
		--Write
		function( _, value )
			net.WriteFloat( value[ 1 ] )
			net.WriteFloat( value[ 2 ] )
			net.WriteFloat( value[ 3 ] )
		end,

		--Read
		function( )
			return Angle( net.ReadFloat( ), net.ReadFloat( ), net.ReadFloat( ) )
		end,
		"Angle",
	},
	[ "entity" ] = {
		--Write
		function( _, value )
			net.WriteEntity( value )
		end,

		--Read
		function( )
			return net.ReadEntity( )
		end,

		"Entity",
	},
	[ "boolean" ] = {
		--Write
		function( _, value )
			net.WriteBool( not value and false or value )
		end,

		--Read
		function( )
			return net.ReadBool()
		end,
		"boolean",
	},
}
nw3.types = types

nw3.SEND_PVS = 0
nw3.SEND_PAS = 1
nw3.SEND_ALL = 2
nw3.SEND_LOCAL = 3

--- Same as SEND_PVS, but the owner never receives the value.
--- Use it for everything the owner predicts by himself.
nw3.SEND_PVS_OTHERS = 4

local net_SendPVS = net.SendPVS
local net_SendPAS = net.SendPAS
local net_Broadcast = net.Broadcast
local net_Send = net.Send
local net_Abort = net.Abort

local Entity_GetPos = Entity.GetPos

--- [SHARED]
---
--- Returns the player who owns the entity ( player owns himself ).
---
---@param entity Entity
---@return Player?
local function getOwner( entity )
	if entity:IsPlayer() then
		---@cast entity Player
		return entity
	end

	local pl = nw3.get( entity, "owner" )

	if pl ~= nil and pl:IsValid() and pl:IsPlayer() then
		---@cast pl Player
		return pl
	end
end

nw3.getOwner = getOwner

local send_type = {
	[ nw3.SEND_PVS ] = function( entity )
		net_SendPVS( Entity_GetPos( entity ) )
	end,
	[ nw3.SEND_PAS ] = function( entity )
		net_SendPAS( Entity_GetPos( entity ) )
	end,
	[ nw3.SEND_ALL ] = function( )
		net_Broadcast()
	end,
	[ nw3.SEND_LOCAL ] = function( entity )
		local pl = getOwner( entity )

		if pl ~= nil then
			net_Send( pl )
		else
			net_Abort()
		end
	end,
	[ nw3.SEND_PVS_OTHERS ] = function( entity )
		local filter = RecipientFilter()
		filter:AddPVS( Entity_GetPos( entity ) )

		local owner = getOwner( entity )

		if owner ~= nil then
			filter:RemovePlayer( owner )
		end

		net_Send( filter )
	end,
}

---@type table< Entity, table< string, any > >
local entity_key_value = setmetatable( {}, {
    __index = function( self, entity )
        local tbl = {}

        rawset( self, entity, tbl )

        return tbl
    end
} )

nw3.entity_key_value = entity_key_value


local entity_list = {
	[ 0 ] = 0,
}

nw3.entity_list = entity_list

local entity_list_map = {}

---@type table<Entity, any[] >
local entity_values = setmetatable( {}, {
    __index = function( self, entity )
        local tbl = { [ 0 ] = 0 }

        rawset( self, entity, tbl )

        return tbl
    end
} )

nw3.entity_values = entity_values

--- [SHARED]
---
--- Registring network var type.
---
---@param string_name string
---@param var_type "uint8" | "uint16" | "uint32" | "int8" | "int16" | "int32" | "float" | "double" | "string" | "vector" | "angle" | "boolean" | "entity"
---@param send_type_id? number
function nw3.register( string_name, var_type, send_type_id )
	if registered_vars[ string_name ] then
		return
	end

	local type_data = types[ var_type ]
	if not type_data then
		error( "[NW3] Wrong type!" )
	end

	if not send_type_id then
		send_type_id = nw3.SEND_PVS
	else
		if not send_type[ send_type_id ] then
			error( "[NW3] Wrong send type!" )
		end
	end

	local send_function = send_type[ send_type_id ]

	local data = {
		type_data,
		string_name,
		send_function,
		send_type_id,
	}

	registered_vars[ string_name ] = data
end

--- [SHARED]
---
--- Checks that value matches the registered type.
---
---@param data table registered_vars entry
---@param value any
---@return boolean
function nw3.checkType( data, value )
	local expected = data[ 1 ][ 3 ]

	if expected == "Entity" then
		return isentity( value )
	end

	return type( value ) == expected
end

local checkType = nw3.checkType

--- [SHARED]
---
--- Set value by key.
---
---@param entity Entity
---@param key string
---@param value any
---@param nosend? boolean
function nw3.set( entity, key, value, nosend )
	local data = registered_vars[ key ]

	if not data then
		error( "[NW3] Unregisterd key" )
	end

	if not checkType( data, value ) then
		error( "[NW3] Wrong type: " .. type( value ) )
	end

	local keys = entity_key_value[ entity ]
	local tvalue = keys[ key ]
	local value_old

	if tvalue == nil then
		tvalue = { key, value }

		local values = entity_values[ entity ]
		local count_values = values[ 0 ] + 1

		values[ count_values ] = tvalue
		values[ 0 ] = count_values

		keys[ key ] = tvalue
	else
		value_old = tvalue[ 2 ]
	end

	tvalue[ 1 ] = key
	tvalue[ 2 ] = value

	if not entity_list_map[ entity ] then
		entity_list_map[ entity ] = true

		local count = entity_list[ 0 ] + 1

		entity_list[ 0 ] = count

		---@diagnostic disable-next-line: assign-type-mismatch
		entity_list[ count ] = entity
	end

	if value_old ~= value then
		hook.Run( "ash.nw3.Update", entity, key, value, value_old )

		if SERVER and not nosend then
			nw3.send( entity, key, value )
		end
	end
end

--- [SHARED]
---
--- Get entity value by key.
---
---@param entity Entity
---@param key string
---@param fallback? any
function nw3.get( entity, key, fallback )
	-- rawget: do not create empty tables for every entity that is only asked ( trace filters etc )
	local keys = rawget( entity_key_value, entity )

	if keys == nil then
		return fallback
	end

	local tvalue = keys[ key ]

	if tvalue == nil then
		return fallback
	end

	return tvalue[ 2 ]
end

hook.Add( "EntityRemoved", "RemoveEntityFromList", function( entity, full_update )
	if full_update then
		return
	end

	local count = entity_list[ 0 ]
	if table.removeByValue( entity_list, entity, count ) then
		count = count - 1

		entity_list[ 0 ] = count
	end

	entity_list_map[ entity ] = nil

	rawset( entity_key_value, entity, nil )
	rawset( entity_values, entity, nil )
end )

nw3.register( "owner", "entity", nw3.SEND_PVS )

return nw3
