MODULE.ClientFiles = {
    "cl_init.lua",
}


MODULE.Networks = {
    "bullet_effect",
}

---@class ash_weapon_base: SWEP
local SWEP = SWEP

local developer = GetConVar( "developer" )

assert( developer ~= nil, "developer convar not found" )

---@type ash.trace
local ash_trace = import "ash.trace"
local trace_cast = ash_trace.cast

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result = { }

---@type ash.trace.Params
local trace = {
    output = trace_result
}

include "shared.lua"

hook.Add( "PlayerAmmoChanged", "Defaults", function( pl, ammotype, old, new )
    local wep = pl:GetActiveWeapon( )

    ---@cast wep ash_weapon_base

    if not ( wep ~= nil and wep:IsValid( ) and wep.IsAshWeapon ) then
        return
    end

    if ammotype ~= wep:GetPrimaryAmmoType( ) then
        return
    end

    if new <= old then
        return
    end

    if wep:Clip1( ) <= 0 and wep:GetMaxClip1( ) > 0 then
        wep:Reload( )
    end
end )
