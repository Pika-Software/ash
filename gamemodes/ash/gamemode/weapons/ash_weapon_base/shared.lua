local math_approach = math.approach
local math_max = math.max
local math_min = math.min
local SharedRandom = util.SharedRandom

---@class ash_weapon_base.FireModes : table
---@field name? string
---@field delay? number
---@field burst_count? number
---@field type? "single" | "burst" | "auto"
---@field burstDelay? number
---@field spreadAdded? Vector
---@field spreadMult? Vector

---@class ash_weapon_base: SWEP
---@field setKickReset fun( self: self, float: number )
---@field getKickReset fun( self: self ): number
---@field setKickX fun( self: self, float: number )
---@field getKickX fun( self: self ): number
---@field setKickY fun( self: self, float: number )
---@field getKickY fun( self: self ): number
---@field setKickZ fun( self: self, float: number )
---@field getKickZ fun( self: self ): number
---@field setKickCurX fun( self: self, float: number )
---@field getKickCurX fun( self: self ): number
---@field setKickCurY fun( self: self, float: number )
---@field getKickCurY fun( self: self ): number
---@field setKickCurZ fun( self: self, float: number )
---@field getKickCurZ fun( self: self ): number
---@field setShoot fun( self: self, float: number )
---@field GetShoot fun( self: self ): number
---@field setBufferedClick fun( self: self, bool: boolean )
---@field getBufferedClick fun( self: self ): boolean
---@field setInReload fun( self: self, bool: boolean )
---@field getInReload fun( self: self ): boolean
---@field SetReloadTime fun( self: self, float: number )
---@field GetReloadTime fun( self: self ): number
---@field setReloadDelay fun( self: self, float: number )
---@field getReloadDelay fun( self: self ): number
---@field SetIdleTime fun( self: self, float: number )
---@field GetIdleTime fun( self: self ): number
---@field setSilencer fun( self: self, bool: boolean )
---@field getSilencer fun( self: self ): boolean
---@field setSilencerTime fun( self: self, float: number )
---@field getSilencerTime fun( self: self ): number
---@field setIsAutomatic fun( self: self, bool: boolean )
---@field getIsAutomatic fun( self: self ): boolean
---@field setShootReset fun( self: self, float: number )
---@field getShootReset fun( self: self ): number
---@field setBurstCount fun( self: self, int: number )
---@field getBurstCount fun( self: self ): number
---@field setBurstCountCur fun( self: self, int: number )
---@field getBurstCountCur fun( self: self ): number
---@field setBurstTime fun( self: self, float: number )
---@field getBurstTime fun( self: self ): number
---@field setIsBurstFire fun( self: self, bool: boolean )
---@field getIsBurstFire fun( self: self ): boolean
---@field setInSight fun( self: self, bool: boolean )
---@field getInSight fun( self: self ): boolean
---@field setRecoverSight fun( self: self, float: number )
---@field getRecoverSight fun( self: self ): number
---@field setSightState fun( self: self, int: number )
---@field getSightState fun( self: self ): number
---@field setLeftGun fun( self: self, bool: boolean )
---@field getLeftGun fun( self: self ): boolean
---@field setFireMode fun( self: self, int: number )
---@field getFireMode fun( self: self ): number
---@field setRateOfFire fun( self: self, float: number )
---@field getRateOfFire fun( self: self ): number
---@field setNextBurstDelay fun( self: self, float: number )
---@field getNextBurstDelay fun( self: self ): number
---@field setSpreadAdded fun( self: self, vector: Vector )
---@field getSpreadAdded fun( self: self ): Vector
---@field setSpreadMult fun( self: self, vector: Vector )
---@field getSpreadMult fun( self: self ): Vector
---@field setReloadManualTime fun( self: self, float: number )
---@field getReloadManualTime fun( self: self ): number
---@field setDelayAnim fun( self: self, float: number )
---@field getDelayAnim fun( self: self ): number
---@field setManualReloadingStart fun( self: self, bool: boolean )
---@field getManualReloadingStart fun( self: self ): boolean
---@field setIsRecover fun( self: self, bool: boolean )
---@field getIsRecover fun( self: self ): boolean
---@field setIsReady fun( self: self, bool: boolean )
---@field getIsReady fun( self: self ): boolean
---@field setSightProgressTo fun( self: self, float: number )
---@field getSightProgressTo fun( self: self ): number
---@field setSightProgressFrom fun( self: self, float: number )
---@field getSightProgressFrom fun( self: self ): number
---@field setSightProgress fun( self: self, float: number )
---@field getSightProgress fun( self: self ): number
---@field setSightProgressSpeed fun( self: self, float: number )
---@field getSightProgressSpeed fun( self: self ): number
---@field ViewKickList? Angle[]
---@field networks table<string, number>
---@field Spread Vector
---@field Animations? table<string, table<string, number | string>>
---@field SoundSilencer? string
---@field HitgroupScale? table<HITGROUP, number>
---@field FireModes ash_weapon_base.FireModes[]
---@field SpreadSight? Vector
---@field DelayAnim? ACT | string
---@field DelayAnimIsSeq? boolean
local SWEP = SWEP

local Angle_Forward = Angle.Forward
local Player_GetViewPunchAngles = Player.GetViewPunchAngles
local Player_SetViewPunchAngles = Player.SetViewPunchAngles
local Player_EyeAngles = Entity.EyeAngles

SWEP.IsAshWeapon = true

SWEP.ViewModel = Model("models/frontfire/weapons/cstrike/c_rif_ak47.mdl")
SWEP.WorldModel = Model("models/frontfire/weapons/w_rif_ak47.mdl")
SWEP.ViewModelFOV = 70
SWEP.ViewKickMax = Angle( 25, 3, 3 )
SWEP.HoldType = "ar2"
SWEP.IsAkimbo = false
SWEP.UseHands = true
SWEP.ManualReloading = false
SWEP.Chamber = false
SWEP.DrawAmmo = true
SWEP.ReadyAnim = false
SWEP.ReloadEmptyAnim = false
SWEP.PumpAnim = false
SWEP.SightSpeedStandart = 10

