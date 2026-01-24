---@class flame.ui
local flame_ui = ...

---@type ash.ui
local ash_ui = require( "ash.ui" )

---@type ash.view
local ash_view = require( "ash.view" )
local view_Data = ash_view.Data

---@type ash.entity
local ash_entity = require( "ash.entity" )

---@type ash.player
local ash_player = require( "ash.player" )

---@type ash.entity.door
local ash_door = require( "ash.entity.door" )

local colors = ash_ui.Colors
local light_grey = colors[ 180 ]
local dark_white = colors[ 200 ]
local dark_grey = colors[ 33 ]
local white = colors.white
local black = colors.black

local Panel = Panel
local Panel_IsValid = Panel.IsValid
local Panel_IsVisible = Panel.IsVisible
local Panel_GetParent = Panel.GetParent
local Panel_InvalidateLayout = Panel.InvalidateLayout

local surface = surface
local surface_DrawRect = surface.DrawRect
local surface_PlaySound = surface.PlaySound
local surface_SetDrawColor = surface.SetDrawColor

local hook_Run = hook.Run

local sizes = ash_ui.scaleMap( {
	v10 = "10vmin",
	v05 = "0.5vmin",
	v2 = "2vmin"
} )

do

	local string_byte = string.byte

	local open_context_menu = console.Command( {
		name = "+menu_context",
		dont_record = true,
		description = "Opens the context menu."
	} )

	flame_ui.OpenContextMenu = open_context_menu

	local close_context_menu = console.Command( {
		name = "-menu_context",
		dont_record = true,
		description = "Closes the context menu."
	} )

	flame_ui.CloseContextMenu = close_context_menu

	---@param command dreamwork.std.console.Command
	---@param pl Player
	local function handler( command, pl )
		if string_byte( command.name, 1, 1 ) == 0x2D --[[ - ]] then
			if input.IsKeyTrapping() then return end
			hook_Run( "OnContextMenuClose" )
		else
			hook_Run( "OnContextMenuOpen" )
		end
	end

	open_context_menu:attach( handler )
	close_context_menu:attach( handler )

end

hook.Add( "ContextMenuEnabled", "Defaults", function()
	return true
end )

hook.Add( "ContextMenuOpen", "Defaults", function()
	return true
end )

local input_GetCursorPos = input.GetCursorPos
local input_SetCursorPos = input.SetCursorPos

