---@class ash.engine
local ash_engine = include( "shared.lua" )

local render_GetRenderTarget = render.GetRenderTarget
local Texture_GetName = Texture.GetName
local hook_Run = hook.Run

do

    local in_water_reflection = false
    local in_water_refraction = false

    hook.Add( "PreDrawTranslucentRenderables", "RenderHooks", function( is_depth_pass, is_skybox_drawing, is_3d_skybox )
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

    hook.Add( "PostDrawTranslucentRenderables", "RenderHooks", function( _, is_depth_pass, is_skybox_drawing, is_3d_skybox )
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

    hook.Add( "PreDrawOpaqueRenderables", "RenderHooks", function( is_depth_pass, is_skybox_drawing, is_3d_skybox )
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

    hook.Add( "PostDrawOpaqueRenderables", "RenderHooks", function( _, is_depth_pass, is_skybox_drawing, is_3d_skybox )
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

do

    local timer_Remove = _G.timer.Remove
    local hook_Remove = _G.hook.Remove

    -- garrysmod/lua/includes/modules/properties.lua
    hook_Remove( "PreDrawHalos", "PropertiesHover" )
    hook_Remove( "GUIMousePressed", "PropertiesClick" )
    hook_Remove( "PreventScreenClicks", "PropertiesPreventClicks" )
    hook_Remove( "PlayerBindPress", "PlayerOptionInput" )
    hook_Remove( "HUDPaint", "PlayerOptionDraw" )

    -- garrysmod/gamemodes/base/gamemode/cl_voice.lua
    hook_Remove( "InitPostEntity", "CreateVoiceVGUI" )
    timer_Remove( "VoiceClean" ) -- skill issue timer

    -- garrysmod/lua/includes/util/client.lua
	hook_Remove( "Think", "RealFrameTime" )

    -- garrysmod/lua/vgui/dtextentry.lua
    -- hook_Remove( "VGUIMousePressed", "TextEntryLoseFocus" ) -- required rewrite

    -- garrysmod/lua/postprocess/frame_blend.lua
    hook_Remove( "PostRender", "RenderFrameBlend" )

    -- garrysmod/lua/postprocess/overlay.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderMaterialOverlay" )

    -- garrysmod/lua/postprocess/super_dof.lua
    hook_Remove( "RenderScene", "RenderSuperDoF" )
    hook_Remove( "GUIMouseReleased", "SuperDOFMouseUp" )
    hook_Remove( "GUIMousePressed", "SuperDOFMouseDown" )
    hook_Remove( "PreventScreenClicks", "SuperDOFPreventClicks" )

    -- garrysmod/lua/postprocess/sunbeams.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderSunbeams" )

    -- garrysmod/lua/postprocess/texturize.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderTexturize" )

    -- garrysmod/lua/postprocess/stereoscopy.lua
    hook_Remove( "RenderScene", "RenderStereoscopy" )

    -- garrysmod/lua/postprocess/motion_blur.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderMotionBlur" )

    -- garrysmod/lua/postprocess/bloom.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderBloom" )

    -- garrysmod/lua/postprocess/bokeh_dof.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderBokeh" )
    hook_Remove( "NeedsDepthPass", "NeedsDepthPass_Bokeh" )

    -- garrysmod/lua/postprocess/color_modify.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderColorModify" )

    -- garrysmod/lua/postprocess/dof.lua
    hook_Remove( "Think", "DOFThink" )

    -- garrysmod/lua/includes/extensions/client/panel/dragdrop.lua
    hook_Remove( "DrawOverlay", "DragNDropPaint" )
    hook_Remove( "Think", "DragNDropThink" )

    -- garrysmod/lua/includes/modules/menubar.lua
    hook_Remove( "OnGamemodeLoaded", "CreateMenuBar" )

    -- garrysmod/lua/postprocess/sobel.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderSobel" )

    -- garrysmod/lua/postprocess/toytown.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderToyTown" )

    -- garrysmod/lua/postprocess/sharpen.lua
    hook_Remove( "RenderScreenspaceEffects", "RenderSharpen" )

    -- garrysmod/lua/includes/modules/halo.lua
    hook_Remove( "PostDrawEffects", "RenderHalos" ) -- THE LAG MACHINE

    -- garrysmod/lua/autorun/client/gm_demo.lua
    hook_Remove( "HUDPaint", "DrawRecordingIcon" )

end

do
    -- i hope in one day rubat just khs
    local variables = debug.getupvalues( Player.ConCommand )
    Player.ConCommand = variables.SendConCommand or Player.ConCommand
end

return ash_engine