SWEP.Primary.Automatic = false
SWEP.Primary.IsAutomatic = false
SWEP.Primary.Magazine = 30
SWEP.Primary.Delay = 0.3
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Damage = 30
SWEP.Primary.DamageMin = 10
SWEP.Primary.DistanceMin = 300
SWEP.Primary.DistanceMax = 1000
SWEP.Primary.ArmorScale = 0.5
SWEP.Primary.CriticalChance = 0
SWEP.Primary.Shaking = false
SWEP.Primary.ShakeAmlitude = 1
SWEP.Primary.ShakeFrequency = 15
SWEP.Primary.ShakeDuration = 0.2

SWEP.Primary.Sound = Sound( "Weapon_M4A1.Single" )

SWEP.Secondary.SightTexture = CLIENT and surface.GetTextureID( "frontfire/scope/scope_cs" )
SWEP.Secondary.SightWScale = 1.3
SWEP.Secondary.SightHScale = 1
SWEP.Secondary.SightColor = color_black
SWEP.Secondary.SightDrawLines = true
SWEP.Secondary.SightSound = Sound("Default.Zoom")
SWEP.Secondary.ViewModelSightPos = Vector( )
SWEP.Secondary.ViewModelSightAng = Angle( )
SWEP.Secondary.SightNoDraw = false
SWEP.Secondary.SightStateZoom = {
    [ 1 ] = 0.4,
    [ 2 ] = 0.2,
}

SWEP.Spread = Vector( 0, 2, 2 )
SWEP.SpreadStart = Vector(0, 1, 1)
SWEP.SpreadMax = Vector( 0, 7, 7 )
SWEP.SpreadMove = Vector(0, 8, 8)
SWEP.SpreadOnAir = Vector( 0, 15, 15 )
SWEP.SpreadNoSight = Vector( 0, 0, 0 )

SWEP.KickSpeed = 20
SWEP.KickRecoverSpeed = 10
SWEP.KickRandomMin = Angle( 0, 0, 0 )
SWEP.KickRandomMax = Angle( 0, 0, 0 )


local defaults_animations = {
    ["draw"] = {
        normal = ACT_VM_DRAW,
        silent = ACT_VM_DRAW_SILENCED,
    },
    ["attack_primary"] = {
        normal = ACT_VM_PRIMARYATTACK,
        silent = ACT_VM_PRIMARYATTACK_SILENCED,
    },
    ["attack_secondary"] = {
        normal = ACT_VM_SECONDARYATTACK,
        silent = ACT_VM_SECONDARYATTACK,
    },
    [ "idle" ] = {
        normal = ACT_VM_IDLE,
        silent = ACT_VM_IDLE_SILENCED,
    },
    [ "reload" ] = {
        normal = ACT_VM_RELOAD,
        silent = ACT_VM_RELOAD_SILENCED,
    },
    [ "reload_empty" ] = {
        normal = ACT_VM_RELOAD_EMPTY,
    },
    [ "reload_manual_start" ] = {
        normal = ACT_SHOTGUN_RELOAD_START,
        silent = ACT_SHOTGUN_RELOAD_START,
    },
    [ "reload_manual" ] = {
        normal = ACT_VM_RELOAD,
        silent = ACT_VM_RELOAD_SILENCED,
    },
    [ "reload_manual_finish" ] = {
        normal = ACT_SHOTGUN_RELOAD_FINISH,
        silent = ACT_SHOTGUN_RELOAD_FINISH,
    },
    [ "ready" ] = {
        normal = ACT_VM_DRAW_DEPLOYED,
    },
    [ "pump" ] = {
        normal = "pump",
    }
}

function SWEP:addNetwork(ntype, name)
    local networks = self.networks or {}
    self.networks = networks

    local types = networks[ ntype ] or 0

    types = types + 1
    networks[ ntype ] = types

    self:NetworkVar( ntype , types - 1, name)

    self[ "get" .. name ] = self[ "Get" .. name ]
    self[ "set" .. name ] = self[ "Set" .. name ]
end

function SWEP:SetupDataTables()
    self:addNetwork("Float", "KickX")
    self:addNetwork("Float", "KickY")
    self:addNetwork("Float", "KickZ")
    self:addNetwork("Float", "KickReset")
    self:addNetwork("Float", "KickCurX")
    self:addNetwork("Float", "KickCurY")
    self:addNetwork("Float", "KickCurZ")
    self:addNetwork("Float", "Spread")
    self:addNetwork("Float", "Shoot")
    self:addNetwork("Float", "ReloadTime")
    self:addNetwork("Float", "ReloadDelay")
    self:addNetwork("Float", "IdleTime")
    self:addNetwork("Float", "SilencerTime")
    self:addNetwork("Float", "ShootReset")
    self:addNetwork("Float", "BurstTime")
    self:addNetwork("Float", "RecoverSight")
    self:addNetwork("Float", "RateOfFire")
    self:addNetwork("Float", "NextBurstDelay")
    self:addNetwork("Float", "ReloadManualTime")
    self:addNetwork("Float", "SightProgress")
    self:addNetwork("Float", "SightProgressTo")
    self:addNetwork("Float", "SightProgressFrom")
    self:addNetwork("Float", "SightProgressSpeed")
    self:addNetwork("Float", "RecoverProgress")
    self:addNetwork("Float", "RecoverProgressTo")
    self:addNetwork("Float", "DelayAnim")

    self:addNetwork("Bool", "BufferedClick")
    self:addNetwork("Bool", "InReload")
    self:addNetwork("Bool", "Silencer")
    self:addNetwork("Bool", "IsAutomatic")
    self:addNetwork("Bool", "IsBurstFire")
    self:addNetwork("Bool", "InSight")
    self:addNetwork("Bool", "LeftGun")
    self:addNetwork("Bool", "ManualReloadingStart")
    self:addNetwork("Bool", "IsReady")
    self:addNetwork("Bool", "IsRecover")

    self:addNetwork("Int", "BurstCount")
    self:addNetwork("Int", "SightState")
    self:addNetwork("Int", "FireMode")
    self:addNetwork("Int", "BurstCountCur")

    self:addNetwork("Vector", "SpreadAdded")
    self:addNetwork("Vector", "SpreadMult")

    self:actionRun("setupDataTables")

    if SERVER then
        self:setKickReset( -1 )
        self:changeFireMode( 1, true )
        self:setSpreadAdded( vector_origin )
        self:setSpreadMult( Vector( 1, 1, 1 ) )
        self:setSightProgressSpeed( self.SightSpeedStandart )
    end
