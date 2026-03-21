local net = net
local IsFirstTimePredicted = IsFirstTimePredicted

local Entity_SetNW2Float = Entity.SetNW2Float
local Entity_GetNW2Float = Entity.GetNW2Float


---@class ash.spectator
local spectator = include( "shared.lua" )

hook.Add( "KeyRelease", "Defaults", function ( ply, key )
	if not IsFirstTimePredicted() then
		return
	end

	if CurTime() < Entity_GetNW2Float( ply, "ash.spectator.kd", 0 ) then
		return
	end

	if not spectator.isSpectator( ply ) then
		return
	end

	if key == IN_ATTACK then
		local next_target = spectator.nextTarget( ply )

		if next_target == nil then
			next_target = spectator.firstTarget( ply )
		end

		if next_target ~= nil and IsValid( next_target ) then
			net.Start( "select_target" )
				net.WriteEntity( next_target )
			net.SendToServer()
		end
	elseif key == IN_ATTACK2 then
		local prev_target = spectator.prevTarget( ply )

		if prev_target == nil then
			prev_target = spectator.lastTarget( ply )
		end

		if prev_target ~= nil and IsValid( prev_target ) then
			net.Start( "select_target" )
				net.WriteEntity( prev_target )
			net.SendToServer()
		end
	end
end )

net.Receive( "select_target", function()
	local ply = LocalPlayer()

	timer.Simple( net.ReadFloat(), function()
		local next_target = spectator.nextTarget( ply )

		if next_target == nil then
			next_target = spectator.firstTarget( ply )
		end

		if next_target ~= nil and IsValid( next_target ) then
			net.Start( "select_target" )
				net.WriteEntity( next_target )
			net.SendToServer()
		end
	end )
end )

return spectator