do

	local CloseDermaMenus = CloseDermaMenus

	---@class flame.ui.ContextMenu : Panel
	local ContextMenu = {}

	function ContextMenu:GetHangOpen()
		return self.m_bHangOpen
	end

	function ContextMenu:SetHangOpen( b )
		self.m_bHangOpen = b
	end

	---@diagnostic disable-next-line: duplicate-set-field
	function ContextMenu:Init()
		self.CursorX, self.CursorY = 0, 0
		self.m_bHangOpen = false

		self:SetWorldClicker( true )
		self:Dock( FILL )

		local scroll_panel = self:Add( "DScrollPanel" )
		self.ScrollPanel = scroll_panel

		---@diagnostic disable-next-line: undefined-field
		scroll_panel.VBar:SetWide( 0 )
		scroll_panel:Dock( LEFT )

		---@diagnostic disable-next-line: inject-field
		scroll_panel.OnMousePressed = function( _, ... )
			return self:OnMousePressed( ... )
		end

		hook.Add( "LanguageChanged", self, function()
			return self:InvalidateChildren( true )
		end )

		hook_Run( "ContextMenuCreated", self )

		self:SetVisible( false )

		local buttons, button_count = {}, 0

		for _, desktop_window in pairs( list.Get( "DesktopWindows" ) ) do
			button_count = button_count + 1
			buttons[ button_count ] = desktop_window
		end

		table.sort( buttons, function( a, b )
			if a.order and b.order then
				return a.order < b.order
			end

			return a.title < b.title
		end )

		for i = 1, button_count, 1 do
			self:AddItem( buttons[ i ] )
		end
	end

	---@diagnostic disable-next-line: duplicate-set-field
	function ContextMenu:PerformLayout()
		local scroll_panel = self.ScrollPanel
		local width = 0

		local canvas = scroll_panel:GetCanvas()
		if canvas ~= nil and Panel_IsValid( canvas ) then
			local children = canvas:GetChildren()

			for i = 1, #children, 1 do
				local child = children[ i ]
				if child:GetName() == "flame.ui.ContextMenu.Button" then
					local paddingLeft, paddingRight = child:GetDockPadding()
					width = math.max( width, paddingLeft + child.Label:GetTextSize() + paddingRight )
				end
			end
		end

		scroll_panel:SetWide( math.max( width, sizes.v10 ) )
	end

	function ContextMenu:AddItem( data )
		local scroll_panel = self.ScrollPanel
		if scroll_panel == nil or not Panel_IsValid( scroll_panel ) then
			return
		end

		local button = scroll_panel:Add( "flame.ui.ContextMenu.Button" )

		local title = data.title

		---@diagnostic disable-next-line: undefined-field
		button:SetTooltip( title )

		---@diagnostic disable-next-line: inject-field
		button.Title = title

		---@diagnostic disable-next-line: undefined-field
		button.Image:SetImage( data.icon )

		Panel_InvalidateLayout( self )

		local created = data.created
		if isfunction( created ) then
			created( button )
		end

		local think = data.think
		if isfunction( think ) then
			hook.Add( "Tick", button, think )
		end

		local click = data.click
		if isfunction( click ) then
			---@diagnostic disable-next-line: inject-field
			button.DoClick = click
		end

		local init = data.init
		if isfunction( init ) then
			---@diagnostic disable-next-line: inject-field
			button.DoClick = function()
				local window = button.Window
				self.Window = window

				if data.onewindow and window ~= nil and Panel_IsValid( window ) then
					window:Remove()
				end

				window = self:Add( "DFrame" )

				---@diagnostic disable-next-line: inject-field
				button.Window = window

				window:SetSize( data.width or 960, data.height or 700 )
				window:SetTitle( title )
				window:Center()

				return init( button, window )
			end
		end

		return button
	end

	function ContextMenu:Open()
		self:SetHangOpen( false )

		if self:IsVisible() then return end

		self:SetVisible( true )

		self:MakePopup()

		self:SetMouseInputEnabled( true )
		self:SetKeyboardInputEnabled( false )

		input_SetCursorPos( self.CursorX, self.CursorY )
		Panel_InvalidateLayout( self, true )

		CloseDermaMenus()
	end

	function ContextMenu:Close( bSkipAnim )
		if self:GetHangOpen() then
			self:SetHangOpen( false )
			return
		end

		self.CursorX, self.CursorY = input_GetCursorPos()

		CloseDermaMenus()

		self:SetKeyboardInputEnabled( false )
		self:SetMouseInputEnabled( false )

		self:SetAlpha( 255 )
		self:SetVisible( false )
	end

	function ContextMenu:StartKeyFocus( pPanel )
		self:SetKeyboardInputEnabled( true )
		self:SetHangOpen( true )
	end

	function ContextMenu:EndKeyFocus( pPanel )
		self:SetKeyboardInputEnabled( false )
	end

	do

		local gui_ScreenToVector = gui.ScreenToVector

		ContextMenu.OnMousePressed = function( _, code )
			return hook_Run( "GUIMousePressed", code, gui_ScreenToVector( input_GetCursorPos() ) )
		end

		ContextMenu.OnMouseReleased = function( _, code )
			return hook_Run( "GUIMouseReleased", code, gui_ScreenToVector( input_GetCursorPos() ) )
		end

	end

 	function ContextMenu:Paint( width, height )
		hook_Run( "flame.ui.DrawContextMenu", self, width, height )
	end

	function ContextMenu:Think()
		hook_Run( "ContextMenuThink", self )
	end

	vgui.Register( "flame.ui.ContextMenu", ContextMenu, "EditablePanel" )

	do

		ash_ui.font( "flame.ui.ContextMenu.Button", {
			font = "Roboto Mono Bold",
			size = "1.25vmin"
		} )

		---@class flame.ui.ContextMenuButton : DButton
		local ContextMenuButton = {}

		function ContextMenuButton:Init()
			self:SetText( "" )
			self:Dock( TOP )

			self.Title = ""

			local label = self:Add( "DLabel" )
			self.Label = label

			label:SetTextColor( white )
			label:SetContentAlignment( 5 )
			label:SetFont( "flame.ui.ContextMenu.Button" )
			label:SetExpensiveShadow( 1, Color( 0, 0, 0, 200 ) )
			label:Dock( BOTTOM )

			local image = self:Add( "DImage" )
			self.Image = image

			image:SetMouseInputEnabled( false )
			image:Dock( FILL )
		end

		ContextMenuButton.DoClick = function() end

		function ContextMenuButton:GetImage()
			return self.Image:GetImage()
		end

		function ContextMenuButton:SetImage( materialPath )
			self.Image:SetImage( materialPath )
			Panel_InvalidateLayout( self )
		end

		function ContextMenuButton:OnCursorEntered()
			if self:IsEnabled() then
				surface_PlaySound( "garrysmod/ui_hover.wav" )
			end
		end

		function ContextMenuButton:OnMouseReleased( mousecode )
			self:MouseCapture( false )

			if not self:IsEnabled() then
				return
			end

			if not self.Depressed and dragndrop.m_DraggingMain ~= self then
				return
			end

			if self.Depressed then
				self.Depressed = nil
				---@diagnostic disable-next-line: undefined-field
				self:OnReleased()
				Panel_InvalidateLayout( self, true )
			end

			if self:DragMouseRelease( mousecode ) then
				return
			end

			if self:IsSelectable() and mousecode == MOUSE_LEFT then
				local canvas = self:GetSelectionCanvas()
				if canvas then
					canvas:UnselectAll()
				end
			end

			---@diagnostic disable-next-line: undefined-field
			if not self.Hovered then
				return
			end

			self.Depressed = true

			surface_PlaySound( "garrysmod/ui_click.wav" )

			if mousecode == MOUSE_RIGHT then
				---@diagnostic disable-next-line: undefined-field
				self:DoRightClick()
			end

			if mousecode == MOUSE_LEFT then
				self:DoClickInternal()
				self:DoClick()
			end

			if mousecode == MOUSE_MIDDLE then
				---@diagnostic disable-next-line: undefined-field
				self:DoMiddleClick()
			end

			self.Depressed = nil
		end

		function ContextMenuButton:PerformLayout()
			local margin = sizes.v05
			local margin2 = margin * 2

			self.Image:DockMargin( margin2, margin2, margin2, 0 )
			self:DockPadding( margin, margin, margin, 0 )

			local width = self:GetWide()
			local height = width

			local label = self.Label
			if label ~= nil and Panel_IsValid( label ) then
				label:SetText( self.Title or label:GetText() )

				local text_width, text_height = label:GetTextSize()
				height = height + text_height
			end

			self:SetTall( height )
		end

		ContextMenuButton.Paint = function( width, height ) end

		vgui.Register( "flame.ui.ContextMenu.Button", ContextMenuButton, "DButton" )

	end

	hook.Add( "OnContextMenuOpen", "Defaults", function()
		local hud_panel = GetHUDPanel()
		if not ( hud_panel ~= nil and Panel_IsValid( hud_panel ) and Panel_IsVisible( hud_panel ) ) or hook_Run( "ContextMenuOpen" ) == false then
			return
		end

		---@type flame.ui.ContextMenu
		---@diagnostic disable-next-line: assign-type-mismatch
		local context_menu = ash_ui.getPanel( "flame.ui.ContextMenu" )

		if not hook_Run( "ContextMenuEnabled" ) then
			if context_menu ~= nil and Panel_IsValid( context_menu ) then
				context_menu:Remove()
			end

			return
		end

		if context_menu == nil or not Panel_IsValid( context_menu ) then
			---@type flame.ui.ContextMenu
			---@diagnostic disable-next-line: assign-type-mismatch
			context_menu = ash_ui.setPanel( "flame.ui.ContextMenu", "flame.ui.ContextMenu", hud_panel )
		end

		if context_menu ~= nil and Panel_IsValid( context_menu ) then
			if not context_menu:IsVisible() then
				context_menu:Open()
			end

			hook_Run( "ContextMenuOpened", context_menu )
		end
	end )

	hook.Add( "OnContextMenuClose", "Defaults", function()
		---@type flame.ui.ContextMenu
		---@diagnostic disable-next-line: assign-type-mismatch
		local context_menu = ash_ui.getPanel( "flame.ui.ContextMenu" )
		if context_menu ~= nil and Panel_IsValid( context_menu ) then
			if DEBUG then
				context_menu:Remove()
			else
				context_menu:Close()
			end

			hook_Run( "ContextMenuClosed", context_menu )
		end
	end )

