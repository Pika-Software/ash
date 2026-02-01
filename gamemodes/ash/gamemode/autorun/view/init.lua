MODULE.ClientFiles = {
    "cl_init.lua",
    "shared.lua"
}

MODULE.Networks = {
    "sync"
}

---@class ash.view
local ash_view = include( "shared.lua" )

do

    local Vector_SetUnpacked = Vector.SetUnpacked
    local Entity_SetNW2Var = Entity.SetNW2Var
    local Entity_IsValid = Entity.IsValid
    local net_ReadFloat = net.ReadFloat
    local hook_Run = hook.Run

    local temp_vector = Vector( 0, 0, 0 )

    net.Receive( "sync", function( _, pl )
        if Entity_IsValid( pl ) and pl:Alive() then
            Vector_SetUnpacked( temp_vector, net_ReadFloat(), net_ReadFloat(), net_ReadFloat() )
            Entity_SetNW2Var( pl, "m_vAim", temp_vector )

            hook_Run( "ash.view.AimVector", pl, temp_vector )
        end
    end )

end

return ash_view
