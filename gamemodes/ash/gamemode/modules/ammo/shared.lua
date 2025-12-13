local Player_GetAmmoCount = Player.GetAmmoCount
local Player_SetAmmo = Player.SetAmmo

local game_AddAmmoType = game.AddAmmoType
local game_GetAmmoName = game.GetAmmoName
local game_GetAmmoData = game.GetAmmoData
local game_GetAmmoMax = game.GetAmmoMax
local game_GetAmmoID = game.GetAmmoID

local math_min, math_max = math.min, math.max
local math_clamp = math.clamp

local bit_band = bit.band
local bit_bor = bit.bor

local isnumber = isnumber
local hook_Run = hook.Run

---@class ash.ammo
local ash_ammo = {}

---@class ash.ammo.Data.WaterSplash
---@field [1] number | nil The minimum water splash size.
---@field [2] number | nil The maximum water splash size.

---@class ash.ammo.Data
---@field damage_override boolean | nil Ammo will overwrite the damage of the fired bullet, `true` by default.
---@field damage_amount number | nil The damage dealt to players and NPCs.
---@field damage_force number | nil The force of the ammo damage.
---@field damage_type DMG | integer | nil Damage type using DMG enum.
---@field tracer TRACER | nil Tracer type using TRACER enum.
---@field limit integer | nil Maximum amount of ammo of this type the player should be able to carry in reserve. -2 makes this ammo type infinite.
---@field water_splash integer | ash.ammo.Data.WaterSplash | nil The size of the water splash created by this ammo.
---@field forceful boolean | nil Using this causes the player to drop the item they are carrying if hits by this ammo.

--- [SHARED]
---
--- Checks if an ammo type exists.
---
---@param ammo_id integer The ID of the ammo.
---@return boolean is_exists True if the ammo exists.
function ash_ammo.exists( ammo_id )
    return game_GetAmmoData( ammo_id ) ~= nil
end

--- [SHARED]
---
--- Returns the parameters of an ammo type.
---
---@param ammo_id integer The ID of the ammo.
---@return string | nil name The name of the ammo.
---@return ash.ammo.Data | nil ammo The parameters of the ammo.
function ash_ammo.get( ammo_id )
    local data = game_GetAmmoData( ammo_id )
    if data ~= nil then
        local min_water_splash, max_water_splash = data.minsplash, data.maxsplash
        local flags = data.flags

        local water_splash
        if min_water_splash == max_water_splash then
            water_splash = min_water_splash
        else
            water_splash = { min_water_splash, max_water_splash }
        end

        return data.name, {
            damage_override = bit_band( flags, 2 ) ~= 0,
            damage_amount = data.plydmg,
            damage_force = data.force,
            damage_type = data.dmgtype,
            tracer = data.tracer,
            limit = data.maxcarry,
            water_splash = water_splash,
            forceful = bit_band( flags, 1 ) ~= 0
        }
    end
end

--- [SHARED]
---
--- Registers a new ammo type.
---
---@param name string Name of the ammo.
---@param params ash.ammo.Data The parameters of the ammo.
---@return integer ammo_id The ID of the new ammo.
function ash_ammo.register( name, params )
    local damage_amount = params.damage_amount or 10
    local damage_force = params.damage_force or 100
    local damage_type = params.damage_type or 2

    if bit_band( damage_type, 2 ) == 0 then
        damage_type = bit_bor( damage_type, 2 )
    end

    local limit = params.limit or 256
    local tracer = params.tracer

    local min_water_splash, max_water_splash = 0, 0
    local water_splash = params.water_splash

    if water_splash ~= nil then
        if isnumber( water_splash ) then
            ---@cast water_splash number
            min_water_splash, max_water_splash = water_splash, water_splash
        else
            ---@cast water_splash ash.ammo.Data.WaterSplash
            min_water_splash, max_water_splash = water_splash[ 1 ] or 0, water_splash[ 2 ] or 0
        end
    end

    local flags = 0

    if params.forceful == true then
        flags = bit_bor( flags, 1 )
    end

    if params.damage_override ~= false then
        flags = bit_bor( flags, 2 )
    end

    game_AddAmmoType( {
        name = name,
        dmgtype = damage_type,
        force = damage_force,
        minsplash = min_water_splash,
        maxsplash = max_water_splash,
        plydmg = damage_amount,
        npcdmg = damage_amount,
        tracer = tracer,
        maxcarry = limit,
        flags = flags
    } )

    return game_GetAmmoID( name )