end

do

	local Panel_GetText = Panel.GetText
	local string_len = string.len

	---@diagnostic disable-next-line: undefined-global
	function DLabel:Think()
		if self.m_bAutoStretchVertical then
			local length = string_len( Panel_GetText( self ) )
			if length ~= self.m_iLastTextLength then
				self.m_iLastTextLength = length
				self:SizeToContentsY()
			end
		end
	end

end

---@diagnostic disable-next-line: undefined-global
function DButton:Paint( w, h )
	if self:GetPaintBackground() then
		surface_SetDrawColor( dark_white.r, dark_white.g, dark_white.b, 240 )
		surface_DrawRect( 0, 0, w, h )
		surface_SetDrawColor( dark_grey.r, dark_grey.g, dark_grey.b, 255 )

		surface_DrawRect( 0, 0, w, 1 )
		surface_DrawRect( 0, 1, 1, h - 2 )
		surface_DrawRect( w - 1, 1, 1, h - 2 )
		surface_DrawRect( 0, h - 1, w, 1 )
	end
end

---@diagnostic disable-next-line: undefined-global
Button.Paint = DButton.Paint

do

	local derma_SkinChangeIndex = derma.SkinChangeIndex
	local derma_GetDefaultSkin = derma.GetDefaultSkin
	local derma_GetNamedSkin = derma.GetNamedSkin

	---@param panel Panel
	---@return table derma_skin
	local function getSkin( panel )
		if derma_SkinChangeIndex() == panel.m_iSkinIndex then
			local skin_name = panel.m_Skin
			if skin_name ~= nil then
				return skin_name
			end
		end

		local derma_skin

		---@diagnostic disable-next-line: undefined-field
		local forced_skin_name = panel.m_ForceSkinName
		if derma_skin == nil then
			if forced_skin_name ~= nil then
				derma_skin = derma_GetNamedSkin( forced_skin_name )
			end

			if derma_skin == nil then
				local parent_panel = Panel_GetParent( panel )
				if parent_panel ~= nil and Panel_IsValid( parent_panel ) then
					derma_skin = getSkin( parent_panel )
				end

				if derma_skin == nil then
					derma_skin = derma_GetDefaultSkin()
				end
			end
		end

		---@diagnostic disable-next-line: inject-field
		panel.m_Skin = derma_skin

		---@diagnostic disable-next-line: inject-field
		panel.m_iSkinIndex = derma_SkinChangeIndex()

		Panel_InvalidateLayout( panel, false )

		return derma_skin
	end

	Panel.GetSkin = getSkin

