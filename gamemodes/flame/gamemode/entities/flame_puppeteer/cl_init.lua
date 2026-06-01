include( "shared.lua" )

---@type ash.entity
local ash_entity = import "ash.entity"

---@class flame_puppeteer : ENT
local ENT = ENT

ENT.Type = "anim"

---@diagnostic disable-next-line: duplicate-set-field
function ENT:Initialize()

end

function ENT:Draw()
end

ENT.DrawTranslucent = ENT.Draw


-- hook.Add( "CalcView", "flame_puppeteer_calcview", function( ply, pos, ang, fov )

-- end )
