---@class ash.ui.falcon
local falcon = {}

---@type ash.ui
local ash_ui = import "ash.ui"

---@type ash.ui.rndx
local rndx = import "ash.ui.rndx"

---@type ash.ui.svg
local ash_svg = import "ash.ui.svg"

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


---@class ash.ui.falcon.state
---@field value any
---@field default any
---@field isState boolean
---@field type any
---@field callbacks table
local state_meta = {}
state_meta.__index = state_meta

---@param value any
function state_meta:set( value )
    if self.value == value then
        return
    end

    self.value = value

    local callbacks = self.callbacks
    local count = callbacks[ 0 ]

    for i = count, 1, -1 do
        if callbacks[ i ][ 1 ]( self ) == false then
            table.remove( callbacks, i )
            callbacks[ 0 ] = callbacks[ 0 ] - 1
        end
    end
end

function state_meta:removeCallback( data )
    local callbacks = self.callbacks
    for i = callbacks[ 0 ], 1, -1 do
        local v = callbacks[ i ]
        if v[ 1 ] == data then
            table.remove( callbacks, i )
            callbacks[ 0 ] = callbacks[ 0 ] - 1
            return
        end
    end
end

---@param default any
function state_meta:get( default )
    local value = self.value
    if value == nil then
        return default or self.default
    end

    return value
end

---@param callback function
function state_meta:addCallback( callback )
    local callbacks = self.callbacks
    local count = callbacks[ 0 ] + 1

    callbacks[ 0 ] = count

    local data = { callback }

    callbacks[ count ] = data

    return function()
        if self ~= nil then
            self:removeCallback( data )
        end
    end
end

---@param value any
---@return ash.ui.falcon.state
local function state( value )
    ---@class ash.ui.falcon.state
    local obj = setmetatable( {}, state_meta )
    obj.default = value
    obj.isState = true
    obj.type = type( value )
    obj.value = value
    obj.callbacks = { [ 0 ] = 0 }

    return obj
end

falcon.state = state


local contex_panel = nil

