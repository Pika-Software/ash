---@class ash
local ash = ash

if ash.Loaded then return end
ash.Loaded = true

---@type dreamwork.std
local std = _G.dreamwork.std

local string = std.string

local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect

---@type dreamwork.std.math
local math = std.math
local math_abs = math.abs
local math_sin = math.sin
local math_lerp = math.lerp
local math_clamp = math.clamp

local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D

local loader_material, loader_size
local screen_width, screen_height

local loader_x, loader_y

---@class ash.loader.Square
---@field index integer
---@field x integer
---@field y integer
---@field progress number
---@field x2 integer
---@field y2 integer
---@field red integer
---@field green integer
---@field blue integer
---@field alpha integer

do

    local square_size, borders, x, y, positions

    ---@type ash.loader.Square[]
    local squares = {}

    ---@type table<integer, integer>
    local alpha_map = {
        [ 0 ] = 70,

        70,
        90,
        110,

        130,
        150,
        170,

        180,
        200,
        220,

        -500
    }

    local render_target

    ---@type integer
    local current_square = 1

    ---@param width integer
    ---@param height integer
    local function loader_init( width, height )
        screen_width, screen_height = width, height

        local vmin = math.min( width, height ) * 0.01
        square_size = math.floor( vmin * 5 )
        borders = math.floor( vmin )
        current_square = 1

        loader_size = borders * 4 + square_size * 3
        loader_x, loader_y = ( screen_width - loader_size ) * 0.5, ( screen_height - loader_size ) * 0.5

        local texture_name = string.format( "ash_loader_%dx%d", loader_size, loader_size )
        render_target = GetRenderTarget( texture_name, loader_size, loader_size )

        loader_material = CreateMaterial( texture_name, "UnlitGeneric", {
            [ "$basetexture" ] = texture_name,
            [ "$translucent" ] = "1"
        } )

        ash.LoadingMaterial = loader_material
        ash.LoadingMaterialSize = loader_size
        ash.LoadingTextureName = texture_name

        x, y = borders, borders

        positions = {
            [ 0 ] = { x, -square_size },

            { x, y },
            { x + borders + square_size, y },
            { x + ( borders + square_size ) * 2, y },

            { x + ( borders + square_size ) * 2, y + borders + square_size },
            { x + borders + square_size, y + borders + square_size },
            { x, y + borders + square_size },

            { x, y + ( borders + square_size ) * 2 },
            { x + borders + square_size, y + ( borders + square_size ) * 2 },
            { x + ( borders + square_size ) * 2, y + ( borders + square_size ) * 2 },

            { x + ( borders + square_size ) * 2, loader_size }
        }

        for i = 1, 9, 1 do
            local start_position = positions[ i ]
            local next_position = positions[ i + 1 ]

            squares[ i ] = {
                index = i,
                x = start_position[ 1 ],
                y = start_position[ 2 ],
                progress = 0,
                x2 = next_position[ 1 ],
                y2 = next_position[ 2 ],
                alpha = alpha_map[ i ],
                red = 180,
                green = 180,
                blue = 250
            }
        end
    end

    hook.Add( "OnScreenSizeChanged", "ash.Loader", function( _, __, width, height )
        loader_init( width, height )
    end, PRE_HOOK )

    loader_init( ScrW(), ScrH() )

    local render_PushRenderTarget = render.PushRenderTarget
    local render_PopRenderTarget = render.PopRenderTarget
    local render_Clear = render.Clear
    local FrameTime = _G.FrameTime

    hook.Add( "Tick", "ash.Loader", function()
        if current_square > 9 then
            current_square = 1
        end

        do

            local square = squares[ 9 - current_square + 1 ]
            local current_index = square.index

            local progress = square.progress

            if progress > 0.5 then
                progress = 1
            end

            if progress == 1 then
                current_square = current_square + 1
                square.progress = 0

                if current_index == 9 then
                    local zero_position = positions[ 0 ]
                    square.x, square.y = zero_position[ 1 ], zero_position[ 2 ]
                    square.alpha = alpha_map[ 0 ]
                    current_index = 0
                else
                    current_index = current_index + 1
                    local current_position = positions[ current_index ]
                    square.x, square.y = current_position[ 1 ], current_position[ 2 ]
                    square.alpha = alpha_map[ current_index ]
                end

                square.index = current_index
                goto skip_loop
            end

            if progress == 0 then
                if current_index == 0 then
                    local zero_position = positions[ 0 ]
                    square.x, square.y = zero_position[ 1 ], zero_position[ 2 ]

                    local one_position = positions[ 1 ]
                    square.x2, square.y2 = one_position[ 1 ], one_position[ 2 ]
                else
                    local start_position = positions[ current_index ]
                    square.x, square.y = start_position[ 1 ], start_position[ 2 ]

                    local next_position = positions[ current_index + 1 ]
                    square.x2, square.y2 = next_position[ 1 ], next_position[ 2 ]

                end
            end

            square.progress = math_clamp( progress + FrameTime() * 2, 0, 1 )

            square.x = math_lerp( progress, square.x, square.x2 )
            square.y = math_lerp( progress, square.y, square.y2 )

            square.alpha = math_lerp( progress, alpha_map[ current_index ], alpha_map[ current_index + 1 ] )

            ::skip_loop::
        end

        render_PushRenderTarget( render_target )
        cam_Start2D()

        render_Clear( 0, 0, 0, 0 )

        for i = 1, 9, 1 do
            local square = squares[ i ]

            local index = square.index
            local fraction = square.progress
            local alpha = math_lerp( fraction, square.alpha, alpha_map[ index + 1 ] )

            surface_SetDrawColor( 55, 55, 55, alpha )
            surface_DrawRect( square.x - 4, square.y - 4, square_size + 4, square_size + 2 )

            if index == 4 then
                surface_SetDrawColor( math_lerp( fraction, 180, 255 ), math_lerp( fraction, 180, 180 ), math_lerp( fraction, 250, 50 ), alpha )
            elseif index == 5 then
                surface_SetDrawColor( math_lerp( fraction, 255, 180 ), math_lerp( fraction, 180, 180 ), math_lerp( fraction, 50, 250 ), alpha )
            else
                surface_SetDrawColor( 180, 180, 250, alpha )
            end

            surface_DrawRect( square.x, square.y, square_size, square_size )
        end

        cam_End2D()
        render_PopRenderTarget()
    end )