end

---@type TraceResult
local trace_result = {}

---@type Trace
local trace = {
	output = trace_result,
	mask = MASK_SHOT
}

---@type Entity | nil
local entity

do

	local Entity_GetNoDraw = Entity.GetNoDraw
	local Entity_GetSolid = Entity.GetSolid
	local Entity_IsValid = Entity.IsValid

	local util_TraceLine = util.TraceLine

	hook.Add( "ContextMenuThink", "Properties", function( self )
		local view_entity = ash_view.Entity
		local start = view_Data.origin

		trace.start = start
		trace.endpos = start + ash_view.AimVector * ( hook_Run( "ContextMenuTraceLength", view_entity ) or 1024 )
		trace.filter = view_entity

		util_TraceLine( trace )

		if not trace_result.Hit then
			entity = nil
			return
		end

		entity = trace_result.Entity
		---@cast entity Entity

		if not Entity_IsValid( entity ) or Entity_GetNoDraw( entity ) or Entity_GetSolid( entity ) == 0 then
			entity = nil
		end
	end )

end

do

	local render = render
	local render_SetBlend = render.SetBlend
	local render_SuppressEngineLighting = render.SuppressEngineLighting

	local render_SetStencilEnable = render.SetStencilEnable
	local render_SetStencilTestMask = render.SetStencilTestMask
	local render_SetStencilWriteMask = render.SetStencilWriteMask
	local render_SetStencilPassOperation = render.SetStencilPassOperation
	local render_SetStencilFailOperation = render.SetStencilFailOperation
	local render_SetStencilZFailOperation = render.SetStencilZFailOperation
	local render_SetStencilReferenceValue = render.SetStencilReferenceValue
	local render_SetStencilCompareFunction = render.SetStencilCompareFunction

	local STENCIL_ALWAYS, STENCIL_KEEP, STENCIL_REPLACE, STENCIL_EQUAL = STENCIL_ALWAYS, STENCIL_KEEP, STENCIL_REPLACE, STENCIL_EQUAL

	local cam_Start2D, cam_End2D = cam.Start2D, cam.End2D
	local cam_Start3D, cam_End3D = cam.Start3D, cam.End3D

	local Entity_DrawModel = Entity.DrawModel

	hook.Add( "flame.ui.DrawContextMenu", "Jailbreak::Properties", function( self, width, height )
		if entity ~= nil then
			cam_Start3D()

			render_SetStencilEnable( true )
			render_SetStencilWriteMask( 1 )
			render_SetStencilTestMask( 1 )
			render_SetStencilReferenceValue( 1 )
			render_SetStencilCompareFunction( STENCIL_ALWAYS )
			render_SetStencilPassOperation( STENCIL_REPLACE )
			render_SetStencilFailOperation( STENCIL_KEEP )
			render_SetStencilZFailOperation( STENCIL_KEEP )

			render_SuppressEngineLighting( true )
			render_SetBlend( 0 )

			Entity_DrawModel( entity )

			render_SetBlend( 1 )
			render_SuppressEngineLighting( false )

			render_SetStencilCompareFunction( STENCIL_EQUAL )
			render_SetStencilPassOperation( STENCIL_KEEP )

			cam_Start2D()
			surface_SetDrawColor( 255, 255, 255, 10 )
			surface_DrawRect( 0, 0, width, height )
			cam_End2D()

			render_SetStencilEnable( false )
			render_SetStencilTestMask( 0 )
			render_SetStencilWriteMask( 0 )
			render_SetStencilReferenceValue( 0 )

			cam_End3D()
		end
	end )

