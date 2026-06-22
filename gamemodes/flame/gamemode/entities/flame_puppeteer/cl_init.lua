include( "shared.lua" )

---@type ash.entity
local ash_entity = import "ash.entity"

---@type ash.view
local ash_view = import "ash.view"

---@type ash.player
local ash_player = import "ash.player"

---@class flame_puppeteer : ENT
local ENT = ENT

ENT.Type = "anim"

---@diagnostic disable-next-line: duplicate-set-field
function ENT:Initialize()

end

-- local m = ENT:GenerateCapsuleMesh( 22, 70, 8, 4 )

local function DrawCapsuleMesh( tris, origin, angles, col )
    col         = col or Color( 0, 255, 0, 255 )

    local up    = angles:Up()
    local right = angles:Right()
    local fwd   = angles:Forward()

    local function toWorld( v )
        return origin + right * v.x + fwd * v.y + up * v.z
    end

    render.SetColorMaterial()

    for i = 1, #tris, 3 do
        local a = toWorld( tris[ i ] )
        local b = toWorld( tris[ i + 1 ] )
        local c = toWorld( tris[ i + 2 ] )
        render.DrawLine( a, b, col, false )
        render.DrawLine( b, c, col, false )
        render.DrawLine( c, a, col, false )
    end
end


local col = color_white

function ENT:Draw()
    -- DrawCapsuleMesh( m, self:GetPos(), self:GetAngles(), col )

    -- local mins, maxs = self:GetCollisionBounds()
    -- render.DrawWireframeBox( self:GetPos(), )
    --
    --

end

ENT.DrawTranslucent = ENT.Draw


-- ---@param data ash.view.Data
-- hook.Add( "ash.view.Perform", "Render", function( data, game_ui_visible )
--     local entity = ash_view.Entity
--     if entity == nil then return end

--     data.drawviewmodel = false
--     data.drawviewer = true

--     data.dopostprocess = true
--     data.drawhud = true

--     data.drawmonitors = false
--     data.bloomtone = true

--     -- if player_isDead( pl ) then
--     --     local ragdoll_entity = player_getRagdoll( pl )
--     --     if ragdoll_entity ~= nil and Entity_IsValid( ragdoll_entity ) then
--     --         trace.filter = ragdoll_entity

--     --         local eye_position, eye_angles = eyes_view( ragdoll_entity )

--     --         local forward = Angle_Forward( eye_angles )

--     --         trace.start = eye_position - forward * 32
--     --         trace.endpos = eye_position + forward * 16

--     --         util.TraceHull( trace )

--     --         if trace_result.Hit then
--     --             Vector_Add( eye_position, trace_result.HitNormal * ( ( trace_result.Fraction ) * 32 ) )
--     --         end

--     --         data.origin = eye_position
--     --         data.angles = eye_angles
--     --         data.fov = fov_desired
--     --         return
--     --     end
--     -- end

--     -- local weapon = pl:GetActiveWeapon()
--     -- if weapon ~= nil and Entity_IsValid( weapon ) then
--     --     ---@diagnostic disable-next-line: undefined-field
--     --     if weapon:GetClass() == "slendy_camera" and weapon.m_bInitialized then
--     --         ---@diagnostic disable-next-line: undefined-field
--     --         data.origin, data.angles = LocalToWorld( camera_origin_offset, camera_angles_offset, darker.GetViewData( pl, weapon.m_eWorldModel ) )
--     --         ---@diagnostic disable-next-line: undefined-field
--     --         data.fov = fov_desired + weapon:GetFieldOfView()
--     --         return
--     --     end
--     -- end




--     data.angles = ash_player.getViewAngles( ash_player.Entity )

--     data.origin --[[, data.angles]] = ash_entity.getAttachmentByName( entity, "eyes" )


--     -- data.origin, data.angles = eyes_view( pl ) --, pl:EyeAngles()
--     -- data.fov = fov_desired
-- end )
