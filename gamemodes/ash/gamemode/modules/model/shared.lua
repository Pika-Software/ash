local util_GetModelInfo = util.GetModelInfo
local Vector_Distance = Vector.Distance

local string_lower = string.lower
local string_match = string.match
local string_byte = string.byte
local string_gsub = string.gsub

local rawset = rawset
local pairs = pairs

---@class ash.model
local ash_model = {}

---@type table<string, string>
local types = {
    [ "models/m_anm.mdl" ] = "male",
    [ "models/f_anm.mdl" ] = "female",
    [ "models/z_anm.mdl" ] = "zombie"
}

ash_model.Types = types

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

ash_model.pathFix = model_path_fix

---@param model_path string
---@return string
local function precache_model( model_path )
    model_path = model_path_fix( model_path )
    models_cache[ model_path ] = true
    return model_path
end

ash_model.precache = precache_model

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
function ash_model.getActivityID( act_name )
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
function ash_model.getActivityName( act_id )
    return activity_names[ act_id ] or "ACT_INVALID"
end

---@class ash.model.Bone
---@field id integer
---@field name string
---@field position Vector
---@field angles Angle
---@field flags integer
---@field surface_material string
---@field phys_id integer
---@field parent ash.model.Bone | nil

---@class ash.model.Attachment
---@field id integer
---@field name string
---@field bone ash.model.Bone

---@class ash.model.HitBox
---@field id integer
---@field bone ash.model.Bone
---@field mins Vector
---@field maxs Vector

---@class ash.model.HitBoxGroup
---@field id integer
---@field name string
---@field count integer
---@field hitboxes ash.model.HitBox[]

---@class ash.model.SequenceEvent
---@field id integer
---@field name string
---@field type integer
---@field cycle number
---@field options string

---@class ash.model.Sequence
---@field id integer
---@field name string
---@field events ash.model.SequenceEvent[]
---@field activity ACT | integer | nil

---@class ash.model.Info
---@field version integer
---@field name string
---@field type "male" | "female" | "zombie" | "other" | string
---@field model string
---@field hands string
---@field mins Vector
---@field maxs Vector
---@field volume number
---@field has_wings boolean
---@field skin_count integer
---@field surface_material string
---@field materials string[]
---@field material_count integer
---@field bones ash.model.Bone[]
---@field bone_count integer
---@field sequences ash.model.Sequence[]
---@field sequence_count integer
---@field attachments ash.model.Attachment[]
---@field attachment_count integer
---@field hitbox_groups ash.model.HitBoxGroup[]
---@field hitbox_group_count integer

---@type table<string, ash.model.Info>
local models_map = {}

---@type ash.model.Info
local fallback_info

--- [SHARED]
---
--- Get the model info by model name.
---
---@param model_name string
---@return ash.model.Info model_info
function ash_model.get( model_name )
    return models_map[ model_name ] or fallback_info
end

