local util_FilterText = util.FilterText
local hook_Run = hook.Run
local bit_band = bit.band

---@class ash.player.chat
local ash_chat = include( "shared.lua" )

---@type ash.i18n
local ash_i18n = require( "ash.i18n" )
local i18n_perform = ash_i18n.perform

---@type ash.entity
local ash_entity = require( "ash.entity" )

---@class ash.player.chat.Message : dreamwork.Object
local Message = class.base( "ash.player.chat.Message", false )

---@param text string
---@param color Color
function Message:append( text, color )
	local length = self[ 0 ] or 0

	length = length + 1
	self[ length ] = color

	length = length + 1
	self[ length ] = text

	self[ 0 ] = length
end

function Message:display()
	hook_Run( "ash.player.chat.Message", self )
end

---@class ash.player.chat.MessageClass : ash.player.chat.Message
---@overload fun(): ash.player.chat.Message
local MessageClass = class.create( Message )
ash_chat.Message = MessageClass

---@type dreamwork.std.console.Variable
---@diagnostic disable-next-line: assign-type-mismatch
local cl_chatfilters = console.Variable.get( "cl_chatfilters", "integer" )

---@type ash.ui
local ash_ui = require( "ash.ui" )

local ui_Colors = ash_ui.Colors

local butterfly_bush = ui_Colors.dreamwork_main
local dark_white = ui_Colors[ 200 ]
local blue = ui_Colors.ash_blue
local white = ui_Colors.white

local light_grey = ui_Colors[ 50 ]

hook.Add( "ash.player.chat.Message", "test", function( message )
	chat.AddText( light_grey, os.date( "[%H:%M:%S] " ), unpack( message ) )
	chat.PlaySound()
end )

net.Receive( "chat", function()
	local message = MessageClass()
	hook_Run( "ash.player.chat.Incoming", message, net.ReadString() )
	message:display()
end )

hook.Add( "ash.player.chat.Incoming", "MessageHandler", function( message, message_type )

end )

do

	local achievements_GetName = achievements.GetName
	local vivid_orange = Color( 255, 200, 50 )

	hook.Add( "OnAchievementAchieved", "AchievementMessage", function( pl, achievement_id )
		local message = MessageClass()
		message:append( "Player ", white )
		message:append( pl:Nick(), ash_entity.getPlayerColor( pl ) )
		message:append( " got achievement ", white )
		message:append( achievements_GetName( achievement_id ), vivid_orange )
		message:display()
	end, PRE_HOOK )

end

---@param text string
---@param color Color | nil
local function server_message( text, color )
	local message = MessageClass()
	message:append( i18n_perform( text ), color or dark_white )
	message:display()
end

-- ---@diagnostic disable-next-line: param-type-mismatch
-- data[ 1 ] = util_FilterText( text, ( bit_band( cl_chatfilters.value, 64 ) == 0 ) and TEXT_FILTER_GAME_CONTENT or TEXT_FILTER_CHAT, speaker )

---@param text string
---@param nickname string | nil
---@param color Color | nil
---@param is_muted boolean | nil
---@param is_dead boolean | nil
---@param team_name string | nil
local function chat_text( text, nickname, color, is_muted, is_dead, team_name )
	local message = MessageClass()

	if is_dead then
		message:append( "[Dead]", dark_white )
	end

	-- if team_name then
	-- 	message:append( team_name, GetTeamColor( team_name ) )
	-- end

	if nickname then
		message:append( nickname, color or dark_white )
	else
		message:append( "Console", color or butterfly_bush )
	end

	message:append( " says: \"", white )

	if is_muted then
		message:append( "**Player is muted**", dark_white )
	else
		message:append( text, white )
	end

	message:append( "\"", white )
	message:display()
end

hook.Add( "ChatText", "MessageHandler", function( index, name, text, message_type )
	if message_type == "servermsg" then
		server_message( text )
	elseif message_type == "chat" then
		chat_text( text )
	end

	return true
end )

function Player:ChatPrint( text )
	server_message( text, white )
end

do
	return
end

local isstring = isstring

local string = string

local messageHandlers = {}

