MODULE.ClientFiles = {
	"cl_init.lua",
	"shared.lua"
}

include( "shared.lua" )

---@type ash.debug
local debug = require( "ash.debug" )

---@type ash.player
local ash_player = require( "ash.player" )
local player_getUseDistance = ash_player.getUseDistance
local animator_getVelocity = ash_player.animator.getVelocity

---@type ash.view
local ash_view = require( "ash.view" )
local view_getAimVector = ash_view.getAimVector

---@type ash.trace
local ash_trace = require( "ash.trace" )
local trace_cast = ash_trace.cast

local WorldToLocal = WorldToLocal
local LocalToWorld = LocalToWorld

local Vector_Mul = Vector.Mul
local Vector_Add = Vector.Add

local Entity_IsValid = Entity.IsValid

local hook_Run = hook.Run

---@class flame_hands : SWEP
---@field m_pObject PhysObj | nil
---@field m_vOffset Vector | nil
---@field m_aOffset Angle | nil
local SWEP = SWEP

---@diagnostic disable-next-line: duplicate-set-field
function SWEP:Initialize()
	self:SetHoldType( "normal" )
	self:SetSensitivity( 1 )

	self.m_fNextThink = 0

	self.m_tShadowControl = {
        secondstoarrive     = 0.1,
        maxangular          = 1000000,
        maxangulardamp      = 1000000,
        maxspeed            = 1000000,
        maxspeeddamp        = 1000000,
        dampfactor          = 1,
        teleportdistance    = 0,
    }
end

function SWEP:StopHolding()
	self:SetHoldType( "normal" )
	self:SetSensitivity( 1 )
	self.m_pObject = nil
	self.m_vOffset = nil
	self.m_aOffset = nil
end

---@diagnostic disable-next-line: duplicate-set-field
function SWEP:SecondaryAttack()
	local pl = self:GetOwner()
	if not ( pl ~= nil and pl:IsValid() and pl:IsPlayer() and pl:Alive() ) then return end

	---@cast pl Player

	local phys_object = self.m_pObject
	if phys_object == nil or not phys_object:IsValid() then return end

	self.m_fNextThink = CurTime() + 0.5
	self:StopHolding()

	phys_object:ApplyForceCenter( animator_getVelocity( pl ) + view_getAimVector( pl ) * ( phys_object:GetMass() * 500 ) )
end