--- [SHARED]
---
--- Set the model path by model name.
---
---@param model_name string
---@param model_path string | nil
---@param hands_path string | nil
---@return ash.model.Info model_info
function ash_model.set( model_name, model_path, hands_path )
    if model_path ~= nil then
        model_path = model_path_fix( model_path )
    end

    if hands_path ~= nil then
        hands_path = model_path_fix( hands_path )
    end

    local model_info = models_map[ model_name ]
    if model_info == nil then
        if model_path == nil then
            model_path = fallback_info.model
        end

        if hands_path == nil then
            hands_path = fallback_info.hands
        end

        model_info = {
            version = 0,
            name = model_name,
            type = "other",
            model = model_path,
            hands = hands_path,
            mins = Vector( -16, -16, 0 ),
            maxs = Vector( 16, 16, 72 ),
            volume = 100,
            has_wings = false,
            skin_count = 0,
            surface_material = "flesh",
            materials = {},
            material_count = 0,
            bones = {},
            bone_count = 0,
            sequences = {},
            sequence_count = 0,
            attachments = {},
            attachment_count = 0,
            hitbox_groups = {},
            hitbox_group_count = 0
        }

        models_map[ model_name ] = model_info
    else

        if model_path == nil then
            model_path = model_info.model or fallback_info.model
        end

        if hands_path == nil then
            hands_path = model_info.hands or fallback_info.hands
        end

        model_info.model = model_path
        model_info.hands = hands_path

    end

    local engine_info = util_GetModelInfo( model_path ) or {}

    model_info.skin_count = engine_info.SkinCount or model_info.skin_count

    local bone_count = engine_info.BoneCount or model_info.bone_count
    model_info.bone_count = bone_count

    local attachment_count = engine_info.AttachmentCount or model_info.attachment_count
    model_info.attachment_count = attachment_count

    local sequence_count = engine_info.SequenceCount or model_info.sequence_count
    model_info.sequence_count = sequence_count

    model_info.surface_material = engine_info.SurfacePropName or model_info.surface_material
    model_info.version = engine_info.Version or model_info.version

    local mins, maxs = engine_info.HullMin, engine_info.HullMax
    model_info.mins, model_info.maxs = mins, maxs

    model_info.volume = Vector_Distance( mins, maxs )

    local sub_models = engine_info.IncludeModels or {}

    for i = 1, engine_info.IncludeModelCount or #sub_models, 1 do
        local model_type = types[ sub_models[ i ] ]
        if model_type ~= nil then
            model_info.type = model_type
            break
        end
    end

    local bones = model_info.bones

    for i in pairs( bones ) do
        bones[ i ] = nil
    end

    local engine_bones = engine_info.Bones
    if engine_bones ~= nil then
        for i = 1, bone_count, 1 do
            local bone = engine_bones[ i ]
            if bone ~= nil then
                bones[ i ] = {
                    id = i - 1,
                    name = bone.Name,
                    position = bone.Position,
                    angles = bone.Angle,
                    flags = bone.Flags,
                    surface_material = bone.SurfacePropName,
                    phys_id = bone.PhysObj
                }
            end
        end

        for i = 1, bone_count, 1 do
            local bone = bones[ i ]
            if bone ~= nil then
                if string_match( string_lower( bone.name ), "[^%l]?wings?[^%l]?" ) ~= nil then
                    model_info.has_wings = true
                end

                local parent_id = engine_bones[ i ].Parent
                if parent_id >= 0 then
                    bone.parent = bones[ parent_id + 1 ]
                end
            end
        end
    end

    local attachments = model_info.attachments

    for i in pairs( attachments ) do
        attachments[ i ] = nil
    end

    local engine_attachments = engine_info.Attachments
    if engine_attachments ~= nil then
        for i = 1, attachment_count, 1 do
            local attachment = engine_attachments[ i ]
            if attachment ~= nil then
                attachments[ i ] = {
                    id = i - 1,
                    name = attachment.Name,
                    bone = bones[ attachment.Bone + 1 ]
                }
            end
        end
    end

    local hitbox_groups = model_info.hitbox_groups

    for i in pairs( hitbox_groups ) do
        hitbox_groups[ i ] = nil
    end

    local engine_hitbox_groups = engine_info.HitBoxSets
    if engine_hitbox_groups ~= nil then
        local hitbox_group_count = #engine_hitbox_groups
        for i = 1, hitbox_group_count, 1 do
            local hitbox_group = engine_hitbox_groups[ i ]
            if hitbox_group ~= nil then
                local hitboxes = {}
                local hitbox_count = hitbox_group.Count

                for j = 1, hitbox_count, 1 do
                    local hitbox = hitbox_group.HitBoxes[ j ]
                    if hitbox ~= nil then
                        hitboxes[ j ] = {
                            id = j - 1,
                            bone = bones[ hitbox.Bone + 1 ],
                            mins = hitbox.Mins,
                            maxs = hitbox.Maxs
                        }
                    end
                end

                hitbox_groups[ i ] = {
                    id = i - 1,
                    name = hitbox_group.Name,
                    count = hitbox_count,
                    hitboxes = hitboxes
                }
            end
        end

        model_info.hitbox_group_count = hitbox_group_count
    end

    local sequences = model_info.sequences

    for i in pairs( sequences ) do
        sequences[ i ] = nil
    end

    local engine_sequences = engine_info.Sequences
    if engine_sequences ~= nil then
        for i = 1, sequence_count, 1 do
            local sequence = engine_sequences[ i ]
            if sequence ~= nil then
                ---@type ash.model.SequenceEvent[]
                local events = {}

                local engine_events = sequence.Events
                if engine_events ~= nil then
                    for j = 1, #engine_events, 1 do
                        local engine_event = engine_events[ j ]
                        if engine_event ~= nil then
                            events[ j ] = {
                                id = engine_event.Event,
                                name = engine_event.Name,
                                type = engine_event.Type,
                                cycle = engine_event.Cycle,
                                options = engine_event.Options
                            }
                        end
                    end
                end

                sequences[ i ] = {
                    id = i - 1,
                    name = sequence.Name,
                    activity = activity_ids[ sequence.Activity ],
                    events = events
                }
            end
        end
    end

    local materials = model_info.materials
    local material_count = 0

    for i in pairs( materials ) do
        materials[ i ] = nil
    end

    local engine_material_directories = engine_info.MaterialDirectories
    if engine_material_directories ~= nil then
        local engine_materials = engine_info.Materials
        if engine_materials ~= nil then
            local engine_materials_count = engine_info.MaterialCount or #engine_materials
            for i = 1, #engine_material_directories, 1 do
                local directory = model_path_fix( engine_material_directories[ i ] )

                if string_byte( directory, -1 ) ~= 0x2F --[[ / ]] then
                    directory = directory .. "/"
                end

                for j = 1, engine_materials_count, 1 do
                    material_count = material_count + 1
                    materials[ material_count ] = directory .. engine_materials[ j ]
                end
            end
        end
    end

    model_info.material_count = material_count

    return model_info
end

fallback_info = ash_model.set( "default", "models/player/infoplayerstart.mdl", "models/weapons/c_arms_infoplayerstart.mdl" )

return ash_model
