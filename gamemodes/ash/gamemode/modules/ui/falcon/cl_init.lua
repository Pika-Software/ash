---@class ash.ui.falcon
local falcon = {}

---@type ash.ui
local ash_ui = import "ash.ui"

---@type ash.ui.rndx
local rndx = import "ash.ui.rndx"


local last_dock_margin = {
    top = 0,
    left = 0,
    right = 0,
    bottom = 0,
}

local last_dock_padding = {
    top = 0,
    left = 0,
    right = 0,
    bottom = 0,
}

do
    ---@class ash.ui.falcon.base_panel : Panel
    ---@field keyValue table<string, any>
    ---@field steps table<string, any>
    ---@field methods table<string, function>
    ---@field dockMargin fun(pnl: ash.ui.falcon.base_panel, tbl: table)
    ---@field dockPadding fun(pnl: ash.ui.falcon.base_panel, tbl: table)
    ---@field dock fun(pnl: ash.ui.falcon.base_panel, dock_type: number)
    ---@field setSize fun(pnl: ash.ui.falcon.base_panel, tbl: table)
    ---@field center fun(pnl: ash.ui.falcon.base_panel)
    local BASE_PANEL = {}

    local function convertUnitsToPixels( struct )
        for name, v in pairs( struct ) do
            struct[ name ] = ash_ui.scale( v )
        end
    end

    local color_background = Color( 10, 10, 10, 200 )
    function BASE_PANEL:Init()
        self.keyValue = {}
        self.steps = {}
        self.methods = {}
        self.paints = {}
        self.paintsBack = {}
        self.actions = {}

        self:setValue( "background.color", color_background )
        self:setValue( "background.round", 4 )
        self:setValue( "background.flags", rndx.SHAPE_FIGMA )

        self:newMethod( "dock", function( pnl, dock_type )
            pnl:Dock( dock_type )
        end )

        self:newMethod( "dockMargin", function( pnl, tbl )
            local left, top, right, bottom = pnl:GetDockMargin()

            convertUnitsToPixels( tbl )

            left = tbl.left or left
            top = tbl.top or top
            right = tbl.right or right
            bottom = tbl.bottom or bottom

            pnl:DockMargin( left, top, right, bottom )
        end )

        self:newMethod( "dockPadding", function( pnl, tbl )
            local left, top, right, bottom = pnl:GetDockPadding()

            convertUnitsToPixels( tbl )

            left = tbl.left or left
            top = tbl.top or top
            right = tbl.right or right
            bottom = tbl.bottom or bottom

            pnl:DockPadding( left, top, right, bottom )
        end )

        self:newMethod( "setSize", function( pnl, tbl )
            local w, h = pnl:GetSize()

            convertUnitsToPixels( tbl )

            if tbl.width then
                w = tbl.width
            end

            if tbl.height then
                h = tbl.height
            end

            pnl:SetSize( w, h )
        end )

        self:newMethod( "paint", function( pnl, name, func )
            pnl.paints[ name ] = func
        end )

        self:newMethod( "paintBack", function( pnl, name, func )
            pnl.paintsBack[ name ] = func
        end )

        self:newMethod( "removePaint", function( pnl, name )
            pnl.paints[ name ] = nil
        end )

        self:newMethod( "removePaintBack", function( pnl, name )
            pnl.paintsBack[ name ] = nil
        end )

        self:newMethod( "center", function( pnl )
            pnl:Center()
        end )

        self:newMethod( "makePopup", function( pnl )
            pnl:MakePopup()
        end )

        self:newMethod( "setVisible", function( pnl, visible )
            pnl:SetVisible( visible )
        end )
    end

    function BASE_PANEL:Paint( w, h )
        for _, func in pairs( self.paintsBack ) do
            func( self, w, h )
        end

        if not self:getValue( "noDrawBackground", false ) then
            rndx.Draw( self:getValue( "background.round" ) or 0, 0, 0, w, h, self:getValue( "background.color" ) or color_background, self:getValue( "background.flags" ) or 0 )
        end

        for _, func in pairs( self.paints ) do
            func( self, w, h )
        end
    end

    ---@param key string
    ---@param value any
    ---@return ash.ui.falcon.base_panel
    function BASE_PANEL:setValue( key, value )
        self.keyValue[ key ] = value
        return self
    end

    ---@param key string
    ---@return any
    function BASE_PANEL:getValue( key, fallback )
        return self.keyValue[ key ] or fallback
    end

    function BASE_PANEL:addStep( key, ... )
        self.steps[ key ] = { ... }
    end

    function BASE_PANEL:runMethod( key, ... )
        local func = self.methods[ key ]
        if func then
            func( self, ... )
        end
    end

    ---@return ash.ui.falcon.base_panel
    function BASE_PANEL:struct( struct )
        self.steps = table.copy( struct )
        return self
    end

    function BASE_PANEL:newMethod( key, func )
        self[ key ] = function( pnl, ... )
            pnl:addStep( key, ... )
            func( pnl, ... )

            return pnl
        end

        self.methods[ key ] = func
    end

    function BASE_PANEL:addAction( class, name, callback )
        self.actions[ class ] = self.actions[ class ] or {}
        self.actions[ class ][ name ] = callback

        return self
    end

    function BASE_PANEL:runAction( class, ... )
        local actions = self.actions[ class ]
        if actions then
            for _, func in pairs( actions ) do
                func( self, ... )
            end
        end
    end

    function BASE_PANEL:OnKeyCodeReleased( keycode )
        self:runAction( "keyCodeReleased", keycode )
    end

    function BASE_PANEL:OnKeyCodePressed( keycode )
        self:runAction( "keyCodePressed", keycode )
    end

    function BASE_PANEL:OnScreenSizeChanged( w, h )
        self:runAction( "screenSizeChanged", w, h )
    end

    function BASE_PANEL:OnMouseMoved( x, y )
        self:runAction( "mouseMoved", x, y )
    end

    function BASE_PANEL:OnMousePressed( keyCode )
        self:runAction( "mousePressed", keyCode )
    end

    function BASE_PANEL:OnMouseReleased( keyCode )
        self:runAction( "mouseReleased", keyCode )

        if keyCode == MOUSE_LEFT then
            self:runAction( "onClick" )
        elseif keyCode == MOUSE_RIGHT then
            self:runAction( "onRightClick" )
        end
    end

    function BASE_PANEL:OnRemove()
        self:runAction( "remove" )
    end

    function BASE_PANEL:OnCursorEntered()
        self:runAction( "cursorEntered" )
    end

    function BASE_PANEL:OnCursorExited()
        self:runAction( "cursorExited" )
    end

    function BASE_PANEL:Think()
        self:runAction( "think" )
    end

    function BASE_PANEL:show()
        self:SetVisible( true )
        self:runAction( "show" )
        self:AlphaTo( 255, 0.2, 0, function()
            if IsValid( self ) then
                self:runAction( "showComplete" )
            end
        end )

        input.SetCursorPos( self:getValue( "saved_mouse_x", ash_ui.ScreenCenterX ), self:getValue( "saved_mouse_y", ash_ui.ScreenCenterY ) )

        return self
    end

    function BASE_PANEL:hide()
        local x, y = input.GetCursorPos()
        self:setValue( "saved_mouse_x", x )
        self:setValue( "saved_mouse_y", y )
        self:runAction( "hide" )
        self:AlphaTo( 0, 0.2, 0, function()
            if IsValid( self ) then
                x, y = input.GetCursorPos()
                self:setValue( "saved_mouse_x", x )
                self:setValue( "saved_mouse_y", y )
                self:runAction( "hideComplete" )
                self:SetVisible( false )
            end
        end )

        return self
    end

    ---@return ash.ui.falcon.base_panel
    function BASE_PANEL:build()
        for key, vars in pairs( self.steps ) do
            self:runMethod( key, vars ~= true and unpack( vars ) or nil )
        end

        return self
    end

    do
        ---@class ash.falcon.panel : ash.ui.falcon.base_panel
        local PANEL = {}

        vgui.Register( "ash.falcon.panel", BASE_PANEL, "Panel" )
    end

    do
        ---@class ash.falcon.frame : ash.ui.falcon.base_panel
        local PANEL = {}

        vgui.Register( "ash.falcon.frame", BASE_PANEL, "EditablePanel" )
    end

    do
        ---@class ash.falcon.button : ash.ui.falcon.base_panel
        local PANEL = {}

        function PANEL:Init()
            self:dock( TOP )
        end

        vgui.Register( "ash.falcon.button", PANEL, "ash.falcon.panel" )
    end

    do
        ---@class ash.falcon.layout : ash.ui.falcon.base_panel
        ---@field setSpace fun( self: ash.falcon.layout, tbl: table )
        ---@field SetSpaceX fun( self: ash.falcon.layout, w: number )
        ---@field SetSpaceY fun( self: ash.falcon.layout, h: number )
        local PANEL = {}

        for key, value in pairs( BASE_PANEL ) do
            PANEL[ key ] = value
        end

        local old_init = PANEL.Init
        function PANEL:Init()
            old_init( self )

            self:dock( FILL )

            self:setValue( "background.color", Color( 0, 0, 0, 0 ) )

            self:newMethod( "setSpace", function( pnl, tbl )
                local w, h = pnl:GetSize()

                convertUnitsToPixels( tbl )

                if tbl.x then
                    w = tbl.x
                end

                if tbl.y then
                    h = tbl.y
                end

                self:SetSpaceX( w )
                self:SetSpaceY( h )
            end )
        end

        vgui.Register( "ash.falcon.layout", PANEL, "DIconLayout" )
    end

    do
        ---@class ash.falcon.scroll : ash.ui.falcon.base_panel
        local PANEL = {}

        for key, value in pairs( BASE_PANEL ) do
            PANEL[ key ] = value
        end

        local old_init = PANEL.Init
        local color_background_vbar = Color( 255, 255, 255 )
        local rndx_flags = rndx.SHAPE_FIGMA
        PANEL.Init = function( self )
            old_init( self )
            self:dock( FILL )
            ---@diagnostic disable-next-line: undefined-field
            local vbar = self.VBar

            ---@cast vbar DVScrollBar

            vbar:SetWide( 8 )

            -- ---@diagnostic disable-next-line: inject-field
            -- vbar.Paint = function( _, w, h )
            --     rndx.Draw( 0, 0, 0, w, h, color_background_vbar )
            -- end

            -- ---@diagnostic disable-next-line: undefined-field
            -- vbar.btnGrip.Paint = function( _, w, h )
            --     rndx.Draw( 8, 0, 0, w, h, color_white, rndx_flags )
            -- end

            -- ---@diagnostic disable-next-line: undefined-field
            -- vbar.btnUp.Paint = function() end
            -- ---@diagnostic disable-next-line: undefined-field
            -- vbar.btnDown.Paint = function() end
        end

        function PANEL:Paint() end

        vgui.Register( "ash.falcon.scroll", PANEL, "DScrollPanel" )
    end

    do
        local draw_text = draw.DrawText

        ---@class ash.falcon.label : ash.falcon.panel
        ---@field setTextData fun(pnl: ash.falcon.label, data: table )
        local PANEL = {}

        local color_gray = Color( 200, 200, 200 )
        function PANEL:Init()
            self:newMethod( "setTextData", function( pnl, data )
                data.color = data.color or pnl:getValue( "color", color_white )
                data.font = data.font or pnl:getValue( "font", "DermaLarge" )
                data.text = data.text or pnl:getValue( "text", "" )

                self:setValue( "text", data.text )
                self:setValue( "font", data.font )
                self:setValue( "color", data.color )

                local w, h = ash_ui.getTextSize( data.text, data.font )
                pnl:setSize( { width = tostring( w ) .. "px", height = tostring( h ) .. "px" } )
            end )

            self:setValue( "color", color_gray )
            self:setValue( "color.cursor", color_white )
            self:setValue( "cursorColorEnabled", false )

            self:addAction( "cursorEntered", "cursor", function( pnl )
                pnl:setValue( "cursor", true )
            end )

            self:addAction( "cursorExited", "cursor", function( pnl )
                pnl:setValue( "cursor", false )
            end )
        end

        function PANEL:Paint( w, h )
            local align = self:getValue( "align", TEXT_ALIGN_LEFT )
            local color = self:getValue( "color", color_white )

            if self:getValue( "cursorColorEnabled", false ) and self:getValue( "cursor", false ) then
                color = self:getValue( "color.cursor", color_white )
            end

            if align == TEXT_ALIGN_LEFT then
                draw_text( self:getValue( "text" ), self:getValue( "font" ), 0, 0, color, TEXT_ALIGN_LEFT )
            elseif align == TEXT_ALIGN_CENTER then
                draw_text( self:getValue( "text" ), self:getValue( "font" ), w * 0.5, 0, color, TEXT_ALIGN_CENTER )
            elseif align == TEXT_ALIGN_RIGHT then
                draw_text( self:getValue( "text" ), self:getValue( "font" ), w, 0, color, TEXT_ALIGN_RIGHT )
            end
        end

        vgui.Register( "ash.falcon.label", PANEL, "ash.falcon.panel" )
    end

    do
        ---@class ash.falcon.model_icon : ash.falcon.panel
        ---@field icon SpawnIcon
        ---@field model fun(pnl: ash.falcon.model_icon, model: string)
        local PANEL = {}

        local model_default = Model( "models/props_borealis/bluebarrel001.mdl" )
        function PANEL:Init()
            local icon = self:Add( "SpawnIcon" )
            icon:SetModel( model_default )
            icon:Dock( FILL )
            icon:SetKeyboardInputEnabled( false )
            icon:SetMouseInputEnabled( false )
            icon:DockPadding( 5, 5, 5, 5 )
            self.icon = icon

            self:newMethod( "model", function( pnl, model )
                pnl.icon:SetModel( model )
                self:setValue( "model", model )
                local w, h = pnl:GetSize()
                w = w - 5
                h = h - 5
                pnl.icon:SetSize( w, h )
            end )

            self:addAction( "cursorEntered", "outline", function( pnl )
                pnl:setValue( "drawOutline", true )
            end )

            self:addAction( "cursorExited", "outline", function( pnl )
                pnl:setValue( "drawOutline", false )
            end )
        end

        function PANEL:Paint( w, h )
            if self:getValue( "drawOutline", false ) then
                rndx.DrawOutlined( self:getValue( "outline.radius", 4 ), 0, 0, w, h, self:getValue( "outline.color", color_white ), 1, rndx.SHAPE_FIGMA )
            end
        end

        vgui.Register( "ash.falcon.model_icon", PANEL, "ash.falcon.panel" )
    end
