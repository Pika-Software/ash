---@type ash.firing
local ash_firing = import "firing"

---@type ash.nw3
local ash_nw3 = import "ash.nw3"

local ash_nw3_get = ash_nw3.get
local ash_nw3_set = ash_nw3.set


local math_approach = math.approach
local math_max = math.max
local math_min = math.min
local SharedRandom = util.SharedRandom
local math_randomseed = _G.math.randomseed
local math_randomf = math.randomf

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
---@field getBulletCountOnShoot fun( self: self ): number
---@field setBulletCountOnShoot fun( self: self, integer: number )
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
SWEP.Primary.BulletCountOnShoot = 1

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

do
    local fallbacks = {
        [ "boolean" ] = false,
        [ "entity" ] = NULL,
        [ "angle" ] = angle_zero,
        [ "vector" ] = vector_origin,
        [ "string" ] = "",
    }

    function SWEP:addNW3( network_type, name )
        local full_name = "ash.weapon." .. self:GetClass() .. "." .. name

        ash_nw3.register( full_name, network_type, ash_nw3.SEND_PVS )

        local fallback = fallbacks[ network_type ]

        if fallback == nil then
            if string.hasPrefix( network_type, "uint" ) or string.hasPrefix( network_type, "int" ) then
                fallback = 0
            elseif network_type == "float" or network_type == "double" then
                fallback = 0
            end
        end

        self[ "get" .. name ] = function( s )
            return ash_nw3_get( s, full_name, fallback )
        end

        self[ "set" .. name ] = function( s, value )
            return ash_nw3_set( s, full_name, value )
        end
    end
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
    self:addNetwork("Int", "BulletCountOnShoot")

    self:addNetwork("Vector", "SpreadAdded")
    self:addNetwork("Vector", "SpreadMult")

    self:actionRun("setupDataTables")

    self:addNW3( "boolean", "InScope" )
    self:addNW3( "boolean", "Automatic" )

    self:addNW3( "float", "DelayFire" )
    self:addNW3( "uint8", "Skin" )

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
                self:reloadFinished()
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
            self:setReloadManualTime( curTime + ( self:getAnimationTime( anim ) * 1.2 ) )

            local new_clip_size = self:Clip1() + 1
            local max_clip = self:GetMaxClip1()

            self:SetClip1( math.clamp( new_clip_size, 0, max_clip ) )

            if new_clip_size > max_clip then
                anim = self:getAnimation( "reload_manual_finish" )
                self:sendWeaponAnim( anim, isSeq )
                self:setReloadManualTime( 0 )
                self:setManualReloadingStart( false )

                self:SetIdleTime( curTime + ( self:getAnimationTime( anim ) * 1.2 ) )
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
        -- if not owner:KeyDown( IN_ATTACK2 ) then
        --     self:toogleADS()
        -- end
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

    self:actionRun("deploy")

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
    self:setBulletCountOnShoot( self.Primary.BulletCountOnShoot )

    self:setAutomatic( self.Primary.IsAutomatic )

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
    if self:Clip1() >= ( ( self.Chamber and not self.ManualReloading ) and max_clip + 1 or max_clip ) then
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

function SWEP:reloadFinished()
    local owner = self:GetOwner()
    ---@cast owner Player

    if not (owner ~= nil and owner:IsValid()) then
        return
    end

    local ammo_type = self:GetPrimaryAmmoType()
    local reserve_ammo = owner:GetAmmoCount(ammo_type)
    local current_clip = self:Clip1()
    local max_clip = self.Primary.ClipSize
    max_clip = self.Chamber and max_clip + 1 or max_clip

    if current_clip == 0 and self.Chamber then
        max_clip = max_clip - 1
    end

    if reserve_ammo <= 0 or current_clip >= max_clip then
        return
    end

    local take_ammo = math.min(max_clip - current_clip, reserve_ammo)

    owner:RemoveAmmo(take_ammo, ammo_type)

    self:SetClip1(current_clip + take_ammo)
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