end

--- [SHARED]
---
--- Returns the ID of an ammo type.
---
---@param ammo_name string The name of the ammo.
---@return integer | nil ammo_id The ID of the ammo.
function ash_ammo.getID( ammo_name )
    local ammo_id = game_GetAmmoID( ammo_name )
    if ammo_id > 0 then
        return ammo_id
    end

    return nil
end

do

    local game_GetAmmoName = game.GetAmmoName

    --- [SHARED]
    ---
    --- Returns the name of an ammo type.
    ---
    ---@param ammo_id integer The ID of the ammo.
    ---@return string | nil name The name of the ammo.
    function ash_ammo.getName( ammo_id )
        return game_GetAmmoName( ammo_id )
    end

end

ash_ammo.getDamage = game.GetAmmoPlayerDamage

--- [SHARED]
---
--- Sets the damage of an ammo type.
---
---@param ammo_id integer The ID of the ammo.
---@param damage_amount number The damage dealt to players and NPCs.
function ash_ammo.setDamage( ammo_id, damage_amount )
    local name, data = ash_ammo.get( ammo_id )
    if name ~= nil then
        ---@cast data ash.ammo.Data
        data.damage_amount = damage_amount
        ash_ammo.register( name, data )
    end
end

ash_ammo.getDamageForce = game.GetAmmoForce

--- [SHARED]
---
--- Sets the force of an ammo type.
---
---@param ammo_id integer The ID of the ammo.
---@param damage_force number The force dealt to players and NPCs.
function ash_ammo.setDamageForce( ammo_id, damage_force )
    local name, data = ash_ammo.get( ammo_id )
    if name ~= nil then
        ---@cast data ash.ammo.Data
        data.damage_force = damage_force
        ash_ammo.register( name, data )
    end
end

ash_ammo.getDamageType = game.GetAmmoDamageType

--- [SHARED]
---
--- Sets the damage type of an ammo type.
---
---@param ammo_id integer The ID of the ammo.
---@param damage_type DMG | integer The damage type.
function ash_ammo.setDamageType( ammo_id, damage_type )
    local name, data = ash_ammo.get( ammo_id )
    if name ~= nil then
        ---@cast data ash.ammo.Data
        data.damage_type = damage_type
        ash_ammo.register( name, data )
    end
end

--- [SHARED]
---
--- Returns the names and count of all registered ammo types.
---
---@return string[] ammo_names
---@return integer ammo_count
function ash_ammo.getNames()
    local ammo_names, ammo_count = {}, 0

    ::ammo_reader_loop::
    ammo_count = ammo_count + 1

    local ammo_name = game_GetAmmoName( ammo_count )
    if ammo_name ~= nil then
        ammo_names[ ammo_count ] = ammo_name
        goto ammo_reader_loop
    end

    return ammo_names, ammo_count - 1
end

--- [SHARED]
---
--- Returns the IDs and count of all registered ammo types.
---
---@return table<string, integer> ammo_ids
---@return integer ammo_count
function ash_ammo.getIDs()
    local ammo_ids, ammo_count = {}, 0

    ::ammo_reader_loop::
    ammo_count = ammo_count + 1

    local ammo_name = game_GetAmmoName( ammo_count )
    if ammo_name ~= nil then
        ammo_ids[ ammo_name ] = ammo_count
        goto ammo_reader_loop
    end

    return ammo_ids, ammo_count - 1
end

--- [SHARED]
---
--- Returns the maximum capacity of an ammo type.
---
---@param pl Player
---@param ammo_id integer
---@return integer max_count
local function getLimit( pl, ammo_id )
    return hook_Run( "PlayerAmmoLimit", pl, ammo_id ) or game_GetAmmoMax( ammo_id )
