MODULE.ClientFiles = {
    "shared.lua"
}

include( "shared.lua" )

local Vector_SetUnpacked = Vector.SetUnpacked
local Vector_Unpack = Vector.Unpack

local Vector_Add = Vector.Add

local Angle_SetUnpacked = Angle.SetUnpacked
local Angle_Unpack = Angle.Unpack


---@type ash.entity
local ash_entity = import "ash.entity"

---@type ash.player
local ash_player = import "ash.player"

---@class flame_puppeteer : ENT
local ENT = ENT

ENT.AutomaticFrameAdvance = true

---@type table<Player, flame_puppeteer>
local puppeters = {}

local shadow_control = {
    secondstoarrive  = 0.1,
    maxangular       = 1000000,
    maxangulardamp   = 1000000,
    maxspeed         = 1000000,
    maxspeeddamp     = 1000000,
    dampfactor       = 0.8,
    teleportdistance = 64,
}

-- shadow_control.deltatime = FrameTime()

---@diagnostic disable-next-line: duplicate-set-field
function ENT:Initialize()
    self:DrawShadow( false )
    -- self:SetNoDraw( true )
end

---@param pl Player
function ENT:Setup( pl )
    local puppet = self:GetPuppet()
    if puppet:IsValid() then
        puppet:Remove()
    end

    local origin = pl:GetPos()
    local angles = pl:GetRenderAngles()

    puppeters[ pl ] = self
    self:SetOwner( pl )

    self:SetPos( origin )
    self:SetAngles( angles )

    -- -- local mins, maxs = pl:GetCollisionBounds()
    -- local mins, maxs = Vector( -16, -16, 0 ), Vector( 16, 16, 72 )
    -- self:PhysicsInitBox( mins, maxs, "flesh" )

    -- self:PhysWake()

    ash_entity.setPlayerColor( self, ash_entity.getPlayerColor( pl ) )
end

---@type TraceResult
local trace_result = {}

---@type Entity[]
local trace_filter = {}

---@type Trace
local trace = {
    mask = MASK_PLAYERSOLID,
    filter = trace_filter,
    output = trace_result,
}

local force_buffer = Vector( 0, 0, 0 )
local trace_down = Vector( 0, 0, -72 )

---@type table<Entity, number>
local tick_times = {}

function ENT:Think()
    local pl = self:GetOwner()
    if pl == nil or not pl:IsValid() then return end

    ---@cast pl Player

    local model_path = pl:GetModel()

    local puppet = self:GetPuppet()
    if not puppet:IsValid() or self:GetModel() ~= model_path then
        ---@diagnostic disable-next-line: param-type-mismatch
        self:SetModel( model_path )

        puppet = ents.Create( "prop_ragdoll" )

        self:SetPuppet( puppet )
        -- self:SetParent( puppet )

        ---@diagnostic disable-next-line: param-type-mismatch
        puppet:SetModel( model_path )

        puppet:SetPos( self:GetPos() )
        puppet:SetAngles( self:GetAngles() )
        puppet:Spawn()

        puppet:SetCollisionGroup( COLLISION_GROUP_WEAPON )

        puppet:SetOwner( pl )
        puppet:SetPhysicsAttacker( pl )
        constraint.NoCollide( self, puppet, 0, 0 )
        ash_entity.setPlayerColor( puppet, ash_entity.getPlayerColor( self ) )
    end

    Vector_SetUnpacked( force_buffer, 0, 0, 0 )

    trace_filter[ 1 ] = self
    trace_filter[ 2 ] = pl
    trace_filter[ 3 ] = puppet

    local puppet_position = puppet:WorldSpaceCenter()

    trace.start = puppet_position
    trace.endpos = puppet_position + trace_down

    util.TraceLine( trace )

    if not trace_result.Hit then return end

    local trace_position = trace_result.HitPos

    local view_angles = ash_player.getViewAngles( pl )
    view_angles[ 1 ] = 0

    for phys_id = 0, puppet:GetPhysicsObjectCount() - 1, 1 do
        local puppet_phys = puppet:GetPhysicsObjectNum( phys_id )
        if puppet_phys ~= nil and puppet_phys:IsValid() then
            local bone_id = puppet:TranslatePhysBoneToBone( phys_id )

            local origin, angles

            local matrix = pl:GetBoneMatrix( bone_id )
            if matrix == nil then
                origin, angles = pl:GetBonePosition( bone_id )
            else
                origin = matrix:GetTranslation()
                angles = matrix:GetAngles()
            end

            local local_origin, local_angles = WorldToLocal( origin, angles, pl:GetPos(), pl:GetRenderAngles() )
            shadow_control.pos, shadow_control.angle = LocalToWorld( local_origin, local_angles, self:GetPos(), view_angles )

            -- shadow_control.pos = shadow_control.pos + Vector( 0, 0, 30 )

            if puppet_phys:IsAsleep() then
                puppet_phys:Wake()
            end

            puppet_phys:ComputeShadowControl( shadow_control )
        end
    end

    -- local act, seq = hook.Run( "CalcMainActivity", pl, puppet:GetVelocity() )

    -- if act ~= nil then
    --     seq = self:SelectWeightedSequence( pl:TranslateWeaponActivity( act ) )
    -- end

    -- if seq ~= nil and self:GetSequence() ~= seq then
    --     self:ResetSequence( seq )
    -- end

    -- self:SetPlaybackRate( pl:GetPlaybackRate() )

    -- for i = 0, ash_entity.getPoseParameterCount( pl ) - 1 do
    --     ash_entity.setPoseParameter( self, ash_entity.getPoseParameterName( pl, i ), ash_entity.getPoseParameter( pl, i ), false )
    -- end

    -- if self:GetCycle() == 1 then
    --     self:SetCycle( 0 )
    -- end

    local cur_time = CurTime()

    self:NextThink( cur_time )
    self:FrameAdvance()

    shadow_control.deltatime = cur_time - (tick_times[ self ] or cur_time)
    tick_times[ self ] = cur_time

    return true
end

-- timer.Simple( 0, function()

--     game.CleanUpMap()

--     local p = Player( 15 )
--     if p == nil or not p:IsValid() then return end

--     ---@type flame_puppeteer
--     local e = ents.Create( "flame_puppeteer" )
--     e:Spawn()
--     e:Setup( p )

-- end )

-- hook.Add( "EntityTakeDamage", "flame_puppeteer_damage", function( ent, dmginfo )
--     if ent:GetClass() ~= "flame_puppeteer" then return true end

-- end )
