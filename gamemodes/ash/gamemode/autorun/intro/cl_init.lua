local surface_SetDrawColor = surface.SetDrawColor

local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D

local math_min = math.min

---@class ash.ui
local ash_ui = require( "ash.ui" )

ash_ui.font( "ash.intro.TextBig", {
    font = "Roboto Mono Medium",
    size = "25vmin"
} )

ash_ui.font( "ash.intro.Text", {
    font = "Roboto Mono Medium",
    size = "12vmin"
} )

ash_ui.font( "ash.intro.TextSmall", {
    font = "Roboto Mono Medium",
    size = "10vmin"
} )

local RT_SIZE = math_min( ash_ui.ScreenWidth, ash_ui.ScreenHeight )
local DOT_SPACING = ash_ui.scale( "0.6vmin" )
local DOT_RADIUS = ash_ui.scale( "0.2vmin" )

local dots = {}
local dot_count = 0

local rt = GetRenderTarget( "ash_intro_dots", RT_SIZE, RT_SIZE )

local function WriteTextToRT( text, font )
    if text == nil then return end

    render.PushRenderTarget( rt )
    render.OverrideAlphaWriteEnable( true, true )
    render.Clear( 0, 0, 0, 255 )

    cam_Start2D()
        surface.SetFont( font or "DermaLarge" )
        surface.SetTextColor( 255,255,255,255 )

        local lines, line_count = string.byteSplit( text, 0x0A --[[ \n ]] )

        for i = 1, line_count, 1 do
            local tw, th = surface.GetTextSize( text )
            surface.SetTextPos( ( RT_SIZE - tw ) / 2, ( RT_SIZE - th ) / 2 + ( i - 1 ) * th / line_count )
            surface.DrawText( lines[ i ] )
        end
    cam_End2D()

    render.OverrideAlphaWriteEnable( false, false )
    render.PopRenderTarget()
end

local function WriteImageToRT( mat )
    render.PushRenderTarget( rt )
    render.OverrideAlphaWriteEnable( true, true )
    render.Clear( 0, 0, 0, 255 )

    cam_Start2D()
        surface.SetMaterial( mat )
        surface_SetDrawColor( 255, 255, 255, 255 )
        surface.DrawTexturedRect( 0, 0, RT_SIZE, RT_SIZE )
    cam_End2D()

    render.OverrideAlphaWriteEnable( false, false )
    render.PopRenderTarget()
end

local function BuildDotMatrixFromRT()
    render.PushRenderTarget( rt )
    render.CapturePixels()

    dot_count = 0

    for y = 0, RT_SIZE - 1, DOT_SPACING do
        for x = 0, RT_SIZE - 1, DOT_SPACING do
            local r, g, b, a = render.ReadPixel( x, y )
            if ( a == nil or a > 10 ) and ( r > 10 or g > 10 or b > 10 ) then
                dot_count = dot_count + 1

                local dot = dots[ dot_count ]
                if dot == nil then
                    dots[ dot_count ] = {
                        tx = x,
                        ty = y,
                        r = r,
                        g = g,
                        b = b,
                        x = x,
                        y = y,
                        t = 1,
                        p0 = { x = x, y = y },
                        p1 = { x = x, y = y },
                        p2 = { x = x, y = y },
                        p3 = { x = x, y = y },
                    }
                else
                    dot.tx = x
                    dot.ty = y
                end
            end
        end
    end


    render.PopRenderTarget()
end

local surface_DrawCircle = surface.DrawCircle
local HSVToColor = HSVToColor

local math_random = math.random
local math_clamp = math.clamp
local math_sqrt = math.sqrt
local math_abs = math.abs

local ash_intro = console.Variable( {
    name = "ash.intro",
    type = "string",
    archive = true
} )

