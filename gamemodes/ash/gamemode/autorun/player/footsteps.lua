---@class ash.player
local player_lib = include( "shared.lua" )

---@type ash.entity
local entity_lib = require( "ash.entity" )

---@type ash.sound
local sound_lib = require( "ash.sound" )
local sound_exists = sound_lib.exists
local sound_merge = sound_lib.merge

local string_match = string.match
local file_Find = file.Find
local hook_Run = hook.Run

---@class ash.player.footsteps
local footsteps = player_lib.footsteps or {}
player_lib.footsteps = footsteps

---@type string[]
local move_types = {
    "wandering",
    "walking",
    "running",
    "landing"
}

footsteps.MoveTypes = move_types

---@type table<string, boolean>
local loud_move_types = {
    running = true,
    landing = true
}

footsteps.LoudMoveTypes = loud_move_types

--- [SHARED]
---
--- Register legacy footsteps for a shoes type and a directory path.
---
--- Files should be named as `{material_name}01.wav` for example.
---
---@param shoes_type string
---@param directory_path string
---@param sound_data ash.sound.Data | nil
function footsteps.registerLegacy( shoes_type, directory_path, sound_data )
    local move_types_count = #move_types

    if sound_data == nil then
        sound_data = {}
    end

    for _, file_name in ipairs( file_Find( "sound/" .. directory_path .. "/*", "GAME" ) ) do
        local material_name = string_match( file_name, "^(%l+)" ) or "default"

        local footstep_sounds = file_Find( "sound/" .. directory_path .. "/" .. material_name .. "*", "GAME" )
        local footstep_sounds_count = #footstep_sounds

        for j = 1, footstep_sounds_count, 1 do
            footstep_sounds[ j ] = ")^" .. directory_path .. "/" .. footstep_sounds[ j ]
        end

        sound_data.sound = footstep_sounds

        for j = 1, move_types_count, 1 do
            sound_merge( shoes_type .. "." .. material_name .. "." .. move_types[ j ], sound_data )
        end
    end
end

--- [SHARED]
---
--- Register footsteps for a shoes type and a directory path.
---
--- Files should be named as `{material_name}/{move_type}/any_name01.wav` for example.
---
---@param shoes_type string
---@param directory_path string
---@param sound_data ash.sound.Data | nil
function footsteps.register( shoes_type, directory_path, sound_data )
    local shoes_path = directory_path .. "/" .. shoes_type .. "/"
    local move_types_count = #move_types

    if sound_data == nil then
        sound_data = {}
    end

    local _, materials = file_Find( "sound/" .. shoes_path .. "*", "GAME" )

    for k = 1, #materials, 1 do
        local material_name = materials[ k ]
        local material_path = shoes_path .. material_name .. "/"

        local types, type_counts = {}, {}

        for i = 1, move_types_count, 1 do
            local move_name = move_types[ i ]

            local move_path = material_path .. move_name .. "/"
            local sounds = file.Find( "sound/" .. move_path .. "*", "GAME" )
            local sound_count = #sounds

            for j = 1, sound_count, 1 do
                sounds[ j ] = ")^" .. move_path .. sounds[ j ]
            end

            type_counts[ move_name ] = sound_count
            types[ move_name ] = sounds
        end

        for i = 1, move_types_count, 1 do
            local move_name = move_types[ i ]

            local move_sounds, move_sound_count = types[ move_name ], type_counts[ move_name ]

            if move_sound_count == 0 then
                local init, finish, step

                if loud_move_types[ move_name ] then
                    init, finish, step = move_types_count, 1, -1
                else
                    init, finish, step = 1, move_types_count, 1
                end

                for j = init, finish, step do
                    local alt_move_name = move_types[ j ]
                    local alt_move_count = type_counts[ alt_move_name ]
                    if alt_move_count ~= 0 then
                        move_sounds = types[ alt_move_name ]
                        move_sound_count = alt_move_count
                        break
                    end
                end
            end

            sound_data.sound = move_sounds

            sound_merge( shoes_type .. "." .. material_name .. "." .. move_name, sound_data )
        end
    end
end

--- [SHARED]
---
--- Check if footsteps exist for a shoes type and a material name.
---
---@param shoes_type string
---@param material_name string
function footsteps.exists( shoes_type, material_name )
    for i = 1, #move_types, 1 do
        if not sound_exists( shoes_type .. "." .. material_name .. "." .. move_types[ i ] ) then
            return false
        end
    end

    return true