do

    local TEXT_FILTER_GAME_CONTENT = TEXT_FILTER_GAME_CONTENT
    local TEXT_FILTER_CHAT = TEXT_FILTER_CHAT

    local chat_AddText, chat_PlaySound = chat.AddText, chat.PlaySound

    local Entity = Entity
	local unpack = unpack

    local NULL = NULL

    local band = bit.band
	local date = os.date
	if cl_chatfilters == nil then
		error( "cl_chatfilters is cannot be nil" )
	end

	local function performChatMessage( speaker, messageType, data )
		for index = 1, pointer - 1 do
			message[ index ] = nil
		end

		pointer = 1

		local handler = messageHandlers[ messageType ]
		if not handler then
			return false
		end

		if speaker:IsValid() and speaker:IsPlayer() and isstring( data[ 1 ] ) then
			---@diagnostic disable-next-line: param-type-mismatch
			data[ 1 ] = util_FilterText( data[ 1 ], (band( cl_chatfilters.value, 64 ) ~= 0) and TEXT_FILTER_CHAT or TEXT_FILTER_GAME_CONTENT, speaker )
			if hook_Run( "OnPlayerChat", nil, speaker, data[ 1 ], false, speaker:Alive() ) then
				return false
			end
		end

		local listener = Jailbreak.Player

		hook_Run( "OnChatText", listener, speaker, data )

        if handler( listener, speaker, data ) then
			return false
		end

        chat_AddText( light_grey, date( "[%H:%M:%S] " ), unpack( message ) )
        chat_PlaySound()

		return true
	end

	Jailbreak.PerformChatMessage = performChatMessage

    local net_ReadBool, net_ReadUInt, net_ReadTable = net.ReadBool, net.ReadUInt, net.ReadTable

	net.Receive( "Jailbreak::Chat", function()
		performChatMessage( net_ReadBool() and Entity( net_ReadUInt( 8 ) ) or NULL, net_ReadUInt( 5 ), net_ReadTable( true ) )
	end )

end

hook.Add( "OnPlayerChat", "Defaults", function(  )
	return not bIsAlive
end )

function GM:OnPlayerChat()
	return true
end

