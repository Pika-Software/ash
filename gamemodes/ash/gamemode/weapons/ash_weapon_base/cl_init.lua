include "shared.lua"

---@class ash_weapon_base: SWEP
local SWEP = SWEP

---@type ash.ui
local ash_ui = import "ash.ui"

---@type ash.ui.rndx
local rndx = import "ash.ui.rndx"

local developer = GetConVar( "developer" )

assert( developer ~= nil, "developer not found" )


local color_red = Color( 255, 0, 0 )
local scale = 0.8

local scale_map = ash_ui.scaleMap( {
    [ "Line" ] = "35vmin",
    [ "LineMini" ] = "15vmin",
    [ "LineIndent" ] = "3vmin",
    [ "LineSide" ] = "5vmin",
    [ "Dot" ] = "4px",
    [ "LineDown" ] = "25vmin",
    [ "LineYSize" ] = "2px",
} )

local line_count = 4
local function drawScope()
    local x = ash_ui.ScreenCenterX
    local y = ash_ui.ScreenCenterY

    local size_dot = scale_map.Dot
    local size_dot_mid = size_dot * 0.5

    rndx.Draw( 16, x - size_dot_mid, y - size_dot_mid, size_dot, size_dot, color_red, rndx.SHAPE_CIRCLE )

    local line_size = scale_map.Line
    local line_indent = scale_map.LineIndent
    local line_size_side = scale_map.LineSide
    local line_y_size = scale_map.LineYSize
    local line_y_size_center = scale_map.LineYSize * 0.5

    rndx.Draw( 0, x + line_indent, y - line_y_size_center, line_size, line_y_size, color_black, 0 )
    rndx.Draw( 0, x + line_indent + line_size, y - ( line_size_side * 0.5 ), line_y_size, line_size_side, color_black, 0 )

    rndx.Draw( 0, x - line_indent - line_size, y - line_y_size_center, line_size, line_y_size, color_black, 0 )
    rndx.Draw( 0, x - line_indent - line_size, y - ( line_size_side * 0.5 ), line_y_size, line_size_side, color_black, 0 )

    local down_line_pos = y + line_indent
    local down_line_size = scale_map.LineDown
    rndx.Draw( 0, x - line_y_size_center, down_line_pos, line_y_size, down_line_size, color_black, 0 )

    local line_mini = scale_map.LineMini
    local line_mini_indent = down_line_size / (line_count)
    local line_mini_center = line_mini * 0.5

    for i = 1, line_count do
        rndx.Draw( 0, x - line_mini_center, down_line_pos + ( i * line_mini_indent ), line_mini, 2, color_black, 0 )
    end
end

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
			-- surface.SetDrawColor(2, 3, 2, 255)
			-- surface.DrawRect(0, ash_ui.ScreenHeight * 0.5, ash_ui.ScreenWidth, 1 )

			-- surface.SetDrawColor(2, 3, 2, 255)
			-- surface.DrawRect(ash_ui.ScreenWidth * 0.5, 0, 1, ash_ui.ScreenHeight )

            drawScope()
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


    self:actionRun( "drawHUD" )
end

function SWEP:calcView(view)
    view.origin, view.angles = LocalToWorld( vector_origin, self:GetKick(), view.origin, view.angles )

    if self:getInSight() then
        view.fov = view.fov * (self.Secondary.SightStateZoom[ self:getSightState() ] or 1)
    end
