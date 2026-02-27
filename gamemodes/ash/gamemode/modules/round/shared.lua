---@class ash.round
local round = {}

local round_stack = {}
local round_stack_count = 0

---@class ash.round.map
local round_map = {}

local CreateConVar = CreateConVar
local timer_Create = timer.Create
local timer_UnPause = timer.UnPause
local timer_Pause = timer.Pause
local table_Empty = _G.table.Empty
local hook_Run = hook.Run
local CurTime = CurTime
local math_max = math.max
local GetGlobal2Float = GetGlobal2Float
local SetGlobal2Float = SetGlobal2Float


--- [SHARED]
---
--- Create round stack
---
---@param data table
function round.createRoundStack( data )
	table_Empty( round_map )

	for i = 1, #data do
		local v = data[ i ]
		local name = v.name
		v.id = i
		---@diagnostic disable-next-line: param-type-mismatch
		v.convar = CreateConVar( "ash_round_time_" .. name, v.time, v.convar_flags or 0, "", 0 )

		round_map[ name ] = v
	end

	round_stack_count = #data
	round_stack = data

	return data
end

--- [SHARED]
---
--- Get time round left
---
---@return integer time left
function round.getTimeLeft()
	local ct = CurTime()
	return math_max( GetGlobal2Float( "ash.round.time", ct ) - ct, 0 )
end

--- [SHARED]
---
--- Get round current type
---
---@return string round_type
function round.getRoundType()
	return GetGlobal2String( "ash.round.type", "" )
end

---@return ash.round.map
function round.getRoundMap(  )
	return round_map
end

if SERVER then

	--- [SERVER]
	---
	--- Start next round type
	---
	---@param old string
	---@return boolean Start or no
	function round.next( old )
		local data = round_map[ old ]

		if data == nil then
			ErrorNoHalt( "error next type round!" )
			return false
		end

		local next_type = data.next
		if next_type then
			local type_next = type( next_type )
			if type_next == "string" then
				round.start( type_next )
			elseif type_next == "function" then
				round.start( next_type( data ) )
			end

			return true
		end

		local id_next = data.id + 1

		if id_next > round_stack_count then
			id_next = 1
		end

		round.start( round_stack[ id_next ].name )

		return true
	end

	--- [SERVER]
	---
	--- Start new round by type
	---
	---@param round_type string
	---@param time integer | nil
	function round.start( round_type, time )
		local data = round_map[ round_type ]

		if data == nil then
			error( "Unknown round type!" )
		end

		time = time or data.convar:GetFloat()

		SetGlobal2String( "ash.round.type", round_type )
		SetGlobal2Float( "ash.round.time", CurTime() + time )

		hook_Run( "ash.round.start", data )

		if data.start then
			data.start( data )
		end

		timer_Create( "ash_round", time, 1, function()
			if data.callback then
				data.callback( data )
			end

			hook_Run( "ash.round.end", data )

			if data.canStartNext then
				if data.canStartNext( data ) == false then
					return
				end
			end

			round.next( round_type )
		end )
	end

	--- [SERVER]
	---
	--- pause round true / false
	---
	---@param bool boolean
	function round.pause( bool )
		if bool then
			timer_Pause( "ash_round" )

			SetGlobal2Bool( "ash_round", true )
		else
			timer_UnPause( "ash_sound" )

			SetGlobal2Bool( "ash_round", false )
		end
	end
end

return round
