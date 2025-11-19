ash.reload()
ash.Logger:info( "Ashes calls you, %s. %s awaits.", cvars.String( SERVER and "hostname" or "name", "unknown" ), ash.Chain[ 1 ].title )
