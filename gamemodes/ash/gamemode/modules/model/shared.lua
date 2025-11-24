---@type dreamwork.std.ModelClass
local Model = dreamwork.std.Model

local glua_util = _G.util

local string_lower = string.lower
local string_gsub = string.gsub
local rawset = rawset

---@class ash.model
local model_lib = {}

---@type table<string, boolean>
local models_cache = {}

do

    local util_PrecacheModel = glua_util.PrecacheModel

    setmetatable( models_cache, {
        __newindex = function( self, model_path, is_cached )
            if is_cached then
                util_PrecacheModel( model_path )
                rawset( self, model_path, true )
            end
        end
    } )

end

local function model_path_fix( model_path )
    return string_gsub( string_lower( model_path ), "[\\/]+", "/" )
end

model_lib.pathFix = model_path_fix

---@param model_path string
---@return string
local function precache_model( model_path )
    model_path = model_path_fix( model_path )
    models_cache[ model_path ] = true
    return model_path
end

model_lib.precache = precache_model

---@class ash.model.Info
---@field name string
---@field model string
---@field hands string
---@field extras table<string, any>

---@type table<string, ash.model.Info>
local models_map = {}

---@type ash.model.Info
local fallback_info = {
    name = "default",
    model = "models/player/mossman.mdl",
    hands = "models/weapons/c_arms_citizen.mdl",
    extras = {}
}

--- [SHARED]
---
--- Get the model info by model name.
---
---@param model_name string
---@return ash.model.Info model_info
function model_lib.get( model_name )
    return models_map[ model_name ] or fallback_info
end

--- [SHARED]
---
--- Set the model path by model name.
---
---@param model_name string
---@param model_path string | nil
---@param hands_path string | nil
---@param extras table<string, any> | nil
---@return ash.model.Info model_info
function model_lib.set( model_name, model_path, hands_path, extras )
    if model_path ~= nil then
        model_path = model_path_fix( model_path )
    end

    if hands_path ~= nil then
        hands_path = model_path_fix( hands_path )
    end

    local model_info = models_map[ model_name ]
    if model_info == nil then
        model_info = {
            name = model_name,
            model = model_path or fallback_info.model,
            hands = hands_path or fallback_info.hands,
            extras = extras or {}
        }

        models_map[ model_name ] = model_info
    end

    model_info.model = model_path or model_info.model or fallback_info.model
    model_info.hands = hands_path or model_info.hands or fallback_info.hands
    model_info.extras = extras or model_info.extras or {}

    return model_info
end

model_lib.getActivityID = Model.getGlobalActivityID
model_lib.getActivityName = Model.getGlobalActivityName

return model_lib