end

---@param mode? number
---@param nomsg? boolean
function SWEP:changeFireMode( mode, nomsg )
    local modes = self.FireModes
    if self.FireModes == nil then
        return
    end

    local next_fire_mode = mode or self:getFireMode() + 1

    if next_fire_mode > #modes then
        next_fire_mode = 1
    end

    local data = modes[ next_fire_mode ]

    self:setFireMode(next_fire_mode)

    if not nomsg then
        local owner = self:GetOwner()
        ---@cast owner Player
        if owner ~= nil and owner:IsValid() then
            owner:PrintMessage(HUD_PRINTCENTER, "Fire mode: " .. data.name)
        end
    end

    if data.type == "burst" then
        self:setBurstCount(data.burst_count or 3)
        self:setIsAutomatic(false)
        self:setIsBurstFire(true)
    elseif data.type == "auto" then
        self:setIsAutomatic(true)
        self:setIsBurstFire(false)
    elseif data.type == "single" then
        self:setIsAutomatic(false)
        self:setIsBurstFire(false)
    end

    if data.burstDelay then
        self:setNextBurstDelay(data.burstDelay)
    else
        self:setNextBurstDelay(0)
    end

    if data.spreadAdded then
        self:setSpreadAdded(data.spreadAdded)
    else
        self:setSpreadAdded(Vector( 0, 0, 0 ))
    end

    if data.spreadMult then
        self:setSpreadMult(data.spreadMult)
    else
        self:setSpreadMult(Vector( 1, 1, 1 ))
    end

    self:setRateOfFire( data.delay or self.Primary.Delay )
end

function SWEP:Think()
    local owner = self:GetOwner()
    local curTime = self:getCurTime()
    local tick = engine.TickInterval()

    ---@cast owner Player
    if not (owner ~= nil and owner:IsValid()) then
        return
    end

    local reset = self:getKickReset()

    -- if reset ~= -1 and curTime >= reset then
    --     self:setKickReset(-1)
    --     -- self:setKickX(0)
    --     -- self:setKickY(0)
    --     -- self:setKickZ(0)
    --     reset = -1
    -- end

    local shot_reset = self:getShootReset()

    if curTime >= shot_reset then
        self:setShoot( math_approach( self:GetShoot(), 0, 30 * tick ) )
    end

    local returning = reset == -1

    local speed = self.KickSpeed

    if returning then
        speed = self.KickRecoverSpeed
    end

    local curX = self:getKickCurX()
    local curY = self:getKickCurY()
    local curZ = self:getKickCurZ()

    local targetX = self:getKickX()
    local targetY = self:getKickY()
    local targetZ = self:getKickZ()

    local x, y, z

    local step = speed * tick

    local isRecover = self:getIsRecover()

    if not isRecover then
        if curX == targetX and curY == targetY and curZ == targetZ then
            self:setIsRecover( true )

            self:setKickX( 0 )
            self:setKickY( 0 )
            self:setKickZ( 0 )
        end
    else
        local recover = self:getRecoverProgress()

        recover = math_approach( recover, self:getRecoverProgressTo(), 30 * tick )

        self:setRecoverProgress( recover )

        step = ( recover ) * tick
    end

    x = math_approach( curX, targetX, step )
    y = math_approach( curY, targetY, step )
    z = math_approach( curZ, targetZ, step )

    self:setKickCurX(x)
    self:setKickCurY(y)
    self:setKickCurZ(z)

    if not self.Primary.Automatic then
        if owner:KeyPressed(IN_ATTACK) and curTime < self:GetNextPrimaryFire() then
            if self:GetNextPrimaryFire() - curTime <= 0.15 then
                self:setBufferedClick(true)
            end
        end

        if self:getBufferedClick() and curTime >= self:GetNextPrimaryFire() then
            self:PrimaryAttack()
            self:setBufferedClick(false)
        end
    end

    local inload = self:getInReload()

    if inload then
        if curTime >= self:GetReloadTime() then
            self:setInReload(false)
            self:actionRun("reload")
            if self:canReload() then
                self:ReloadFinished()
            end
        end
    end

    local primary_ammo_type =  self:GetPrimaryAmmoType()

    local reload_delay = self:getReloadDelay()

    if reload_delay > 0 and curTime >= reload_delay then
        self:setReloadDelay(0)
        self:Reload( 0 )
    end

    local silencer = self:getSilencer()
    local silencer_time = self:getSilencerTime()

    if silencer_time > 0 and curTime >= silencer_time then
        self:setSilencer( not silencer )
        self:setSilencerTime(0)

        self:actionRun( "silencer" )
    end

    local idle_time = self:GetIdleTime()
    if idle_time > 0 and curTime >= idle_time and not inload and silencer_time <= 0 then
        self:actionRun("idle")
        self:SetIdleTime(-1)
        self:sendWeaponAnim( self:getAnimation("idle") )
    end

    local recoverSight = self:getRecoverSight()

    if recoverSight > 0 and curTime >= recoverSight and reload_delay <= 0 then
        self:setRecoverSight(0)
        if not self:getInSight() then
            self:setInSight( true )
        end
    end

    self.Primary.Automatic = self:getIsAutomatic()

    local burst_count = self:getBurstCountCur()
    local burst_delay = self:getBurstTime()

    if burst_count > 0 and burst_delay > 0 and curTime >= burst_delay then
        self:setBurstCountCur(burst_count - 1)
        self:setBurstAttack(self:getRateOfFire())

        if self:Clip1() > 0 then
            self:fireBullet()
        end
    end

    local reload_manual_time = self:getReloadManualTime()
    if reload_manual_time > 0 and curTime >= reload_manual_time then
        local anim, isSeq = self:getAnimation( "reload" )

        if owner:GetAmmoCount( self:GetPrimaryAmmoType() ) > 0 then
            self:sendWeaponAnim( anim, isSeq )
            self:setReloadManualTime( curTime + ( self:getAnimationTime( anim ) * 1.1 ) )

            local new_clip_size = self:Clip1() + 1
            local max_clip = self:GetMaxClip1()

            self:SetClip1( math.clamp( new_clip_size, 0, max_clip ) )

            if new_clip_size > max_clip then
                anim = self:getAnimation( "reload_manual_finish" )
                self:sendWeaponAnim( anim, isSeq )
                self:setReloadManualTime( 0 )
                self:setManualReloadingStart( false )

                self:SetIdleTime( curTime + ( self:getAnimationTime( anim ) * 1.5 ) )
            else
                owner:RemoveAmmo( 1, primary_ammo_type )
            end
        else
            anim, isSeq = self:getAnimation( "reload_manual_finish" )
            self:sendWeaponAnim( anim, isSeq )
            self:setReloadManualTime( 0 )
            self:setManualReloadingStart( false )

            self:SetIdleTime( curTime + ( self:getAnimationTime( anim ) * 1.5 ) )
        end
    end

    local inSight = self:getInSight()

    if inSight then
        if not owner:KeyDown( IN_ATTACK2 ) then
            self:toogleADS()
        end
    end

    self:setSightProgress( Lerp( tick * self:getSightProgressSpeed(), self:getSightProgress(), self:getSightProgressTo() ) )

    local delay_anim_time = self:getDelayAnim()

    if delay_anim_time > 0 and curTime >= delay_anim_time then
        self:setDelayAnim( 0 )

        local anim, isseq = self.DelayAnim, self.DelayAnimIsSeq

        if anim then
            self:sendWeaponAnim( anim, isseq )
            self:SetIdleTime( curTime + self:getAnimationTime( anim ) )
        end

        self.DelayAnim = nil
        self.DelayAnimIsSeq = nil
    end

    self:actionRun( "think" )
