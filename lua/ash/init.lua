ash.send( "/" .. ash.ChainFile )
ash.send( "/ash/cl_init.lua" )
ash.resend()

ash.reload()

ash.performWorkshopDL()

ash.rebuild( true )
ash.send( "/" .. ash.WorkshopFile )

ash.Logger:info( "Ashes calls you, %s. %s awaits.", cvars.String( "hostname", "unknown" ), ash.Chain[ 1 ].title )
