---@class ash.player
local ash_player = require( "ash.player" )

---@class flame.camera.body
local camera = {}

local Vector_SetUnpacked = Vector.SetUnpacked
local Vector_Unpack = Vector.Unpack

local Vector_Add = Vector.Add
local Vector_Sub = Vector.Sub

local Vector_Mul = Vector.Mul
local Vector_Div = Vector.Div

local math_min, math_max = math.min, math.max
local math_lerp = math.lerp
local math_sin = math.sin
local math_abs = math.abs

local FrameTime = FrameTime
local CurTime = CurTime

local getEyePos = alium_lobby.getEyePos

-- local buffer_origin = view_Data.origin

-- local view_height = MainEyePos()[ 3 ]

---@type integer
local history_size = 20

---@type Vector[]
local position_history = { [ 0 ] = 0 }

---@type Angle[]
local angles_history = { [ 0 ] = 0 }

local eyes_origin_local = Vector( 0, 0, 0 )

local animator = ash_player.animator
local animator_getVelocity = animator.getVelocity

local reset_blend = 0
local reset_time  = 0.12

local function camera_reset( pl )
    local eyes_position = getEyePos( pl )
    Vector_Sub( eyes_position, pl:GetPos() )
    Vector_Add( eyes_position, animator_getVelocity( pl ) * FrameTime() )

    for i = 1, position_history[ 0 ], 1 do
        position_history[ i ] = eyes_position
    end
end

--hook.Add( "ash.player.CrouchingAnimation", "Camera", camera_reset, PRE_HOOK )
-- hook.Add( "ash.player.Sequence", "Camera",  print, PRE_HOOK )

hook.Add( "ash.player.animator.Activity", "Camera", function( pl, act, act2 )
    if not ash_player.isLocal( pl ) then return end

    if act == ash_player.animator.getStandActivity( pl ) then
        camera_reset( pl )
        reset_blend = 1
    end
    if act2 == ash_player.animator.getStandActivity( pl ) then
        reset_blend = 1.5
    end
end, PRE_HOOK )

local yaw_center = 0.5
local yaw_tolerance = 0.01
local yaw_jump = 0.01

local yaw_last = nil

hook.Add( "ash.player.Think", "AimYawReset", function( pl, is_local )
    if not is_local then return end

    local id = pl:LookupPoseParameter( "aim_yaw" )
    if not id or id < 0 then return end

    local yaw = pl:GetPoseParameter( "aim_yaw" )

    if yaw_last then

        local delta = math_abs( yaw - yaw_last )

      --  local offCenter = math_abs( yaw_last - yaw_center ) > yaw_tolerance
      --  local centered = math_abs( yaw - yaw_center ) < yaw_tolerance
        local jumped = delta >= yaw_jump

        if jumped then
            hook.Run( "ash.player.AimYawReset", pl, yaw, delta )
        end
    end

    yaw_last = yaw

end )

hook.Add( "ash.player.AimYawReset", "Camera", function( pl )
    if not ash_player.isLocal( pl ) then return end
    if pl:GetSequenceActivity( pl:GetSequence() ) == pl:TranslateWeaponActivity(  ash_player.animator.getStandActivity( pl ) ) then
        camera_reset( pl )
        reset_blend = 1
    end
end )

---@param pl Player
hook.Add( "ash.player.Think", "Camera", function( pl, is_local )
    if not is_local then return end

    local eyes_position = getEyePos( pl )
    Vector_Sub( eyes_position, pl:GetPos() )
    Vector_Add( eyes_position, animator_getVelocity( pl ) * FrameTime() )

    if not ash_player.isOnGround( pl ) then
        Vector_SetUnpacked( eyes_origin_local, Vector_Unpack( eyes_position ) )
        return
    end

    if position_history[ 0 ] > 0 then
        if reset_blend > 0 then
            local t = FrameTime() / reset_time
            reset_blend = math_max( reset_blend - t, 0 )

            for i = 1, position_history[ 0 ] do
                if position_history[ i ] then
                    local p = position_history[ i ]

                    p[1] = Lerp( t, p[1], eyes_position[1] )
                    p[2] = Lerp( t, p[2], eyes_position[2] )
                    p[3] = Lerp( t, p[3], eyes_position[3] )
                end
            end
        end
    end

    if pl:GetSequenceActivity( pl:GetSequence() ) == pl:TranslateWeaponActivity(  ash_player.animator.getStandActivity( pl ) ) and reset_blend == 0 then
        if position_history[ 1 ] then
            eyes_origin_local = position_history[ 1 ]
            return
        end
    end

    Vector_SetUnpacked( eyes_origin_local, Vector_Unpack( eyes_position ) )

    local positions_count = position_history[ 0 ]

    for i = math_max( 0, positions_count - 1 ), 1, -1 do
        local origin = position_history[ i ]
        position_history[ i + 1 ] = origin

        ---@diagnostic disable-next-line: param-type-mismatch
        Vector_Add( eyes_origin_local, origin )
    end

    positions_count = math_min( positions_count + 1, history_size )

    position_history[ 0 ] = positions_count
    position_history[ 1 ] = eyes_position

    Vector_Div( eyes_origin_local, positions_count )
end )

---@param pl Player
---@return Vector origin
function camera.getPosition( pl )
    local eyes_position = pl:GetPos()
    Vector_Add( eyes_position, eyes_origin_local )
    return eyes_position
end


return camera