end

function SWEP:FireAnimationEvent(_, __, event)
    if event == 5001 then
        if self:getSilencer() then
            return true
        end
    end
end

function SWEP:callback()
end

function SWEP:getCurTime()
    local curtime = CurTime( )
    local curatt = self:GetNextPrimaryFire( )
    local diff = curtime - curatt

    if diff > engine.TickInterval( ) or diff < 0 then
        curatt = curtime
    end

    return curatt
end

function SWEP:sendWeaponAnim( anim, isSeq, delay )
    local owner = self:GetOwner()
    ---@cast owner Player

    if owner == nil or not owner:IsValid() then
        return
    end

    if delay == nil or delay <= 0 then
        local vm = owner:GetViewModel()

        if vm == nil or not vm:IsValid() then
            return
        end

        if not isSeq then
            vm:SendViewModelMatchingSequence( vm:SelectWeightedSequence( anim ) )
        else
            if isstring(anim) then
                anim = vm:LookupSequence( anim )
            end

            vm:SendViewModelMatchingSequence( anim )
        end
    else
        self.DelayAnim = anim
        self.DelayAnimIsSeq = isSeq
        self:setDelayAnim( self:getCurTime() + delay )
    end
end

--- [SHARED]
---
--- Returns the appropriate animation for the given action.
---
---@param action string
---@return ACT, boolean
function SWEP:getAnimation( action )
    local anim
    local anims = self.Animations

    if anims then
        anim = anims[action]

        if anim == nil then
            anim = defaults_animations[action]
        end
    else
        anim = defaults_animations[ action ]
    end

    local anim_normal = anim and anim.normal

    return anim_normal or -1, isstring( anim_normal )
end

function SWEP:getHitgroupScale( hitgroup )
    local hook_scale = hook.Run( "frontfire.GetHitgroupScale", hitgroup )
    if hook_scale ~= nil then
        return hook_scale
    end

    if self.HitgroupScale == nil then
        return 1
    end

    return self.HitgroupScale[hitgroup] or 1
end

