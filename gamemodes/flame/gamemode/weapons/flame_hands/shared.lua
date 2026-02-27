---@class flame_hands : SWEP
---@field GetSensitivity fun(self: flame_hands): number
---@field SetSensitivity fun(self: flame_hands, sensitivity: number)
local SWEP = SWEP

SWEP.PrintName = "Hands"

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel	= ""

SWEP.Primary = {
    ClipSize = -1,
    DefaultClip = 0,
    Automatic = false,
    Ammo = "none"
}

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = 0,
    Automatic = false,
    Ammo = "none"
}

function SWEP:PrimaryAttack()
end

function SWEP:Reload()
end

function SWEP:SetupDataTables()
    self:NetworkVar( "Float", 0, "Sensitivity" )
end
