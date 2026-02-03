local hook_Run = hook.Run
local util = util

---@class ash.entity.damage
local ash_damage = include( "shared.lua" )

---@type ash.entity
local ash_entity = require( "ash.entity" )

do

	local util_BlastDamage = util.BlastDamage
    local util_Effect = util.Effect
    local EffectData = EffectData
    local math_ceil = math.ceil

	--- [SERVER]
	---
	--- Creates an explosion at the given position.
	---
	---@param origin Vector
	---@param radius number
	---@param damage number
	---@param attacker Entity
	---@param inflictor Entity
	function ash_damage.explosion( origin, radius, damage, attacker, inflictor )
        if inflictor == nil then
            inflictor = attacker
        end

        local fx = EffectData()
		fx:SetOrigin( origin )

		local fx_scale = math_ceil( radius / 125 )
		fx:SetRadius( fx_scale )
		fx:SetScale( fx_scale )

		fx:SetMagnitude( math_ceil( damage / 18.75 ) )

		util_Effect( "Sparks", fx )
		util_Effect( "Explosion", fx )

		util_BlastDamage( inflictor, attacker, origin, radius, damage )
	end

end

local DamageInfo_GetDamageForce = DamageInfo.GetDamageForce
local DamageInfo_GetDamageType = DamageInfo.GetDamageType
local DamageInfo_GetDamage = DamageInfo.GetDamage
local DamageInfo_SetDamage = DamageInfo.SetDamage

local damage_isExplosion = ash_damage.isExplosion
local damage_isNeverGib = ash_damage.isNeverGib

local Entity_GetClass = Entity.GetClass
local Vector_Length = Vector.Length

local utils_isRagdollClass = ash_entity.isRagdollClass
local utils_isButtonClass = ash_entity.isButtonClass
local utils_isPropClass = ash_entity.isPropClass
local utils_isDoorClass = ash_entity.isDoorClass

local vector_origin = vector_origin

---@param arguments any[]
---@param entity Entity
---@param damage_info CTakeDamageInfo
---@diagnostic disable-next-line: redundant-parameter
hook.Add( "EntityTakeDamage", "DamageHandler", function( arguments, entity, damage_info )
	if hook_Run( "PreEntityTakeDamage", entity, damage_info ) == false then
		return true
	end

	local damage_type = DamageInfo_GetDamageType( damage_info )

	if damage_isExplosion( damage_type ) then
		DamageInfo_SetDamage( damage_info, DamageInfo_GetDamage( damage_info ) + Vector_Length( DamageInfo_GetDamageForce( damage_info ) ) / 256 )
	end

	local class_name = Entity_GetClass( entity )

	if class_name == "player" then
		if hook_Run( "PrePlayerTakeDamage", entity, damage_info ) == false or
			hook_Run( "PlayerTakeDamage", entity, damage_info ) == false then
			return true
		end

		hook_Run( "PostPlayerTakeDamage", entity, damage_info )
		return false
	end

	if utils_isRagdollClass( class_name ) then
		if hook_Run( "PreRagdollTakeDamage", entity, damage_info, class_name ) == false or
			hook_Run( "RagdollTakeDamage", entity, damage_info, class_name ) == false then
			return true
		end

		hook_Run( "PostRagdollTakeDamage", entity, damage_info, class_name )
		return false
	end

	if damage_isNeverGib( damage_type ) then
		damage_info:SetDamageForce( vector_origin )
		damage_info:ScaleDamage( 0.25 )
	end

	if utils_isButtonClass( class_name ) then
		if hook_Run( "PreButtonTakeDamage", entity, damage_info, class_name ) == false or
			hook_Run( "ButtonTakeDamage", entity, damage_info, class_name ) == false then
			return true
		end

		hook_Run( "PostButtonTakeDamage", entity, damage_info, class_name )
		return false
	end

	if utils_isDoorClass( class_name ) then
		if hook_Run( "PreDoorTakeDamage", entity, damage_info, class_name ) == false or
			hook_Run( "DoorTakeDamage", entity, damage_info, class_name ) == false then
			return true
		end

		hook_Run( "PostDoorTakeDamage", entity, damage_info, class_name )
		return false
	end

	if utils_isPropClass( class_name ) then
		if hook_Run( "PrePropTakeDamage", entity, damage_info, class_name ) == false or
			hook_Run( "PropTakeDamage", entity, damage_info, class_name ) == false then
			return true
		end

		hook_Run( "PostPropTakeDamage", entity, damage_info, class_name )
		return false
	end

	if entity:IsWeapon() then
		if hook_Run( "PreWeaponTakeDamage", entity, damage_info, class_name ) == false or
			hook_Run( "WeaponTakeDamage", entity, damage_info, class_name ) == false then
			return true
		end

		hook_Run( "PostWeaponTakeDamage", entity, damage_info, class_name )
		return false
	end

	if hook_Run( "PreEntityClassTakeDamage", entity, damage_info, class_name ) == false or
		hook_Run( "EntityClassTakeDamage", entity, damage_info, class_name ) == false then
		return true
	end

	hook_Run( "PostEntityClassTakeDamage", entity, damage_info, class_name )
	return false
end, POST_HOOK_RETURN )

return ash_damage
