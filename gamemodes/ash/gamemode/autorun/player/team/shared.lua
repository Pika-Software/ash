---@class ash
local ash = ash

local string_match = string.match

local Entity = Entity
local entity_GetNW2Var = Entity.GetNW2Var
local entity_SetNW2Var = Entity.SetNW2Var

--- [SHARED]
---
--- ash Team Library
---
---@class ash.player.team
---@field List ash.player.team.TeamData[] A list of all teams.
---@field Count integer The number of teams.
local ash_team = {
	List = {},
	Count = 0
}

---@class ash.player.team.TeamData
---@field name string
---@field color Color
---@field score integer
---@field mates string[]
---@field mate_count integer
---@field models string[]
---@field model_count integer
---@field players Player[]
---@field player_count integer

--- [SHARED]
---
--- A list of all teams.
---
---@type ash.player.team.TeamData[]
local team_list = ash_team.List

--- [SHARED]
---
--- The number of teams.
---
---@type integer
local team_count = ash_team.Count

---@type ash.player.team.TeamData
---@diagnostic disable-next-line: missing-fields
local team_metatable = {}

--- [SHARED]
---
--- Gets a list of all teams.
---
---@return string[] team_list
---@return integer team_count
function ash_team.getAll()
	return team_list, team_count
end

--- [SHARED]
---
--- Gets the number of teams.
---
---@return integer team_count
function ash_team.getCount()
	return team_count
end

--- [SHARED]
---
--- Initializes a team.
---
---@param team_name string
---@return ash.player.team.TeamData
local function team_init( team_name )
	for i = 1, team_count, 1 do
		local team_data = team_list[ i ]
		if team_data.name == team_name then
			return team_data
		end
	end

	team_count = team_count + 1
	ash_team.Count = team_count

	---@diagnostic disable-next-line: missing-fields
	local team_data = setmetatable( {
		name = team_name
	}, team_metatable )

	team_list[ team_count ] = team_data

	return team_data
end

---@type table<string, integer>
local player_counts = {}

setmetatable( player_counts, {
	__index = function()
		return 0
	end
} )

---@type table<string, Player[]>
local players = {}

setmetatable( players, {
	---@param team_name string
	__index = function( self, team_name )
		team_init( team_name )

		local player_list = {}
		self[ team_name ] = player_list
		return player_list
	end
} )

hook.Add( "EntityNetworkedVarChanged", "Default", function( entity, name, previous_value, new_value )
	if entity ~= nil and entity:IsValid() then
		if name == "ash.player.team" then
			if previous_value == nil then
				previous_value = "none"
			end

			if new_value == nil then
				new_value = "none"
			end

			if entity:IsPlayer() then
				local previous_team = players[ previous_value ]
				local previous_size = player_counts[ previous_value ]

				for i = previous_size, 1, -1 do
					if previous_team[ i ] == entity then
						previous_size = previous_size - 1
						table.remove( previous_team, i )
						break
					end
				end

				player_counts[ previous_value ] = previous_size

				local new_team = players[ new_value ]

				local new_size = player_counts[ new_value ] + 1
				new_team[ new_size ] = entity

				player_counts[ new_value ] = new_size

				hook.Run( "ash.PlayerTeamChanged", entity, new_value, previous_value )
				return
			end

			hook.Run( "ash.EntityTeamChanged", entity, new_value, previous_value )
			return
		end

		return
	end

	local team_name = string_match( name, "ash%.team%.([^.]+)%.score" )
	if team_name == nil then
		return
	end

	hook.Run( "ash.TeamScoreChanged", team_name, tonumber( previous_value or 0, 10 ), tonumber( new_value or 0, 10 ) )
end, 1 )

