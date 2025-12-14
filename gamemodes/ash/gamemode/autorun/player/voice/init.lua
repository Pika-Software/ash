local Entity_GetNW2Float = Entity.GetNW2Float
local Entity_SetNW2Float = Entity.SetNW2Float

---@class ash.player.voice
local ash_voice = {}

--- [SERVER]
---
--- Gets the player's voice volume scale.
---
---@param pl Player
---@return number scale The player's voice volume scale. Range is from 0 to 1.
function ash_voice.getVolumeScale( pl )
    return Entity_GetNW2Float( pl, "m_fVoiceVolumeScale", 1 )
end

--- [SERVER]
---
--- Sets the player's voice volume scale.
---
---@param pl Player
---@param scale number
---@diagnostic disable-next-line: duplicate-set-field
function ash_voice.setVolumeScale( pl, scale )
    Entity_SetNW2Float( pl, "m_fVoiceVolumeScale", scale )
end

return ash_voice
