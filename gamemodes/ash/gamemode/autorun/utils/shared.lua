---@type dreamwork.std
local dreamwork = ash.dreamwork
local debug = dreamwork.debug

--- [SHARED]
---
--- ash Utils Library (FFUL)
---
---@class ash.utils
local utils = {}
ash.utils = utils

local string_gsub = string.gsub
local string_lower = string.lower

--- [SHARED]
---
--- Get unix time current day in 0:00 hour
---
---@param time number
---@return number
function utils.getDayStartTime( time )
    ---@type osdate
    ---@diagnostic disable-next-line: assign-type-mismatch
    local data = os.date( "*t", time or os.time() )

    data.sec = 0
    data.min = 0
    data.hour = 0

    return os.time( data )
end

do

    local math_random = math.random
    local raw_set = dreamwork.raw.set

    ---@type table<string, boolean>
    local models_cache = {}

    do

        local util_PrecacheModel = _G.util.PrecacheModel

        setmetatable( models_cache, {
            __newindex = function( self, model_path, is_cached )
                if is_cached then
                    util_PrecacheModel( model_path )
                    raw_set( self, model_path, true )
                end
            end
        } )

    end

    local function model_path_fix( model_path )
        return string_gsub( string_lower( model_path ), "[\\/]+", "/" )
    end

    ---@param model_path string
    ---@return string
    local function precache_model( model_path )
        model_path = model_path_fix( model_path )
        models_cache[ model_path ] = true
        return model_path
    end

    utils.Model = precache_model

    local values = debug.getupvalues( player_manager.AddValidModel )

    ---@type table<string, string>
    local model_paths = values.ModelList or {}

    ---@type table<string, string>
    local model_names = values.ModelListRev or {}

    ---@type string[]
    local model_list = {}

    ---@type integer
    local model_count = 0

    for model_name, model_path in pairs( model_paths ) do
        model_count = model_count + 1
        model_list[ model_count ] = model_path_fix( model_path )
    end

    setmetatable( model_paths, {
        __newindex = function( self, model_name, model_path )
            model_path = model_path_fix( model_path )

            raw_set( model_paths, model_name, model_path )
            raw_set( model_names, model_path, model_name )

            model_count = model_count + 1
            model_list[ model_count ] = model_path
        end
    } )

    ---@param model_name string
    ---@return string model_path
    function utils.PlayerModel( model_name )
        local model_path = model_paths[ model_name ]
        if model_path == nil then
            if model_count == 0 then
                return "models/player/mossman.mdl"
            else
                return model_list[ math_random( 1, model_count ) ]
            end
        else
            return model_path
        end
    end

    do

        local Entity_SetModel = Entity.SetModel

        ---@param pl Player
        ---@param model_path string
        function Player.SetModel( pl, model_path )
            model_path = model_path_fix( model_path )

            if hook.Run( "CanPlayerChangeModel", pl, model_path ) == false then
                return false
            end

            Entity_SetModel( pl, model_path )
            hook.Run( "PlayerModelChanged", pl, model_path )

            return true
        end

    end

end

return utils