end

local contex_panel = nil

do
    local function scroll( struct, callback )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.scroll" )
        ---@cast panel ash.falcon.scroll

        panel:struct( struct )
            :build()

        local old_panel = contex_panel
        contex_panel = panel
        if callback then
            callback()
        end

        contex_panel = old_panel

        return panel
    end

    falcon.scroll = scroll


    ---@param name string
    ---@param struct table
    ---@param callback fun()
    ---@return ash.falcon.frame
    local function frame( name, struct, callback )
        local panel = ash_ui.setPanel( name, "ash.falcon.frame", nil )
        ---@cast panel ash.falcon.frame

        panel:struct( struct )
            :build()

        local old_panel = contex_panel
        contex_panel = panel
        if callback then
            callback()
        end

        contex_panel = old_panel

        return panel
    end

    falcon.frame = frame

    ---@param struct table
    ---@param struct_scroll? table
    ---@param callback fun()
    ---@return ash.falcon.frame
    local function frameScroll( name, struct, struct_scroll, callback )
        return frame( name, struct, function()
            scroll( struct_scroll or {}, callback )
        end )
    end

    falcon.frameScroll = frameScroll

    local function button( struct, callback )
        assert( contex_panel ~= nil, "parent panel is required" )


        local panel = contex_panel:Add( "ash.falcon.button" )
        ---@cast panel ash.falcon.button

        panel:struct( struct )
            :build()

        local old_panel = contex_panel
        contex_panel = panel
        if callback then
            callback()
        end

        contex_panel = old_panel

        return panel
    end

    falcon.button = button

    local function layout( struct, callback )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.layout" )
        ---@cast panel ash.falcon.layout

        panel:struct( struct )
            :build()

        local old_panel = contex_panel
        contex_panel = panel
        if callback then
            callback()
        end

        contex_panel = old_panel

        return panel
    end

    falcon.layout = layout

    local function label( struct, callback )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.label" )
        ---@cast panel ash.falcon.label

        panel:struct( struct )
            :build()

        local old_panel = contex_panel
        contex_panel = panel
        if callback then
            callback()
        end

        contex_panel = old_panel

        return panel
    end

    falcon.label = label

    local function modelIcon( struct, callback )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.model_icon" )
        ---@cast panel ash.falcon.model_icon

        panel:struct( struct )
            :build()

        local old_panel = contex_panel
        contex_panel = panel
        if callback then
            callback()
        end

        contex_panel = old_panel

        return panel
    end

    falcon.modelIcon = modelIcon

    local function panel( struct, callback )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.panel" )
        ---@cast panel ash.falcon.panel

        panel:struct( struct )
            :build()

        local old_panel = contex_panel
        contex_panel = panel
        if callback then
            callback()
        end

        contex_panel = old_panel

        return panel
    end

    falcon.panel = panel
end


return falcon
