---@type ash.firing
local ash_firing = import "firing"

---@type ash.nw3
local ash_nw3 = import "ash.nw3"

local ash_nw3_get = ash_nw3.get
local ash_nw3_set = ash_nw3.set


local bit_band = bit.band
local ash_firing_time = ash_firing.curTime
local math_approach = math.approach
local math_max = math.max
local math_min = math.min
local math_floor = math.floor

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
---@field getShoot fun( self: self ): number
---@field setBufferedClick fun( self: self, bool: boolean )
---@field getBufferedClick fun( self: self ): boolean
---@field setInReload fun( self: self, bool: boolean )
---@field getInReload fun( self: self ): boolean
---@field setReloadTime fun( self: self, float: number )
---@field getReloadTime fun( self: self ): number
---@field setReloadDelay fun( self: self, float: number )
---@field getReloadDelay fun( self: self ): number
---@field setIdleTime fun( self: self, float: number )
---@field getIdleTime fun( self: self ): number
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
---@field setIsMissfire fun( self: self, bool: boolean )
---@field getIsMissfire fun( self: self ): boolean
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
---@field setReabilityAmount fun( self: self, float: number )
---@field getReabilityAmount fun( self: self ): number
---@field setReabilityMissfireChance fun( self: self, float: number )
---@field getReabilityMissfireChance fun( self: self ): number
---@field setManualReloadingSkipFirst fun( self: self, bool: boolean )
---@field getManualReloadingSkipFirst fun( self: self ): boolean
---@field setInScope fun( self: self, bool: boolean )
---@field getInScope fun( self: self ): boolean
---@field setAutomatic fun( self: self, bool: boolean )
---@field getAutomatic fun( self: self ): boolean
---@field setVMLoop fun( self: self, bool: boolean )
---@field getVMLoop fun( self: self ): boolean
---@field setVMActive fun( self: self, bool: boolean )
---@field getVMActive fun( self: self ): boolean
---@field setVMToIdle fun( self: self, bool: boolean )
---@field getVMToIdle fun( self: self ): boolean
---@field setIsMissfireFixingIsFast fun( self: self, bool: boolean )
---@field getIsMissfireFixingIsFast fun( self: self ): boolean
---@field setSkin fun( self: self, int: number )
---@field getSkin fun( self: self ): number
---@field setVMWeightedSequence fun( self: self, int: number )
---@field getVMWeightedSequence fun( self: self ): number
---@field setDelayFire fun( self: self, float: number )
---@field getDelayFire fun( self: self ): number
---@field setSpread fun( self: self, float: number )
---@field getSpread fun( self: self ): number
---@field setRecoverProgress fun( self: self, float: number )
---@field getRecoverProgress fun( self: self ): number
---@field setRecoverProgressTo fun( self: self, float: number )
---@field getRecoverProgressTo fun( self: self ): number
---@field setIsMissfireFixing fun( self: self, float: number )
---@field getIsMissfireFixing fun( self: self ): number
---@field setIsMissfireFixingFastTime fun( self: self, float: number )
---@field getIsMissfireFixingFastTime fun( self: self ): number
---@field setVMTime fun( self: self, float: number )
---@field getVMTime fun( self: self ): number
---@field setVMDuration fun( self: self, float: number )
---@field getVMDuration fun( self: self ): number
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

SWEP.ViewModel = Model( "models/frontfire/weapons/cstrike/c_rif_ak47.mdl" )
SWEP.WorldModel = Model( "models/frontfire/weapons/w_rif_ak47.mdl" )
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
SWEP.ManualReloadingSkipFirst = false

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
SWEP.Secondary.SightSound = Sound( "Default.Zoom" )
SWEP.Secondary.ViewModelSightPos = Vector()
SWEP.Secondary.ViewModelSightAng = Angle()
SWEP.Secondary.SightNoDraw = false
SWEP.Secondary.SightStateZoom = {
    [ 1 ] = 0.4,
    [ 2 ] = 0.2,
}

SWEP.Spread = Vector( 0, 2, 2 )
SWEP.SpreadStart = Vector( 0, 1, 1 )
SWEP.SpreadMax = Vector( 0, 7, 7 )
SWEP.SpreadMove = Vector( 0, 8, 8 )
SWEP.SpreadOnAir = Vector( 0, 15, 15 )
SWEP.SpreadNoSight = Vector( 0, 0, 0 )

SWEP.KickSpeed = 20
SWEP.KickRecoverSpeed = 25
SWEP.KickRandomMin = Angle( 0, 0, 0 )
SWEP.KickRandomMax = Angle( 0, 0, 0 )
SWEP.KickRandomStability = Angle( 1, 1, 1 )
SWEP.KickMult = Angle( 1, 1, 1 )

SWEP.Reability = false
SWEP.ReabilityAmount = 300
SWEP.ReabilityFastFixChance = 25