end

ash_ammo.getTotalCapacity = getLimit

--- [SHARED]
---
--- Sets the maximum capacity of an ammo type.
---
---@param ammo_id integer
---@param limit integer
function ash_ammo.setTotalCapacity( ammo_id, limit )
    local name, data = ash_ammo.get( ammo_id )
    if name ~= nil then
        ---@cast data ash.ammo.Data
        data.limit = limit

        ash_ammo.register( name, data )
    end
end

ash_ammo.getCount = Player_GetAmmoCount
ash_ammo.getCountAll = Player.GetAmmo

--- [SHARED]
---
--- Returns the remaining capacity of an ammo type.
---
---@param pl Player
---@param ammo_id integer
---@return integer count
local function getRemainingCapacity( pl, ammo_id )
    return math_max( 0, getLimit( pl, ammo_id ) - Player_GetAmmoCount( pl, ammo_id ) )
end

ash_ammo.getRemainingCapacity = getRemainingCapacity

if SERVER then

    --- [SERVER]
    ---
    --- Sets the count of an ammo type.
    ---
    ---@param pl Player
    ---@param ammo_id integer
    ---@param count integer
    local function setCount( pl, ammo_id, count )
        Player_SetAmmo( pl, math_clamp( count, 0, getLimit( pl, ammo_id ) ), ammo_id )
    end

    ash_ammo.setCount = setCount

    --- [SERVER]
    ---
    --- Gives the player ammo.
    ---
    ---@param pl Player
    ---@param ammo_id integer
    ---@param count integer
    local function give( pl, ammo_id, count )
        setCount( pl, ammo_id, Player_GetAmmoCount( pl, ammo_id ) + count )
    end

    ash_ammo.give = give

    --- [SERVER]
    ---
    --- Takes the player ammo.
    ---
    ---@param pl Player
    ---@param ammo_id integer
    ---@param count integer
    local function take( pl, ammo_id, count )
        setCount( pl, ammo_id, Player_GetAmmoCount( pl, ammo_id ) - count )
    end

    ash_ammo.take = take
    ash_ammo.takeAll = Player.RemoveAllAmmo

    do

        local ammos = {
            item_ammo_pistol = game_GetAmmoID( "Pistol" ),
            item_ammo_smg1 = game_GetAmmoID( "SMG1" ),
            item_box_buckshot = game_GetAmmoID( "Buckshot" ),
            item_ammo_smg1_grenade = game_GetAmmoID( "SMG1_Grenade" ),
            item_rpg_round = game_GetAmmoID( "RPG_Round" ),
            item_ammo_crossbow = game_GetAmmoID( "XBowBolt" ),
            item_ammo_ar2_altfire = game_GetAmmoID( "AR2AltFire" ),
            item_ammo_357 = game_GetAmmoID( "357" ),
            item_ammo_ar2 = game_GetAmmoID( "AR2" )
        }

        ammos.item_ammo_pistol_large = ammos.item_ammo_pistol
        ammos.item_ammo_smg1_large = ammos.item_ammo_smg1
        ammos.item_ammo_357_large = ammos.item_ammo_357
        ammos.item_ammo_ar2_large = ammos.item_ammo_ar2

        for ammo_name, ammo_id in pairs( ammos ) do
            if ammo_id == -1 then
                ammos[ ammo_name ] = nil
            end
        end

        hook.Add( "PlayerCanPickupItem", "HL2Fix", function( pl, entity )
            local ammo_id = ammos[ entity:GetClass() ]
            if ammo_id ~= nil and Player_GetAmmoCount( pl, ammo_id ) >= getLimit( pl, ammo_id ) then
                return false
            end
        end )

    end

    do

        local grenade_id = game_GetAmmoID( "Grenade" )

        hook.Add( "PlayerAmmoChanged", "HL2Fix", function( pl, ammo_id, _, count )
            if ammo_id == grenade_id then
                setCount( pl, grenade_id, math_min( count, getLimit( pl, grenade_id ) ) )
            end
        end )

    end

end

return ash_ammo