end
do
    local cl_ash_weapon_skin = console.Variable( {
        name = "cl_ash_weapon_skin",
        type = "boolean",
        default = true,
        min = 0,
        max = 1,
        client_dll = true,
        archive = true,
    })

    local Entity_GetSkin = Entity.GetSkin
    local Entity_SetSkin = Entity.SetSkin
    function SWEP:CalcViewModelView( vm, oldpos, oldeyeang, pos, ang )
        local npos, nang = pos, ang

        if self:getInSight() then
            npos, nang = oldpos, oldeyeang
        end

        local kick = self:GetKick()

        local sight_pos, sight_ang = self.Secondary.ViewModelSightPos, self.Secondary.ViewModelSightAng

        local scale_pos = self:getSightProgress()
        if scale_pos then
            sight_pos = sight_pos * scale_pos
            sight_ang = sight_ang * scale_pos
        end

        npos, nang = LocalToWorld( vector_origin, kick, npos, nang )
        npos, nang = LocalToWorld( sight_pos, sight_ang, npos, nang )

        local skin = self:getSkin() or 0
        if cl_ash_weapon_skin.value then
            if Entity_GetSkin( vm ) ~= skin then
                Entity_SetSkin( vm, skin )
            end
        else
            if Entity_GetSkin( vm ) ~= 0 then
                Entity_SetSkin( vm, 0 )
            end
        end

        return npos, nang
    end


    local Entity_DrawModel = Entity.DrawModel
    function SWEP:RenderOverride()
        local skin = self:getSkin() or 0
        if cl_ash_weapon_skin.value then
            if Entity_GetSkin( self ) ~= skin then
                Entity_SetSkin( self, skin )
            end
        else
            if Entity_GetSkin( self ) ~= 0 then
                Entity_SetSkin( self, 0 )
            end
        end

        Entity_DrawModel( self )
    end
end

function SWEP:GetViewModelPosition(pos, ang)
    return pos, ang
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

    local function drawCrosshair(ply, punch, spread, x, y)
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
    		return not ( developer:GetBool() and LocalPlayer():IsSuperAdmin() ) and true or false
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

        drawCrosshair(ply, Angle(self:getKickCurX(), self:getKickCurY(), self:getKickCurZ()), num_spread, x, y)

        return true
    end

    do
        local Player_GetObserverMode = Player.GetObserverMode
        local Player_GetObserverTarget = Player.GetObserverTarget
        local Player_GetActiveWeapon = Player.GetActiveWeapon


        hook.Add( "RenderScreenspaceEffects", "ChromaEffect", function()
            local lp = LocalPlayer()

            if lp ~= nil and lp:IsValid() then
                local pl = lp
                if Player_GetObserverMode( lp ) == OBS_MODE_IN_EYE then
                    local target = Player_GetObserverTarget( lp )

                    if target ~= nil and target:IsValid() and target:IsPlayer() then
                        pl = target
                    end
                end


                local wep = Player_GetActiveWeapon( pl )

                ---@cast wep ash_weapon_base

                if wep ~= nil and wep:IsValid() and wep.IsAshWeapon then
                    wep:actionRun( "screenSpaceEffect" )
                end
            end
        end )
    end
end

local STEPS_POS = { 0.001, 0.01, 0.05, 0.1, 0.5, 1 }
local STEPS_ANG = { 0.01, 0.1, 0.5, 1, 5, 15 }

local COL_ACTIVE = Color( 60, 130, 220 )
local COL_IDLE   = Color( 70, 70, 70 )

local function Fmt( v )
    local s = string.format( "%.4f", v )
    s = s:gsub( "0+$", "" ):gsub( "%.$", "" )
    if s == "-0" or s == "" then s = "0" end
    return s
end

local function PrintSight( pos, ang )
    print( "----" )
    printf( "SWEP.Secondary.ViewModelSightPos = Vector( %f, %f, %f )\nSWEP.Secondary.ViewModelSightAng = Angle( %f, %f, %f )",
        pos.x, pos.y, pos.z,
        ang.x, ang.y, ang.z )
end

local function BuildSightString( pos, ang )
    return string.format( "SWEP.Secondary.ViewModelSightPos = Vector( %f, %f, %f )\nSWEP.Secondary.ViewModelSightAng = Angle( %f, %f, %f )",
        pos.x, pos.y, pos.z,
        ang.x, ang.y, ang.z )
end

