MODULE.ClientFiles = {
    "shared.lua"
}

---@class ash.entity
local entity_lib = include( "shared.lua" )

do

    local Entity_SetNW2Vector = Entity.SetNW2Vector

    --- [SERVER]
    ---
    --- Sets color for `player_color` matproxy.
    ---
    ---@param entity Entity
    ---@param color Color
    function entity_lib.setPlayerColor( entity, color )
        Entity_SetNW2Vector( entity, "m_vPlayerColor", Vector( color.r / 255, color.g / 255, color.b / 255 ) )
    end

end

---@type ash.utils
local utils_lib = require( "ash.utils" )

local utils_isPropClass = utils_lib.isPropClass
local utils_isButtonClass = utils_lib.isButtonClass
local utils_isRagdollClass = utils_lib.isRagdollClass

local hook_Run = hook.Run

local Entity_GetClass = Entity.GetClass
local Entity_SetNW2Bool = Entity.SetNW2Bool

hook.Add( "OnEntityCreated", "Scanner", function( entity )
    hook_Run( "PreEntityCreated", entity )
    hook_Run( "EntityCreated", entity )

    local class_name = Entity_GetClass( entity )

    if class_name == "player" then
		hook_Run( "PlayerCreated", entity )
    elseif utils_isPropClass( class_name ) then
        hook_Run( "PropCreated", entity )
    elseif utils_isButtonClass( class_name ) then
        Entity_SetNW2Bool( entity, "m_bButton", true )
        hook_Run( "ButtonCreated", entity )
    elseif utils_isRagdollClass( class_name ) then
        hook_Run( "RagdollCreated", entity )
    elseif entity:IsWeapon() then
        hook_Run( "WeaponCreated", entity )
    end

    hook_Run( "PostEntityCreated", entity )

    ---@diagnostic disable-next-line: redundant-parameter, undefined-global
end, PRE_HOOK )


return entity_lib