local defaults_animations = {
    [ "draw" ] = {
        normal = ACT_VM_DRAW,
        silent = ACT_VM_DRAW_SILENCED,
    },
    [ "attack_primary" ] = {
        normal = ACT_VM_PRIMARYATTACK,
        silent = ACT_VM_PRIMARYATTACK_SILENCED,
    },
    [ "attack_secondary" ] = {
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

function SWEP:addNetwork( ntype, name )
    local networks = self.networks or {}
    self.networks = networks

    local types = networks[ ntype ] or 0

    types = types + 1
    networks[ ntype ] = types

    self:NetworkVar( ntype, types - 1, name )

    self[ "get" .. name ] = self[ "Get" .. name ]
    self[ "set" .. name ] = self[ "Set" .. name ]
end


do
    ash_nw3.register( "ash.weapon.Clip1", "uint16", ash_nw3.SEND_PVS )
    ash_nw3.register( "ash.weapon.Clip2", "uint16", ash_nw3.SEND_PVS )

    ---@return number
    function SWEP:getClip1()
        return ash_nw3_get( self, "ash.weapon.Clip1", 0 )
    end

    ---@return number
    function SWEP:getClip2()
        return ash_nw3_get( self, "ash.weapon.Clip2", 0 )
    end

    ---@return number
    function SWEP:getMaxClip1(  )
        return self.Primary.ClipSize or 0
    end

    ---@return number
    function SWEP:getMaxClip2(  )
        return self.Secondary.ClipSize or 0
    end

    ---@param amount number
    function SWEP:setClip1( amount )
        ash_nw3_set( self, "ash.weapon.Clip1", amount )
    end

    ---@param amount number
    function SWEP:setClip2( amount )
        ash_nw3_set( self, "ash.weapon.Clip2", amount )
    end


    ---@param amount number
    function SWEP:takePrimaryAmmo( amount )
        ash_nw3_set( self, "ash.weapon.Clip1", math_max( ash_nw3_get( self, "ash.weapon.Clip1", 0 ) - amount, 0 ) )
    end

    ---@param amount number
    function SWEP:takeSecondaryAmmo( amount )
        ash_nw3_set( self, "ash.weapon.Clip2", math_max( ash_nw3_get( self, "ash.weapon.Clip2", 0 ) - amount, 0 ) )
    end
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
            return ash_nw3_set( s, full_name, value, s.noSendContext )
        end
    end
end

function SWEP:SetupDataTables()
    self:addNW3( "boolean", "BufferedClick" )
    self:addNW3( "boolean", "InReload" )
    self:addNW3( "boolean", "Silencer" )
    self:addNW3( "boolean", "IsAutomatic" )
    self:addNW3( "boolean", "IsBurstFire" )
    self:addNW3( "boolean", "InSight" )
    self:addNW3( "boolean", "LeftGun" )
    self:addNW3( "boolean", "ManualReloadingStart" )
    self:addNW3( "boolean", "IsReady" )
    self:addNW3( "boolean", "IsRecover" )
    self:addNW3( "boolean", "ManualReloadingSkipFirst" )

    self:addNW3( "uint8", "BurstCount" )
    self:addNW3( "uint8", "SightState" )
    self:addNW3( "uint8", "FireMode" )
    self:addNW3( "uint8", "BurstCountCur" )
    self:addNW3( "uint8", "BulletCountOnShoot" )
    self:addNW3( "uint8", "Skin" )
    self:addNW3( "uint8", "ReabilityMissfireChance" )

    self:addNW3( "vector", "SpreadAdded" )
    self:addNW3( "vector", "SpreadMult" )

    self:addNW3( "boolean", "InScope" )
    self:addNW3( "boolean", "Automatic" )
    self:addNW3( "boolean", "VMLoop" )
    self:addNW3( "boolean", "VMActive" )
    self:addNW3( "boolean", "VMToIdle" )
    self:addNW3( "boolean", "IsMissfire" )
    self:addNW3( "boolean", "IsMissfireFixingIsFast" )

    self:addNW3( "double", "DelayFire" )
    self:addNW3( "double", "KickX" )
    self:addNW3( "double", "KickY" )
    self:addNW3( "double", "KickZ" )
    self:addNW3( "double", "KickReset" )
    self:addNW3( "double", "KickCurX" )
    self:addNW3( "double", "KickCurY" )
    self:addNW3( "double", "KickCurZ" )
    self:addNW3( "double", "Spread" )
    self:addNW3( "double", "Shoot" )
    self:addNW3( "double", "ReloadTime" )
    self:addNW3( "double", "ReloadDelay" )
    self:addNW3( "double", "IdleTime" )
    self:addNW3( "double", "SilencerTime" )
    self:addNW3( "double", "ShootReset" )
    self:addNW3( "double", "BurstTime" )
    self:addNW3( "double", "RecoverSight" )
    self:addNW3( "double", "RateOfFire" )
    self:addNW3( "double", "NextBurstDelay" )
    self:addNW3( "double", "ReloadManualTime" )
    self:addNW3( "double", "SightProgress" )
    self:addNW3( "double", "SightProgressTo" )
    self:addNW3( "double", "SightProgressFrom" )
    self:addNW3( "double", "SightProgressSpeed" )
    self:addNW3( "double", "RecoverProgress" )
    self:addNW3( "double", "RecoverProgressTo" )
    self:addNW3( "double", "DelayAnim" )
    self:addNW3( "double", "IsMissfireFixing" )
    self:addNW3( "double", "IsMissfireFixingFastTime" )

    self:addNW3( "double", "VMTime" )
    self:addNW3( "double", "VMDuration" )

    self:addNW3( "uint16", "VMWeightedSequence" )
    self:addNW3( "uint16", "ReabilityAmount" )

    if SERVER then
        self:setKickReset( -1 )
        self:changeFireMode( 1, true )
        self:setSpreadAdded( vector_origin )
        self:setSpreadMult( Vector( 1, 1, 1 ) )
        self:setSightProgressSpeed( self.SightSpeedStandart )
    end

    self:actionRun( "setupDataTables" )
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

    self:setFireMode( next_fire_mode )

    if not nomsg then
        local owner = self:GetOwner()
        ---@cast owner Player
        if owner ~= nil and owner:IsValid() then
            owner:PrintMessage( HUD_PRINTCENTER, "Fire mode: " .. data.name )
        end
    end

    if data.type == "burst" then
        self:setBurstCount( data.burst_count or 3 )
        self:setIsAutomatic( false )
        self:setIsBurstFire( true )
    elseif data.type == "auto" then
        self:setIsAutomatic( true )
        self:setIsBurstFire( false )
    elseif data.type == "single" then
        self:setIsAutomatic( false )
        self:setIsBurstFire( false )
    end

    if data.burstDelay then
        self:setNextBurstDelay( data.burstDelay )
    else
        self:setNextBurstDelay( 0 )
    end

    if data.spreadAdded then
        self:setSpreadAdded( data.spreadAdded )
    else
        self:setSpreadAdded( Vector( 0, 0, 0 ) )
    end

    if data.spreadMult then
        self:setSpreadMult( data.spreadMult )
    else
        self:setSpreadMult( Vector( 1, 1, 1 ) )
    end

    self:setRateOfFire( data.delay or self.Primary.Delay )
end

do
    local tick = engine.TickInterval()
    SWEP.noSendContext = false

    ---@param in_mask number
    ---@param position Vector
    ---@param angle Angle
    ---@param time number
    function SWEP:tick( in_mask, position, angle, time )
        self.noSendContext = true

        local owner = self:GetOwner()

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

        if time >= shot_reset then
            self:setShoot( math_approach( self:getShoot(), 0, 30 * tick ) )
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

            step = (recover) * tick
        end

        x = math_approach( curX, targetX, step )
        y = math_approach( curY, targetY, step )
        z = math_approach( curZ, targetZ, step )

        self:setKickCurX( x )
        self:setKickCurY( y )
        self:setKickCurZ( z )

        local inload = self:getInReload()

        if inload then
            if time >= self:getReloadTime() then
                self:setInReload( false )
                self:actionRun( "reload" )
                if self:canReload() then
                    self:reloadFinished()
                end
            end
        end

        local primary_ammo_type = self:GetPrimaryAmmoType()

        local reload_delay = self:getReloadDelay()

        if reload_delay > 0 and time >= reload_delay then
            self:setReloadDelay( 0 )
            self:Reload( 0 )
        end

        local silencer = self:getSilencer()
        local silencer_time = self:getSilencerTime()

        if silencer_time > 0 and time >= silencer_time then
            self:setSilencer( not silencer )
            self:setSilencerTime( 0 )

            self:actionRun( "silencer" )
        end

        local recoverSight = self:getRecoverSight()

        if recoverSight > 0 and time >= recoverSight and reload_delay <= 0 then
            self:setRecoverSight( 0 )
            if not self:getInSight() then
                self:setInSight( true )
            end
        end

        self.Primary.Automatic = self:getIsAutomatic()

        local burst_count = self:getBurstCountCur()
        local burst_delay = self:getBurstTime()

        if burst_count > 0 and burst_delay > 0 and time >= burst_delay then
            self:setBurstCountCur( burst_count - 1 )
            self:setBurstAttack( self:getRateOfFire() )

            if self:getClip1() > 0 then
                self:fireBullet()
            end
        end

        local reload_manual_time = self:getReloadManualTime()
        if reload_manual_time > 0 and time >= reload_manual_time then
            local anim, isSeq = self:getAnimation( "reload" )

            if owner:GetAmmoCount( self:GetPrimaryAmmoType() ) > 0 then
                if self:getManualReloadingSkipFirst() then
                    self:setManualReloadingSkipFirst( false )
                else
                    self:playVM( anim, 1, false )
                end

                self:setReloadManualTime( time + (self:getAnimationTime( anim ) * 1.2) )

                local new_clip_size = self:getClip1() + 1
                local max_clip = self:getMaxClip1()

                self:setClip1( math.clamp( new_clip_size, 0, max_clip ) )

                if new_clip_size > max_clip then
                    anim = self:getAnimation( "reload_manual_finish" )
                    self:playVM( anim, 1, true )
                    self:setReloadManualTime( 0 )
                    self:setManualReloadingStart( false )
                else
                    owner:RemoveAmmo( 1, primary_ammo_type )
                end
            else
                anim = self:getAnimation( "reload_manual_finish" )
                self:playVM( anim, 1, true )
                self:setReloadManualTime( 0 )
                self:setManualReloadingStart( false )
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

        if delay_anim_time > 0 and time >= delay_anim_time then
            self:setDelayAnim( 0 )

            local anim, isseq = self.DelayAnim, self.DelayAnimIsSeq

            if anim then
                self:sendWeaponAnim( anim, isseq )
                self:setIdleTime( time + self:getAnimationTime( anim ) )
            end

            self.DelayAnim = nil
            self.DelayAnimIsSeq = nil
        end

        if SERVER then
            local clip1_engine = self:Clip1()
            local clip1 = self:getClip1()

            if clip1_engine ~= clip1 then
                self:SetClip1( clip1 )
            end

            local clip2_engine = self:Clip2()
            local clip2 = self:getClip2()

            if clip2_engine ~= clip2 then
                self:SetClip1( clip2 )
            end
        end

        local missfire_fix = self:getIsMissfireFixing()

        if self:getIsMissfire() and missfire_fix > 0 then
            if time >= missfire_fix then
                if not self:getIsMissfireFixingIsFast() then
                    self:setIsMissfire( false )
                    self:setReabilityMissfireChance( 0 )
                    self:setReabilityAmount( self.ReabilityAmount )
                elseif self.ReabilityFastFixChance >= ash_firing.randomNumber( owner, 0, 100 ) then
                    self:setIsMissfire( false )
                    self:setReabilityMissfireChance( 0 )
                    self:setReabilityAmount( self.ReabilityAmount )
                end

                self:setIsMissfireFixingIsFast( false )
                self:setIsMissfireFixing( 0 )
            end
        end

        self:actionRun( "think" )

        self.noSendContext = false
    end
end

function SWEP:Think() end

function SWEP:FireAnimationEvent( _, __, event )
    if event == 5001 then
        if self:getSilencer() then
            return true
        end
    end
end

function SWEP:callback()
end

function SWEP:getCurTime()
    local curtime = ash_firing_time()
    local curatt = self:GetNextPrimaryFire()
    local diff = curtime - curatt

    if diff > engine.TickInterval() or diff < 0 then
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
            if isstring( anim ) then
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
        anim = anims[ action ]

        if anim == nil then
            anim = defaults_animations[ action ]
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

    return self.HitgroupScale[ hitgroup ] or 1
end

function SWEP:Deploy()
    local draw_anim = self:getAnimation( "draw" )
    local len = self:getAnimationTime( draw_anim )
    local curTime = ash_firing_time()

    if self.ReadyAnim and not self:getIsReady() then
        self:setIsReady( true )

        draw_anim = self:getAnimation( "ready" )
        len = self:getAnimationTime( draw_anim )
    end

    self:nextPrimaryFire( len )
    self:nextSecondaryFire( len )
    self:setIdleTime( curTime + len )
    self:playVM( self:getSilencer() and ACT_VM_DRAW_SILENCED or ACT_VM_DRAW )
    self:setInReload( false )
    self:setSilencerTime( 0 )
    self:setReloadTime( 0 )

    self:setKickCurX( 0 )
    self:setKickCurY( 0 )
    self:setKickCurZ( 0 )
    self:setKickX( 0 )
    self:setKickY( 0 )
    self:setKickZ( 0 )
    self:setKickReset( -1 )
    self:setShoot( 0 )
    self:setRecoverSight( 0 )
    self:setSightState( 0 )
    self:setInSight( false )
    self:setBurstCountCur( 0 )
    self:setManualReloadingStart( false )

    self:SetHoldType( self.HoldType )
    self.sightTime = 0


    self:setSightProgress( 0 )
    self:setSightProgressFrom( 0 )
    self:setSightProgressTo( 0 )

    local owner = self:GetOwner()

    ---@cast owner Player

    if not (owner ~= nil and owner:IsValid()) then
        return true
    end

    if self:getMaxClip1() > 0 and self:getClip1() <= 0 and owner:GetAmmoCount( self:GetPrimaryAmmoType() ) > 0 then
        self:Reload( len )
    end

    self:actionRun( "deploy" )

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

    local velocity = math_floor( owner:GetVelocity():Length2D() )

    local spreadMax = self.SpreadMax
    local spread = (self.Spread * self:getCurShoot() ) + self.SpreadStart
    spread = Vector( 0, math_min( spread.y, spreadMax.y ), math_min( spread.z, spreadMax.z ) )

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

do
    function SWEP:initialize()
        self:setIsAutomatic( self.Primary.IsAutomatic )
        self:callback()
        self:actionRun( "initialized" )

        self:setRateOfFire( self.Primary.Delay )

        self:setSightProgress( 0 )
        self:setSightProgressFrom( 0 )
        self:setSightProgressTo( 0 )
        self:setBulletCountOnShoot( self.Primary.BulletCountOnShoot )

        self:setAutomatic( self.Primary.IsAutomatic )


        local owner = self:GetOwner()
        ---@cast owner Player

        if not (owner ~= nil and owner:IsValid()) then
            return
        end


        local clip1_max = self:getMaxClip1()
        local amount_reserve = self.Primary.DefaultClip - clip1_max
        if amount_reserve > 0 then
            if amount_reserve <= clip1_max then
                self:setClip1( amount_reserve )
            else
                self:setClip1( clip1_max )
            end
        end

        self:setReabilityAmount( self.ReabilityAmount )

        self:setClip1( self.Primary.ClipSize )
        self:SetClip2( self.Secondary.ClipSize )
        self:setIsReady( false )

        ash.Logger:debug( "Weapon created! %s", tostring( self ) )
    end

    ---@param entity ash_weapon_base
    hook.Add( "OnEntityCreated", "ash_weapon_base", function( entity )
        timer.Simple( 0, function()
            if entity ~= nil and entity:IsValid() and entity.IsAshWeapon then
                entity:initialize()
            end
        end )
    end )
end

--- [SHARED]
---
--- Calculates the duration of the given animation.
---
---@param anim number | string
---@return number time
function SWEP:getAnimationTime( anim )
    if type( anim ) == "string" then
        return self:SequenceDuration( self:SelectWeightedSequence( self:LookupSequence( anim ) ) )
    else
        return self:SequenceDuration( self:SelectWeightedSequence( anim ) )
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

    local max_clip = self:getMaxClip1()
    if self:getClip1() >= ((self.Chamber and not self.ManualReloading) and max_clip + 1 or max_clip) then
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
    local reserve_ammo = owner:GetAmmoCount( ammo_type )
    local current_clip = self:getClip1()
    local max_clip = self.Primary.ClipSize
    max_clip = self.Chamber and max_clip + 1 or max_clip

    if current_clip == 0 and self.Chamber then
        max_clip = max_clip - 1
    end

    if reserve_ammo <= 0 or current_clip >= max_clip then
        return
    end

    local take_ammo = math.min( max_clip - current_clip, reserve_ammo )

    owner:RemoveAmmo( take_ammo, ammo_type )

    self:setClip1( current_clip + take_ammo )
end

---@param reload_delay? number
-- function SWEP:Reload( reload_delay )
--     if not self:canReload() then
--         return
--     end

--     if self:getInSight() then
--         self:toogleADS()
--     end

--     self:setInSight( false )
--     self:setRecoverSight( 0 )
--     self:setDelayAnim( 0 )

--     reload_delay      = reload_delay or 0

--     local cur_time    = ash_firing_time()
--     local anim, isSeq = self:getAnimation( "reload" )
--     local time        = cur_time + self:getAnimationTime( anim )

--     if self.ReloadEmptyAnim and self:getClip1() == 0 then
--         anim, isSeq = self:getAnimation( "reload_empty" )
--         time        = cur_time + self:getAnimationTime( anim )
--     end

--     if reload_delay > 0 then
--         self:setReloadDelay( cur_time + reload_delay )
--     else
--         if not self.ManualReloading then
--             self:setInReload( true )
--             self:setReloadTime( time )
--             self:setIdleTime( time )
--             self:playVM( anim, 1, false )
--         else
--             anim, isSeq = self:getAnimation( "reload_manual_start" )
--             self:sendWeaponAnim( anim, isSeq )
--             self:setManualReloadingStart( true )

--             local time_reload = (self:getAnimationTime( anim ))
--             self:setIdleTime( 0 )
--             self:setReloadManualTime( cur_time + time_reload )

--             anim, isSeq = self:getAnimation( "reload" )

--             time_reload = time_reload + (self:getAnimationTime( anim ) * 1.2)

--             self:nextPrimaryFire( time_reload )
--             self:nextSecondaryFire( time_reload )
--         end
--     end
-- end

--- [SHARED]
---
---
---
---@param action string
---@param callback any
---@param name? string
function SWEP:addAction( action, callback, name )
    name = name or (action .. "." .. tostring( SysTime() ))

    local action_map = self.actions
    local actions = action_map[ action ] or { [ 0 ] = 0 }
    action_map[ action ] = actions

    local count = actions[ 0 ]

    for i = 1, count do
        if actions[ i ][ 1 ] == name then
            table.remove( actions, i )

            count = count - 1
            break
        end
    end

    count = count + 1

    actions[ 0 ] = count
    actions[ count ] = { name, callback }
end

---@param action string
---@param name string
function SWEP:removeAction( action, name )
    local actions = self.actions[ action ]

    if actions ~= nil then
        local count = actions[ 0 ]
        for i = 1, count do
            if actions[ i ][ 1 ] == name then
                table.remove( actions, i )

                count = count - 1
                break
            end
        end

        actions[ 0 ] = count
    end
end

---@param action string
---@param ... any
function SWEP:actionRun( action, ... )
    ---@type table<string, table<number, any>>
    self.actions = self.actions or {}

    local actions = self.actions[ action ]

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
    return math_floor( self:getShoot() )
end

function SWEP:addKick( ang )
    local p, y, r = self:getKickCurX(), self:getKickCurY(), self:getKickCurZ()

    local viewPunchMax = self.ViewKickMax

    p = math.clamp( p + ang.x, -viewPunchMax.x, viewPunchMax.x )
    y = math.clamp( y + ang.y, -viewPunchMax.y, viewPunchMax.y )
    r = math.clamp( r + ang.r, -viewPunchMax.z, viewPunchMax.z )

    local curtime = ash_firing_time()
    local curatt = self:GetNextPrimaryFire()
    local diff = curtime - curatt

    if diff > engine.TickInterval() or diff < 0 then
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

    if not (owner ~= nil and owner:IsValid()) then
        return
    end

    local shoot = self:getShoot()
    ---@cast owner Player

end

function SWEP:GetKick()
    return Angle( math.round( self:getKickCurX(), 3 ) , math.round( self:getKickCurY(), 3 ), math.round( self:getKickCurZ(), 3 ) )
end

do
    local data = {}
    ---@return Angle
    function SWEP:getShootAngle( angle )
        local owner = self:GetOwner()
        if not (owner ~= nil and owner:IsValid()) then
            return angle
        end

        local kick = self:GetKick()

        local ang = angle + kick + Player_GetViewPunchAngles( owner )
        data.angle = ang

        self:actionRun( "shootAngle", data )

        return data.angle
    end
end


---@param delay number
function SWEP:nextPrimaryFire( delay )
    local curtime = ash_firing_time()
    local curatt = self:GetNextPrimaryFire()
    local diff = curtime - curatt

    if diff > engine.TickInterval() or diff < 0 then
        curatt = curtime
    end

    self:SetNextPrimaryFire( curatt + delay )
end

---@param delay number
function SWEP:nextSecondaryFire( delay )
    local curtime = ash_firing_time()
    local curatt = self:GetNextSecondaryFire()
    local diff = curtime - curatt

    if diff > engine.TickInterval() or diff < 0 then
        curatt = curtime
    end

    self:SetNextSecondaryFire( curatt + delay )
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
    net.Receive( "primary_fire", function()
        local start = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
        local hit = Vector( net.ReadDouble(), net.ReadDouble(), net.ReadDouble() )
        timer.Simple( 0.25, function()
            server_hits[ #server_hits + 1 ] = { start, hit }
        end )

    end )
end

do

    local data = {}
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
        local damage = damage_max

        if current_distance < start_distance then
            damage = damage_max
        elseif current_distance >= start_distance and current_distance <= stop_distance then
            damage = damage_max - (damage_max - damage_min) * (current_distance - start_distance) / (stop_distance - start_distance)
        elseif current_distance > stop_distance then
            damage = damage_min
        end

        data.damage = damage
        data.current_distance = current_distance
        data.stop_distance = stop_distance
        data.start_distance = start_distance
        data.damage_max = damage_max
        data.damage_min = damage_min

        self:actionRun( "calcDamageDistance", data )

        return data.damage
    end
end

function SWEP:getPrimaryDamage()
    return self.Primary.Damage
end

function SWEP:getPrimaryDamageMin()
    return self.Primary.DamageMin
end

---@type ash.trace.Output
---@diagnostic disable-next-line: missing-fields
local trace_result_size = {}

---@type ash.trace.Params
local trace_size = {
    output = trace_result_size
}

local function penetraitTrace( dir, filter, filter_map )
    local p_start = trace_result.HitPos + (dir * 16)
    trace.start = p_start
    trace.endpos = p_start + dir * dist_limit
    trace.filter = filter
    trace.mask = MASK_SHOT

    trace_cast( trace )

    local entity = trace_result.Entity
    if entity ~= nil and not filter_map[ entity ] then
        filter[ #filter + 1 ] = entity
        filter_map[ entity ] = true
    end

    if trace_result.StartSolid then
        for i = 1, 4 do
            trace.start = trace_result.StartPos
            trace.endpos = trace_result.HitPos
            trace.filter = filter
            trace.mask = MASK_SHOT
            trace_cast( trace )

            if not trace_result.StartSolid then
                break
            end

            entity = trace_result.Entity
            if entity ~= nil and not filter_map[ entity ] then
                filter[ #filter + 1 ] = entity
                filter_map[ entity ] = true
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
    if self:getSilencerTime() > 0 then
        return false
    end

    if self:getInReload() then
        return false
    end

    if self:getBurstCountCur() > 0 then
        return false
    end

    if self:getIsMissfire() then
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
        data.seed = ash_firing_time()
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

    if target and target:IsValid() and (target:IsNPC() or target:IsPlayer()) then
        bullet_effect.effects = false
    else
        bullet_effect.effects = true
    end

    dmginfo:SetDamage( 0 )

    return bullet_effect
end


local distance_limit = 65536

local hits = {}

--[[
function SWEP:PrimaryAttack()
    if not self:canPrimaryAttack() then
        return
    end

    local curTime = ash_firing_time()
    local owner = self:GetOwner()

    if not (owner ~= nil and owner:IsValid()) then
        return
    end

    if self:getClip1() <= 0 then
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
    self:takePrimaryAmmo( 1 )

    local insight = self:getInSight()

    if not self.Secondary.NoRecoverSight then
        if insight then
            self:setInSight(false)
            self:setRecoverSight(curTime + (delay * 0.9))
        elseif self:getRecoverSight() > 0 then
            self:setRecoverSight(curTime + (delay * 0.9))
        end
    end

    if self:getClip1() <= 0 and self:canReload() then
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

function SWEP:emitSound( sound_name, sound_level, pitch, volume, channel, sound_flags, dsp )
    local owner = self:GetOwner()

    if not ( owner ~= nil and owner:IsValid() ) then
        return
    end
    ---@cast owner Player

    local isPlayer = owner:IsPlayer()

    if CLIENT then
        if LocalPlayer() == owner then
            self:EmitSound( sound_name, sound_level, pitch, volume, channel, sound_flags, dsp )
        end
    else
        local rf = RecipientFilter()
        rf:AddPAS( self:EyePos() )
        if isPlayer then
            rf:RemovePlayer( owner )
        end

        self:EmitSound( sound_name, sound_level, pitch, volume, channel, sound_flags, dsp, rf )
    end
end

function SWEP:calcKick( )
    local owner = self:GetOwner()

    ---@cast owner Player
    if not ( owner ~= nil and IsValid( owner ) ) then
        return
    end

    local kick = self.ViewKickList
    local ang = kick and kick [ math_min( math_max( self:getCurShoot(), 1 ), #kick ) ] or angle_zero

    local random_kick_min = self.KickRandomMin
    local random_kick_max = self.KickRandomMax

    local random_kick = Angle( ash_firing.randomNumber( owner, random_kick_min.x, random_kick_max.x ), ash_firing.randomNumber( owner, random_kick_min.y, random_kick_max.y ), ash_firing.randomNumber( owner, random_kick_min.z, random_kick_max.z ) )

    local stability = self.KickRandomStability

    random_kick[ 1 ] = random_kick[ 1 ] * stability[ 1 ]
    random_kick[ 2 ] = random_kick[ 2 ] * stability[ 2 ]
    random_kick[ 3 ] = random_kick[ 3 ] * stability[ 3 ]

    ang = ang + random_kick
    local mult = self.KickMult
    ang[ 1 ] = ang[ 1 ] * mult[ 1 ]
    ang[ 2 ] = ang[ 2 ] * mult[ 2 ]
    ang[ 3 ] = ang[ 3 ] * mult[ 3 ]

    return ang
end

do
    local data = {}
    function SWEP:calcDamage( target, tr_result )
        local position_start, position_end = tr_result.StartPos, tr_result.HitPos
        local distance = position_start:Distance( position_end )
        local damage = self:calculateDamageDistance( distance, self.Primary.DistanceMax, self.Primary.DistanceMin, self:getPrimaryDamage(), self:getPrimaryDamageMin() )

        damage = damage * self:getHitgroupScale( tr_result.HitGroup )
        data.damage = damage
        data.target = target
        data.trace_result = tr_result
        data.distance = distance

        self:actionRun( "calcDamage", data )

        return data.damage
    end
end

---@param owner Player
---@param position Vector
---@param angle Angle
---@param time number
function SWEP:primaryAttack( owner, position, angle, time )
    if not self:canPrimaryAttack() then
        return
    end

    local curTime = ash_firing_time()

    -- print( "randomNumber",  )

    if self:getClip1() <= 0 then
        self:SetNextPrimaryFire( curTime + 1 )
        return
    end

    if CLIENT and self.Primary.Shaking then
        util.ScreenShake( vector_origin, self.Primary.ShakeAmlitude, self.Primary.ShakeFrequency, self.Primary.ShakeDuration, 0 )
    end

    self:setReloadManualTime( 0 )
    self:setManualReloadingStart( false )

    ---kick
    do
        self:addKick( self:calcKick( ) )
        self:setShootReset( curTime + .5 )
        self:setShoot( self:getCurShoot() + 1 )
    end

    ---reability
    do
        local new_reability = math_max( self:getReabilityAmount() - 1, 0 )
        self:setReabilityAmount( new_reability )

        if new_reability <= 0 then
            local new_missfire = math_min( self:getReabilityMissfireChance() + 1, 100 )

            if new_missfire >= ash_firing.randomNumber( owner, 0, 100 ) then
                self:setIsMissfire( true )
            end

            self:setReabilityMissfireChance( new_missfire )
        end
    end

    ---sound
    self:emitSound( self:getSilencer() and self.Primary.SoundSilencer or self.Primary.Sound )

    self:takePrimaryAmmo( 1 )

    local dir = Angle_Forward( angle )

    local spread = self:calcSpread()
    local y = spread.y / 500
    local z = spread.z / 500
    local origin_dir = dir
    dir = LocalToWorld( Vector( 0, ash_firing.randomNumber( owner, -y, y ), ash_firing.randomNumber( owner, -z, z ) ), angle_zero, origin_dir, angle )

    self:setDelayFire( curTime + self:getRateOfFire() )

    if not self.PumpAnim then
        self:playVM( self:getSilencer() and ACT_VM_PRIMARYATTACK_SILENCED or ACT_VM_PRIMARYATTACK )
    else
        self:playVM( self:getAnimation( "pump" ), 1, true )
    end


    self:setBufferedClick( false )

    for i = 1, self.Primary.BulletCountOnShoot do
        dir = LocalToWorld( Vector( 0, ash_firing.randomNumber( owner, -y, y ), ash_firing.randomNumber( owner, -z, z ) ), angle_zero, origin_dir, angle )

        local tr_result = ash_firing.fireBullet( time, owner, position, dir )

        if CLIENT then
            hits[ #hits + 1 ] = { tr_result.StartPos, tr_result.HitPos, Color( 255, 255, 0 ), curTime + 30 }

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

            local target = tr_result.Entity

            if target ~= nil and target:IsValid() then
                local dmginfo = DamageInfo()
                dmginfo:SetDamageType( DMG_BULLET )
                dmginfo:SetAttacker( owner )
                dmginfo:SetInflictor( self )
                dmginfo:SetWeapon( self )
                dmginfo:SetDamage( self:calcDamage( target, tr_result ) )
                dmginfo:SetReportedPosition( tr_result.StartPos )
                dmginfo:SetDamagePosition( tr_result.HitPos )

                target:TakeDamageInfo( dmginfo )
            end

        end
    end
end

function SWEP:Reload()

end

function SWEP:reload( owner, reload_delay )
    local cur_time = ash_firing_time()
    if not self:getIsMissfire() then
        if not self:canReload() then
            return
        end

        if self:getInSight() then
            self:toogleADS()
        end

        self:setInSight( false )
        self:setRecoverSight( 0 )
        self:setDelayAnim( 0 )

        reload_delay      = reload_delay or 0

        local anim, isSeq = self:getAnimation( "reload" )
        local time = cur_time + self:getAnimationTime( anim )

        if self.ReloadEmptyAnim and self:getClip1() == 0 then
            anim, isSeq = self:getAnimation( "reload_empty" )
            time = cur_time + self:getAnimationTime( anim )
        end

        if reload_delay > 0 then
            self:setReloadDelay( cur_time + reload_delay )
        else
            if not self.ManualReloading then
                self:setInReload( true )
                self:setReloadTime( time )
                anim = self:getSilencer() and ACT_VM_RELOAD_SILENCED or ACT_VM_RELOAD

                if self.ReloadEmptyAnim then
                    if self:getClip1() <= 0 then
                        anim = self:getAnimation( "reload_empty" )
                    end
                end

                self:playVM( anim )
            else
                anim, isSeq = self:getAnimation( "reload_manual_start" )
                self:playVM( anim, 1, false )
                self:setManualReloadingStart( true )

                local time_reload = (self:getAnimationTime( anim ) )
                self:setReloadManualTime( cur_time + time_reload )

                anim = self:getAnimation( "reload" )
                if self.ManualReloadingSkipFirst then
                    self:setManualReloadingSkipFirst( true )
                    anim = self:getAnimation( "reload_manual_start" )
                end

                time_reload = time_reload + ( self:getAnimationTime( anim ) )

                self:nextPrimaryFire( time_reload )
                self:nextSecondaryFire( time_reload )
            end
        end
    elseif self:getIsMissfireFixing() <= 0 then
        local anim, isSeq = self:getAnimation( "reload" )
        local time = cur_time + self:getAnimationTime( anim )
        self:setIsMissfireFixing( time )
        self:setIsMissfireFixingFastTime( cur_time + 0.5 )
        self:setIsMissfireFixingIsFast( false )

        self:playVM( anim, 1, true )
    elseif not self:getIsMissfireFixingIsFast() and cur_time <= self:getIsMissfireFixingFastTime() then
        local anim, isSeq = self:getAnimation( "reload" )
        local time = cur_time + ( self:getAnimationTime( anim ) * 0.5 )
        self:setIsMissfireFixing( time )
        self:setIsMissfireFixingIsFast( true )

        self:playVM( anim, 2, true )
    end

    print( "reloading!" )
end

---@param owner Player
---@param position Vector
---@param angle Angle
function SWEP:secondaryAttack( owner, position, angle )
    self:setInScope( not self:getInScope() )
end

--- Resolves a sequence index from an activity (number) or a sequence name (string).
---@param vm Entity Viewmodel entity
---@param anim ACT|string ACT_* enum or sequence name, e.g. "fire_01"
---@return integer seq Sequence index, or -1 if not found
function SWEP:lookupVMSeq( vm, anim )
    if isstring( anim ) then
        local seq = vm:LookupSequence( anim )
        return seq
    elseif isnumber( anim ) then
        return vm:SelectWeightedSequence( anim )
    end
    return -1
end

--- Returns the animation length in seconds without playing it.
---@param anim ACT|string ACT_* enum or sequence name
---@param rate? number Playback rate (default 1)
---@return number length Length in seconds adjusted by rate, 0 if the animation was not found
function SWEP:getVMAnimLength( anim, rate )
    local owner = self:GetOwner()
    if not IsValid( owner ) or not owner:IsPlayer() then return 0 end

    local vm = owner:GetViewModel( 0 )
    if not IsValid( vm ) then return 0 end

    local seq = self:lookupVMSeq( vm, anim )
    if seq < 0 then return 0 end

    rate = ( rate and rate > 0 ) and rate or 1
    return vm:SequenceDuration( seq ) / rate
end


--- Plays an animation on the viewmodel.
---@param anim integer|string ACT_* enum or sequence name ("fire_01")
---@param rate? number Playback rate (default 1)
---@param to_idle? boolean
function SWEP:playVM( anim, rate, to_idle )
    local owner = self:GetOwner()
    if not IsValid( owner ) or not owner:IsPlayer() then return 0 end

    local vm = owner:GetViewModel( 0 )
    if not IsValid( vm ) then return 0 end

    local seq = self:lookupVMSeq( vm, anim )
    if seq < 0 then return 0 end -- keep the current animation untouched

    rate = rate or 1
    local duration = vm:SequenceDuration( seq )

    if rate ~= 1 then
        duration = duration * ( 1 / rate )
    end

    if to_idle == nil then
        to_idle = true
    end

    self:setVMWeightedSequence( seq )
    self:setVMTime( CurTime() )
    self:setVMDuration( duration )
    self:setVMToIdle( to_idle )
end

if CLIENT then
    net.Receive( "bullet_effect", function()
        local t = { Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() ), Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() ), Color( 255, 0, 0 ), ash_firing_time() + 15 }
        timer.Simple( 1, function()
            hits[ #hits + 1 ] = t
        end )
    end )

    hook.Add( "PostDrawOpaqueRenderables", "Debug", function()
        for i = 1, #hits do
            local v = hits[ i ]

            render.DrawLine( v[ 1 ], v[ 2 ], v[ 3 ], true )

            if ash_firing_time() > v[ 4 ] then
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

--     local curTime = ash_firing_time()

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
--         self:setIdleTime( curTime + anim_time )
--     end

--     self:EmitSound( self:getSilencer() and self.Primary.SoundSilencer or self.Primary.Sound )
-- end

--[[
function SWEP:PrimaryAttack()
    if not self:canPrimaryAttack() then
        return
    end

    local curTime = ash_firing_time()
    local owner = self:GetOwner()

    if not (owner ~= nil and owner:IsValid()) then
        return
    end

    if self:getClip1() <= 0 then
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
    self:takePrimaryAmmo( 1 )

    local insight = self:getInSight()

    if not self.Secondary.NoRecoverSight then
        if insight then
            self:setInSight(false)
            self:setRecoverSight(curTime + (delay * 0.9))
        elseif self:getRecoverSight() > 0 then
            self:setRecoverSight(curTime + (delay * 0.9))
        end
    end

    if self:getClip1() <= 0 and self:canReload() then
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
    local time = self:getAnimationTime( anim )

    local ct = ash_firing_time()
    self:setSilencerTime( ct + time )
    self:setIdleTime( ct + time )
    self:playVM( anim )
    self:nextPrimaryFire( time )
    self:nextSecondaryFire( time )
end

function SWEP:AdjustMouseSensitivity( defaultSensitivity, localFOV, defaultFOV )
    local pl = self:GetOwner()
    ---@cast pl Player


    if IsValid( pl ) and pl.GetFOV then
        local fov = pl:GetFOV() * (self.Secondary.SightStateZoom[ self:getSightState() ] or 1)
        local max_fov = 90

        if self:getInSight() and fov < max_fov then
            local diff = max_fov - fov

            local percent = (diff / max_fov)
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
        self:setInSight( true )
        self:setSightState( 1 )
    elseif insight and state < #(self.Secondary.SightStateZoom) then
        self:setSightState( state + 1 )
    else
        self:setInSight( false )
        self:setSightState( 0 )
    end

    self:EmitSound( self.Secondary.SightSound )

    self:nextSecondaryFire( 0.3 )
end

function SWEP:SecondaryAttack()

end
