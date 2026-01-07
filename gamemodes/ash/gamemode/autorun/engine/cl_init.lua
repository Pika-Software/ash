---@class ash.engine
local ash_engine = include( "shared.lua" )

local render_GetRenderTarget = render.GetRenderTarget
local Texture_GetName = Texture.GetName
local hook_Run = hook.Run

---@type ash.ui
local ash_ui = require( "ash.ui" )

do

    local render_View = render.RenderView
    local cam_Start2D = cam.Start2D
    local cam_End2D = cam.End2D

    ---@type ViewData
    local view = {
        drawviewmodel = true,
        dopostprocess = true,
        drawmonitors = false,
        drawviewer = false,
        bloomtone = true,
        drawhud = true
    }

    view.offcenter = {}
    ash_engine.View = view

    local function resolutionChanged( w, h, aspect )
        view.w, view.h = w, h
        view.aspect = aspect

        local offcenter = view.offcenter

        offcenter.left = 0
        offcenter.right = w

        offcenter.top = 0
        offcenter.bottom = h
    end

    hook.Add( "ScreenResolutionChanged", "Render", resolutionChanged )
    resolutionChanged( ash_ui.ScreenWidth, ash_ui.ScreenHeight, ash_ui.ScreenAspect )

    hook.Add( "RenderScene", "Render", function( arguments )
        if arguments[ 2 ] == true then return true end
        hook_Run( "PerformView", view )
        cam_Start2D()
        render_View( view )
        hook_Run( "RenderOverlay" )
        cam_End2D()
        return true
    end, POST_HOOK_RETURN )

end

do

    local in_water_reflection = false
    local in_water_refraction = false

    hook.Add( "PreDrawTranslucentRenderables", "Render", function( is_depth_pass, is_skybox_drawing, is_3d_skybox )
        local texture = render_GetRenderTarget()
        if texture ~= nil then
            local texture_name = Texture_GetName( texture )
            if texture_name == "_rt_waterreflection" then
                in_water_reflection = true

                if is_skybox_drawing then
                    return hook_Run( "PreDrawTranslucentSkyboxReflection", is_3d_skybox, is_depth_pass )
                end

                return hook_Run( "PreDrawTranslucentReflection", is_depth_pass )
            elseif texture_name == "_rt_waterrefraction" then
                in_water_refraction = true

                if is_skybox_drawing then
                    return hook_Run( "PreDrawTranslucentSkyboxRefraction", is_3d_skybox, is_depth_pass )
                end

                return hook_Run( "PreDrawTranslucentRefraction", is_depth_pass )
            end
        end

        if is_skybox_drawing then
            return hook_Run( "PreDrawTranslucentSkybox", is_3d_skybox, is_depth_pass )
        end

        return hook_Run( "PreDrawTranslucentWorld", is_depth_pass )
    end, PRE_HOOK )

    hook.Add( "PostDrawTranslucentRenderables", "Render", function( _, is_depth_pass, is_skybox_drawing, is_3d_skybox )
        if in_water_reflection then
            in_water_reflection = false

            if is_skybox_drawing then
                hook_Run( "PostDrawTranslucentSkyboxReflection", is_3d_skybox, is_depth_pass )
            else
                hook_Run( "PostDrawTranslucentReflection", is_depth_pass )
            end

            return
        elseif in_water_refraction then
            in_water_refraction = false

            if is_skybox_drawing then
                hook_Run( "PostDrawTranslucentSkyboxRefraction", is_3d_skybox, is_depth_pass )
            else
                hook_Run( "PostDrawTranslucentRefraction", is_depth_pass )
            end

            return
        end

        if is_skybox_drawing then
            hook_Run( "PostDrawTranslucentSkybox", is_3d_skybox, is_depth_pass )
            return
        end

        hook_Run( "PostDrawTranslucentWorld", is_depth_pass )
    end, POST_HOOK )

end

do

    local in_water_reflection = false
    local in_water_refraction = false

    hook.Add( "PreDrawOpaqueRenderables", "Render", function( is_depth_pass, is_skybox_drawing, is_3d_skybox )
        local texture = render_GetRenderTarget()
        if texture ~= nil then
            local texture_name = Texture_GetName( texture )
            if texture_name == "_rt_waterreflection" then
                in_water_reflection = true

                if is_skybox_drawing then
                    return hook_Run( "PreDrawOpaqueSkyboxReflection", is_3d_skybox, is_depth_pass )
                end

                return hook_Run( "PreDrawOpaqueReflection", is_depth_pass )
            elseif texture_name == "_rt_waterrefraction" then
                in_water_refraction = true

                if is_skybox_drawing then
                    return hook_Run( "PreDrawOpaqueSkyboxRefraction", is_3d_skybox, is_depth_pass )
                end

                return hook_Run( "PreDrawOpaqueRefraction", is_depth_pass )
            end
        end

        if is_skybox_drawing then
            return hook_Run( "PreDrawOpaqueSkybox", is_3d_skybox, is_depth_pass )
        end

        return hook_Run( "PreDrawOpaqueWorld", is_depth_pass )
    end, PRE_HOOK_RETURN )

    hook.Add( "PostDrawOpaqueRenderables", "Render", function( _, is_depth_pass, is_skybox_drawing, is_3d_skybox )
        if in_water_reflection then
            in_water_reflection = false

            if is_skybox_drawing then
                hook_Run( "PostDrawOpaqueSkyboxReflection", is_3d_skybox, is_depth_pass )
            else
                hook_Run( "PostDrawOpaqueReflection", is_depth_pass )
            end

            return
        elseif in_water_refraction then
            in_water_refraction = false

            if is_skybox_drawing then
                hook_Run( "PostDrawOpaqueSkyboxRefraction", is_3d_skybox, is_depth_pass )
            else
                hook_Run( "PostDrawOpaqueRefraction", is_depth_pass )
            end

            return
        end

        if is_skybox_drawing then
            hook_Run( "PostDrawOpaqueSkybox", is_3d_skybox, is_depth_pass )
        else
            hook_Run( "PostDrawOpaqueWorld", is_depth_pass )
        end
    end, POST_HOOK )

end

return ash_engine