local function OpenScopeSetup( wep )
    if not IsValid( wep ) then return end

    wep.Secondary = wep.Secondary or {}
    wep.Secondary.ViewModelSightPos = wep.Secondary.ViewModelSightPos or Vector()
    wep.Secondary.ViewModelSightAng = wep.Secondary.ViewModelSightAng or Angle()

    local ViewModelSightPos = wep.Secondary.ViewModelSightPos
    local ViewModelSightAng = wep.Secondary.ViewModelSightAng

    local origPos = Vector( ViewModelSightPos.x, ViewModelSightPos.y, ViewModelSightPos.z )
    local origAng = Angle( ViewModelSightAng.x, ViewModelSightAng.y, ViewModelSightAng.z )

    local step = { pos = 0.01, ang = 0.1 }
    local refreshers = {}

    local function RefreshAll()
        for _, fn in ipairs( refreshers ) do fn() end
    end

    local frame = ash_ui.setPanel( "ash.weapon.ScopeSetup", "DFrame" )
    frame:SetSize( 340, 440 )
    frame:CenterVertical()
    frame:MakePopup()
    frame:SetTitle( "Scope Setup" )

    -- Множитель шага: Shift = x10, Ctrl = /10
    local function Mult()
        if input.IsShiftDown() then return 10 end
        if input.IsControlDown() then return 0.1 end
        return 1
    end

    -- Выбор шага
    local function AddStepSelector( title, list, key )
        local lbl = vgui.Create( "DLabel", frame )
        lbl:Dock( TOP )
        lbl:DockMargin( 8, 6, 8, 2 )
        lbl:SetText( title )

        local row = vgui.Create( "DPanel", frame )
        row:Dock( TOP )
        row:SetTall( 24 )
        row:DockMargin( 8, 0, 8, 0 )
        row.Paint = nil

        for _, value in ipairs( list ) do
            local b = vgui.Create( "DButton", row )
            b:Dock( LEFT )
            b:SetWide( 48 )
            b:DockMargin( 0, 0, 2, 0 )
            b:SetText( tostring( value ) )
            b:SetTextColor( color_white )
            b.Paint = function( self, w, h )
                draw.RoundedBox( 4, 0, 0, w, h, step[ key ] == value and COL_ACTIVE or COL_IDLE )
            end
            b.DoClick = function()
                step[ key ] = value
            end
        end
    end

    -- Строка редактирования одной оси
    local function AddRow( label, group, get, set )
        local row = vgui.Create( "DPanel", frame )
        row:Dock( TOP )
        row:SetTall( 28 )
        row:DockMargin( 8, 0, 8, 4 )
        row.Paint = nil

        local function Apply( v )
            set( math.round( v, 4 ) )
            RefreshAll()
            PrintSight( ViewModelSightPos, ViewModelSightAng )
        end

        local function Nudge( dir )
            Apply( get() + dir * step[ group ] * Mult() )
        end

        local lbl = vgui.Create( "DLabel", row )
        lbl:Dock( LEFT )
        lbl:SetWide( 50 )
        lbl:SetText( label )

        -- Кнопка обнуления (справа)
        local zero = vgui.Create( "DButton", row )
        zero:Dock( RIGHT )
        zero:SetWide( 24 )
        zero:DockMargin( 2, 0, 0, 0 )
        zero:SetText( "0" )
        zero.DoClick = function() Apply( 0 ) end

        -- Кнопки с удержанием: -, +
        local function HoldButton( text, dir, side )
            local b = vgui.Create( "DButton", row )
            b:Dock( side )
            b:SetWide( 30 )
            b:DockMargin( 2, 0, 2, 0 )
            b:SetText( text )
            b.Think = function( self )
                if self:IsDown() then
                    local t = CurTime()
                    if not self.held then
                        self.held = true
                        self.nextRep = t + 0.4
                        Nudge( dir )
                    elseif t >= self.nextRep then
                        self.nextRep = t + 0.05
                        Nudge( dir )
                    end
                else
                    self.held = false
                end
            end
            return b
        end

        HoldButton( "+", 1, RIGHT )

        local entry = vgui.Create( "DTextEntry", row )
        entry:Dock( FILL )

        HoldButton( "-", -1, RIGHT )
        -- "-" докается правее, поэтому переставим порядок через вторую пару:
        -- (см. ниже: меняем сторону на LEFT для минуса)

        entry:SetText( Fmt( get() ) )

        local function Commit()
            local n = tonumber( entry:GetValue() )
            if n then Apply( n ) else entry:SetText( Fmt( get() ) ) end
        end
        entry.OnEnter = Commit
        entry.OnLoseFocus = Commit

        -- Колёсико мыши над полем: шаг, Shift = x10, Ctrl = /10
        entry.OnMouseWheeled = function( self, delta )
            Nudge( delta > 0 and 1 or -1 )
            return true
        end

        -- Стрелки вверх/вниз в поле
        entry.OnKeyCodeTyped = function( self, code )
            if code == KEY_UP then Nudge( 1 ) return end
            if code == KEY_DOWN then Nudge( -1 ) return end
            if code == KEY_ENTER or code == KEY_PAD_ENTER then Commit() return end
            DTextEntry.OnKeyCodeTyped( self, code )
        end

        refreshers[ #refreshers + 1 ] = function()
            if not entry:HasFocus() then
                entry:SetText( Fmt( get() ) )
            end
        end
    end

    -- Позиция
    AddStepSelector( "Шаг позиции", STEPS_POS, "pos" )
    AddRow( "Pos X", "pos", function() return ViewModelSightPos.x end, function( v ) ViewModelSightPos.x = v end )
    AddRow( "Pos Y", "pos", function() return ViewModelSightPos.y end, function( v ) ViewModelSightPos.y = v end )
    AddRow( "Pos Z", "pos", function() return ViewModelSightPos.z end, function( v ) ViewModelSightPos.z = v end )

    -- Угол
    AddStepSelector( "Шаг угла", STEPS_ANG, "ang" )
    AddRow( "Ang P", "ang", function() return ViewModelSightAng.x end, function( v ) ViewModelSightAng.x = v end )
    AddRow( "Ang Y", "ang", function() return ViewModelSightAng.y end, function( v ) ViewModelSightAng.y = v end )
    AddRow( "Ang R", "ang", function() return ViewModelSightAng.z end, function( v ) ViewModelSightAng.z = v end )

    local hint = vgui.Create( "DLabel", frame )
    hint:Dock( TOP )
    hint:DockMargin( 8, 4, 8, 0 )
    hint:SetWrap( true )
    hint:SetAutoStretchVertical( true )
    hint:SetText( "Колёсико / ↑↓ в поле: изменить на шаг. Shift = x10, Ctrl = /10. Кнопки +/- можно удерживать." )

    -- Нижние кнопки
    local btnPanel = vgui.Create( "DPanel", frame )
    btnPanel:Dock( BOTTOM )
    btnPanel:SetTall( 30 )
    btnPanel:DockMargin( 8, 4, 8, 8 )
    btnPanel.Paint = nil

    local btnCopy = vgui.Create( "DButton", btnPanel )
    btnCopy:Dock( LEFT )
    btnCopy:SetWide( 150 )
    btnCopy:SetText( "Копировать" )
    btnCopy.DoClick = function()
        SetClipboardText( BuildSightString( ViewModelSightPos, ViewModelSightAng ) )
        PrintSight( ViewModelSightPos, ViewModelSightAng )
    end

    local btnReset = vgui.Create( "DButton", btnPanel )
    btnReset:Dock( RIGHT )
    btnReset:SetWide( 150 )
    btnReset:SetText( "Сбросить" )
    btnReset.DoClick = function()
        ViewModelSightPos.x = origPos.x
        ViewModelSightPos.y = origPos.y
        ViewModelSightPos.z = origPos.z
        ViewModelSightAng.x = origAng.x
        ViewModelSightAng.y = origAng.y
        ViewModelSightAng.z = origAng.z
        RefreshAll()
        PrintSight( ViewModelSightPos, ViewModelSightAng )
    end

    return frame
end

concommand.Add( "ash_weapon_scope_menu", function()
    OpenScopeSetup( LocalPlayer():GetActiveWeapon() )
end )