do

	local TrimLeft, sub, match = string.TrimLeft, string.sub, string.match

	function GM:OnChatTab( text )
		text = TrimLeft( text )

		if sub( text, 1, 1 ) == "/" then
			local command = match( text, "/( [^%s]+ )" )
			if not command then
				return "/whisper " .. sub( text, 2 )
			end

			local arguments = sub( text, #command + 2 )
			if "whisper" == command then
				text = "/emotion" .. arguments
			elseif "emotion" == command then
				text = "/coin" .. arguments
			elseif "coin" == command then
				text = "/roll" .. arguments
			elseif "roll" == command then
				text = "/looc" .. arguments
			elseif "looc" == command then
				text = "/ooc" .. arguments
			elseif "ooc" == command then
				text = "/whisper" .. arguments
			end
		else
			text = "/whisper " .. text
		end

		return text
	end

end

local GetTeamColor, Translate = Jailbreak.GetTeamColor, Jailbreak.Translate
local GetPhrase = language.GetPhrase

do

	local turquoise = Color( 64, 224, 208 )

	local function OOCHandler( listener, speaker, data, isLocal )
		if isLocal then
			insert( blue )
			insert( GetPhrase( "jb.chat.looc" ), "[]", true )
		else
			insert( turquoise )
			insert( GetPhrase( "jb.chat.ooc" ), "[]", true )
		end

		if not data[ 3 ] then
			insert( dark_white )
			insert( GetPhrase( "jb.chat.dead" ), "[]", true )
		end

		local teamID = data[ 4 ]
		if teamID then
			insert( GetTeamColor( teamID ) )
			insert( GetPhrase( "jb.chat.team." .. teamID ), "[]", true )
		end

		local text, nickname, isMuted = data[ 1 ], data[ 2 ], false
		if speaker:IsValid() and speaker:IsPlayer() then
			if speaker:IsDeveloper() then
				insert( butterfly_bush )
				insert( "/", "<>", true )
			end

			insert( speaker:GetModelColor() )
			insert( nickname or speaker:Nick() )

			if speaker:IsMuted() then
				text, isMuted = GetPhrase( "jb.chat.muted" ), true
			end
		else
			insert( dark_white )
			insert( nickname )
		end

		insert( white )
		insert( ": " )

		if isMuted then
			insert( dark_white )
		end

		insert( text )
	end

	messageHandlers[ CHAT_OOC ] = OOCHandler

	messageHandlers[ CHAT_LOOC ] = function( listener, speaker, data )
		OOCHandler( listener, speaker, data, true )
	end

end

do

	local table_remove = table.remove

	messageHandlers[ CHAT_EMOTION ] = function( listener, speaker, data )
		if not table_remove( data, 2 ) then
			insert( dark_white )
			insert( GetPhrase( "jb.chat.dead" ), "[]", true )
		end

		local nickname = table_remove( data, 1 )
		if speaker:IsValid() and speaker:IsPlayer() then
			if speaker:IsMuted() then
				return true
			end

			if speaker:IsDeveloper() then
				insert( butterfly_bush )
				insert( "/", "<>", true )
			end

			insert( speaker:GetModelColor() )
			insert( nickname or speaker:Nick() )
		else
			insert( dark_white )
			insert( nickname )
		end

		insert( white )
		insert( " " )

		for _index_0 = 1, #data do
			local value = data[ _index_0 ]
			insert( isstring( value ) and Translate( value ) or value )
		end

	end

end

do

	local MinWhisperDistance, MaxWhisperDistance = Jailbreak.MinWhisperDistance, Jailbreak.MaxWhisperDistance

	local math_random = math.random
	local math_floor = math.floor
	local math_max = math.max

	local sub = utf8.sub

	local replaceSymbols = {
		"#",
		"*",
		"~",
		"-",
		" "
	}

	messageHandlers[ CHAT_WHISPER ] = function( listener, speaker, data )
		if not data[ 3 ] then
			insert( dark_white )
			insert( GetPhrase( "jb.chat.dead" ), "[]", true )
		end

		local teamID = data[ 4 ]
		if teamID then
			insert( GetTeamColor( teamID ) )
			insert( GetPhrase( "jb.chat.team." .. teamID ), "[]", true )
		end

		local text, nickname, isMuted = data[ 1 ], data[ 2 ], false
		if speaker:IsValid() and speaker:IsPlayer() then
			if speaker:IsDeveloper() then
				insert( butterfly_bush )
				insert( "/", "<>", true )
			end

			insert( speaker:GetModelColor() )
			insert( nickname or speaker:Nick() )

			if speaker:IsMuted() then
				text, isMuted = GetPhrase( "jb.chat.muted" ), true
			end

			local distance, minDistance = speaker:EyePos():Distance( listener:EyePos() ), MinWhisperDistance:GetInt()
			if distance > minDistance then
				local maxDistance = MaxWhisperDistance:GetInt()
				if distance > maxDistance then
					return true
				end

				local lostSymbols = {}
				local length = #text

				local fraction = (distance - minDistance) / (maxDistance - minDistance)

				for i = 1, floor( length * fraction ) do
					local index = random( 1, length )
					while lostSymbols[ index ] ~= nil do
						index = random( 1, length )
					end

					lostSymbols[ index ] = true
				end

				local newText = ""

				for i = 1, floor( length * max( 1 - fraction, 0.25 ) ) do
					if lostSymbols[ i ] then
						newText = newText .. replaceSymbols[ random( 1, #replaceSymbols ) ]
					else
						newText = newText .. sub( text, i, i )
					end
				end

				text = newText
			end
		else
			insert( dark_white )
			insert( nickname )
		end

		insert( white )
		insert( " " .. GetPhrase( "jb.chat.whispers" ) .. ": \"" )

		if isMuted then
			insert( dark_white )
		end

		insert( text )

		if isMuted then
			insert( white )
		end

		insert( "\"" )
	end
end

messageHandlers[ CHAT_CUSTOM ] = function( _, __, data )
	for _index_0 = 1, #data do
		local value = data[ _index_0 ]
		insert( isstring( value ) and Translate( value ) or value )
	end
end

messageHandlers[ CHAT_CONNECTED ] = function( _, __, data )
	insert( white )
	insert( GetPhrase( "jb.player" ) .. " " )

	insert( data[ 1 ] )
	insert( data[ 2 ] )

	local steamID = data[ 3 ]
	if steamID then
		insert( white )
		insert( " ( " )

		insert( blue )
		insert( steamID )

		insert( white )
		insert( " )" )
	end

	insert( white )
	insert( " " .. GetPhrase( "jb.chat.player.connected" ) )
end

do

    local asparagus = Color( 128, 154, 86 )

    messageHandlers[ CHAT_CONNECT ] = function( _, __, data )
		insert( white )
		insert( GetPhrase( "jb.player" ) .. " " )

        insert( asparagus )
		insert( data[ 1 ] )

        local address = data[ 2 ]
		if address then
			insert( white )
			insert( " ( " )

            insert( blue )
			insert( address )

            insert( white )
			insert( " )" )
		end

		insert( white )
		insert( " " .. GetPhrase( "jb.chat.player.connecting" ) )
	end

end

do

    local au_chico = Color( 154, 98, 86 )

    messageHandlers[ CHAT_DISCONNECT ] = function( _, __, data )
		insert( white )
		insert( GetPhrase( "jb.player" ) .. " " )

        insert( au_chico )
		insert( data[ 1 ] )

        local steamID = data[ 2 ]
		if steamID then
			insert( white )
			insert( " ( " )

            insert( blue )
			insert( steamID )

            insert( white )
			insert( " )" )
		end

		local reason = data[ 3 ]
		if reason ~= nil then
			insert( white )
    		insert( " " .. GetPhrase( "jb.chat.player.disconnected-with-reason" ) .. ": \"" )

            insert( dark_white )
			insert( reason )

            insert( white )
			insert( "\"" )
		else

            insert( white )
			insert( " " .. GetPhrase( "jb.chat.player.disconnected" ) )
		end
	end

end

messageHandlers[ CHAT_NAMECHANGE ] = function( _, __, data )
	insert( white )
	insert( GetPhrase( "jb.player" ) .. " " )

    local color = data[ 3 ]
	insert( color )
	insert( data[ 1 ] )

    insert( white )
	insert( " " .. GetPhrase( "jb.chat.player.changed-name" ) .. " " )

    insert( color )
	insert( data[ 2 ] )

    insert( white )
	insert( "." )
end

return ash_chat
