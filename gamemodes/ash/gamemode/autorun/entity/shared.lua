---@class ash.entity
local entity_lib = {}

---@type ash.utils
local utils = require( "ash.utils" )

do

    local Entity_GetHitboxSetCount = Entity.GetHitboxSetCount
    local Entity_GetHitBoxCount = Entity.GetHitBoxCount

    local Entity_GetHitboxSet = Entity.GetHitboxSet
    local Entity_SetHitboxSet = Entity.SetHitboxSet

    local Entity_GetHitBoxHitGroup = Entity.GetHitBoxHitGroup
    local Entity_GetHitBoxBounds = Entity.GetHitBoxBounds
    local Entity_GetHitBoxBone = Entity.GetHitBoxBone

    --- [SHARED]
    ---
    --- Get hitbox set count.
    ---
    ---@param entity Entity
    ---@return integer
    function entity_lib.getHitboxGroupCount( entity )
        return Entity_GetHitboxSetCount( entity )
    end

    --- [SHARED]
    ---
    --- Get hitbox count.
    ---
    ---@param entity Entity
    ---@param hitbox_group integer
    ---@return integer
    function entity_lib.getHitboxCount( entity, hitbox_group )
        return Entity_GetHitBoxCount( entity, ( hitbox_group or 0 ) - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox groups.
    ---
    ---@param entity Entity
    ---@return string[] groups
    ---@return integer group_count
    function entity_lib.getHitboxGroups( entity )
        local initial_hitbox_group = Entity_GetHitboxSet( entity )
        local groups, group_count = {}, 0

        for hitbox_group = 1, Entity_GetHitboxSetCount( entity ), 1 do
            Entity_SetHitboxSet( entity, hitbox_group - 1 )
            local _, group_name = Entity_GetHitboxSet( entity )

            group_count = group_count + 1
            groups[ group_count ] = group_name
        end

        Entity_SetHitboxSet( entity, initial_hitbox_group )

        return groups, group_count
    end

    --- [SHARED]
    ---
    --- Get hitbox set.
    ---
    ---@param entity Entity
    ---@return integer hitbox_group
    function entity_lib.getHitboxGroup( entity )
        return Entity_GetHitboxSet( entity ) + 1
    end

    --- [SHARED]
    ---
    --- Set hitbox set.
    ---
    ---@param entity Entity
    ---@param hitbox_group integer
    function entity_lib.setHitboxGroup( entity, hitbox_group )
        return Entity_SetHitboxSet( entity, hitbox_group - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox ID.
    ---
    ---@param entity Entity
    ---@param bone_id integer
    ---@return integer | nil hitbox
    ---@return integer hitbox_group
    function entity_lib.getHitbox( entity, bone_id )
        local hitbox_group = Entity_GetHitboxSet( entity )

        for hitbox = 0, Entity_GetHitBoxCount( entity, hitbox_group ) - 1, 1 do
            if Entity_GetHitBoxBone( entity, hitbox, hitbox_group ) == bone_id then
                return hitbox + 1, hitbox_group + 1
            end
        end

        return nil, hitbox_group + 1
    end

    --- [SHARED]
    ---
    --- Get hitbox bone.
    ---
    ---@param entity Entity
    ---@param hitbox integer
    ---@param hitbox_group integer
    ---@return integer | nil
    function entity_lib.getHitboxBone( entity, hitbox, hitbox_group )
        return Entity_GetHitBoxBone( entity, hitbox - 1, hitbox_group - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox bounds.
    ---
    ---@param entity Entity
    ---@param hitbox integer
    ---@param hitbox_group integer
    ---@return Vector | nil mins
    ---@return Vector | nil maxs
    function entity_lib.getHitboxBounds( entity, hitbox, hitbox_group )
        return Entity_GetHitBoxBounds( entity, hitbox - 1, hitbox_group - 1 )
    end

    --- [SHARED]
    ---
    --- Get hitbox hit group.
    ---
    ---@param entity Entity
    ---@param hitbox integer
    ---@param hitbox_group integer
    ---@return integer | nil
    function entity_lib.getHitboxHitGroup( entity, hitbox, hitbox_group )
        return Entity_GetHitBoxHitGroup( entity, hitbox - 1, hitbox_group - 1 )
    end

end

do

    local Entity_SelectWeightedSequence = Entity.SelectWeightedSequence

    --- [SHARED]
    ---
    --- Check if activity exists.
    ---
    ---@param entity Entity
    ---@param activity integer
    function entity_lib.isActivityExists( entity, activity )
        local sequence_id = Entity_SelectWeightedSequence( entity, activity )
        return sequence_id ~= nil and sequence_id > 0
    end

end

do

    local Entity_LookupAttachment = Entity.LookupAttachment
    local Entity_GetAttachment = Entity.GetAttachment

    --- [SHARED]
    ---
    --- Get attachment ID.
    ---
    ---@param entity Entity
    ---@param attachment_name string
    ---@return integer | nil
    local function getAttachmentID( entity, attachment_name )
        local attachment_id = Entity_LookupAttachment( entity, attachment_name )

        if attachment_id == nil or attachment_id == 0 or attachment_id == -1 then
            return nil
        end

        return attachment_id
    end

    entity_lib.getAttachmentID = getAttachmentID

    --- [SHARED]
    ---
    --- Get attachment by ID.
    ---
    ---@param entity Entity
    ---@param attachment_id integer | nil
    ---@return Vector | nil attachment_origin
    ---@return Angle | nil attachment_angles
    ---@return integer | nil bone_id
    local function getAttachmentByID( entity, attachment_id )
        if attachment_id == nil then
            return nil, nil, nil
        end

        local attachment_data = Entity_GetAttachment( entity, attachment_id )

        if attachment_data == nil then
            return nil, nil, nil
        end

        return attachment_data.Pos, attachment_data.Ang, attachment_data.Bone
    end

    entity_lib.getAttachmentByID = getAttachmentByID

    --- [SHARED]
    ---
    --- Get attachment by name.
    ---
    ---@param entity Entity
    ---@param attachment_name string
    ---@return Vector | nil attachment_origin
    ---@return Angle | nil attachment_angles
    ---@return integer | nil bone_id
    function entity_lib.getAttachmentByName( entity, attachment_name )
        return getAttachmentByID( entity, getAttachmentID( entity, attachment_name ) )
    end

end

do

    local Entity_GetNW2Vector = Entity.GetNW2Vector

    do

        local default_color = Vector( 0.33, 0.33, 0.33 )

        --- [SHARED]
        ---
        --- Get player color.
        ---
        ---@param entity Entity
        ---@return Vector color_vec3
        function Entity.GetPlayerColor( entity )
            return Entity_GetNW2Vector( entity, "m_vPlayerColor", default_color )
        end

        entity_lib.getPlayerColor = Entity.GetPlayerColor

    end

end

local Entity_GetClass = Entity.GetClass

do

    local utils_isRagdollClass = utils.isRagdollClass

    --- [SHARED]
    ---
    --- Check if entity is prop.
    ---
    ---@param entity Entity
    ---@return boolean is_prop
    function entity_lib.isProp( entity )
        return utils_isRagdollClass( Entity_GetClass( entity ) )
    end

end

do

    local utils_isRagdollClass = utils.isRagdollClass

    --- [SHARED]
    ---
    --- Check if entity is ragdoll.
    ---
    ---@param entity Entity
    ---@return boolean is_ragdoll
    function entity_lib.isRagdoll( entity )
        return utils_isRagdollClass( Entity_GetClass( entity ) )
    end

end

entity_lib.isPlayer = Entity.IsPlayer

return entity_lib
