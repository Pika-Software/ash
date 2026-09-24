include( "shared.lua" )

---@class ash_weapon_base: SWEP
local SWEP = SWEP

---@type ash.ui
local ash_ui = import "ash.ui"

---@type ash.ui.rndx
local rndx = import "ash.ui.rndx"

function SWEP:DrawHUD()
	local size_sight_w = math.floor(ash_ui.ScreenHeight * self.Secondary.SightWScale)
	local size_sight_h = math.floor(ash_ui.ScreenHeight * self.Secondary.SightHScale)
	local midX = ash_ui.ScreenCenterX
	local midY = ash_ui.ScreenCenterY
	local color = self.Secondary.SightColor

	local texture = self.Secondary.SightTexture
	if not self.Secondary.SightNoDraw and self:getInSight() and texture then
		local center_sight_w = math.floor(size_sight_w * 0.5)
		local center_sight_h = math.floor(size_sight_h * 0.5)
		local size_top = math.floor((ash_ui.ScreenHeight * 0.5) - math.floor(size_sight_h * 0.5) )

		--lines
		if self.Secondary.SightDrawLines then
			surface.SetDrawColor(2, 3, 2, 255)
			surface.DrawRect(0, ash_ui.ScreenHeight * 0.5, ash_ui.ScreenWidth, 1 )

			surface.SetDrawColor(2, 3, 2, 255)
			surface.DrawRect(ash_ui.ScreenWidth * 0.5, 0, 1, ash_ui.ScreenHeight )
		end


		surface.SetDrawColor(color.r, color.g, color.b, color.a)
		surface.SetTexture(texture)
		surface.DrawTexturedRect(midX - center_sight_w, midY - center_sight_h, size_sight_w, size_sight_h)

		local size = midX - center_sight_w
		surface.SetDrawColor(2, 3, 2, 255)

		--right
		surface.DrawRect(0, 0, size, ash_ui.ScreenHeight)

		--left
		surface.DrawRect(ash_ui.ScreenWidth - size, 0, size, ash_ui.ScreenHeight)

		--up
		surface.DrawRect(0, 0, ash_ui.ScreenWidth, size_top )

		--down
		surface.DrawRect(0, ash_ui.ScreenHeight - size_top, ash_ui.ScreenWidth, size_top )
	end
end

do
    local string_to_color = _G.string.ToColor
    local cl_ash_crosshair_color = console.Variable( {
        name = "cl_ash_crosshair_color",
        type = "string",
        default = "0 255 0 255",
        client_dll = true,
        archive = true,
    })

    local cl_ash_crosshair_size = console.Variable( {
        name = "cl_ash_crosshair_size",
        type = "integer",
        default = 8,
        min = 1,
        max = 16,
        client_dll = true,
        archive = true,
    })

    local cl_ash_crosshair_width = console.Variable( {
        name = "cl_ash_crosshair_width",
        type = "integer",
        default = 13,
        min = 1,
        max = 4095,
        client_dll = true,
        archive = true,
    })

    local cl_ash_crosshair_height = console.Variable( {
        name = "cl_ash_crosshair_height",
        type = "integer",
        default = 3,
        min = 1,
        max = 9,
        client_dll = true,
        archive = true,
    })

    local cl_ash_crosshair_drawlines = console.Variable( {
        name = "cl_ash_crosshair_drawlines",
        type = "boolean",
        min = 0,
        max = 1,
        default = true,
        client_dll = true,
        archive = true,
    })

    local cl_ash_crosshair_drawdot = console.Variable( {
        name = "cl_ash_crosshair_drawdot",
        type = "boolean",
        min = 0,
        max = 1,
        default = true,
        client_dll = true,
        archive = true,
    })


    local color_outline = Color(0, 0, 0, 255)
    ---@diagnostic disable-next-line
    local color_box = string_to_color(cl_ash_crosshair_color.value)

    cl_ash_crosshair_color:attach(function( _, new_value )
        timer.Simple(0, function()
            ---@diagnostic disable-next-line
            color_box = string_to_color(cl_ash_crosshair_color.value)
        end)
    end)

    local function DrawOutlineBox(x, y, w, h)
        rndx.Draw(0, x, y, w, h, color_box)
        rndx.DrawOutlined(0, x, y, w, h, color_outline, 1, 0)
    end

    local mat_dot = Material("ash/crosshair/cross_dot.png", "smooth")
    local mat_cross = Material("ash/crosshair/cross_black.png", "smooth")
    local dot_x, dot_y = -1, -1
    local calc_spread = 0

    function FFDrawCrosshair(ply, punch, spread, x, y)
    	if dot_x == -1 then
    		dot_x, dot_y = x, y
    	end

    	-- dot_x, dot_y = Lerp(FrameTime() * 4, dot_x, x), Lerp(FrameTime() * 4, dot_y, y)
        dot_x = math.approach(dot_x, x, FrameTime() * 10)
        dot_y = math.approach(dot_y, y, FrameTime() * 10)

        local size_line_w = cl_ash_crosshair_width.value
        size_line_w = size_line_w % 2 == 0 and size_line_w + 1 or size_line_w

        local size_line_h = cl_ash_crosshair_height.value
        size_line_h = size_line_h % 2 == 0 and size_line_h + 1 or size_line_h

        local size_center = cl_ash_crosshair_size.value

    	local x_add = 0

        -- calc_spread = Lerp(FrameTime() * 15, calc_spread, (spread) * 500)
        calc_spread = math.approach(calc_spread, (spread) * 500, FrameTime() * 200)

        x_add = x_add + (calc_spread)


        size_center = size_center + x_add

        if cl_ash_crosshair_drawlines.value then
            --left
            DrawOutlineBox(x - size_line_w - size_center, y - math.floor(size_line_h * 0.5), size_line_w, size_line_h)

            --right
            DrawOutlineBox(x + size_center + 1, y - math.floor(size_line_h * 0.5), size_line_w, size_line_h)

            --bottom
            DrawOutlineBox(x - math.floor(size_line_h * 0.5), y + size_center + 1, size_line_h, size_line_w)

            --top
            DrawOutlineBox(x - math.floor(size_line_h * 0.5), y - size_line_w - size_center, size_line_h, size_line_w)
        end

        local dot_size = 9

        -- if cl_ash_crosshair_drawdot.value then
        --     surface.SetDrawColor(0, 0, 0, 255)
        --     surface.SetMaterial(mat_cross)
        --     surface.DrawTexturedRect(dot_x - math.floor( dot_size * 0.5 ), dot_y - math.floor( dot_size * 0.5 ), dot_size, dot_size)

        --     surface.SetDrawColor(224, 0, 0, 255)
        --     surface.SetMaterial(mat_dot)
        --     surface.DrawTexturedRect(dot_x - math.floor( dot_size * 0.5 ), dot_y - math.floor( dot_size * 0.5 ), dot_size, dot_size)
        -- end
    end

    function SWEP:DoDrawCrosshair( x, y )
    	if self:getInSight() then
    		return false
    	end

    	local ply = self:GetOwner()

        local spread = self:calcSpread()

        local num_spread = 0
        if spread.x > spread.y then
            num_spread = spread.x
        else
            num_spread = spread.y
        end

        num_spread = num_spread / 500

        FFDrawCrosshair(ply, Angle(self:getKickCurX(), self:getKickCurY(), self:getKickCurZ()), num_spread, x, y)

        return true
    end
end
