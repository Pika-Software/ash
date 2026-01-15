local Entity_GetNW2Float = Entity.GetNW2Float
local Entity_SetNW2Float = Entity.SetNW2Float
local hook_Run = hook.Run

---@type ash.player
local ash_player = ...

---@class ash.player.voice
local ash_voice = {}

--- [SHARED]
---
--- Gets the player's voice volume scale.
---
---@param pl Player
---@return number scale The player's voice volume scale. Range is from 0 to 1.
function ash_voice.getVolumeScale( pl )
    return Entity_GetNW2Float( pl, "m_fVoiceVolumeScale", 1 )
end

--- [SHARED]
---
--- Sets the player's voice volume scale.
---
---@param pl Player
---@param scale number
---@diagnostic disable-next-line: duplicate-set-field
function ash_voice.setVolumeScale( pl, scale )
    Entity_SetNW2Float( pl, "m_fVoiceVolumeScale", scale )
end

if CLIENT then

    local Player_GetVoiceVolumeScale = Player.GetVoiceVolumeScale
    local Player_SetVoiceVolumeScale = Player.SetVoiceVolumeScale
    local Player_IsVoiceAudible = Player.IsVoiceAudible
    local Player_VoiceVolume = Player.VoiceVolume

    --- [CLIENT]
    ---
    --- Checks if the player's voice is audible.
    ---
    ---@param pl Player
    function ash_voice.isAudible( pl )
        return hook_Run( "ash.player.voice.CanHear", ash_player.Entity, pl ) or Player_IsVoiceAudible( pl )
    end

    --- [CLIENT]
    ---
    --- Gets the player's voice volume.
    ---
    ---@return number volume The player's voice volume. Range is from 0 to 1.
    function ash_voice.getVolume( pl )
        local volume = Player_VoiceVolume( pl )
        return hook_Run( "ash.player.voice.Volume", pl, volume ) or volume
    end

    --- [CLIENT]
    ---
    --- Gets the player's voice volume scale.
    ---
    ---@return number scale The player's voice volume scale. Range is from 0 to 1.
    local function getVolumeScale( pl )
        local scale = Entity_GetNW2Float( pl, "m_fVoiceVolumeScale", 1 )
        return hook_Run( "ash.player.voice.VolumeScale", pl, scale ) or scale
    end

    ash_voice.getVolumeScale = getVolumeScale

    --- [CLIENT]
    ---
    --- Sets the player's voice volume scale.
    ---
    ---@param pl Player
    ---@param scale number
    ---@diagnostic disable-next-line: duplicate-set-field
    function ash_voice.setVolumeScale( pl, scale )
        Entity_SetNW2Float( pl, "m_fVoiceVolumeScale", scale )
    end

    hook.Add( "ash.player.Think", "VolumeController", function( pl, is_local )
        if is_local then return end

        local scale = getVolumeScale( pl )

        if Player_GetVoiceVolumeScale( pl ) ~= scale then
            Player_SetVoiceVolumeScale( pl, scale )
        end
    end, PRE_HOOK )

end

return ash_voice