hook.Add( "EntityRemoved", "Default", function( entity, full_update )
	if full_update or entity == nil or not entity:IsValid() then return end

	if entity:IsPlayer() then
		local team_name = entity_GetNW2Var( entity, "ash.player.team", "none" )
		if team_name == "none" then return end

		local player_list = players[ team_name ]
		local team_size = player_counts[ team_name ]

		for i = team_size, 1, -1 do
			if player_list[ i ] == entity then
				team_size = team_size - 1
				table.remove( player_list, i )
				break
			end
		end

		player_counts[ team_name ] = team_size
	end
end, 1 )

local GetGlobal2Int = GetGlobal2Int
local SetGlobal2Int = SetGlobal2Int
local color_white = color_white
local math_min = math.min

---@type table<string, Color[]>
local colors = {}

setmetatable( colors, {
	__index = function( self, team_name )
		self[ team_name ] = color_white
		return color_white
	end
} )

---@type table<string, string[]>
local mates = {}

setmetatable( mates, {
	__index = function( self, team_name )
		local mate_lst = {}
		self[ team_name ] = mate_lst
		return mate_lst
	end
} )

---@type table<string, integer>
local mate_counts = {}

setmetatable( mate_counts, {
	__index = function()
		return 0
	end
} )

---@type table<string, table<string, boolean>>
local is_mates = {}

setmetatable( is_mates, {
	__index = function( self, team_name )
		local is_mate = {}
		self[ team_name ] = is_mate
		return is_mate
	end
} )

---@type table<string, string[]>
local models = {}

setmetatable( models, {
	__index = function( self, team_name )
		local model_lst = {}
		self[ team_name ] = model_lst
		return model_lst
	end
} )

---@type table<string, integer>
local model_counts = {}

setmetatable( model_counts, {
	__index = function()
		return 0
	end
} )

--- [SHARED]
---
--- Gets the score of the specified team.
---
---@param team_name string
---@return integer score
local function getScore( team_name )
	return GetGlobal2Int( "ash.player.team." .. team_name .. ".score", 0 )
end

ash_team.getScore = getScore

--- [SHARED]
---
--- Returns the team name of the player as a string.
---
---@param entity Entity
---@return string | "none" team_name The team name of the player or "none" if not set.
function ash_team.getTeam( entity )
	return entity_GetNW2Var( entity, "ash.player.team", "none" )
end

if SERVER then

	--- [SERVER]
	---
	--- Sets the team name of the player.
	---
	---@param entity Entity
	---@param team_name string The team name to set for the player.
	function ash_team.setTeam( entity, team_name )
		entity_SetNW2Var( entity, "ash.player.team", team_name or "none" )
	end

	--- [SERVER]
	---
	--- Sets the score of the specified team.
	---
	---@param team_name string
	---@param score integer
	local function setScore( team_name, score )
		SetGlobal2Int( "ash.player.team." .. team_name .. ".score", score )
	end

	ash_team.setScore = setScore

	--- [SERVER]
	---
	--- Adds the specified score to the team's current score.
	---
	--- If the resulting score is less than 0, it will be set to 0.
	---
	---@param team_name string
	---@param score integer
	local function addScore( team_name, score )
		return setScore( team_name, math_min( 0, getScore( team_name ) + score ) )
	end

	ash_team.addScore = addScore

	--- [SERVER]
	---
	--- Takes the specified score from the team's current score.
	---
	--- If the resulting score is less than 0, it will be set to 0.
	---
	---@param team_name string
	---@param score integer
	function ash_team.takeScore( team_name, score )
		return addScore( team_name, -score )
	end

end

--- [SHARED]
---
--- Gets a list of all players in the specified team.
---
---@param team_name string
---@return Player[]
function ash_team.getMembers( team_name )
	return players[ team_name ]
end