function SWEP:Deploy()
    local draw_anim = self:getAnimation( "draw" )
    local len = self:getAnimationTime( draw_anim )
    local curTime = CurTime()

    if self.ReadyAnim and not self:getIsReady() then
        self:setIsReady( true )

        draw_anim = self:getAnimation( "ready" )
        len = self:getAnimationTime( draw_anim )
    end

    self:nextPrimaryFire(len)
    self:nextSecondaryFire(len)
    self:SetIdleTime(curTime + len)
    self:sendWeaponAnim(draw_anim)
    self:setInReload(false)
    self:setSilencerTime(0)
    self:SetReloadTime(0)

    self:setKickCurX(0)
    self:setKickCurY(0)
    self:setKickCurZ(0)
    self:setKickX(0)
    self:setKickY(0)
    self:setKickZ(0)
    self:setKickReset(-1)
    self:setShoot(0)
    self:setRecoverSight(0)
    self:setSightState(0)
    self:setInSight(false)
    self:setBurstCountCur(0)
    self:setManualReloadingStart( false )

    self:SetHoldType(self.HoldType)
    self:actionRun("deploy")
    self.sightTime = 0


    self:setSightProgress( 0 )
    self:setSightProgressFrom( 0 )
    self:setSightProgressTo( 0 )

    local owner = self:GetOwner()

    ---@cast owner Player

    if not (owner ~= nil and owner:IsValid()) then
        return true
    end

    if self:GetMaxClip1() > 0 and self:Clip1() <= 0 and owner:GetAmmoCount( self:GetPrimaryAmmoType() ) > 0 then
        self:Reload( len )
    end

    return true
end

--- [SHARED]
---
--- Calculates the spread of the weapon based on the current shoot count.
---
---@return Vector
function SWEP:calcSpread()
    local owner = self:GetOwner()
    ---@cast owner Player

    if not (owner ~= nil and owner:IsValid()) then
        return vector_origin
    end

    local velocity = owner:GetVelocity():Length2D()

    local spreadMax = self.SpreadMax
    local spread = (self.Spread * self:getCurShoot()) + self.SpreadStart
    spread = Vector(0, math_min(spread.y, spreadMax.y), math_min(spread.z, spreadMax.z))

    if velocity >= 25 then
        spread = spread + self.SpreadMove
    end



    if not owner:OnGround() then
        spread = spread + self.SpreadOnAir
    end

    if not self:getInSight() then
        spread = spread + self.SpreadNoSight
    elseif self.SpreadSight then
        spread = self.SpreadSight
    end

    spread = spread + self:getSpreadAdded()
    spread = spread * self:getSpreadMult()

    -- if not owner:IsOnGround() then
    --     spread = spread + self.SpreadOnAir
    -- elseif not self:getInSight() then
    --     spread = spread + self.SpreadNoSight
    -- elseif velocity > 10 then
    --     spread = spread + self.SpreadMove
    -- end

    return spread
end

function SWEP:Initialize()
    self:setIsAutomatic( self.Primary.IsAutomatic )
    self:callback()
    self:actionRun("initialized")

    self:setRateOfFire( self.Primary.Delay )

    self:setSightProgress( 0 )
    self:setSightProgressFrom( 0 )
    self:setSightProgressTo( 0 )

    self:setIsReady( false )
end

--- [SHARED]
---
--- Calculates the duration of the given animation.
---
---@param anim number | string
---@return number time
function SWEP:getAnimationTime(anim)
    if type(anim) == "string" then
        return self:SequenceDuration(self:SelectWeightedSequence( self:LookupSequence(anim) ))
    else
        return self:SequenceDuration(self:SelectWeightedSequence(anim))
    end
end

--- [SHARED]
---
--- Checks if the weapon can be reloaded.
---
---@return boolean
function SWEP:canReload()
    if self:getInReload() then
        return false
    end

    if self:getManualReloadingStart() then
        return false
    end

    if self:getSilencerTime() > 0 then
        return false
    end

    local max_clip = self:GetMaxClip1()
    if self:Clip1() >= ( self.Chamber and max_clip + 1 or max_clip ) then
        return false
    end

    local owner = self:GetOwner()
    ---@cast owner Player

    if not (owner ~= nil and owner:IsValid()) then
        return false
    end

    if owner:GetAmmoCount( self:GetPrimaryAmmoType() ) <= 0 then
        return false
    end

    return true
end

---@param reload_delay? number
function SWEP:Reload( reload_delay )
    if not self:canReload() then
        return
    end

    if self:getInSight() then
        self:toogleADS()
    end

    self:setInSight( false )
    self:setRecoverSight( 0 )
    self:setDelayAnim( 0 )

    reload_delay = reload_delay or 0

    local cur_time = CurTime()
    local anim, isSeq  = self:getAnimation("reload")
    local time = cur_time + self:getAnimationTime(anim)

    if self.ReloadEmptyAnim and self:Clip1() == 0 then
        anim, isSeq  = self:getAnimation("reload_empty")
        time = cur_time + self:getAnimationTime(anim)
    end

    if reload_delay > 0 then
        self:setReloadDelay(cur_time + reload_delay)
    else
        if not self.ManualReloading then
            self:setInReload( true )
            self:sendWeaponAnim(anim, isSeq)
            self:SetReloadTime(time)
            self:SetIdleTime(time)
        else
            anim, isSeq = self:getAnimation( "reload_manual_start" )
            self:sendWeaponAnim( anim, isSeq )
            self:setManualReloadingStart( true )

            local time_reload = ( self:getAnimationTime( anim ) )
            self:SetIdleTime( 0 )
            self:setReloadManualTime( cur_time + time_reload )

            anim, isSeq = self:getAnimation( "reload" )

            time_reload = time_reload + ( self:getAnimationTime( anim ) * 1.2 )

            self:nextPrimaryFire( time_reload )
            self:nextSecondaryFire( time_reload )
        end
    end
end

--- [SHARED]
---
---
---
---@param action string
---@param callback any
---@param name? string
function SWEP:addAction(action, callback, name)
    name = name or (action .. "." .. tostring(SysTime()))

    local action_map = self.actions
    local actions = action_map[action] or { [0] = 0 }
    action_map[action] = actions

    local count = actions[0]

    for i = 1, count do
        if actions[i][1] == name then
            table.remove(actions, i)

            count = count - 1
            break
        end
    end

    count = count + 1

    actions[0] = count
    actions[count] = { name, callback }
end

