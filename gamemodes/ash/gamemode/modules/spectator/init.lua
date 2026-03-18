local Player_SpectateEntity = Player.SpectateEntity
local Player_Spectate = Player.Spectate
local Player_Alive = Player.Alive
local Player_GetObserverMode = Player.GetObserverMode
local Player_GetObserverTarget = Player.GetObserverTarget

local Entity_SetNW2Float = Entity.SetNW2Float
local Entity_GetNW2Float = Entity.GetNW2Float

local OBS_MODE_ROAMING = _G.OBS_MODE_ROAMING
local OBS_MODE_IN_EYE = _G.OBS_MODE_IN_EYE

local hook_Run = hook.Run

---@class ash.spectator
local spectator = include( "shared.lua" )

MODULE.Networks = {
	"select_target",
}
MODULE.ClientFiles = {
    "cl_init.lua",
}

local function removeOldSpecList( ent )
	if not IsValid( ent ) then
		return
	end

	local old_ent = Player_GetObserverTarget( ent )

	if old_ent ~= nil and IsValid( old_ent ) then
		local specs = spectator.getSpectatorsForEntity( old_ent )

		specs[ ent ] = nil
	end
end

---@param ent Entity
---@return table<Player, boolean>
function spectator.getSpectatorsForEntity( ent )
	---@diagnostic disable-next-line: undefined-field
	return ent.spectators or {}
end

---@param ply Player
---@param target Entity | Player
---@param mode integer | nil
function spectator.specate( ply, target, mode )
	if mode ~= nil then
		Player_Spectate( ply, mode or OBS_MODE_ROAMING )
	else
		mode = Player_GetObserverMode( ply )
	end

	removeOldSpecList( ply )

	Player_SpectateEntity( ply, target )

	if mode == OBS_MODE_IN_EYE and target:IsPlayer() then
		target:SetupHands()
	end

	---@diagnostic disable-next-line: undefined-field
	target.spectators[ ply ] = true
end

do
	local Player_UnSpectate = Player.UnSpectate

	--- [SERVER]
	---
	--- un spectate player.
	---
	---@param ply Player
	function spectator.unSpecate( ply )
		if spectator.isSpectator( ply ) then
			removeOldSpecList( ply )
			Player_UnSpectate( ply )
		end
	end

end

net.Receive( "select_target", function( _, ply )
	if Player_Alive( ply ) then
		return
	end

	local ct = CurTime()

	if ct < Entity_GetNW2Float( ply, "ash.spectator.kd", 0 ) then
		return
	end

	if not spectator.isSpectator( ply ) then
		return
	end

	local target = net.ReadEntity()

	if hook_Run( "ash.spectator.CanPlayerSelectTarget", ply, target ) == false then
		return
	end

	if not spectator.isAllowedEntity( ply, target ) then
		return
	end

	spectator.specate( ply, target )

	Entity_SetNW2Float( ply, "ash.specatator.kd", ct + 0.3 )
end )

hook.Add( "OnEntityCreated", "Defaults", function( ent )
	ent.spectators = {}
end, PRE_HOOK )

hook.Add( "ash.entity.PlayerRemoved", "Defaults", function( ent )
	removeOldSpecList( ent )
end )

hook.Add( "ash.player.ragdoll.PostCreate", "Defaults", function( ply )
	for obs, _ in pairs( spectator.getSpectatorsForEntity( ply ) ) do
		if obs ~= ply then
			net.Start( "select_target" )
				net.WriteFloat( 5 )
			net.Send( obs )
		end
	end
end )

return spectator
