include( "shared.lua" )

local render_GetRenderTarget = render.GetRenderTarget
local Texture_GetName = Texture.GetName
local hook_Run = hook.Run

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
                    return hook_Run( "PreDrawTranslucentSkyboxInWaterReflection", is_depth_pass, is_3d_skybox )
                end

                return hook_Run( "PreDrawTranslucentWaterReflection", is_depth_pass )
            elseif texture_name == "_rt_waterrefraction" then
                in_water_refraction = true

                if is_skybox_drawing then
                    return hook_Run( "PreDrawTranslucentSkyboxInWaterRefraction", is_depth_pass, is_3d_skybox )
                end

                return hook_Run( "PreDrawTranslucentWaterRefraction", is_depth_pass )
            end
        end

        if is_skybox_drawing then
            return hook_Run( "PreDrawTranslucentSkybox", is_depth_pass, is_3d_skybox )
        end

        return hook_Run( "PreDrawTranslucentWorld", is_depth_pass )
    end, PRE_HOOK )

    hook.Add( "PostDrawTranslucentRenderables", "Render", function( _, is_depth_pass, is_skybox_drawing, is_3d_skybox )
        if in_water_reflection then
            in_water_reflection = false

            if is_skybox_drawing then
                hook_Run( "PostDrawTranslucentSkyboxInWaterReflection", is_depth_pass, is_3d_skybox )
            else
                hook_Run( "PostDrawTranslucentWaterReflection", is_depth_pass )
            end

            return
        elseif in_water_refraction then
            in_water_refraction = false

            if is_skybox_drawing then
                hook_Run( "PostDrawTranslucentSkyboxInWaterRefraction", is_depth_pass, is_3d_skybox )
            else
                hook_Run( "PostDrawTranslucentWaterRefraction", is_depth_pass )
            end

            return
        end

        if is_skybox_drawing then
            hook_Run( "PostDrawTranslucentSkybox", is_depth_pass, is_3d_skybox )
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
                    return hook_Run( "PreDrawOpaqueSkyboxInWaterReflection", is_depth_pass, is_3d_skybox )
                end

                return hook_Run( "PreDrawOpaqueWaterReflection", is_depth_pass )
            elseif texture_name == "_rt_waterrefraction" then
                in_water_refraction = true

                if is_skybox_drawing then
                    return hook_Run( "PreDrawOpaqueSkyboxInWaterRefraction", is_depth_pass, is_3d_skybox )
                end

                return hook_Run( "PreDrawOpaqueWaterRefraction", is_depth_pass )
            end
        end

        if is_skybox_drawing then
            return hook_Run( "PreDrawOpaqueSkybox", is_depth_pass, is_3d_skybox )
        end

        return hook_Run( "PreDrawOpaqueWorld", is_depth_pass )
    end, PRE_HOOK_RETURN )

    hook.Add( "PostDrawOpaqueRenderables", "Render", function( _, is_depth_pass, is_skybox_drawing, is_3d_skybox )
        if in_water_reflection then
            in_water_reflection = false

            if is_skybox_drawing then
                hook_Run( "PostDrawOpaqueSkyboxInWaterReflection", is_depth_pass, is_3d_skybox )
            else
                hook_Run( "PostDrawOpaqueWaterReflection", is_depth_pass )
            end

            return
        elseif in_water_refraction then
            in_water_refraction = false

            if is_skybox_drawing then
                hook_Run( "PostDrawOpaqueSkyboxInWaterRefraction", is_depth_pass, is_3d_skybox )
            else
                hook_Run( "PostDrawOpaqueWaterRefraction", is_depth_pass )
            end

            return
        end

        if is_skybox_drawing then
            hook_Run( "PostDrawOpaqueSkybox", is_depth_pass, is_3d_skybox )
            return
        end

        hook_Run( "PostDrawOpaqueWorld", is_depth_pass )
    end, POST_HOOK )

end
