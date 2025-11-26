
---@class ash.entity.damage
local damage_lib = {}

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
damage_lib.isNonPhysical = isNonPhysical

--- [SHARED]
---
--- Checks if the damage is close range.
---
damage_lib.isCloseRange = isCloseRange

--- [SHARED]
---
--- Checks if the damage is from a bullet.
---
damage_lib.isBullet = isBullet

--- [SHARED]
---
--- Checks if the damage is from a bullet.
---
damage_lib.isNeverGib = isNeverGib

--- [SHARED]
---
--- Checks if the damage is from a dissolve.
---
damage_lib.isDissolve = isDissolve

--- [SHARED]
---
--- Checks if the damage is from an explosion.
---
damage_lib.isExplosion = isExplosion

--- [SHARED]
---
--- Checks if the damage is from a crush.
---
damage_lib.isCrush = isCrush

--- [SHARED]
---
--- Checks if the damage is from a shock.
---
damage_lib.isShock = isShock

--- [SHARED]
---
--- Checks if the damage is from a burn.
---
damage_lib.isBurn = isBurn

--- [SHARED]
---
--- Checks if the damage is from a fall.
---
damage_lib.isFall = isFall


return damage_lib
