---@class ash.entity
local entity_lib = include( "shared.lua" )

---@type dreamwork.std
local std = _G.dreamwork.std
local math = std.math

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

do

    local Entity_IsValid = Entity.IsValid
    local Entity_SetName = Entity.SetName
    local Entity_GetName = Entity.GetName
    local Entity_Fire = Entity.Fire

    local string_format = string.format
    local timer_Simple = timer.Simple
    local math_isint = math.isint
    local uuid_v7 = std.uuid.v7
    local tostring = tostring

    local isBoolean = std.isBoolean
    local isNumber = std.isNumber
    local isColor = std.isColor
    local isentity = isentity
    local isvector = isvector
    local isangle = isangle
    local IsColor = IsColor

    --- [SERVER]
    ---
    --- Send input to entity.
    ---
    ---@param entity Entity
    ---@param key string
    ---@param value any | nil
    ---@param delay number | nil
    ---@param activator Entity | nil
    ---@param caller Entity | nil
    function entity_lib.sendInput( entity, key, value, delay, activator, caller )
        if isentity( value ) then
            if not Entity_IsValid( entity ) then
                error( "entity is not valid", 2 )
            end

            local name, temp_name = Entity_GetName( value ), uuid_v7()
            Entity_SetName( value, temp_name )

            timer_Simple( 0, function()
                if Entity_IsValid( entity ) then
                    Entity_Fire( entity, key, temp_name, delay, activator, caller )
                    Entity_SetName( value, name or "" )
                end
            end )

            return
        end

        if isNumber( value ) then
            if math_isint( value ) then
                value = string_format( "%d", value )
            else
                value = string_format( "%f", value )
            end
        elseif IsColor( value ) or isColor( value ) then
            value = string_format( "%d %d %d %d", value.r, value.g, value.b, value.a )
        elseif isvector( value ) or isangle( value ) then
            value = string_format( "%f %f %f", value[ 1 ], value[ 2 ], value[ 3 ] )
        elseif isBoolean( value ) then
            value = value and "1" or "0"
        else
            value = tostring( value )
        end

        Entity_Fire( entity, key, value, delay, activator, caller )
    end

end

return entity_lib
