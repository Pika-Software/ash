_G.require( "niknaks" )

if not _G.NikNaks then
	error( "NikNaks library needed!" )
end

---@type ash.player
local ash_player = import "ash.player"

---@class ash.bsp
local bsp = {}

local Entity_EyePos = Entity.EyePos

---@type table< Player, Vector >
local player_pos = setmetatable( {}, {
    __index = function( self, entity )
        local position = vector_origin

        rawset( self, entity, position )

        return position
    end
} )

---@type table< Player, number >
local player_leafcluster = setmetatable( {}, {
    __index = function( self, entity )
        rawset( self, entity, -1 )

        return -1
    end
} )

local map = NikNaks.CurrentMap

bsp.CurrentMap = map

local hook_Run = hook.Run

timer.Create( "ash.bsp.ClusterThink", 1, 0, function()
	for _, pl in ash_player.iterator( false, true ) do
		local position = Entity_EyePos( pl )
		local cur_cluster = player_leafcluster[ pl ]
		if position ~= cur_cluster then
			player_pos[ pl ] = position

			local leaf = map:PointInLeaf( 0, position )

			if leaf then
				local cluster = leaf.cluster

				if cluster ~= player_leafcluster[ pl ] then
					hook_Run( "ash.bsp.PlayerChangeCluster", pl, position, cur_cluster, cluster )

					player_leafcluster[ pl ] = cluster
				end
			end
		end
	end
end)

return bsp
