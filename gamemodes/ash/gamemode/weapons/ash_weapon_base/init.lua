MODULE.ClientFiles = {
    "cl_init.lua",
}
MODULE.Networks = {
    "primary_fire",
    "bullet_effect",
}

---@class ash_weapon_base: SWEP
local SWEP = SWEP


local developer = GetConVar("developer")

assert(developer ~= nil, "developer convar not found")

---@type ash.trace
local ash_trace = import "ash.trace"
local trace_cast = ash_trace.cast

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result = {}

---@type ash.trace.Params
local trace = {
    output = trace_result
}

include( "shared.lua" )

hook.Add( "PlayerAmmoChanged", "Defaults", function( pl, ammotype, old, new )
    local wep = pl:GetActiveWeapon()

    ---@cast wep ash_weapon_base

    if not (wep ~= nil and wep:IsValid() and wep.IsAshWeapon) then
        return
    end

    if ammotype ~= wep:GetPrimaryAmmoType() then
        return
    end

    if new <= old then
        return
    end

    if wep:Clip1() <= 0 and wep:GetMaxClip1() > 0 then
        wep:Reload()
    end
end)

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result_size = {}

---@type ash.trace.Params
local trace_size = {
    output = trace_result_size
}

local dist_limit = 65536
local Vector_Distance = Vector.Distance


net.Receive("primary_fire", function(_, pl)
    local count = net.ReadUInt( 5 )
    local dir = Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
    local weapon = pl:GetActiveWeapon()

    ---@cast weapon ash_weapon_base

    if not (weapon ~= nil and weapon:IsValid() and weapon.IsFrontfireWeapon) then
        return
    end

    if weapon:Clip1() > 0 then
        weapon:TakePrimaryAmmo(1)
    end

    if weapon:Clip1() <= 0 and weapon:canReload() then
        weapon:Reload()
    end

    local primary_data = weapon.Primary

    local start_pos_first

    ---@type table<Entity, boolean>
    local damaged_entities = {}
    for i = 1, count do
        local start_pos = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
        local hit_pos = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
        local entity = net.ReadEntity()
        local hit_group = net.ReadUInt(5)

        if start_pos_first == nil then
            start_pos_first = start_pos
        end

        trace.start = start_pos
        trace.endpos = start_pos + dir * dist_limit
        trace.filter = pl
        trace.mask = MASK_SHOT

        trace_cast(trace)

        if trace_result.Hit then
            local ht_pos = trace_result.HitPos
            local normal = trace_result.HitNormal or vector_origin

            net.Start("bullet_effect")
            net.WriteDouble(ht_pos.x)
            net.WriteDouble(ht_pos.y)
            net.WriteDouble(ht_pos.z)
            net.WriteDouble(normal.x)
            net.WriteDouble(normal.y)
            net.WriteDouble(normal.z)
            net.WriteUInt(trace_result.SurfaceProps, 8)
            net.SendOmit(pl)
        end

        if entity ~= nil then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage( weapon:calculateDamageDistance( Vector_Distance( start_pos_first, hit_pos ), primary_data.DistanceMax, primary_data.DistanceMin, weapon:getPrimaryDamage(), weapon:getPrimaryDamageMin() ) )
            dmginfo:SetReportedPosition(start_pos)
            dmginfo:SetDamagePosition(hit_pos)
            dmginfo:SetAttacker(pl)
            dmginfo:SetInflictor(weapon)
            dmginfo:SetDamageType(DMG_BULLET)

            dmginfo:ScaleDamage( weapon:getHitgroupScale( hit_group ) )

            local target = trace_result.Entity

            if entity:IsValid() and entity:IsPlayer() or entity:IsNPC() then
                if not damaged_entities[entity] then
                    entity:TakeDamageInfo(dmginfo)
                end
            else
                if target ~= nil and target:IsValid() and not damaged_entities[target] and not (target:IsPlayer() or target:IsNPC()) then
                    target:DispatchTraceAttack( dmginfo, trace_result )
                end
            end

            if target ~= nil and target:IsValid() then
                if not damaged_entities[target] then
                    damaged_entities[target] = true
                end
            end

            if not damaged_entities[entity] then
                damaged_entities[entity] = true
            end

            if developer:GetBool() then
                net.Start("primary_fire")
                net.WriteVector(start_pos)
                net.WriteVector(hit_pos)
                net.Send( pl )
            end
        end
    end
end)