end

--- [SHARED]
---
--- Register footsteps for a shoes type and a directory path.
---
--- Files should be named as `{material_name}/{move_type}/any_name01.wav` for example.
---
---@param shoes_type string
---@param material_name string
---@param material_base string
---@param sound_data ash.sound.Data | nil
function footsteps.alias( shoes_type, material_name, material_base, sound_data )
    local base_half_name = shoes_type .. "." .. material_base
    local sound_half_name = shoes_type .. "." .. material_name

    if sound_data == nil then
        sound_data = {}
    end

    for i = 1, #move_types, 1 do
        local move_name = move_types[ i ]
        sound_data.name = sound_half_name .. "." .. move_name
        sound_merge( base_half_name .. "." .. move_name, sound_data )
    end
end

---@type table<Player, string>
local player_shoes = {}

setmetatable( player_shoes, {
    __mode = "k",
    __index = function( self, pl )
        local shoes_type = "default"
        self[ pl ] = shoes_type
        return shoes_type
    end
} )

--- [SHARED]
---
--- Gets the player's shoes type.
---
---@param pl Player
---@return string shoes_type
function footsteps.getShoesType( pl )
    return player_shoes[ pl ]
end

--- [SHARED]
---
--- Sets the player's shoes type.
---
---@param pl Player
---@param shoes_type string
function footsteps.setShoesType( pl, shoes_type )
    player_shoes[ pl ] = shoes_type
end

do

    local Entity_GetBoneMatrix = Entity.GetBoneMatrix
    local Entity_GetMoveType = Entity.GetMoveType
    local Entity_WaterLevel = Entity.WaterLevel

    local entity_getHitboxBounds = entity_lib.getHitboxBounds
    local entity_getHitbox = entity_lib.getHitbox

    local util = util
    local util_TraceLine = util.TraceLine
    local util_TraceHull = util.TraceHull

    ---@type TraceResult
    local trace_results = {}

    ---@type HullTrace | Trace
    local trace = {
        output = trace_results
    }

    ---@type table<Player, table<string, boolean>>
    local footstates = {}

    setmetatable( footstates, {
        __mode = "k",
        __index = function( self, pl )
            local bones = {}
            self[ pl ] = bones
            return bones
        end
    } )

    ---@param pl Player
    ---@param bone_id integer
    local function perform_step_sound( pl, bone_id )
        local matrix = Entity_GetBoneMatrix( pl, bone_id )
        if matrix == nil then return end

        trace.filter = pl

        local origin = matrix:GetTranslation()
        local angles = matrix:GetAngles()

        local direction = -angles:Right() * 6

        trace.start = origin
        trace.endpos = origin + direction

        local hitbox, hitbox_group = entity_getHitbox( pl, bone_id )

        if hitbox == nil then
            trace.mins, trace.maxs = nil, nil
        else
            ---@diagnostic disable-next-line: assign-type-mismatch
            trace.mins, trace.maxs = entity_getHitboxBounds( pl, hitbox, hitbox_group )
        end

        if trace.mins == nil then
            ---@cast trace Trace
            util_TraceLine( trace )
        else
            ---@cast trace HullTrace
            util_TraceHull( trace )
        end

        local state = trace_results.Hit

        if state == footstates[ pl ][ bone_id ] then return end
        footstates[ pl ][ bone_id ] = state

        if state then
            hook_Run( "PlayerTakesFootstep", pl, trace_results, bone_id )
        end
    end

    local player_isCrouching = player_lib.isCrouching
    local player_isRunning = player_lib.isRunning
    local player_isFalling = player_lib.isFalling

    local Entity_GetBoneCount = Entity.GetBoneCount
    local Entity_GetBoneName = Entity.GetBoneName

    hook.Add( "PlayerPostThink", "FootstepsThink", function( pl )
        if Entity_GetMoveType( pl ) == MOVETYPE_LADDER then
            -- hook_Run( "PlayerOnLadder", pl )
            return
        end

        if Entity_WaterLevel( pl ) == 3 then
            -- hook_Run( "PlayerInWater", pl )
            return
        end

        for bone_id = 0, Entity_GetBoneCount( pl ) - 1, 1 do
            local bone_name = Entity_GetBoneName( pl, bone_id )
            if bone_name ~= nil and string_match( bone_name, "^ValveBiped.Bip%d+_%w_Foot$" ) ~= nil then
                perform_step_sound( pl, bone_id )
            end
        end

        ---@diagnostic disable-next-line: redundant-parameter, undefined-global
    end, PRE_HOOK )

    ---@param origin Vector
    ---@param shoes_type string
    ---@param material_name string
    ---@param move_type string
    ---@param volume number | nil
    ---@param sound_level integer | nil
    ---@param pitch integer | nil
    ---@param dsp integer | nil
    local function emitFootstepSound( origin, shoes_type, material_name, move_type, volume, sound_level, pitch, dsp )
        sound_lib.play( shoes_type .. "." .. material_name .. "." .. move_type, origin, sound_level, pitch, volume, dsp )
        -- PrintMessage( HUD_PRINTCENTER, shoes_type .. "." .. material_name .. "." .. move_type )
    end

    player_lib.emitFootstepSound = emitFootstepSound

    ---@param pl Player
    ---@param trace_results TraceResult
    ---@param bone_name string
    hook.Add( "PlayerTakesFootstep", "Default", function( pl, trace_results, bone_name )
        local move_type, volume, sound_level

        if player_isCrouching( pl ) then
            move_type = "wandering"
            sound_level = 40
            volume = 0.75
        elseif player_isRunning( pl ) then
            move_type = "running"
            sound_level = 90
            volume = 1.25
        elseif player_isFalling( pl ) then
            move_type = "landing"
            sound_level = 100
            volume = 1.5
        else
            move_type = "walking"
            sound_level = 75
            volume = 1
        end

        local water_level = Entity_WaterLevel( pl )
        if water_level == 1 or water_level == 2 then
            emitFootstepSound( trace_results.HitPos, player_shoes[ pl ], "water", move_type, volume, sound_level, nil, 1 )
            return
        end

        local surface_data = util.GetSurfaceData( trace_results.SurfaceProps )
        if surface_data ~= nil then
            emitFootstepSound( trace_results.HitPos, player_shoes[ pl ], surface_data.name, move_type, volume, sound_level, nil, 1 )
        end
    end )

