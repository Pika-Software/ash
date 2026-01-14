---@class flame.ui
local flame_ui = ...

---@type ash.ui
local ash_ui = require( "ash.ui" )

local Colors = ash_ui.Colors
local c33 = Colors[ 33 ]

---@type ash.i18n
local ash_i18n = require( "ash.i18n" )
local i18n_perform = ash_i18n.perform

ash_ui.font( "flame.ui.Tooltip", {
	font = "Roboto Mono",
	size = "1.8vmin"
} )

local tooltip_fadeout = CreateClientConVar( "tooltip_fadeout", "2", true, false, "Tooltip fadeout speed multiplier.", 0, 10 )
local tooltip_clear = CreateClientConVar( "tooltip_clear", "1", true, false, "If enabled, game will clear alpha of tooltips after fading out.", 0, 1 )
local tooltip_fadein = CreateClientConVar( "tooltip_fadein", "3", true, false, "Tooltip fadein speed multiplier.", 0, 10 )

local tooltip_delay = GetConVar( "tooltip_delay" )

local FrameTime = FrameTime
local math_min = math.min
local CurTime = CurTime

local Panel_GetParent = Panel.GetParent
local Panel_IsVisible = Panel.IsVisible
local Panel_SetText = Panel.SetText
local Panel_IsValid = Panel.IsValid

do

	local vgui_CursorVisible = vgui.CursorVisible
	local input_GetCursorPos = input.GetCursorPos

	---@class flame.ui.Tooltip : Panel
	local Tooltip = {}

	function Tooltip:Init()
		self:SetFontInternal( "flame.ui.Tooltip" )
		self:SetContentAlignment( 5 )
		self:SetAlpha( 0 )

		self:SetPaintBackgroundEnabled( true )
		self:SetKeyboardInputEnabled( false )
		self:SetMouseInputEnabled( false )
		self:SetPaintedManually( true )
		self:InvalidateLayout( true )

		hook.Add( "ash.view.DrawOverlay", self, self.PaintManual )
	end

	function Tooltip:Think()
		if not vgui_CursorVisible() then
			self:SetVisible( false )
			return
		end

		local x, y = input_GetCursorPos()
		self:SetPos( x, y - self:GetTall() )

		if self.m_bFadeIn then
			local alpha = self:GetAlpha()
			if alpha > 0 then
				self:SetAlpha( math.max( 0, alpha - FrameTime() * 255 * tooltip_fadein:GetFloat() ) )
			elseif Panel_IsVisible( self ) then
				self:SetVisible( false )
			end

			return
		end

		local lastTextChange = self.LastTextChange
		if not lastTextChange then
			self:SetVisible( false )
			return
		end

		local timePassed = CurTime() - lastTextChange
		if timePassed <= tooltip_delay:GetFloat() then
			if tooltip_clear:GetBool() then
				self:SetAlpha( 0 )
			end

			return
		end

		local alpha = self:GetAlpha()
		if alpha < 255 then
			return self:SetAlpha( math_min( alpha + FrameTime() * 255 * tooltip_fadeout:GetFloat(), 255 ) )
		end
	end

	function Tooltip:PerformLayout()
		self:SetBGColor( c33.r, c33.g, c33.b, 240 )

		local text_width, text_height = self:GetTextSize()
		local margin = ash_ui.scale( "0.25vmin" )

		return self:SetSize( margin + text_width + margin, margin + text_height + margin )
	end

	function Tooltip:SetText( str )
		Panel_SetText( self, str )
		self.LastTextChange = CurTime()
		self:SetVisible( true )
		self.m_bFadeIn = false
	end

	vgui.Register( "flame.ui.Tooltip", Tooltip, "Label" )

end

local function removeTooltip( self )
	---@type flame.ui.Tooltip
	---@diagnostic disable-next-line: assign-type-mismatch
	local tooltip_panel = ash_ui.getPanel( "flame.ui.Tooltip" )
	if tooltip_panel ~= nil and Panel_IsValid( tooltip_panel ) then
		tooltip_panel.m_bFadeIn = true
	end

	return true
end

_G.RemoveTooltip = removeTooltip
_G.EndTooltip = removeTooltip

local function findTooltip( panel )
	while panel ~= nil and Panel_IsValid( panel ) do
		if Panel_IsVisible( panel ) then
			local text = panel.strTooltipText
			if text ~= nil then
				return i18n_perform( text )
			end
		end

		panel = Panel_GetParent( panel )
	end
end

_G.FindTooltip = findTooltip

---@diagnostic disable-next-line: duplicate-set-field
function _G.ChangeTooltip( panel )
	removeTooltip()

	local text = findTooltip( panel )
	if text == nil then return end

	---@type flame.ui.Tooltip
	---@diagnostic disable-next-line: assign-type-mismatch
	local tooltip_panel = ash_ui.getPanel( "flame.ui.Tooltip" )

	if DEBUG and tooltip_panel ~= nil and Panel_IsValid( tooltip_panel ) then
		tooltip_panel:Remove()
	end

	if tooltip_panel == nil or not Panel_IsValid( tooltip_panel ) then
		---@type flame.ui.Tooltip
		---@diagnostic disable-next-line: assign-type-mismatch
		tooltip_panel = ash_ui.setPanel( "flame.ui.Tooltip", "flame.ui.Tooltip" )
	end

	tooltip_panel:SetText( text )
end
