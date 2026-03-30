---@type dreamwork
local dreamwork = _G.dreamwork

---@type dreamwork.std
local std = dreamwork.std

---@type ash.gamemode.Info
local gamemode_info = ash.Chain[ 1 ]
local gamemode_name = gamemode_info.name

local gamemode_description = std.string.format( "%s@%s", gamemode_info.title, gamemode_info.version )

do

    ---@type GM
    local GM = ( GM or GAMEMODE )

    GM.Name = gamemode_info.title
    GM.Author = gamemode_info.author

    GM.FolderName = gamemode_name
    GM.Folder = "gamemodes/" .. gamemode_name

    GM.GrabEarAnimation = std.debug.fempty
    GM.MouthMoveAnimation = GM.GrabEarAnimation

    if CLIENT then

        ---@diagnostic disable-next-line: duplicate-set-field
        function GM:GetTeamColor( entity )
            ---@type fun( entity: Entity ): Vector
            ---@diagnostic disable-next-line: undefined-field
            local fn = entity.GetPlayerColor
            if fn == nil then
                return Color( 255, 255, 255, 255 )
            end

            local vec3 = fn( entity )
            return Color( vec3[ 1 ] * 255, vec3[ 2 ] * 255, vec3[ 3 ] * 255, 255 )
        end

    end

    function GM:GetGameDescription()
        return gamemode_description
    end

end

dreamwork.engine.hookCatch( "GamemodeSelected", function( name, t )
    if name == "base" then
        std.table.clearKeys( t )
    end
end )

if SERVER then

    local RunConsoleCommand = _G.RunConsoleCommand

    local convars = {
        { "sv_gamename_override", gamemode_description },
        { "sv_defaultdeployspeed", "1" },
        { "mp_show_voice_icons", "0" },
        { "sv_gravity", "800" }
    }

    for i = 1, #convars, 1 do
        local convar_data = convars[ i ]
        RunConsoleCommand( convar_data[ 1 ], convar_data[ 2 ] )
    end

end

do

    local hook_Remove = _G.hook.Remove

    -- [[ SHARED ]] --

	hook_Remove( "EntityRemoved", "RemoveWidgets" )
	hook_Remove( "OnEntityCreated", "CreateWidgets" )

	-- garrysmod/lua/includes/modules/notification.lua
	hook_Remove( "Think", "NotificationThink" )

	-- garrysmod/lua/includes/extensions/entity.lua
	-- hook_Remove( "EntityRemoved", "DoDieFunction" ) -- still trash, but full removing take some time

end