do
    ---@class ash.ui.falcon.base_panel : Panel
    ---@field keyValue table<string, any>
    ---@field steps table<string, any>
    ---@field methods table<string, function>
    ---@filed states ash.ui.falcon.state[]
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
        self.states = {}

        self:set( "background.color", color_background )
        self:set( "background.round", 4 )
        self:set( "background.flags", rndx.SHAPE_FIGMA )

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

        self:newMethod( "setPos", function( pnl, x, y )
            x = x or 0
            y = y or 0

            pnl:SetPos( x, y )
        end )

        self:newMethod( "setX", function( pnl, x )
            pnl:SetX( x )
        end )

        self:newMethod( "setY", function( pnl, y )
            pnl:SetY( y )
        end )

        self:newMethod( "keyboardInput", function( pnl, boolean )
            pnl:SetKeyBoardInputEnabled( boolean )
        end )

        self:newMethod( "mouseInput", function( pnl, boolean )
            pnl:SetMouseInputEnabled( boolean )
        end )

        self:newMethod( "paintedManually", function( pnl, boolean )
            pnl:SetPaintedManually( boolean )
        end )

        self:newMethod( "addState", function( pnl, st, callback )
            local states = pnl.states

            states[ #states + 1 ] = { st, st:addCallback( callback ) }
        end )
    end

    function BASE_PANEL:Paint( w, h )
        for _, func in pairs( self.paintsBack ) do
            func( self, w, h )
        end

        if not self:getValue( "noDrawBackground", false ) then
            if self:getValue( "outline.draw", false ) then
                rndx.DrawOutlined( self:getValue( "outline.round", self:getValue( "background.round" ) ) or 0, 0, 0, w, h, self:getValue( "outline.color" ) or color_white, self:getValue( "background.thickness", 1 ), self:getValue( "outline.flags", self:getValue( "background.flags", 0 ) ) or 0 )
            end

            rndx.Draw( self:getValue( "background.round" ) or 0, 0, 0, w, h, self:getValue( "background.color" ) or color_background, self:getValue( "background.flags" ) or 0 )
        end

        for _, func in pairs( self.paints ) do
            func( self, w, h )
        end
    end

    ---@param key string
    ---@param value any
    ---@return ash.ui.falcon.base_panel
    function BASE_PANEL:set( key, value )
        local keyValue = self.keyValue
        local data = keyValue[ key ] or {}
        keyValue[ key ] = data

        if istable( value ) and value.isState then
            data[ 1 ] = 1
            data[ 2 ] = value
        else
            data[ 1 ] = 0
            data[ 2 ] = value
        end

        return self
    end

    ---@param key string
    ---@param default any
    ---@return any
    function BASE_PANEL:get( key, default )
        local data = self.keyValue[ key ]

        if data ~= nil then
            local t = data[ 1 ]
            local value = data[ 2 ]
            if t == 0 then

                ---@cast value string
                return value
            elseif t == 1 then

                ---@cast value ash.ui.falcon.state
                return value:get()
            end
        end

        return default
    end

    BASE_PANEL.setValue = BASE_PANEL.set
    BASE_PANEL.getValue = BASE_PANEL.get

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
        self:build()
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
        local states = self.states
        for i = 1, #states do
            states[ i ][ 2 ]()
        end

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
        self:set( "saved_mouse_x", x )
        self:set( "saved_mouse_y", y )
        self:runAction( "hide" )
        self:AlphaTo( 0, 0.2, 0, function()
            if IsValid( self ) then
                x, y = input.GetCursorPos()
                self:set( "saved_mouse_x", x )
                self:set( "saved_mouse_y", y )
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

    function BASE_PANEL:context( callback )
        local old_context_panel = contex_panel
        contex_panel = self
        callback()
        contex_panel = old_context_panel

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

            self:set( "background.color", Color( 0, 0, 0, 0 ) )

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
        ---@field setTextData fun( pnl: ash.falcon.label, data: table ): ash.falcon.label
        ---@field set fun( pnl: ash.falcon.label, key: any, value: any ): ash.falcon.label
        local PANEL = {}

        local color_gray = Color( 200, 200, 200 )
        function PANEL:Init()
            self:newMethod( "setTextData", function( pnl, data )
                if isstring( data ) then
                    self:set( "text", data )
                else
                    data.text = data.text or pnl:getValue( "text", "" )
                    data.color = data.color or pnl:getValue( "color", color_white )
                    data.font = data.font or pnl:getValue( "font", "DermaLarge" )

                    self:set( "text", data.text )
                    self:set( "font", data.font )
                    self:set( "color", data.color )
                end

                if not self:getValue( "staticSize", false ) then
                    local w, h = ash_ui.getTextSize( data.text, data.font )
                    pnl:setSize( { width = tostring( w ) .. "px", height = tostring( h ) .. "px" } )
                end
            end )

            self:set( "color", color_gray )
            self:set( "color.cursor", color_white )
            self:set( "cursorColorEnabled", false )

            self:addAction( "cursorEntered", "cursor", function( pnl )
                pnl:set( "cursor", true )
            end )

            self:addAction( "cursorExited", "cursor", function( pnl )
                pnl:set( "cursor", false )
            end )
        end

        function PANEL:Paint( w, h )
            local align = self:get( "align", TEXT_ALIGN_LEFT )
            local color = self:get( "color", color_white )

            if self:get( "cursorColorEnabled", false ) and self:get( "cursor", false ) then
                color = self:get( "color.cursor", color_white )
            end

            -- rndx.Draw( 0, 0, 0, w, h, color_white )
            local text, font = self:get( "text" ), self:get( "font" )

            local wt, ht = ash_ui.getTextSize( text, font )

            if align == TEXT_ALIGN_LEFT then
                draw_text( text, font, 0, h * 0.5 - (ht * 0.5), color, TEXT_ALIGN_LEFT )
            elseif align == TEXT_ALIGN_CENTER then
                draw_text( text, font, w * 0.5, h * 0.5, color, TEXT_ALIGN_CENTER )
            elseif align == TEXT_ALIGN_RIGHT then
                draw_text( text, font, w, h * 0.5 - (ht * 0.5), color, TEXT_ALIGN_RIGHT )
            elseif align == TEXT_ALIGN_BOTTOM then
                draw_text( text, font, 0, 0, color, TEXT_ALIGN_BOTTOM )
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
                self:set( "model", model )
                local w, h = pnl:GetSize()
                w = w - 5
                h = h - 5
                pnl.icon:SetSize( w, h )
            end )

            self:addAction( "cursorEntered", "outline", function( pnl )
                pnl:set( "drawOutline", true )
            end )

            self:addAction( "cursorExited", "outline", function( pnl )
                pnl:set( "drawOutline", false )
            end )
        end

        function PANEL:Paint( w, h )
            if self:getValue( "drawOutline", false ) then
                rndx.DrawOutlined( self:getValue( "outline.radius", 4 ), 0, 0, w, h, self:getValue( "outline.color", color_white ), 1, rndx.SHAPE_FIGMA )
            end
        end

        vgui.Register( "ash.falcon.model_icon", PANEL, "ash.falcon.panel" )
    end

    do
        ---@class ash.falcon.image : ash.falcon.panel
        ---@field setImage fun(pnl: ash.falcon.image, img: any, params: string? )
        ---@field image_type integer
        ---@field image any
        local PANEL = {}

        local surface_SetDrawColor = surface.SetDrawColor
        local surface_SetMaterial = surface.SetMaterial
        local surface_DrawTexturedRect = surface.DrawTexturedRect

        function PANEL:Init()
            self:newMethod( "setImage", function( pnl, img, params )
                local img_type = type( img )
                if img_type == "string" then
                    if string.hasSuffix( img, ".svg.txt" ) or string.hasSuffix( img, ".svg" ) then
                        pnl.image_type = 1
                        pnl.image = ash_svg.Load( img )
                    else
                        pnl.image_type = 0
                        pnl.image = Material( img, params )
                    end
                elseif img_type == "IMaterial" then
                    pnl.image_type = 0
                    pnl.image = img
                end
            end )
        end

        function PANEL:Paint( w, h )
            local img_type = self.image_type

            if self.image then
                if img_type == 0 then
                    surface_SetDrawColor( self:getValue( "image.color", color_white ) )
                    surface_SetMaterial( self.image )
                    surface_DrawTexturedRect( 0, 0, w, h )
                elseif img_type == 1 then
                    self.image:Render( 0, 0, w, h )
                end
            end
        end

        vgui.Register( "ash.falcon.image", PANEL, "ash.falcon.panel" )
    end
end



do
    local function scroll( struct )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.scroll" )
        ---@cast panel ash.falcon.scroll

        panel:struct( struct )
            :build()

        return panel
    end

    falcon.scroll = scroll


    ---@param name string
    ---@param struct table
    ---@return ash.falcon.frame
    local function root( name, struct )
        local panel = ash_ui.setPanel( name, "ash.falcon.frame", nil )
        ---@cast panel ash.falcon.frame

        panel:struct( struct )
            :build()

        return panel
    end

    falcon.root = root

    local function button( struct )
        assert( contex_panel ~= nil, "parent panel is required" )


        local panel = contex_panel:Add( "ash.falcon.button" )
        ---@cast panel ash.falcon.button

        panel:struct( struct )
            :build()


        return panel
    end

    falcon.button = button

    local function layout( struct )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.layout" )
        ---@cast panel ash.falcon.layout

        panel:struct( struct )
            :build()

        return panel
    end

    falcon.layout = layout

    local function label( struct )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.label" )
        ---@cast panel ash.falcon.label

        panel:struct( struct )
            :build()
        return panel
    end

    falcon.label = label

    local function modelIcon( struct )
        assert( contex_panel ~= nil, "parent panel is required" )

        local panel = contex_panel:Add( "ash.falcon.model_icon" )
        ---@cast panel ash.falcon.model_icon

        panel:struct( struct )
            :build()


        return panel
    end

    falcon.modelIcon = modelIcon

    local function panel( struct )
        assert( contex_panel ~= nil, "parent panel is required" )

        local pnl = contex_panel:Add( "ash.falcon.panel" )
        ---@cast pnl ash.falcon.panel

        pnl:struct( struct )
            :build()

        return pnl
    end

    falcon.panel = panel

    local function image( struct )
        assert( contex_panel ~= nil, "parent panel is required" )

        local pnl = contex_panel:Add( "ash.falcon.image" )
        ---@cast pnl ash.falcon.image

        pnl:struct( struct )
            :build()

        return pnl
    end

    falcon.image = image
end


return falcon
