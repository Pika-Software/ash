local hook_Run = hook.Run

---@type ash.ui
local ash_ui = require( "ash.ui" )

---@type ash.player
local ash_player = require( "ash.player" )

---@class ash.view
---@field AimVector Vector The aim vector.
---@field Data ash.view.Data The view data.
---@field ViewEntity Entity The view entity.
local ash_view = include( "shared.lua" )

---@class ash.view.Data : ViewData
local data = {
    drawviewmodel = true,
    dopostprocess = true,
    drawmonitors = false,
    drawviewer = false,
    bloomtone = true,
    drawhud = true,
    offcenter = {}
}

ash_view.Data = data

do

    local render_View = render.RenderView
    local cam_Start2D = cam.Start2D
    local cam_End2D = cam.End2D

    ---@param w integer
    ---@param h integer
    ---@param aspect number
    local function resolutionChanged( w, h, aspect )
        data.w, data.h = w, h
        data.aspect = aspect

        local offcenter = data.offcenter

        offcenter.left = 0
        offcenter.right = w

        offcenter.top = 0
        offcenter.bottom = h
    end

    hook.Add( "ash.ui.ScreenResolution", "Render", resolutionChanged )
    resolutionChanged( ash_ui.ScreenWidth, ash_ui.ScreenHeight, ash_ui.ScreenAspect )

    hook.Add( "RenderScene", "Render", function( arguments, origin, angles, fov )
        if arguments[ 2 ] == true then return true end

        data.origin, data.angles = origin, angles
        data.fov = fov

        hook_Run( "ash.view.Perform", data )

        cam_Start2D()
        render_View( data )
        hook_Run( "ash.view.DrawOverlay" )
        cam_End2D()

        return true
    end, POST_HOOK_RETURN )

end

do

    local Entity_SetNW2Var = Entity.SetNW2Var
    local Entity_IsValid = Entity.IsValid

    local gui_IsGameUIVisible = gui.IsGameUIVisible
    local util_AimVector = util.AimVector

    ---@type fun(): Angle
    ---@diagnostic disable-next-line: undefined-global
    local MainEyeAngles = MainEyeAngles

    local net_Start = net.Start
    local net_WriteFloat = net.WriteFloat
    local net_SendToServer = net.SendToServer

    hook.Add( "ash.view.AimVector", "Sync", function( _, aim )
        net_Start( "sync", true )
        net_WriteFloat( aim[ 1 ] )
        net_WriteFloat( aim[ 2 ] )
        net_WriteFloat( aim[ 3 ] )
        net_SendToServer()
    end )

    ash_view.AimVector = Vector( 0, 0, 0 )

    ---@param pl Player
    local function aim_update( pl )
        local aim_vector = util_AimVector( data.angles or MainEyeAngles(), data.fov or 90, ash_ui.CursorX or 0, ash_ui.CursorY or 0, ash_ui.ScreenWidth or 0, ash_ui.ScreenHeight or 0 ) or ash_view.AimVector

        if ash_view.AimVector == aim_vector then return end
        ash_view.AimVector = aim_vector

        Entity_SetNW2Var( pl, "m_vAim", aim_vector )
        hook_Run( "ash.view.AimVector", pl, aim_vector )
    end

    hook.Add( "ash.player.ViewAngles", "AimVector", function( pl )
        aim_update( pl )
    end, PRE_HOOK )

    hook.Add( "ash.ui.CursorMoved", "AimVector", function()
        if gui_IsGameUIVisible() then return end

        ---@diagnostic disable-next-line: undefined-field
        local pl = ash_player.Entity
        if pl ~= nil and Entity_IsValid( pl ) then
            aim_update( pl )
        end
    end, PRE_HOOK )

end

do

    local GetViewEntity = GetViewEntity

    ash_view.Entity = GetViewEntity() or NULL

    timer.Create( "ViewEntity", 0.5, 0, function()
        local entity = GetViewEntity() or NULL
        if entity ~= ash_view.Entity then
            hook_Run( "ash.view.Entity", ash_view.Entity, entity )
            ash_view.Entity = entity
        end
    end )

end

return ash_view
