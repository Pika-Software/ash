local logger = ash.Logger

ash.send( "/" .. ash.ChainFile )
ash.send( "/ash/cl_init.lua" )
ash.resend()

ash.reload()

do

    local workshop_list, workshop_length = ash.getWorkshopDL()
    local resource_AddWorkshop = _G.resource.AddWorkshop

    for i = 1, workshop_length, 1 do
        local wsid = workshop_list[ i ]
        resource_AddWorkshop( wsid )
        logger:info( "Workshop item '%s' added to content watcher list.", wsid )
    end

end

ash.rebuild( true )
ash.send( "/" .. ash.WorkshopFile )

logger:info( "Ashes calls you, %s. %s awaits.", cvars.String( "hostname", "unknown" ), ash.Chain[ 1 ].title )
