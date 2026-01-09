---@class flame.ui
local flame_ui = ...

---@type ash.ui
local ash_ui = require( "ash.ui" )

local colors = ash_ui.Colors

local dark_white = colors[ 200 ]
local light_grey = colors[ 50 ]
local dark_grey = colors[ 33 ]
local black = colors.black
local white = colors.white

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

		scroll_panel:SetWide( math.max( width, ash_ui.scale( "10vmin" ) ) )
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

	-- function ContextMenu:Paint( width, height )
	-- 	if GetRoundState() ~= ROUND_RUNNING then
	-- 		return
	-- 	end

	-- 	local remainingTime = GetRemainingTime()
	-- 	if remainingTime == 0 then
	-- 		return
	-- 	end

	-- 	surface_SetFont( "Jailbreak::RoundState" )

	-- 	local text = format( GetPhrase( "jb.round.2" ), remainingTime )
	-- 	local x, y = Jailbreak.ScreenCenterX - surface_GetTextSize( text ) / 2, VMin( 1 )

	-- 	surface_SetTextPos( x - 1, y - 1 )
	-- 	surface_SetTextColor( black.r, black.g, black.b, 50 )
	-- 	surface_DrawText( text )

	-- 	surface_SetTextPos( x + 3, y + 3 )
	-- 	surface_SetTextColor( black.r, black.g, black.b, 120 )
	-- 	surface_DrawText( text )

	-- 	surface_SetTextColor( white.r, white.g, white.b, 255 )
	-- 	surface_SetTextPos( x, y )
	-- 	surface_DrawText( text )
	-- end

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
			local margin = ash_ui.scale( "0.5vmin" )
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
