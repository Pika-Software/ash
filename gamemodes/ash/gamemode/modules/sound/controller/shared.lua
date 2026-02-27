local Entity_GetNW2Var = Entity.GetNW2Var
local Entity_SetNW2Var = Entity.SetNW2Var
local Entity_IsValid = Entity.IsValid
local tostring = tostring

---@type ash.sound.bass
local bass = require( "ash.sound.bass" )


---@class ash.sound.bass.Controller : dreamwork.Object
---@field __class ash.sound.bass.ControllerClass
---@field private m_sName string The name of the controller object.
local Controller = class.base( "ash.sound.bass.Controller", false )

---@return string | nil
function Controller:getSource()
    return Entity_GetNW2Var( self, "m_sSource", "" )
end

---@param url string
function Controller:setSource( url )
    Entity_SetNW2Var( self, "m_sSource", tostring( url ) )
end

---@return string
function Controller:getName()
    return self.m_sName
end

---@type table<string, ash.sound.bass.Controller>
local controllers = {}
gc.setTableRules( controllers, false, true )

---@param name string
---@protected
function Controller:__init( name )
    controllers[ name ] = self
    self.m_sName = name
end

---@class ash.sound.bass.ControllerClass : ash.sound.bass.Controller
---@field __base ash.sound.bass.Controller
---@overload fun( name: string ): ash.sound.bass.Controller
local ControllerClass = class.create( Controller )

if SERVER then

    MODULE.Networks = {
        "sync"
    }

    function Controller:play()

    end

end

if CLIENT then


end


return ControllerClass
