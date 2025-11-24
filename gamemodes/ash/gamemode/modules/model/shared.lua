local string_lower = string.lower
local string_gsub = string.gsub
local rawset = rawset

---@class ash.model
local model_lib = {}

---@type table<string, boolean>
local models_cache = {}

do

    local util_PrecacheModel = util.PrecacheModel

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

---@type table<string, integer>
local activity_ids = {}

do

    local util_GetActivityIDByName = util.GetActivityIDByName

    setmetatable( activity_ids, {
        __index = function( self, name )
            local id = util_GetActivityIDByName( name )
            self[ name ] = id
            return id
        end
    } )

end

---@type table<integer, string>
local activity_names = {}

do

    local util_GetActivityNameByID = util.GetActivityNameByID

    setmetatable( activity_names, {
        __index = function( self, id )
            local name = util_GetActivityNameByID( id )
            self[ id ] = name
            return name
        end
    } )

end

--- [SHARED AND MENU]
---
--- Returns the ID of the activity by name.
---
--- Basic activities: https://developer.valvesoftware.com/wiki/Activity_List#Base_activities
---
--- Gmod ones: https://wiki.facepunch.com/gmod/Enums/ACT
---
---@param act_name string The name of the activity.
---@return integer act_id The ID of the activity.
function model_lib.getActivityID( act_name )
    return activity_ids[ act_name ] or -1
end

--- [SHARED AND MENU]
---
--- Returns the name of the activity by ID.
---
--- Basic activities: https://developer.valvesoftware.com/wiki/Activity_List#Base_activities
---
--- Gmod ones: https://wiki.facepunch.com/gmod/Enums/ACT
---
---@param act_id integer The ID of the activity.
---@return string act_name The name of the activity.
function model_lib.getActivityName( act_id )
    return activity_names[ act_id ] or "ACT_INVALID"
end


return model_lib