---@param action string
---@param name string
function SWEP:removeAction(action, name)
    local actions = self.actions[action]

    if actions ~= nil then
        local count = actions[0]
        for i = 1, count do
            if actions[ i ][ 1 ] == name then
                table.remove(actions, i)

                count = count - 1
                break
            end
        end

        actions[ 0 ] = count
    end
end

---@param action string
---@param ... any
function SWEP:actionRun(action, ...)
    ---@type table<string, table<number, any>>
    self.actions = self.actions or  {}

    local actions = self.actions[action]

    local last_return
    if actions ~= nil then
        for i = 1, actions[ 0 ] do
            last_return = actions[ i ][ 2 ]( self, ... )
        end
    end

    local hook_return = hook.Run( "frontfire.weapon.Action", self, action, ... )
    return hook_return ~= nil and hook_return or last_return
end

function SWEP:getCurShoot()
	return math.floor( self:GetShoot() )
end

function SWEP:addKick( ang )
	local p, y, r = self:getKickCurX(), self:getKickCurY(), self:getKickCurZ()

    local viewPunchMax = self.ViewKickMax

	p = math.clamp( p + ang.x, -viewPunchMax.x, viewPunchMax.x )
	y = math.clamp( y + ang.y, -viewPunchMax.y, viewPunchMax.y )
	r = math.clamp( r + ang.r, -viewPunchMax.z, viewPunchMax.z )

    local curtime = CurTime( )
    local curatt = self:GetNextPrimaryFire( )
    local diff = curtime - curatt

    if diff > engine.TickInterval( ) or diff < 0 then
        curatt = curtime
    end

    self:setKickReset( curtime + 0.1 )
    self:setRecoverProgressTo( self.KickRecoverSpeed )
    self:setRecoverProgress( 0 )

	self:setKickX( p )
	self:setKickY( y )
	self:setKickZ( r )
    self:setIsRecover( false )

	local owner = self:GetOwner()

	if not ( owner ~= nil and owner:IsValid() ) then
		return
	end

	local shoot = self:GetShoot()
	---@cast owner Player
	Player_SetViewPunchAngles( owner, ang * 2 )
end

function SWEP:GetKick( )
    return Angle( self:getKickCurX(), self:getKickCurY(), self:getKickCurZ() )
end

---@return Vector
function SWEP:getDir()
    local owner = self:GetOwner()
    if not (owner ~= nil and owner:IsValid()) then
        return vector_origin
    end

    local kick = self:GetKick()
    ---@cast owner Player

    local dir = { Angle_Forward(Player_EyeAngles(owner) + ( kick ) + Player_GetViewPunchAngles(owner)) }

    self:actionRun( "dir", dir )

    return dir[ 1 ]
end

---@param delay number
function SWEP:nextPrimaryFire( delay )
    local curtime = CurTime( )
    local curatt = self:GetNextPrimaryFire( )
    local diff = curtime - curatt

    if diff > engine.TickInterval( ) or diff < 0 then
        curatt = curtime
    end

    self:SetNextPrimaryFire( curatt + delay )
end

---@param delay number
function SWEP:nextSecondaryFire(delay)
    local curtime = CurTime()
    local curatt = self:GetNextSecondaryFire()
    local diff = curtime - curatt

    if diff > engine.TickInterval() or diff < 0 then
        curatt = curtime
    end

    self:SetNextSecondaryFire(curatt + delay)
end

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

local server_hit_pos
local server_start_pos
if CLIENT then
    net.Receive("primary_fire", function()
        server_hit_pos = net.ReadVector()
        server_start_pos = net.ReadVector()
    end)
end

local client_hit_pos
local client_start_pos
local dist_limit = 65536

local other_hists = {}

if CLIENT then
    local color_red = Color(255, 0, 0)
    local color_yellow = Color(255, 255, 0)

    local color_start = Color(255, 0, 255)
    local color_end = Color(100, 200, 255)
    -- hook.Add("PostDrawOpaqueRenderables", "Defaults", function()

    --     if client_hit_pos then
    --         -- render.DrawLine(client_start_pos, client_hit_pos, color_white, true)
    --         -- render.DrawWireframeSphere(client_hit_pos, 4, 8, 8, color_white, true)
    --         render.DrawWireframeSphere(client_start_pos, 4, 8, 8, color_black, true)
    --     end

    --     -- if server_hit_pos then
    --     --     render.DrawLine(server_start_pos, server_hit_pos, color_red, true)
    --     -- end

    --     for i = 1, #other_hists do
    --         local data = other_hists[i]
    --         -- render.DrawLine(data[1], data[2], color_yellow, true)

    --         render.DrawWireframeSphere(data[1], 4, 8, 8, color_start, true)
    --         render.DrawWireframeSphere(data[2], 4, 8, 8, color_end, true)
    --     end
    -- end)
end

--- [SHARED]
---
--- Calculates the damage based on the current distance from the start to the stop distance.
---
---@param current_distance number
---@param stop_distance number
---@param start_distance number
---@param damage_max number
---@param damage_min number
---@return number
function SWEP:calculateDamageDistance( current_distance, stop_distance, start_distance, damage_max, damage_min )
    if current_distance < start_distance then
        return damage_max
    end

    if current_distance >= start_distance and current_distance <= stop_distance then
        return damage_max - ( damage_max - damage_min ) * (current_distance - start_distance) / ( stop_distance - start_distance )
    end

    if current_distance > stop_distance then
        return damage_min
    end

    return damage_max
end

function SWEP:getPrimaryDamage()
    return self.Primary.Damage
end

function SWEP:getPrimaryDamageMin( )
    return self.Primary.DamageMin
end

if CLIENT then
    net.Receive("bullet_effect", function()
        local hit_pos = Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
        local hit_normal = Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
        local surface_props = net.ReadUInt(8)

        util.Decal("Impact.Concrete", hit_pos + hit_normal, hit_pos - hit_normal)

        local ed = EffectData()
        ed:SetOrigin(hit_pos)
        ed:SetNormal(hit_normal)
        ed:SetSurfaceProp(surface_props)
        util.Effect("Impact", ed)
    end)