hook.Add( "ash.Loaded", "Welcome", function()
    local hash = util.SHA1( game.GetIPAddress() )
    ash.Logger:debug( "Generated hash '%s' for IP '%s'.", hash, game.GetIPAddress() )

    if ash_intro.value == hash then return end
    ash_intro.value = hash

    WriteTextToRT( "</Powered by Ash>", "ash.intro.Text" )
    BuildDotMatrixFromRT()

    local randOffset = 6
    local speed = 2.5

    local fading = false
    local alpha = 255

    local hue, saturation, lightness = 20, 1, 1

    futures.run( function()
        -- hue, saturation, lightness = ash_ui.Colors.ash_main:toHSV()
        futures.sleep( 2 )
        if fading then return end

        hue, saturation, lightness = ash_ui.Colors.dreamwork_main:toHSV()

        WriteTextToRT( "Developers:\n- Unknown Developer\n- AngoNex\n", "ash.intro.TextSmall" )
        BuildDotMatrixFromRT()

        futures.sleep( 2 )
        if fading then return end

        WriteTextToRT( "'^'", "ash.intro.TextBig" )
        BuildDotMatrixFromRT()

        futures.sleep( 2 )
        fading = true
    end )

    local skip_keys = {
        [ KEY_ESCAPE ] = true,
        [ KEY_SPACE ] = true,
        [ KEY_ENTER ] = true
    }

    hook.Add( "ash.player.Input", "Welcome", function( pl, key_id, is_down, is_local )
        if not ( is_down and is_local ) or skip_keys[ key_id ] == nil then return end
        hook.Remove( "ash.player.Input", "Welcome" )
        fading = true
    end )

    hook.Add( "PostRender", "Welcome", function()
        if alpha == 0 then
            hook.Remove( "PostRender", "Welcome" )
            return
        end

        local frame_time = FrameTime()

        if fading then
            alpha = math_clamp( alpha - frame_time * 255, 0, 255 )
        end

        local screen_width, screen_height = ash_ui.ScreenWidth, ash_ui.ScreenHeight

        cam_Start2D()

        surface_SetDrawColor( 0, 0, 0, alpha )
        surface.DrawRect( 0, 0, screen_width, screen_height )

        local ox = screen_width / 2 - RT_SIZE / 2
        local oy = screen_height / 2 - RT_SIZE / 2

        for i = 1, dot_count, 1 do
            local dot = dots[ i ]

            local tx, ty = dot.tx, dot.ty
            local frac = dot.t

            if frac >= 1 or math_abs( dot.p3.x - tx ) > 1 or math_abs( dot.p3.y - ty ) > 1 then
                frac = 0
                dot.t = frac

                dot.p0 = {
                    x = dot.x,
                    y = dot.y
                }

                dot.p1 = {
                    x = dot.x + ( math_random() - 0.5 ) * randOffset,
                    y = dot.y + ( math_random() - 0.5 ) * randOffset
                }

                dot.p2 = {
                    x = tx + ( math_random() - 0.5 ) * randOffset,
                    y = ty + ( math_random() - 0.5 ) * randOffset
                }

                dot.p3 = {
                    x = tx,
                    y = ty
                }
            end

            frac = math_min( frac + speed * frame_time, 1 )
            dot.t = frac

            local invT = 1 - frac

            local p0, p1, p2, p3 = dot.p0, dot.p1, dot.p2, dot.p3

            local x = invT ^ 3 * p0.x + 3 * invT ^ 2 * frac * p1.x + 3 * invT * frac ^ 2 * p2.x + frac ^ 3 * p3.x
            local y = invT ^ 3 * p0.y + 3 * invT ^ 2 * frac * p1.y + 3 * invT * frac ^ 2 * p2.y + frac ^ 3 * p3.y

            dot.x = x
            dot.y = y

            local dx = dot.x - tx
            local dy = dot.y - ty
            local dist = math_sqrt( dx * dx + dy * dy )
            local brightness = ( 1 - dist / 30 )

            local color = HSVToColor( hue + x % 15, saturation, lightness )
            surface_DrawCircle( ox + x, oy + y, DOT_RADIUS, color.r, color.g, color.b, alpha * brightness )
        end

        cam_End2D()
    end )
end )
