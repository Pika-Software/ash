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

---@type ash.ui
local ash_ui = require( "ash.ui" )

local Vector_SetUnpacked = Vector.SetUnpacked
local Vector_Unpack = Vector.Unpack
local Vector_Mul = Vector.Mul
local Vector_Add = Vector.Add

local Entity_IsValid = Entity.IsValid

local hook_Run = hook.Run

include( "shared.lua" )

---@class flame_hands : SWEP
local SWEP = SWEP

---@diagnostic disable-next-line: duplicate-set-field
function SWEP:Initialize()
end

---@diagnostic disable-next-line: duplicate-set-field
function SWEP:SecondaryAttack()
end

function SWEP:ShouldDrawHUD( pl, name )
    if name == "CHudWeaponSelection" and ash_player.getKeyState( pl, 1 ) then
        return false
    end
end

function SWEP:AdjustMouseSensitivity()
    return self:GetSensitivity()
end

---@param cmd CUserCmd
hook.Add( "InputMouseApply", "MouseLock", function( cmd )
    local pl = LocalPlayer()
    if pl == nil or not pl:IsValid() then return end

    local weapon = pl:GetActiveWeapon()
    if weapon == nil or not weapon:IsValid() or weapon:GetClass() ~= "flame_hands" then return end

    if ash_player.getKeyState( pl, IN_RELOAD ) then
        -- cmd:SetViewAngles( pl:EyeAngles() )
        cmd:SetMouseX( 0 )
        cmd:SetMouseY( 0 )
        return true
    end
end )

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result = {}

---@type ash.trace.Params
local trace = {
    output = trace_result
}

---@diagnostic disable-next-line: duplicate-set-field
function SWEP:Think()
    -- local pl = self:GetOwner()
    -- if not ( pl ~= nil and pl:IsValid() and pl:IsPlayer() and pl:Alive() ) then return end

    -- ---@cast pl Player

    -- local eye_position = pl:EyePos()

    -- trace.start = eye_position
    -- trace.endpos = eye_position + view_getAimVector( pl ) * player_getUseDistance( pl )
    -- trace.filter = { pl }

    -- trace_cast( trace )

    -- if not trace_result.Hit or trace_result.StartSolid or trace_result.HitWorld then return end
end

local util_IntersectRayWithPlane = util.IntersectRayWithPlane
local WorldToLocal = WorldToLocal

local function getCursorPosition( pl, origin, angles )
	local intersect_position = util_IntersectRayWithPlane( pl:EyePos(), view_getAimVector( pl ), origin, angles:Up() )
    if intersect_position == nil then
        return false, 0, 0
    end

	local position = WorldToLocal( intersect_position, angle_zero, origin, angles )

    local data = intersect_position:ToScreen()

    return data.visible, data.x, data.y

    -- return true, position[ 1 ], -position[ 2 ]
end

-- local material = ash_ui.loadMaterial( "flame_hands1", "https://cdn.p1ka.eu/alium/alium_lobby/icons/x512/crosshair_carry_one_handed.png", bit.bor( 4, 8, 16 ) )

-- local sizes = ash_ui.scaleMap( {
--     icon_width = "20vmin",
--     icon_height = "10vmin"
-- } )

function SWEP:DrawHUD()
    -- local position = trace_result.HitPos
    -- local angles = trace_result.HitNormal:Angle()
    -- angles[ 1 ] = angles[ 1 ] + 90

    -- local visible, x, y = getCursorPosition( ash_player.Entity, position, angles )
    -- if visible then
    --     -- cam.Start3D2D( position, angles, 0.05 )
    --         surface.SetDrawColor( 255, 255, 255, math.min( 255, 255 - trace_result.Fraction * 255 ) )
    --         surface.SetMaterial( material )
    --         surface.DrawTexturedRectRotated( x, y, sizes.icon_width, sizes.icon_height, 90 )
    --     -- cam.End3D2D()
    -- end
end
