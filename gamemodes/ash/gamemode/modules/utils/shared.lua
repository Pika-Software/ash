local util = util

--- [SHARED]
---
--- ash Utils Library (FFUL)
---
---@class ash.utils
local utils = {}
ash.utils = utils

do

    local prop_class_names = list.GetForEdit( "ash.prop.classnames" )

    prop_class_names.prop_physics_multiplayer = true
	prop_class_names.prop_physics_override = true
	prop_class_names.prop_dynamic_override = true
	prop_class_names.prop_dynamic = true
	prop_class_names.prop_ragdoll = true
	prop_class_names.prop_physics = true
	prop_class_names.prop_detail = true
	prop_class_names.prop_static = true

    --- [SHARED]
    ---
    --- Checks if the class name is a prop class.
    ---
    ---@param class_name string
    ---@return boolean is_prop
    function utils.isPropClass( class_name )
        return prop_class_names[ class_name ] == true
    end

end

do

    local ragdoll_class_names = list.GetForEdit( "ash.ragdoll.classnames" )

    ragdoll_class_names.prop_ragdoll = true
    ragdoll_class_names.C_ClientRagdoll = true
    ragdoll_class_names.C_HL2MPRagdoll = true
    ragdoll_class_names.hl2mp_ragdoll = true

    --- [SHARED]
    ---
    --- Checks if the class name is a ragdoll class.
    ---
    ---@param class_name string
    ---@return boolean is_ragdoll
    function utils.isRagdollClass( class_name )
        return ragdoll_class_names[ class_name ] == true
    end

end

do

    local button_class_names = list.GetForEdit( "ash.button.classnames" )

    button_class_names.func_button = true

    --- [SHARED]
    ---
    --- Checks if the class name is a button class.
    ---
    ---@param class_name string
    ---@return boolean is_button
    function utils.isButtonClass( class_name )
        return button_class_names[ class_name ] == true
    end

end

do

    local util_TraceLine = util.TraceLine

    local trace_result = {}

    local trace = {
        collisiongroup = _G.COLLISION_GROUP_WORLD,
        output = trace_result
    }

    --- [SHARED]
    ---
    --- Checks if a position is inside the level bounds (inside the world).
    ---
    ---@param origin Vector
    ---@return boolean
    utils.isInLevelBounds = util.IsInWorld or function( origin )
        trace.start = origin
        trace.endpos = origin

        util_TraceLine( trace )
        return not trace_result.HitWorld
    end

end

return utils
