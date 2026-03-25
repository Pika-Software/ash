local Entity_GetClass = Entity.GetClass
local Entity_GetAngles = Entity.GetAngles
local Entity_GetPos = Entity.GetPos
local Entity_SetParent = Entity.SetParent

---@class ash.camera : ENT
local ENT = ENT

ENT.Type = "anim"

function ENT:Initialize()
	self:SetMoveType( MOVETYPE_NONE )
	self:SetNoDraw( true )
	self:DrawShadow( false )
end

hook.Add( "OnEntityCreated", "Defaults", function( ent )
	if Entity_GetClass( ent ) == "point_viewcontrol" then
		timer.Simple( 0, function()
			if not IsValid( ent ) then
				return
			end

			local camera = ents.Create( "ash_camera" )
			camera:SetPos( Entity_GetPos( ent ) )
			camera:SetAngles( Entity_GetAngles( ent ) )
			camera:Spawn()

			ash.Logger:debug( "Create ash_camera %s, parent to %s", camera, ent )

			Entity_SetParent( ent, camera )
		end )
	end
end )