end

do

    ---@class ash.player.footsteps.ShoesData : ash.sound.Data
    ---@field aliases table<string, string>
    ---@field path string | nil

    --- https://developer.valvesoftware.com/wiki/Material_surface_properties
    ---@type table<string, ash.player.footsteps.ShoesData>
    local shoes = {
        default = {
            channel = 6,
            level = 75,
            pitch = { 118, 138 },
            aliases = {
                { "tile", "concrete" },
                { "default", "concrete" },
                { "default_silent", "tile" },
                { "boulder", "concrete" },
                { "brick", "concrete" },
                { "concrete_block", "concrete" },
                { "gravel", "concrete" },
                { "rock", "concrete" },
                { "plastic", "concrete" },
                -- { "metal", "metalbar" },
                { "solidmetal", "metal" },
                { "metalbox", "metal" },
                { "metalvent", "metalbox" },
                { "computer", "metalbox" },
                { "metalgrate", "metal" },
                { "wood_solid", "wood" },
                { "woodpanel", "wood_solid" },
                { "wood_furniture", "woodpanel" },
                { "wood_lowdensity", "wood_furniture" },
                { "wood_box", "wood_furniture" },
                { "wood_crate", "wood_furniture" },
                { "wood_plank", "wood_furniture" },
                { "rubber", "carpet" }
            }
        }
    }

    footsteps.Shoes = shoes

    hook.Add( "Initialize", "BuildFootsteps", function()
        for shoes_name, data in pairs( shoes ) do
            local directory_path = data.path or "player/footsteps"

            footsteps.registerLegacy( shoes_name, directory_path, data )
            footsteps.register( shoes_name, directory_path, data )

            local aliases = data.aliases

            for i = 1, #aliases, 1 do
                local alias = aliases[ i ]
                local material_name, material_base = alias[ 1 ], alias[ 2 ]

                if not footsteps.exists( shoes_name, material_name ) then
                    footsteps.alias( shoes_name, material_name, material_base )
                end
            end
        end
    end )

end

return footsteps