end

ash.reload()

hook.Add( "CreateMove", "ash.Workshop", function( cmd )
    cmd:ClearMovement()
    cmd:SetImpulse( 0 )
    cmd:ClearButtons()
    return true
end )

do

    local surface_DrawTexturedRect = surface.DrawTexturedRect
    local surface_SetTextColor = surface.SetTextColor
    local surface_GetTextSize = surface.GetTextSize
    local surface_SetMaterial = surface.SetMaterial
    local surface_SetTextPos = surface.SetTextPos
    local surface_DrawText = surface.DrawText
    local surface_SetFont = surface.SetFont
    local CurTime = CurTime

    ---@type boolean | nil
    local is_ready = nil

    ---@type string
    local text = "Preparing"

    timer.Create( "ash.Workshop", 0.5, 0, function()
        if string.byteCount( text, 0x2E --[[ . ]], false ) == 3 then
            text = string.byteTrim( text, 0x2E --[[ . ]], true )
        else
            text = text .. "."
        end
    end )

    ---@type string[] | nil
    local workshop_list, err_msg = ash.infoFileDecode( ash.WorkshopFile )

    ---@type integer
    local workshop_length = 0

    hook.Add( "PreRender", "ash.Workshop", function()
        if is_ready == nil then
            is_ready = true

            if workshop_list == nil then
                ash.Logger:error( "Satellite failed to receive workshop information, " .. err_msg )
                net.Start( "ash.network" )
                net.SendToServer()
                return true
            end

            workshop_length = #workshop_list

            if workshop_length ~= 0 then
                ash.Logger:info( "Satellite successfully received workshop information, %s items preparing to download.", workshop_length )
            end

            local workshop = std.steam.workshop

            std.futures.run( function()
                ---@cast workshop_list string[]

                local elapsed = std.time.elapsed()

                local titles = {}

                for i = 1, workshop_length, 1 do
                    local wsid = workshop_list[ i ]
                    text = string.format( "Fetching '%s'", wsid )

                    local info = workshop.fetchInfo( wsid, 120 )
                    titles[ wsid ] = info.title
                end

                local files = {}

                for i = 1, workshop_length, 1 do
                    local wsid = workshop_list[ i ]
                    text = string.format( "Downloading '%s'", titles[ wsid ] )

                    files[ wsid ] = string.match( workshop.download( wsid, 900 ), "^/[^/]+/(.*)$" )
                end

                for i = 1, workshop_length, 1 do
                    local wsid = workshop_list[ i ]
                    text = string.format( "Mounting '%s'", titles[ wsid ] )

                    if not game.MountGMA( files[ wsid ] ) then
                        ash.Logger:error( "Failed to mount '%s' (%s).", titles[ wsid ], wsid )
                    end
                end

                if workshop_length ~= 0 then
                    ash.Logger:info( "Downloaded %s assets, took %.2f seconds.", workshop_length, std.time.elapsed() - elapsed )
                    timer.Remove( "ash.Workshop" )
                    text = "Ready!"
                end
            end, function()
                hook.Remove( "CreateMove", "ash.Workshop" )
                hook.Remove( "PreRender", "ash.Workshop" )
                timer.Remove( "ash.Workshop" )
                hook.Run( "ash.Loaded" )
            end )

            return true
        end

        cam_Start2D()

        local rgb = math_abs( math_sin( CurTime() * 2 ) ) * 20 + 50
        surface_SetDrawColor( rgb, rgb, rgb, 255 )
        surface_DrawRect( 0, 0, screen_width, screen_height )

        surface_SetDrawColor( 33, 33, 33, 255 )
        surface_DrawRect( loader_x, loader_y, loader_size, loader_size )

        surface_SetDrawColor( 255, 255, 255, 255 )
        surface_SetMaterial( loader_material )
        surface_DrawTexturedRect( loader_x, loader_y, loader_size, loader_size )

        surface_SetTextColor( 255, 255, 255 )
        surface_SetFont( "DermaLarge" )

        local text_width, text_height = surface_GetTextSize( text )
        surface_SetTextPos( loader_size * 0.5 + ( screen_width - loader_size - text_width ) * 0.5, ( screen_height + loader_size ) * 0.5 + text_height )

        surface_DrawText( text )

        cam_End2D()

        return true
    end, PRE_HOOK_RETURN )

end

ash.Logger:info( "Ashes calls you, %s. %s awaits.", cvars.String( "name", "unknown" ), ash.Chain[ 1 ].title )