do

	---@type ash.trace.Output
	---@diagnostic disable-next-line: missing-fields
	local trace_result = {}

	---@type ash.trace.Params
	local trace = {
		count = 10,
		penetrate = true,
		output = trace_result
	}

	---@param pl Player
	---@param entity Entity
	---@return boolean
	local function is_pickupable( pl, entity )
		return entity ~= nil and Entity_IsValid( entity ) and entity:GetMoveType() == 6 and not entity:GetNoDraw() and hook_Run( "ash.player.ShouldUse", pl, entity ) ~= false
	end

	function trace.callback()
		-- debug.overlay.line( trace.start, trace.endpos, 255, 0, 0, false, 10 )

		local entity = trace_result.Entity

		---@type Entity[]
		---@diagnostic disable-next-line: assign-type-mismatch
		local filter = trace.filter

		---@diagnostic disable-next-line: param-type-mismatch
		if trace_result.HitWorld or not is_pickupable( filter[ 1 ], entity ) then
			filter[ #filter + 1 ] = entity
			return true
		end

		return false
	end

	---@diagnostic disable-next-line: duplicate-set-field
	function SWEP:Think()
		local pl = self:GetOwner()
		if not ( pl ~= nil and pl:IsValid() and pl:IsPlayer() and pl:Alive() ) then return end

		---@cast pl Player

		if ash_player.getKeyState( pl, 1 ) then
			if self.m_fNextThink > CurTime() then return end

			local view_position = pl:EyePos()

			local phys_object = self.m_pObject
			if phys_object ~= nil and phys_object:IsValid() then
				if self:GetHoldType() ~= "magic" then
					self:SetHoldType( "magic" )
				end

				if view_position:Distance( phys_object:GetPos() ) > 128 then
					self:StopHolding()
					return
				end

				self:ComputePhysics( pl, phys_object )
				return
			end

			trace.start = view_position
			trace.endpos = view_position + view_getAimVector( pl ) * player_getUseDistance( pl )
			trace.filter = { pl }

			trace_cast( trace )

			if not trace_result.Hit or trace_result.StartSolid or trace_result.HitWorld then return end

            local entity = trace_result.Entity

			---@diagnostic disable-next-line: param-type-mismatch
			if not is_pickupable( pl, entity ) then return end

			---@cast entity Entity

			local phys_bone = trace_result.PhysicsBone
			if phys_bone ~= nil then
				phys_object = entity:GetPhysicsObjectNum( phys_bone )
			else
				phys_object = entity:GetPhysicsObject()
			end

			if phys_object ~= nil and phys_object:IsValid() and phys_object:IsMotionEnabled() then
				self.m_vOffset, self.m_aOffset = WorldToLocal( phys_object:GetPos(), phys_object:GetAngles(), pl:EyePos(), view_getAimVector( pl ):Angle() )
				self.m_pObject = phys_object

				local mass = 0

				for i = 0, entity:GetPhysicsObjectCount() - 1 do
					local phys = entity:GetPhysicsObjectNum( i )
					if phys ~= nil and phys:IsValid() then
						mass = mass + phys:GetMass()
					end
				end

				self:SetSensitivity( math.clamp( ( 150 / math.ceil( mass ) ) * 0.1, 0, 1 ) )
				return
			end
		end

		if self.m_pObject ~= nil then
			self:StopHolding()
			return
		end

		if self:GetHoldType() ~= "normal" then
			self:SetHoldType( "normal" )
		end
	end

end

---@param pl Player
---@param key integer
hook.Add( "ash.player.Key", "RotationReset", function( pl, key )
	if key ~= IN_RELOAD or ash_player.getKeyUpTime( pl, key ) >= 0.1 then return end

	---@type flame_hands
	---@diagnostic disable-next-line: assign-type-mismatch
	local weapon = pl:GetActiveWeapon()
	if weapon == nil or not weapon:IsValid() or weapon:GetClass() ~= "flame_hands" then return end

	local phys_object = weapon.m_pObject
	if phys_object == nil or not phys_object:IsValid() then return end

	local view_angles = view_getAimVector( pl ):Angle()
	weapon.m_aOffset = Angle( view_angles[ 1 ], 180, 0 )
end )

---@param pl Player
---@param wheel number
hook.Add( "ash.player.MouseWheel", "DistanceController", function( pl, wheel )
	if not ash_player.getKeyState( pl, 1 ) then return end

	---@type flame_hands
	---@diagnostic disable-next-line: assign-type-mismatch
	local weapon = pl:GetActiveWeapon()
	if weapon == nil or not weapon:IsValid() or weapon:GetClass() ~= "flame_hands" then return end

	if weapon.m_vOffset == nil or weapon.m_aOffset == nil then return end

	local view_angles = view_getAimVector( pl ):Angle()
	local view_position = pl:EyePos()

	local position, angles = LocalToWorld( weapon.m_vOffset, weapon.m_aOffset, view_position, view_angles )
	Vector_Add( position, view_getAimVector( pl ) * wheel * 5 )

	local distance = position:Distance( view_position )

	if wheel > 0 then
		if distance > player_getUseDistance( pl ) then return end
	else
		local player_mins, player_maxs = pl:GetCollisionBounds()
		local object_mins, object_maxs = weapon.m_pObject:GetAABB()

		if distance < ( math.max( player_maxs[ 1 ] - player_mins[ 1 ], player_maxs[ 2 ] - player_mins[ 2 ] ) + math.max( object_maxs[ 1 ] - object_mins[ 1 ], object_maxs[ 2 ] - object_mins[ 2 ] ) ) * 0.5 then return end
	end

	weapon.m_vOffset, weapon.m_aOffset = WorldToLocal( position, angles, view_position, view_angles )
end )

---@param pl Player
---@param x number
---@param y number
hook.Add( "ash.player.Mouse", "DistanceController", function( pl, _, x, y )
	if not ash_player.getKeyState( pl, IN_RELOAD ) then return end

	---@type flame_hands
	---@diagnostic disable-next-line: assign-type-mismatch
	local weapon = pl:GetActiveWeapon()
	if weapon == nil or not weapon:IsValid() or weapon:GetClass() ~= "flame_hands" then return end

	if weapon.m_vOffset == nil or weapon.m_aOffset == nil then return end

	local view_angles = view_getAimVector( pl ):Angle()
	local view_position = pl:EyePos()

	local position, angles = LocalToWorld( weapon.m_vOffset, weapon.m_aOffset, view_position, view_angles )

	local frame_time = FrameTime()

	local sensitivity = 5
	local step = frame_time * sensitivity

	angles:RotateAroundAxis( view_angles:Up(), x * step )
	angles:RotateAroundAxis( view_angles:Right(), y * step )

	weapon.m_vOffset, weapon.m_aOffset = WorldToLocal( position, angles, view_position, view_angles )
end )

---@param pl Player
---@param phys_object PhysObj
function SWEP:ComputePhysics( pl, phys_object )
	if phys_object:IsAsleep() then
		phys_object:Wake()
	end

	local shadow_control = self.m_tShadowControl

	local player_velocity = animator_getVelocity( pl )
	Vector_Mul( player_velocity, FrameTime() * 10 )

	local view_position = pl:EyePos()
	Vector_Add( view_position, player_velocity )

	shadow_control.pos, shadow_control.angle = LocalToWorld( self.m_vOffset, self.m_aOffset, view_position, view_getAimVector( pl ):Angle() )
	shadow_control.deltatime = FrameTime()

	phys_object:ComputeShadowControl( shadow_control )
end