end

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result_size = {}

---@type ash.trace.Params
local trace_size = {
    output = trace_result_size
}

local function penetraitTrace(dir, filter, filter_map)
    local p_start = trace_result.HitPos + (dir * 16)
    trace.start = p_start
    trace.endpos = p_start + dir * dist_limit
    trace.filter = filter
    trace.mask = MASK_SHOT

    trace_cast(trace)

    local entity = trace_result.Entity
    if entity ~= nil and not filter_map[entity] then
        filter[#filter + 1] = entity
        filter_map[entity] = true
    end

    if trace_result.StartSolid then
        for i = 1, 4 do
            trace.start = trace_result.StartPos
            trace.endpos = trace_result.HitPos
            trace.filter = filter
            trace.mask = MASK_SHOT
            trace_cast(trace)

            if not trace_result.StartSolid then
                break
            end

            entity = trace_result.Entity
            if entity ~= nil and not filter_map[entity] then
                filter[#filter + 1] = entity
                filter_map[entity] = true
            end

            trace_result.StartPos = trace_result.StartPos + (dir * 16)
        end
    end
end

function SWEP:setBurstAttack( delay )
    self:setBurstTime( self:getCurTime() + delay )
end

--- [SHARED]
---
--- Checks if the primary attack can be performed.
---
---@return boolean
function SWEP:canPrimaryAttack()
	local curTime = CurTime()

    if self:getSilencerTime() > 0 then
        return false
    end

    if self:getInReload() then
        return false
    end

    if self:getBurstCountCur() > 0 then
        return false
    end

	return true
end

function SWEP:fireBullet()
    local owner = self:GetOwner()
    ---@cast owner Player

    if not (owner ~= nil and owner:IsValid()) then
        return
    end

    local curTime = CurTime()

    if CLIENT and IsFirstTimePredicted() then
        local dir = self:getDir() * 0.5

        local spread = self:calcSpread()
        spread = spread / 1000

        spread = Vector(0, SharedRandom("frontfire.spread.x", -spread.y, spread.y),
            SharedRandom("frontfire.spread.z", -spread.z, spread.z))

        dir = LocalToWorld(spread, angle_zero, dir, owner:GetAngles())

        local start = owner:GetShootPos()
        trace.start = start
        trace.endpos = start + dir * dist_limit
        trace.mask = MASK_SHOT

        ---@type table<Entity, boolean>
        local filter_map = { [owner] = true }

        ---@type Entity[]
        local filter = {
            [1] = owner,
        }

        trace.filter = filter

        trace_cast(trace)

        util.Decal("Impact.Concrete", trace_result.HitPos + trace_result.Normal,
            trace_result.HitPos - trace_result.Normal)

        local ed = EffectData()
        ed:SetOrigin(trace_result.HitPos)
        ed:SetNormal(trace_result.Normal)
        ed:SetSurfaceProp(trace_result.SurfaceProps)
        util.Effect("Impact", ed)

        local entity = trace_result.Entity
        if entity ~= nil and not filter_map[entity] then
            filter[#filter + 1] = entity
            filter_map[entity] = true
        end

        client_hit_pos = trace_result.StartPos
        client_start_pos = trace_result.HitPos

        local last_hit = trace_result.HitPos

        table.clearIndexes(other_hists)

        local hits = { [1] = { trace_result.StartPos, trace_result.HitPos, trace_result.Entity, trace_result.HitGroup } }
        local hits_count = 1

        local dist_travel = 0
        local max_dist = 32

        for i = 1, 4 do
            penetraitTrace(dir, filter, filter_map)

            local dist = last_hit:Distance(trace_result.StartPos)

            dist_travel = dist_travel + dist

            if dist_travel > max_dist then
                break
            end

            other_hists[#other_hists + 1] = { trace_result.StartPos, trace_result.HitPos }
            hits_count = hits_count + 1
            hits[hits_count] = { trace_result.StartPos, trace_result.HitPos, trace_result.Entity, trace_result.HitGroup }

            last_hit = trace_result.HitPos
        end

        net.Start("primary_fire")
        net.WriteUInt(hits_count, 5)
        net.WriteDouble(dir.x)
        net.WriteDouble(dir.y)
        net.WriteDouble(dir.z)
        for i = 1, hits_count do
            local v = hits[i]
            local s_pos = v[1]
            local h_pos = v[2]

            net.WriteDouble(s_pos.x)
            net.WriteDouble(s_pos.y)
            net.WriteDouble(s_pos.z)
            net.WriteDouble(h_pos.x)
            net.WriteDouble(h_pos.y)
            net.WriteDouble(h_pos.z)
            net.WriteEntity(v[3])
            net.WriteUInt(v[4], 5)
        end
        net.SendToServer()
    end

    local anim, isSeq = self:getAnimation( "attack_primary" )
    local anim_time = self:getAnimationTime( anim )

    owner:MuzzleFlash()
    owner:SetAnimation( PLAYER_ATTACK1 )
    self:setBufferedClick( false)
    self:sendWeaponAnim( anim, isSeq )

    if self.PumpAnim then
        anim, isSeq = self:getAnimation( "pump" )
        self:sendWeaponAnim( anim, isSeq, anim_time )
    else
        self:SetIdleTime( curTime + anim_time )
    end

    self:EmitSound( self:getSilencer() and self.Primary.SoundSilencer or self.Primary.Sound )
end

function SWEP:PrimaryAttack()
    if not self:canPrimaryAttack() then
        return
    end

    local curTime = CurTime()
    local owner = self:GetOwner()

    if not (owner ~= nil and owner:IsValid()) then
        return
    end

    if self:Clip1() <= 0 then
        self:SetNextPrimaryFire(curTime + 1)
        return
    end

    if CLIENT and IsFirstTimePredicted() and self.Primary.Shaking then
        util.ScreenShake( vector_origin, self.Primary.ShakeAmlitude, self.Primary.ShakeFrequency, self.Primary.ShakeDuration, 0 )
    end

    ---@cast owner Player

    self:fireBullet()

    self:setReloadManualTime( 0 )
    self:setManualReloadingStart( false )

    local kick = self.ViewKickList
    local ang = kick and kick[math_min(math_max(self:getCurShoot(), 1), #kick)] or angle_zero


    local delay = self:getRateOfFire()

    local random_kick_min = self.KickRandomMin
    local random_kick_max = self.KickRandomMax
    local random_kick = Angle( SharedRandom( "ash_weapon_base.RandomKickY", random_kick_min.x, random_kick_max.x ), SharedRandom( "ash_weapon_base.RandomKickY", random_kick_min.y, random_kick_max.y ), SharedRandom( "ash_weapon_base.RandomKickZ", random_kick_min.z, random_kick_max.z ) )

    if not random_kick:IsZero() then
        ang = ang + random_kick
    end

    self:addKick( ang )
    self:setShootReset( curTime + .5 )
    self:setShoot(self:getCurShoot() + 1)
    self:TakePrimaryAmmo( 1 )

    local insight = self:getInSight()

    if not self.Secondary.NoRecoverSight then
        if insight then
            self:setInSight(false)
            self:setRecoverSight(curTime + (delay * 0.9))
        elseif self:getRecoverSight() > 0 then
            self:setRecoverSight(curTime + (delay * 0.9))
        end
    end

    if self:Clip1() <= 0 and self:canReload() then
        self:Reload()
    end

    if self:getIsBurstFire() then
        self:setBurstCountCur(self:getBurstCount() - 1)
        self:setBurstAttack(delay)
        self:nextPrimaryFire( self:getNextBurstDelay() )
    else
        self:nextPrimaryFire(delay)
    end

    self:setLeftGun( not self:getLeftGun() )
    self:actionRun("primaryAttack")
end

-- if CLIENT then
--     hook.Add("PlayerBindPress", "Defaults", function(owner, bind)
--         if bind == "+attack" then
--             local self = owner:GetActiveWeapon()
--             ---@cast self ash_weapon_base

--             if self ~= nil and self:IsValid() then

--             end
--         end
--     end)
-- end

function SWEP:toogleADS()
    local sight = not self:getInSight()

    self:setInSight( sight )
    self:setSightState( sight and 1 or 0 )
    self:nextSecondaryFire( 0.1 )

    self:setSightProgressSpeed( self.SightSpeedStandart )

    if sight then
        self:setSightProgressTo( 1 )
    else
        self:setSightProgressTo( 0 )
    end
end

function SWEP:attachSilencer()
    if self:getInReload() then
        return
    end

    if self:getSilencerTime() > 0 then
		return false
	end

    local anim = self:getSilencer() and ACT_VM_DETACH_SILENCER or ACT_VM_ATTACH_SILENCER
    local time = self:getAnimationTime(anim)

    local ct = CurTime()
    self:setSilencerTime( ct + time )
    self:SetIdleTime(ct + time)
    self:sendWeaponAnim(anim)
    self:nextPrimaryFire(time)
    self:nextSecondaryFire(time)
end

function SWEP:AdjustMouseSensitivity( defaultSensitivity, localFOV, defaultFOV)
    local pl = self:GetOwner()
    ---@cast pl Player


    if IsValid( pl ) and pl.GetFOV then
        local fov = pl:GetFOV( ) * ( self.Secondary.SightStateZoom[self:getSightState( )] or 1 )
        local max_fov = 90

        if self:getInSight( ) and fov < max_fov then
            local diff = max_fov - fov

            local percent = ( diff / max_fov )
            percent = 1 - percent

            return percent
        end
    end

    return 1
end

function SWEP:toggleSight()
    if self:getInReload() then
        return
    end

    local insight = self:getInSight()
    local state = self:getSightState()

    if not insight then
        self:setInSight(true)
        self:setSightState(1)
    elseif insight and state < #(self.Secondary.SightStateZoom) then
        self:setSightState(state + 1)
    else
        self:setInSight(false)
        self:setSightState(0)
    end

    self:EmitSound( self.Secondary.SightSound )

    self:nextSecondaryFire( 0.3 )
end

function SWEP:SecondaryAttack()

end

--
-- SWEP.Secondary.ViewModelSightPos = Vector( )
-- SWEP.Secondary.ViewModelSightAng = Angle( )
function SWEP:calcView(view)
    view.origin, view.angles = LocalToWorld( vector_origin, self:GetKick(), view.origin, view.angles )

    if self:getInSight() then
        view.fov = view.fov * (self.Secondary.SightStateZoom[ self:getSightState() ] or 1)
    end
end

function SWEP:CalcViewModelView( vm, oldpos, oldeyeang, pos, ang )
    local npos, nang = pos, ang

    if self:getInSight() then
        npos, nang = oldpos, oldeyeang
    end

    local kick = self:GetKick()

    local sight_pos, sight_ang = self.Secondary.ViewModelSightPos, self.Secondary.ViewModelSightAng

    local scale_pos = self:getSightProgress()
    if scale_pos then
        sight_pos = sight_pos * scale_pos
        sight_ang = sight_ang * scale_pos
    end

    npos, nang = LocalToWorld( vector_origin, kick, npos, nang )
    npos, nang = LocalToWorld( sight_pos, sight_ang, npos, nang )

    return npos, nang
end


function SWEP:GetViewModelPosition(pos, ang)
    return pos, ang
end