local server_hits = {}
if CLIENT then
    net.Receive("primary_fire", function()
        local start = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
        local hit = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
        timer.Simple( 0.25, function()
            server_hits[ #server_hits + 1 ] = { start, hit }
        end )

    end)
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

if CLIENT then
    local data = {}

    ---@return table
    function SWEP:clientShootInfo()
        local owner = self:GetOwner()
        ---@cast owner Player

        if not (owner ~= nil and owner:IsValid()) then
            return {}
        end

        local shootpos = owner:GetShootPos()
        local dir = self:getDir()
        local time = os.clock()

        data.shootpos = shootpos
        data.dir = dir
        data.time = time
        data.seed = CurTime()
        data.spread = self:calcSpread()

        self:actionRun( "clientShot", data )

        return data
    end
end


---@type Bullet
local bullet = {}

local bullet_effect = { effects = false, damage = false }

---@param tr TraceResult
local function bulletCallback( _, tr, dmginfo )
    local target = tr.target

    if target and target:IsValid() and ( target:IsNPC() or target:IsPlayer() ) then
        bullet_effect.effects = false
    else
        bullet_effect.effects = true
    end

    dmginfo:SetDamage( 0 )

    return bullet_effect
end


local distance_limit = 65536

local hits = {}

---@param owner Player
---@param position Vector
---@param angle Angle
---@param time number
function SWEP:primaryAttack( owner, position, angle, time )
    local dir = Angle_Forward( angle )

    if not self:getInScope() then
        dir = LocalToWorld( Vector( 0, ash_firing.randomNumber( owner, -0.1, 0.1 ), ash_firing.randomNumber( owner, -0.1, 0.1 ) ), angle_zero, dir, angle )
    end

    self:setDelayFire( CurTime() + 0.1 )

    local tr_result = ash_firing.fireBullet( time, owner, position, dir )
    self:sendWeaponAnim( self:getAnimation( "attack_primary" ) )

    if CLIENT then
        hits[ #hits + 1 ] = { tr_result.StartPos, tr_result.HitPos, Color( 255, 255, 0 ), CurTime() + 30 }

        local vm = owner:GetViewModel()

    else
        local pos_hit = tr_result.HitPos
        local pos_start = tr_result.StartPos

        net.Start( "bullet_effect" )
            net.WriteFloat( pos_start[ 1 ] )
            net.WriteFloat( pos_start[ 2 ] )
            net.WriteFloat( pos_start[ 3 ] )

            net.WriteFloat( pos_hit[ 1 ] )
            net.WriteFloat( pos_hit[ 2 ] )
            net.WriteFloat( pos_hit[ 3 ] )
        net.Send( owner )
    end
end


---@param owner Player
---@param position Vector
---@param angle Angle
function SWEP:secondaryAttack( owner, position, angle )
    self:setInScope( not self:getInScope() )

    print( "InScope:",  self:getInScope() )
end

---@param owner Player
function SWEP:reload( owner )
    if CLIENT then
        local vm = owner:GetViewModel()

        if vm ~= nil and vm:IsValid() then
            local seq = vm:SelectWeightedSequence( ACT_VM_RELOAD )
            if seq ~= -1 then
                vm:SendViewModelMatchingSequence( seq )
                vm:SetCycle( 0 )
                vm:SetPlaybackRate( 1 )
            end
        end
    end
end

if CLIENT then
    net.Receive("bullet_effect", function()
        local t = { Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() ) , Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() ), Color( 255, 0, 0 ), CurTime() + 5 }
        timer.Simple( 0.25, function()
            hits[ #hits + 1 ] = t
        end )
    end)

    hook.Add( "PostDrawOpaqueRenderables", "Debug", function()
        for i = 1, #hits do
            local v = hits[ i ]

            render.DrawLine( v[ 1 ], v[ 2 ], v[ 3 ], true )
            render.DrawSphere( v[ 2 ], 2, 16, 16, v[ 3 ] )

            if CurTime() > v[ 4 ] then
                table.remove( hits, i )

                break
            end
        end
    end )
end

function SWEP:PrimaryAttack()

end

-- function SWEP:primaryAttack( owner, data )
--     local dir = data.dir
--     local shootpos = data.shootpos

--     local spread = data.spread
--     spread = spread / 500

--     local targets = {}
--     local targets_count = 0

--     for i = 1, self:getBulletCountOnShoot() do
--         local x, y = math.randomf( -spread.y, spread.y ), math.randomf( -spread.z, spread.z )

--         local dir_spread = LocalToWorld( Vector( 0, x, y ), angle_zero, dir, owner:EyeAngles() )
--         local start = shootpos
--         trace.start = start
--         trace.filter = owner
--         trace.endpos = start + dir_spread * dist_limit
--         trace.mask = MASK_SHOT

--         trace_cast( trace )

--         local target = trace_result.Entity

--         if target ~= nil and target:IsPlayer() then
--             targets_count = targets_count + 1

--             targets[ targets_count ] = target
--         end

--         -- bullet.Attacker = owner
--         -- bullet.Inflictor = self
--         -- bullet.Damage = 0
--         -- bullet.Force = 1
--         -- bullet.Distance = dist_limit
--         -- bullet.HullSize = 0
--         -- bullet.Tracer = 1
--         -- bullet.IgnoreEntity = owner
--         -- bullet.Spread = vector_origin
--         -- bullet.Dir = dir_spread
--         -- bullet.Src = shootpos
--         -- bullet.Num = 1
--         -- bullet.TracerName = "Tracer"
--         -- bullet.Callback = bulletCallback

--         -- owner:FireBullets( bullet, true )

--         -- if CLIENT then
--         --     client_hits[ #client_hits + 1 ] = { trace_result.StartPos, trace_result.HitPos }
--         -- else
--         --     local start_pos = trace_result.StartPos
--         --     local hit_pos = trace_result.HitPos

--         --     net.Start( "primary_fire" )
--         --         net.WriteDouble( start_pos[ 1 ] )
--         --         net.WriteDouble( start_pos[ 2 ] )
--         --         net.WriteDouble( start_pos[ 3 ] )

--         --         net.WriteDouble( hit_pos[ 1 ] )
--         --         net.WriteDouble( hit_pos[ 2 ] )
--         --         net.WriteDouble( hit_pos[ 3 ] )
--         --     net.Send( owner )
--         -- end
--     end

--     return targets
-- end


-- function SWEP:fireBullet()
--     local owner = self:GetOwner()
--     ---@cast owner Player

--     if not (owner ~= nil and owner:IsValid()) then
--         return
--     end

--     local curTime = CurTime()

--     if CLIENT and IsFirstTimePredicted() then
--         local data = self:clientShootInfo()

--         table.clearKeys( client_hits )
--         table.clearKeys( server_hits )

--         math_randomseed( data.seed )

--         self:primaryAttack( owner, data )

--         math_randomseed( os.time()  )


--         local dir = data.dir
--         local shootpos = data.shootpos
--         local spread = data.spread

--         net.Start( "primary_fire" )
--             net.WriteDouble( data.time )

--             net.WriteDouble( data.seed )

--             net.WriteDouble( shootpos[ 1 ] )
--             net.WriteDouble( shootpos[ 2 ] )
--             net.WriteDouble( shootpos[ 3 ] )

--             net.WriteDouble( dir[ 1 ] )
--             net.WriteDouble( dir[ 2 ] )
--             net.WriteDouble( dir[ 3 ] )

--             net.WriteFloat( spread.y )
--             net.WriteFloat( spread.z )
--         net.SendToServer()
--     end

--     local anim, isSeq = self:getAnimation( "attack_primary" )
--     local anim_time = self:getAnimationTime( anim )

--     owner:MuzzleFlash()
--     owner:SetAnimation( PLAYER_ATTACK1 )
--     self:setBufferedClick( false)
--     self:sendWeaponAnim( anim, isSeq )

--     if self.PumpAnim then
--         anim, isSeq = self:getAnimation( "pump" )
--         self:sendWeaponAnim( anim, isSeq, anim_time )
--     else
--         self:SetIdleTime( curTime + anim_time )
--     end

--     self:EmitSound( self:getSilencer() and self.Primary.SoundSilencer or self.Primary.Sound )
-- end

--[[
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

    self:setReloadManualTime( 0 )
    self:setManualReloadingStart( false )

    local kick = self.ViewKickList
    local ang = kick and kick[math_min(math_max(self:getCurShoot(), 1), #kick)] or angle_zero


    local delay = self:getRateOfFire()

    local random_kick_min = self.KickRandomMin
    local random_kick_max = self.KickRandomMax
    -- local random_kick = Angle( SharedRandom( "ash_weapon_base.RandomKickY", random_kick_min.x, random_kick_max.x ), SharedRandom( "ash_weapon_base.RandomKickY", random_kick_min.y, random_kick_max.y ), SharedRandom( "ash_weapon_base.RandomKickZ", random_kick_min.z, random_kick_max.z ) )

    -- if not random_kick:IsZero() then
    --     ang = ang + random_kick
    -- end

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

]]

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


