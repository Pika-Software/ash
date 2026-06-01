---@class flame_puppeteer : ENT
---@field RagdollEntity Entity
---@field GetPuppet fun( self: flame_puppeteer ): Entity
---@field SetPuppet fun( self: flame_puppeteer, puppet: Entity )
local ENT = ENT

ENT.Type = "anim"

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Puppet" )
end