end

do

	local surface_SetTextColor = surface.SetTextColor
	local surface_GetTextSize = surface.GetTextSize
	local surface_SetTextPos = surface.SetTextPos
	local surface_DrawText = surface.DrawText
	local surface_SetFont = surface.SetFont

	local Vector_Distance = Vector.Distance

	local string_upper = string.upper

	local math_round = math.round
	local math_lerp = math.lerp
	local math_max = math.max

	ash_ui.font( "flame.ui.ContextMenu.Target - Name", {
		font = "Roboto Mono Bold",
		size = "2.5vmin"
	} )

	ash_ui.font( "flame.ui.ContextMenu.Target - Health", {
		font = "Roboto Mono",
		size = "1.8vmin"
	} )

	ash_ui.font( "flame.ui.ContextMenu.Target - Use", {
		font = "Roboto Mono Bold",
		size = "2vmin"
	} )

	local target_names = {
		momentary_rot_button = "Button",
		func_door_rotating = "Door",
		prop_door_rotating = "Door",
		func_rot_button = "Button",
		func_button = "Button",
		prop_ragdoll = "Body",
		func_door = "Door"
	}

	local asparagus = Color( 128, 154, 86 )
	local red = Color( 255, 50, 50 )

	local entity_type = 0

	hook.Add( "flame.ui.DrawContextMenu", "TargetInfo", function( self, width, height )
		if entity == nil then return end

		local mouseX, mouseY = ash_ui.CursorX, ash_ui.CursorY
		local class_name = entity:GetClass()
		local r, g, b = 255, 255, 255
		local text = nil
		entity_type = 0

		if class_name == "player" then
			---@cast entity Player

			if ash_player.isDead( entity ) then return end
			text = entity:Nick()
			entity_type = 1
		elseif ash_entity.isButton( entity ) then
			text = "Button"
			entity_type = 2
		else
			text = target_names[ class_name ]
			if text == nil then return end
			entity_type = 7
		end

		if entity_type == 0 then
			return
		end

		local x, y = 0, mouseY + sizes.v2

		if text ~= nil then
			surface_SetFont( "flame.ui.ContextMenu.Target - Name" )

			local text_width, text_height = surface_GetTextSize( text )
			x = mouseX - text_width * 0.5

			surface_SetTextPos( x - 1, y - 1 )
			surface_SetTextColor( black.r, black.g, black.b, 50 )
			surface_DrawText( text )

			surface_SetTextPos( x + 3, y + 3 )
			surface_SetTextColor( black.r, black.g, black.b, 120 )
			surface_DrawText( text )

			surface_SetTextColor( r, g, b )
			surface_SetTextPos( x, y )
			surface_DrawText( text )

			y = y + text_height
		end

		text = nil

		if entity_type == 1 then
			if entity:HasGodMode() then
				text = "Invincible"
				r, g, b = 254, 242, 0
			else
				local frac = entity:Health() / entity:GetMaxHealth()
				if frac <= 0 then
					text = "Dead"
				elseif frac < 0.25 then
					text = "Half Dead"
				elseif frac < 0.5 then
					text = "Badly Wounded"
				elseif frac < 0.75 then
					text = "Wounded"
				elseif frac < 0.90 then
					text = "Hurt"
				else
					text = "Healthy"
				end

				r, g, b = math_lerp( frac, red.r, asparagus.r ), math_lerp( frac, red.g, asparagus.g ), math_lerp( frac, red.b, asparagus.b )
			end
		else
			local health = entity:Health()
			if health >= 1 then
				local frac = math_max( 0, math_round( 1 - ( health / entity:GetMaxHealth() ), 2 ) )
				if frac ~= 0 then
					text = "Damaged by " .. ( frac * 100 ) .. "%"
					r, g, b = dark_white.r, dark_white.g, dark_white.b
				end
			end
		end

		if text ~= nil then
			surface_SetFont( "flame.ui.ContextMenu.Target - Health" )

			local text_width, text_height = surface_GetTextSize( text )
			x = mouseX - text_width * 0.5

			surface_SetTextColor( dark_grey.r, dark_grey.g, dark_grey.b, 100 )

			for sx = -2, 2 do
				for sy = -2, 2 do
					surface_SetTextPos( x + sx, y + sy )
					surface_DrawText( text )
				end
			end

			surface_SetTextColor( r, g, b )
			surface_SetTextPos( x, y )
			surface_DrawText( text )
			y = y + text_height
		end

		local view_entity = ash_view.Entity
		if Vector_Distance( trace.start, trace_result.HitPos ) > ash_player.getUseDistance( view_entity ) then
			return
		end

		local key_name = input.LookupBinding( "use" )
		if key_name == nil then return end

		if view_entity:IsPlayer() and view_entity:Alive() then
			---@cast view_entity Player
			text = nil

			if entity_type == 2 then
				text = "Press"
			elseif class_name == "prop_door_rotating" or class_name == "func_door_rotating" then
				if ash_door.isLocked( entity ) then
					text = "Locked"
				else

					local state = ash_door.getState( entity )
					if state == 0 or state == 3 then
						text = "Open"
					else
						text = "Close"
					end

				end
			elseif class_name == "func_door" then
				text = "Open/Close"
			end

			if text ~= nil then
				key_name = string_upper( key_name )

				surface_SetFont( "flame.ui.ContextMenu.Target - Use" )

				local text_width, text_height = surface_GetTextSize( text )
				local margin = sizes.v05

				width, height = text_width * 1.2, text_height * 1.25

				x = mouseX - ( width + margin + height ) * 0.5
				y = y + ( ( height - text_height ) * 0.5 + margin )

				if ash_player.getKeyState( view_entity, 32 ) then
					surface_SetDrawColor( light_grey.r, light_grey.g, light_grey.b, 240 )
					surface_SetTextColor( dark_grey.r, dark_grey.g, dark_grey.b )
				else
					surface_SetDrawColor( dark_grey.r, dark_grey.g, dark_grey.b, 240 )
					surface_SetTextColor( dark_white.r, dark_white.g, dark_white.b )
				end

				surface_DrawRect( x, y - ( height - text_height ) * 0.5, height, height )

				surface_SetTextPos( x + ( height - surface_GetTextSize( key_name ) ) * 0.5, y )
				surface_DrawText( key_name )
				x = x + ( height + margin )

				surface_SetDrawColor( dark_grey.r, dark_grey.g, dark_grey.b, 240 )
				surface_DrawRect( x, y - ( height - text_height ) * 0.5, width, height )
				x = x + ( ( width - text_width ) * 0.5 )

				surface_SetTextColor( dark_white.r, dark_white.g, dark_white.b )
				surface_SetTextPos( x, y )
				surface_DrawText( text )
			end
		end
	end )

end
