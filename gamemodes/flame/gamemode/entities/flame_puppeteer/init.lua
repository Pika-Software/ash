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

    self:SetOwner( pl )

    self:SetPos( origin )
    self:SetAngles( angles )

    -- local mins, maxs = Vector( -16, -16, 0 ), Vector( 16, 16, 72 )
    local mins, maxs = pl:GetCollisionBounds()

    local wide = math.abs( maxs[ 1 ] - mins[ 1 ] )
    local deep = math.abs( maxs[ 2 ] - mins[ 2 ] )
    local tall = math.abs( maxs[ 3 ] - mins[ 3 ] )

    local width = math.max( wide, deep ) * 0.5
    tall = tall * 0.8

    print( width, tall )

    self:SetSolid( SOLID_VPHYSICS )
    self:PhysicsFromMesh( ENT:GenerateCapsuleMesh( width, tall ), "flesh", vector_origin )
    self:SetMoveType( MOVETYPE_VPHYSICS )

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:SetMass( 100 )
        phys:Wake()
    end

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
local trace_down = Vector( 0, 0, -128 )

---@type table<Entity, number>
local tick_times = {}

---@param phys PhysObj
---@param gravity Vector
local function KeepUpright( phys, gravity )
    local gravity_strength = gravity:Length()
    gravity:Normalize()

    -- local up = -gravity:GetNormalized()

    -- local angVel = phys:GetAngleVelocity()

    -- -- keep ONLY rotation around gravity axis
    -- local gravitySpin = up * angVel:Dot( up )

    -- -- remove everything else (this is what causes rolling/pitch spin)
    -- phys:AddAngleVelocity( -(angVel - gravitySpin) * 0.5 )
end


local function CapsuleMove( phys, dir, speed, gravity )
    local up = -gravity:GetNormalized()

    local vel = phys:GetVelocity()

    local flatVel = vel - up * vel:Dot( up )
    local flatDir = dir - up * dir:Dot( up )

    if flatDir:LengthSqr() > 0.001 then
        flatDir:Normalize()
    end

    local delta = flatDir * speed - flatVel

    phys:AddVelocity( delta * 0.2 )
end

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

        -- puppet:SetCollisionGroup( COLLISION_GROUP_WEAPON )


        puppet:SetOwner( pl )
        puppet:SetPhysicsAttacker( pl )

        pl:SetViewEntity( puppet )



        constraint.NoCollide( self, puppet, 0, 0 )

        ash_entity.setPlayerColor( puppet, ash_entity.getPlayerColor( self ) )
    end

    trace_filter[ 1 ] = self
    trace_filter[ 2 ] = pl
    trace_filter[ 3 ] = puppet

    local puppet_position = puppet:WorldSpaceCenter()

    trace.start = puppet_position
    trace.endpos = puppet_position + trace_down

    util.TraceLine( trace )

    if not trace_result.Hit then return end

    local view_angles = ash_player.getViewAngles( pl )
    view_angles[ 1 ] = 0


    local trace_position = trace_result.HitPos

    local puppeteer_phys = self:GetPhysicsObject()
    if puppeteer_phys ~= nil and puppeteer_phys:IsValid() then

        if puppeteer_phys:IsAsleep() then
            puppeteer_phys:Wake()
        end

        local keys = ash_player.getKeys( pl )

        local player_speed = 0

        local water_level = ash_entity.getWaterLevel( pl )
        if ash_player.isOnGround( pl ) then
            player_speed = hook.Run( "ash.player.WalkSpeed", pl, keys, ash_player.isCrouching( pl ), water_level ) or 200
        elseif water_level == 0 then
            player_speed = hook.Run( "ash.player.FallSpeed", pl, keys, ash_player.isCrouching( pl ) ) or 10
        else
            player_speed = hook.Run( "ash.player.SwimSpeed", pl, keys, water_level ) or 150
        end

        -- shadow_control.pos = self:GetPos() + dir * player_speed * 0.1

        -- if bit.band( keys, IN_JUMP ) ~= 0 then
        --     puppeteer_phys:AddVelocity( vector_up * pl:GetJumpPower() * 0.15 )
        -- end

        shadow_control.pos = self:GetPos() + ash_player.getDirection( pl ) * player_speed * 0.1
        shadow_control.angle = angle_zero

        puppeteer_phys:ComputeShadowControl( shadow_control )

        -- CapsuleMove(
        --     puppeteer_phys,
        --     ash_player.getDirection( pl ),
        --     player_speed,
        --     physenv.GetGravity()
        -- )

        -- KeepUpright(
        --     puppeteer_phys,
        --     physenv.GetGravity()
        -- )
    end

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

--     local p = Player( 10 )
--     if p == nil or not p:IsValid() then return end

--     ---@type flame_puppeteer
--     local e = ents.Create( "flame_puppeteer" )
--     e:Spawn()
--     e:Setup( p )

--     e:SetPos( p:GetPos() + Vector( 20, 0, 100 ) )

-- end )

-- hook.Add( "FinishMove", "flame_puppeteer_finish_move", function( pl, mv )
--     if pl:GetViewEntity() ~= pl then return true end

-- end )

-- hook.Add( "EntityTakeDamage", "flame_puppeteer_damage", function( ent, dmginfo )
--     if ent:GetClass() ~= "flame_puppeteer" then return true end

-- end )
