local Entity_GetClass = Entity.GetClass

---@type ash.entity
local ash_entity = import "entity"

---@class ash.spectator
local spectator = {}

local hook_Run = hook.Run

local cams = ash_entity.getByClass( "ash_camera", false )

local cams_and_players = ash_entity.filter( function( ent )
	return Entity_GetClass( ent ) == "ash_camera" or ent:IsPlayer()
end )

---@param ply Player
---@param ent Entity
---@return boolean
function spectator.isAllowedEntity( ply, ent )
	local hook_callback = hook_Run( "ash.spectator.IsAllowedEntity", ply, ent )

	if hook_callback ~= nil then
		return hook_callback
	end

	local class = Entity_GetClass( ent )

	if ply == ent then
		return false
	end

	if class == "ash_camera" then
		return true
	end

	if class == "player" then
		if ent:Alive() then
			return true
		end

		return false
	end

	return false
end

---@param ply Player
---@return Entity[]
function spectator.getAllowedEnts( ply )
	local hook_callback = hook_Run( "ash.spectator.GetAllowedEntity", ply )

	if hook_callback ~= nil then
		return hook_callback
	end

	return cams_and_players.tbl
end

do
	local table_getIndex = table.getIndex
	local Player_GetObserverTarget = Player.GetObserverTarget

	---@return Entity | nil
	function spectator.nextTarget( ply )
		local ents_list = spectator.getAllowedEnts( ply )
		local target = Player_GetObserverTarget( ply )

		if IsValid( target ) then
			local index = table_getIndex( ents_list, target )
			for i = 1, #ents_list do
				local next_target = ents_list[ i ]
				local allowed = spectator.isAllowedEntity( ply, next_target )

				if i > index and allowed then
					return next_target
				end
			end
		end
	end

	---@return Entity | nil
	function spectator.prevTarget( ply )
		local ents_list = spectator.getAllowedEnts( ply )
		local target = Player_GetObserverTarget( ply )

		if IsValid( target ) then
			local index = table_getIndex( ents_list, target )
			for i = #ents_list, 1, -1 do
				local next_target = ents_list[ i ]
				local allowed = spectator.isAllowedEntity( ply, next_target )

				if i < index and allowed then
					return next_target
				end
			end
		end
	end
end

---@return Entity | nil
function spectator.firstTarget( ply )
	local ents_list = spectator.getAllowedEnts( ply )

	for i = 1, #ents_list do
		local next_target = ents_list[ i ]
		if spectator.isAllowedEntity( ply, next_target ) then
			return next_target
		end
	end
end

---@return Entity | nil
function spectator.lastTarget( ply )
	local ents_list = spectator.getAllowedEnts( ply )

	for i = #ents_list, 1, -1 do
		local next_target = ents_list[ i ]
		if spectator.isAllowedEntity( ply, next_target ) then
			return next_target
		end
	end
end

do
	local Player_GetObserverMode = Player.GetObserverMode

	---@return boolean
	function spectator.isSpectator( ply )
		return Player_GetObserverMode( ply ) ~= OBS_MODE_NONE
	end
end

return spectator
