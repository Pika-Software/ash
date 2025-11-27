ash.reload()

---@type dreamwork.std
local std = _G.dreamwork.std

local string = std.string

---@type dreamwork.std.math
local math = std.math
local math_lerp = math.lerp
local math_clamp = math.clamp

---@type string[] | nil
local workshop_list, err_msg = ash.infoFileDecode( ash.WorkshopFile )

---@type integer
local workshop_length = 0

local sw, sh = ScrW(), ScrH()
local sw_w, sh_h = sw / 2, sh / 2

local vmin = math.min( sw, sh ) / 100

local square_size = math.floor( vmin * 5 )
local bounds = math.floor( vmin )

local x, y = sw_w - ( square_size ) * 2, sh_h - ( square_size ) * 2


local positions = {
    [ 0 ] = { x, -square_size },

    { x, y },
    { x + bounds + square_size, y },
    { x + ( bounds + square_size ) * 2, y },

    { x + ( bounds + square_size ) * 2, y + bounds + square_size },
    { x + bounds + square_size, y + bounds + square_size },
    { x, y + bounds + square_size },

    { x, y + ( bounds + square_size ) * 2 },
    { x + bounds + square_size, y + ( bounds + square_size ) * 2 },
    { x + ( bounds + square_size ) * 2, y + ( bounds + square_size ) * 2 },

    { x + ( bounds + square_size ) * 2, sh }
}

local alpha_map = {
    [ 0 ] = 0,

    40,
    60,
    80,

    90,
    120,
    150,

    180,
    200,
    220,

    -500
}

---@class ash.loader.Square
---@field index integer
---@field x integer
---@field y integer
---@field progress number
---@field x2 integer
---@field y2 integer
---@field alpha integer

---@type ash.loader.Square[]
local squares = {}

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
        alpha = alpha_map[ i ]
    }
end

local text = "Preparing"

timer.Create( "ash.Workshop", 0.5, 0, function()
    if string.byteCount( text, 0x2E --[[ . ]], false ) == 3 then
        text = string.match( text, "^(.*)%.*$" )
    else
        text = text .. "."
    end
end )

local is_ready = nil

local ash_main = std.Color( 255, 180, 50 )

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
                dots = 0
            end
        end, function()
            hook.Remove( "CreateMove", "ash.Workshop" )
            hook.Remove( "PreRender", "ash.Workshop" )
            hook.Remove( "Tick", "ash.Workshop" )
            timer.Remove( "ash.Workshop" )
        end )

        return true
    end

    cam.Start2D()

    surface.SetDrawColor( 20, 20, 20, 255 )
    surface.DrawRect( 0, 0, sw, sh )

    for _, square in ipairs( squares ) do
        surface.SetDrawColor( 55, 55, 55, square.alpha )
        surface.DrawRect( square.x - 4, square.y - 4, square_size + 4, square_size + 2 )

        if square.index == 4 then
            local progress = square.progress
            surface.SetDrawColor( math_lerp( progress, 180, ash_main.r ), math_lerp( progress, 180, ash_main.g ), math_lerp( progress, 250, ash_main.b ), square.alpha )
        elseif square.index == 5 then
            local progress = square.progress
            surface.SetDrawColor( math_lerp( progress, ash_main.r, 180 ), math_lerp( progress, ash_main.g, 180 ), math_lerp( progress, ash_main.b, 250 ), square.alpha )
        else
            surface.SetDrawColor( 180, 180, 250, square.alpha )
        end

        surface.DrawRect( square.x, square.y, square_size, square_size )
    end

    surface.SetFont( "DermaLarge" )
    local tw, th = surface.GetTextSize( text )

    surface.SetTextColor( 255, 255, 255 )
    surface.SetTextPos( x + ( ( ( bounds + square_size ) * 2 + square_size ) - tw ) / 2, y + ( ( ( bounds + square_size ) * 2 + square_size ) + th ) )
    surface.DrawText( text )

    cam.End2D()
    return true
end, PRE_HOOK_RETURN )

local FrameTime = _G.FrameTime
local current = 1

hook.Add( "CreateMove", "ash.Workshop", function( cmd )
    cmd:ClearMovement()
    cmd:SetImpulse( 0 )
    cmd:ClearButtons()
    return true
end )

hook.Add( "Tick", "ash.Workshop", function()
    if current > 9 then
        current = 1
    end

    local square = squares[ 9 - current + 1 ]
    local current_index = square.index

    local progress = square.progress

    if progress > 0.5 then
        progress = 1
    end

    if progress == 1 then
        current = current + 1
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
end )

ash.Logger:info( "Ashes calls you, %s. %s awaits.", cvars.String( "name", "unknown" ), ash.Chain[ 1 ].title )
