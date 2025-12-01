
---@class ash.entity.damage
local ash_damage = {}

local bit_band = bit.band
local bit_bor = bit.bor

---@param type_id integer
---@return fun( damage_type: integer ): boolean
local function make_is_function( type_id )
	return function( damage_type )
		return bit_band( damage_type, type_id ) ~= 0
	end
end

local isNonPhysical = make_is_function( bit_bor( DMG_DROWN, DMG_POISON, DMG_RADIATION, DMG_NERVEGAS, DMG_PARALYZE, DMG_SHOCK, DMG_SONIC, DMG_BURN ) )
local isCloseRange = make_is_function( bit_bor( DMG_SLASH, DMG_FALL, DMG_CLUB, DMG_CRUSH ) )
local isBullet = make_is_function( bit_bor( DMG_BULLET, DMG_SNIPER ) )
local isNeverGib = make_is_function( DMG_NEVERGIB )
local isDissolve = make_is_function( DMG_DISSOLVE )
local isExplosion = make_is_function( DMG_BLAST )
local isCrush = make_is_function( DMG_CRUSH )
local isShock = make_is_function( DMG_SHOCK )
local isBurn = make_is_function( DMG_BURN )
local isFall = make_is_function( DMG_FALL )


--- [SHARED]
---
--- Checks if the damage is non-physical.
---
ash_damage.isNonPhysical = isNonPhysical

--- [SHARED]
---
--- Checks if the damage is close range.
---
ash_damage.isCloseRange = isCloseRange

--- [SHARED]
---
--- Checks if the damage is from a bullet.
---
ash_damage.isBullet = isBullet

--- [SHARED]
---
--- Checks if the damage is from a bullet.
---
ash_damage.isNeverGib = isNeverGib

--- [SHARED]
---
--- Checks if the damage is from a dissolve.
---
ash_damage.isDissolve = isDissolve

--- [SHARED]
---
--- Checks if the damage is from an explosion.
---
ash_damage.isExplosion = isExplosion

--- [SHARED]
---
--- Checks if the damage is from a crush.
---
ash_damage.isCrush = isCrush

--- [SHARED]
---
--- Checks if the damage is from a shock.
---
ash_damage.isShock = isShock

--- [SHARED]
---
--- Checks if the damage is from a burn.
---
ash_damage.isBurn = isBurn

--- [SHARED]
---
--- Checks if the damage is from a fall.
---
ash_damage.isFall = isFall


return ash_damage