--- [SHARED]
---
--- Gets a list of all players in the specified team and its mate teams.
---
---@param team_name string
---@param filter fun( ply: Player ): boolean
---@return Player[], integer
function ash_team.getMates( team_name, filter )
	---@type Player[]
	local team_mates = {}

	---@type integer
	local team_mates_count = 0

	local player_list = players[ team_name ]
	if player_list == nil then
		return team_mates, team_mates_count
	end

	for i = 1, player_counts[ team_name ], 1 do
		local ply = player_list[ i ]
		if filter == nil or filter( ply ) then
			team_mates_count = team_mates_count + 1
			team_mates[ team_mates_count ] = ply
		end
	end

	local mate_lst = team_mates[ team_name ]
	if mate_lst == nil then
		return team_mates, team_mates_count
	end

	for i = 1, mate_counts[ team_name ], 1 do
		local mate_team_name = mate_lst[ i ]
		local mate_team = players[ mate_team_name ]
		if mate_team ~= nil then
			for j = 1, player_counts[ mate_team_name ], 1 do
				local ply = mate_team[ j ]
				if filter == nil or filter( ply ) then
					team_mates_count = team_mates_count + 1
					team_mates[ team_mates_count ] = ply
				end
			end
		end
	end

	return team_mates, team_mates_count
end

--- [SHARED]
---
--- Gets a list of all player models for the specified team.
---
---@param team_name string
---@param mate_team_name string
---@return boolean is_mate
function ash_team.isMate( team_name, mate_team_name )
	return is_mates[ team_name ][ mate_team_name ] == true or team_name == mate_team_name
end

--- [SHARED]
---
--- Gets the number of mate teams for the specified team.
---
---@param team_name string
---@return Color clr
function ash_team.getColor( team_name )
	return colors[ team_name ]
end

--- [SHARED]
---
--- Sets the color for the specified team.
---
---@param team_name string
---@param color Color
function ash_team.setColor( team_name, color )
	colors[ team_name ] = color
end

---@diagnostic disable-next-line: inject-field
function team_metatable:__index( key )
	if key == "color" then
		return colors[ self.name ]
	elseif key == "mate_count" then
		return mate_counts[ self.name ]
	elseif key == "mates" then
		return mates[ self.name ]
	elseif key == "model_count" then
		return model_counts[ self.name ]
	elseif key == "models" then
		return models[ self.name ]
	elseif key == "player_count" then
		return player_counts[ self.name ]
	elseif key == "player" then
		return players[ self.name ]
	elseif key == "score" then
		return getScore( self.name )
	end
end

---@class ash.player.team.TeamOptions
---@field name string
---@field color Color
---@field score integer | nil
---@field mates string[] | nil
---@field models string[] | nil

--- [SHARED]
---
--- Gets the number of mate teams for the specified team.
---
---@param team_options ash.player.team.TeamOptions
---@return ash.player.team.TeamData team_data
function ash_team.register( team_options )
	local team_name = team_options.name

	colors[ team_name ] = team_options.color

	if SERVER then
		ash_team.setScore( team_name, team_options.score or 0 )
	end

	local mate_lst = team_options.mates
	if mate_lst ~= nil then
		---@type string[]
		local team_mates = {}

		---@type integer
		local team_mates_count = 0

		---@type table<string, boolean>
		local is_mate = {}

		for i = 1, #mate_lst, 1 do
			local mate_team_name = mate_lst[ i ]
			is_mate[ mate_team_name ] = true

			team_mates_count = team_mates_count + 1
			team_mates[ team_mates_count ] = mate_team_name
		end

		mate_counts[ team_name ] = team_mates_count
		mates[ team_name ] = team_mates
		is_mates[ team_name ] = is_mate
	end

	local model_lst = team_options.models
	if model_lst ~= nil then
		---@type string[]
		local team_models = {}

		---@type integer
		local model_count = 0

		for i = 1, #model_lst, 1 do
			model_count = model_count + 1
			team_models[ model_count ] = model_lst[ i ]
		end

		model_counts[ team_name ] = model_count
		models[ team_name ] = team_models
	end

	local team_data = team_init( team_name )
	hook.Run( "ash.TeamRegistered", team_name, team_data )
	return team_data
end

return ash_team
