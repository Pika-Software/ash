---@class flame.player
local flame_player = include( "shared.lua" )

do

    local cl_playermodel = console.Variable.get( "cl_playermodel", "string" )

    flame_player.SelectedModel = console.Variable( {
        name = "flame_player_model",
        type = "string",
        default = cl_playermodel and cl_playermodel.value or "default",
        description = "The name of player model to use.",
        archive = true,
        userinfo = true,
        dont_record = true
    } )

end

do

    local cl_playercolor = console.Variable( {
        name = "cl_playercolor",
        type = "string",
        default = "0.24 0.34 0.41",
        description = "The value is a Vector - so between 0-1 - not between 0-255",
        archive = true,
        userinfo = true,
        dont_record = true
    } )

    flame_player.SelectedColor = console.Variable( {
        name = "flame_player_color",
        type = "string",
        ---@diagnostic disable-next-line: param-type-mismatch
        default = string.format( "%d %d %d", flame_player.V3toRGB( cl_playercolor.value or cl_playercolor.default ) ),
        description = "The color of the player model to use, its RGB values, separated by spaces, from 0 to 255.",
        archive = true,
        userinfo = true,
        dont_record = true
    } )

end

do

    local cl_weaponcolor = console.Variable( {
        name = "cl_weaponcolor",
        type = "string",
        default = "0.30 1.80 2.10",
        description = "The value is a Vector - so between 0-1 - not between 0-255",
        archive = true,
        userinfo = true,
        dont_record = true
    } )

    flame_player.SelectedWeaponColor = console.Variable( {
        name = "flame_weapon_color",
        type = "string",
        ---@diagnostic disable-next-line: param-type-mismatch
        default = string.format( "%d %d %d", flame_player.V3toRGB( cl_weaponcolor.value or cl_weaponcolor.default ) ),
        description = "The color of the player weapon to use, its RGB values, separated by spaces, from 0 to 255.",
        archive = true,
        userinfo = true,
        dont_record = true
    } )

end

do

    local cl_playerskin = console.Variable( {
        name = "cl_playerskin",
        type = "integer",
        default = 0,
        description = "The skin to use, if the model has any",
        archive = true,
        userinfo = true,
        dont_record = true
    } )

    flame_player.SelectedSkin = console.Variable( {
        name = "flame_player_skin",
        type = "integer",
        default = cl_playerskin.value or cl_playerskin.default,
        description = "The skin to use, if the model has any (0 is default).",
        archive = true,
        userinfo = true,
        dont_record = true
    } )

end

-- do

--     local cl_playerbodygroups = console.Variable( {
--         name = "cl_playerbodygroups",
--         type = "string",
--         default = "0",
--         description = "The bodygroups to use, if the model has any",
--         archive = true,
--         userinfo = true,
--         dont_record = true
--     } )

-- end

---@param pl Player
hook.Add( "ash.player.Initialized", "Defaults", function( pl, is_local )
    if is_local then
        pl:ConCommand( "hud_draw_fixed_reticle 0" )
        pl:ConCommand( "dsp_player 1" )
        pl:ConCommand( "dsp_room 1" )
    end
end )

local addon_name = "Land of the Living"

if CLIENT then

    local view = {}

    hook.Add( "CalcView", addon_name, function( pl, origin, angles, fov )
        ---@type Entity
        local rag = pl:GetNWEntity( addon_name )
        if rag == nil or not rag:IsValid() then return end

        local attachment_id = rag:LookupAttachment( "eyes" )
        if attachment_id == nil or attachment_id <= 0 then return end

        local attachment = rag:GetAttachment( attachment_id )
        if attachment == nil then return end

        view.origin = attachment.Pos
        -- view.angles = attachment.Ang
        view.fov = fov

        return view
    end )

    hook.Add( "PrePlayerDraw", addon_name, function( pl, flags )
        local rag = pl:GetNWEntity( addon_name )
        if rag == nil or not rag:IsValid() then return end

        local head_id = rag:LookupBone( "ValveBiped.Bip01_Head1" )
        if head_id ~= nil and head_id >= 0 then
            rag:ManipulateBoneScale( head_id, vector_origin )
        end

        rag:DrawModel( flags )
        return true
    end )

    hook.Add( "ShouldDrawLocalPlayer", addon_name, function( pl )
        local rag = pl:GetNWEntity( addon_name )
        if rag == nil or not rag:IsValid() then return end

        return true
    end )

    -- hook.Add( "PreDrawViewModel", addon_name, function( _, pl )
    --     local rag = pl:GetNWEntity( addon_name )
    --     if rag == nil or not rag:IsValid() then return end

    --     return true
    -- end )

end

return flame_player
