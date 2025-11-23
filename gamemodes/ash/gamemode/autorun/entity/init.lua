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


return entity_lib
