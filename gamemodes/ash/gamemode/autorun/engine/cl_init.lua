---@alias ash.engine.HUD.Element
---| "CHudHealth" The player health meter.
---| "CHudBattery" The player armor meter.
---| "CHudSuitPower" HEV Suit power.
---| "CHudGeiger" Geiger counter from Half-Life 2. Only active when the sound plays. Hiding this stops the sound.
---| "CHudDamageIndicator" The damage indicator from Half-Life 2, active only when visible.
---| "CHudPoisonDamageIndicator" The "Neurotoxin Detected" HUD above Health when you get hit by a poison headcrab.
---| "CHudAmmo" Primary ammo counter.
---| "CHudSecondaryAmmo" Secondary ammo counter ( SMG1 grenades, AR2 energy balls )
---| "CHudChat" The default chat box, escape menu, and console.
---| "CHudHistoryResource" Weapon Pickup Indicator
---| "CHudWeaponSelection" The weapon selection panel.
---| "CHudZoom" Suit zoom from Half-Life 2.
---| "CHudWeapon" Handles creation/updating colors of `CHudCrosshair`.
---| "CHudCrosshair" The default SWEP and HL2 weapon crosshair.
---| "CHUDQuickInfo" Health and ammo near crosshair. ( `hud_quickinfo` `1` )
---| "CHudVehicle" Crosshair for jeep and airboat when gun is mounted.
---| "CHudTrain" Possibly the controls HUD for controllable func_tracktrain.
---| "CHudCloseCaption" Close captions.
---| "CHudGMod" The `GetHUDPanel()` Panel.
---| "CHudDeathNotice" The death notice panel. Disabled in Garry's Mod.
---| "CHudHintDisplay" The key hint display? Disabled in Garry's Mod.
---| "CHudMenu" A generic menu on the left side of the screen with simple 1/2/3/etc key inputs. Typically used in other Source games as map voting, etc.
---| "CHudMessage" Possibly handles the Half-Life 2 title on HUD on relevant maps, as well as the text from `game_text` entity.
---| "CHudSquadStatus" Citizen Squad status HUD from Half-Life 2. Only called if citizens follow you.
---| "NetGraph" The netgraph. Only works if `net_graph` convar is above `0`.
---| string

---@class ash.engine
---@field HUD table<ash.engine.HUD.Element, boolean> The table/map of enabled/disabled UI elements.
local ash_engine = include( "shared.lua" )

---@type ash.player
local ash_player = require( "ash.player" )

local hook_Run = hook.Run

do

    ---@type table<ash.engine.HUD.Element, boolean>
    local defaults = {
        -- Health, Armor & HEV Suit
        CHudHealth = false,
        CHudBattery = false,
        CHudSuitPower = false,

        -- Damage
        CHudGeiger = true,
        CHudDamageIndicator = true,
        CHudPoisonDamageIndicator = true,

        -- Ammo
        CHudAmmo = false,
        CHudSecondaryAmmo = false,

        -- Chat
        CHudChat = true,

        -- Weapon pickup indicator
        CHudHistoryResource = false,

        -- Weapon Selector
        CHudWeaponSelection = true,

        -- Zoom HUD Effects
        CHudZoom = true,

        -- Crosshair
        CHudWeapon = true,
        CHudCrosshair = true,
        CHUDQuickInfo = false,

        -- Vehicle Crosshair
        CHudVehicle = true,

        -- func_tracktrain vehicles HUD
        CHudTrain = true,

        -- Close captions
        CHudCloseCaption = false,

        -- GMOD HUD's
        CHudGMod = true,

        CHudDeathNotice = true,
        CHudHintDisplay = false,

        -- Voting menu
        CHudMenu = true,

        -- game_text entity messages
        CHudMessage = true,

        -- NPC Squad
        CHudSquadStatus = false,

        -- Debug
        NetGraph = true
    }

    ---@type table<ash.engine.HUD.Element, boolean>
    local should_draw = {}
    setmetatable( should_draw, { __index = defaults } )

    hook.Add( "HUDShouldDraw", "ShouldDrawHUD", function( name )
        return should_draw[ name ] == true
    end, PRE_HOOK_RETURN )

    local player_getActiveWeapon = ash_player.getActiveWeapon
    local Entity_IsValid = Entity.IsValid
    local ErrorNoHalt = ErrorNoHalt
    local xpcall = xpcall

    local names, name_count = table.keys( defaults )

    timer.Create( "ShouldDrawHUD", 0.25, 0, function()
        for i = 1, name_count, 1 do
            local name = names[ i ]

            local pl = ash_player.Entity
            if pl ~= nil and Entity_IsValid( pl ) and pl:Alive() then
                local weapon = player_getActiveWeapon( pl )
                if weapon ~= nil and Entity_IsValid( weapon ) then
                    ---@diagnostic disable-next-line: undefined-field
                    local ShouldDrawHUD = weapon.ShouldDrawHUD
                    if ShouldDrawHUD ~= nil then
                        local success, result = xpcall( ShouldDrawHUD, ErrorNoHalt, weapon, pl, name )
                        if success and result ~= nil then
                            should_draw[ name ] = result == true
                            goto skip
                        end
                    end

                    ---@diagnostic disable-next-line: undefined-field
                    local HUDShouldDraw = weapon.HUDShouldDraw
                    if HUDShouldDraw ~= nil then
                        local success, result = xpcall( HUDShouldDraw, ErrorNoHalt, weapon, name )
                        if success and result ~= nil then
                            should_draw[ name ] = result == true
                            goto skip
                        end
                    end
                end

                local success, result = xpcall( hook_Run, ErrorNoHalt, "ash.engine.ShouldDrawHUD", pl, name )
                if success and result ~= nil then
                    should_draw[ name ] = result == true
                end

                ::skip::
            end
        end
    end )

end

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
