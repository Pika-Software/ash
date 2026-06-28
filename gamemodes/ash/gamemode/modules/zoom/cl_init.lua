-- TODO: maybe add convars to configure the parameters


local hook_Add = hook.Add
local math_min = math.min
local math_max = math.max
local Lerp = Lerp
local FrameTime = FrameTime
local LocalPlayer = LocalPlayer

local hook_name = "ash.zoom"
--- @class ash.zoom
local ash_zoom = {}

local is_zooming = false
local tr_zoom = nil
local factor = nil

--- @class ash.zoom.config
--- @field variable? boolean Enable variable zoom (scroll mouse wheel to change FOV)
--- @field factor_min? number Minimum zoom factor (requires variable zoom enabled)
--- @field factor_max? number Maximum zoom factor (requires variable zoom enabled)
--- @field factor_step? number Zoom factor difference on mouse scroll
--- @field default_factor? number Default zoom factor immediately on pressing +zoom

--- [CLIENT]
---
--- Enables zoom functionality on `+zoom`
--- @param config ash.zoom.config
function ash_zoom.setup( config )
    local variable = config.variable or false
    local factor_min = config.factor_min or 0.1
    local factor_max = config.factor_max or 1.0
    local factor_step = config.factor_step or 0.025
    local default_factor = config.default_factor or 0.5
    factor = default_factor
    local speed = 14

    hook_Add( "ash.player.Key", hook_name, function( ply, key, pressed )
        if ply ~= LocalPlayer() then return end

        if key ~= IN_ZOOM then return end

        if pressed then
            is_zooming = true
        else
            is_zooming = false
            factor = default_factor
        end
    end, NORMAL_HOOK )

    hook_Add( "PlayerBindPress", hook_name .. ".toggle", function( ply, bind )
        if ply ~= LocalPlayer() then return end

        if bind == "toggle_zoom" then
            is_zooming = not is_zooming
        end
    end, NORMAL_HOOK )

    if variable then
        hook_Add( "ash.player.MouseWheel", hook_name, function( ply, wheel )
            if ply ~= LocalPlayer() then return end

            if not is_zooming then return end

            if wheel > 0 then
                factor = math_max( factor_min, factor - factor_step )
            else
                factor = math_min( factor_max, factor + factor_step )
            end
        end, NORMAL_HOOK )

        hook_Add( "PlayerBindPress", hook_name, function( ply, bind )
            if ply ~= LocalPlayer() then return end

            if is_zooming and (bind == "invprev" or bind == "invnext") then
                return true
            end
        end, NORMAL_HOOK )
    end

    hook_Add( "CalcView", hook_name, function( ply, _, _, fov )
        if not ply:Alive() then return end

        local target_zoom = is_zooming and fov * factor or fov
        if tr_zoom == nil then tr_zoom = fov end

        tr_zoom = Lerp( speed * FrameTime(), tr_zoom, target_zoom )

        return { fov = tr_zoom }
    end, NORMAL_HOOK )
end

local hook_Remove = hook.Remove

--- [CLIENT]
---
--- Disable all existing zoom functionality.
--- Removes hooks associated with the zoom module.
function ash_zoom.teardown()
    hook_Remove( "ash.player.Key", hook_name )
    hook_Remove( "ash.player.MouseWheel", hook_name )
    hook_Remove( "PlayerBindPress", hook_name )
    hook_Remove( "CalcView", hook_name )
end

return ash_zoom
