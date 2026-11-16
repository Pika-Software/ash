MODULE.ClientFiles = {
	"cl_init.lua",
}

MODULE.Networks = {
	"input",
	"input_ack",
	"hitbox",
}

---@class ash.firing
local firing = include "shared.lua"

---@type ash.player
local ash_player = import "ash.player"

---@type ash.entity
local ash_entity = import "ash.entity"

local bit_band = bit.band
local math_clamp = math.clamp

local developer = GetConVar( "developer" )

local CurTime = CurTime
local Entity_GetHitBoxBone = Entity.GetHitBoxBone
local Entity_GetHitBoxBounds = Entity.GetHitBoxBounds
local Entity_GetBonePosition = Entity.GetBonePosition
local Entity_GetHitBoxCount = Entity.GetHitBoxCount

local Player_GetShootPos = Player.GetShootPos
local Player_GetActiveWeapon = Player.GetActiveWeapon
local Entity_GetClass = Entity.GetClass
local table_removeByValue = table.removeByValue

local in_allowed = firing.in_allowed

local tick_count = 16

local entities_snapshots = firing.entities_snapshots

local table_remove = table.remove

local compensation_entities = firing.compensation_entities

---@type table< Entity, boolean >
local compensation_entities_map = firing.compensation_entities_map

local allowedLagCompensationEntity = {}
firing.allowedLagCompensationEntity = allowedLagCompensationEntity

timer.Simple( 1, function()
	for _, entity in ash_entity.iterator() do
		if entity:IsPlayer() or entity:IsNPC() or allowedLagCompensationEntity[ Entity_GetClass( entity ) ] and not compensation_entities_map[ entity ] then
			local count = compensation_entities[ 0 ] + 1

			---@diagnostic disable-next-line: assign-type-mismatch
			compensation_entities[ count ] = entity
			compensation_entities[ 0 ] = count

			compensation_entities_map[ entity ] = true
		end
	end
end )

do
	concommand.Add( "frng_entity", function( pl )
		for i = 1, compensation_entities[ 0 ] do
			local entity = compensation_entities[ i ]

			pl:PrintMessage( HUD_PRINTCONSOLE, tostring( entity ) .. "\n" )
		end
	end )

	local function addEntity( entity )
		if entity:IsPlayer() or entity:IsNPC() or allowedLagCompensationEntity[ Entity_GetClass( entity ) ]  and not compensation_entities_map[ entity ] then
			local count = compensation_entities[ 0 ] + 1

			---@diagnostic disable-next-line: assign-type-mismatch
			compensation_entities[ count ] = entity
			compensation_entities[ 0 ] = count

			compensation_entities_map[ entity ] = true
		end
	end

	local function removeEntity( entity )
		if entity:IsPlayer() or entity:IsNPC() or allowedLagCompensationEntity[ Entity_GetClass( entity ) ]  and compensation_entities_map[ entity ] then
			local count = compensation_entities[ 0 ]

			compensation_entities_map[ entity ]  = nil

			if table_removeByValue( compensation_entities, entity, count ) then
				count = count - 1

				compensation_entities[ 0 ] = count
			end
		end
	end

	hook.Add( "OnEntityCreated", "CompensationEntity", function( entity )
		if entity ~= nil and entity:IsValid() then
			addEntity( entity )
		end
	end )

	hook.Add( "EntityRemoved", "CompensationEntity", function( entity )
		if entity ~= nil and entity:IsValid() then
			removeEntity( entity )
		end
	end )

	---@param pl Player
	hook.Add( "ash.player.PostSpawn", "CompensationEntity", function( pl )
		addEntity( pl )
	end )

	---@param pl Player
	hook.Add( "ash.player.PostDeath", "CompensationEntity", function( pl )
		removeEntity( pl )
	end )

	hook.Add( "OnNPCKilled", "CompensationEntity", function( npc )
		removeEntity( npc )
	end )
end

hook.Add( "Tick", "LagCompensation", function( )
	for i = 1, compensation_entities[ 0 ] do
		local entity = compensation_entities[ i ]

		---@diagnostic disable-next-line: cast-type-mismatch
		---@cast entity Entity
		local ct = CurTime()
		local poses = { }

		local count = Entity_GetHitBoxCount( entity, 0 )

		for j = 0, count - 1 do
			local mins, maxs = Entity_GetHitBoxBounds( entity, j, 0 )
			local pos, ang = Entity_GetBonePosition( entity, Entity_GetHitBoxBone( entity, j, 0 ) )

			poses[ j + 1 ] = { pos, ang, mins, maxs, entity:GetHitBoxHitGroup( j, 0 ) }
		end

		poses[ 0 ] = count

		local snapshots = entities_snapshots[ entity ]
		local snapshots_count = snapshots[ 0 ]

		---@cast snapshots_count number

		if snapshots_count + 1 > tick_count then
			table_remove( snapshots, 1 )
			snapshots_count = snapshots_count - 1
		end

		snapshots_count = snapshots_count + 1
		snapshots[ snapshots_count ] = { ct, poses }

		snapshots[ 0 ] = snapshots_count
	end
end )

do
	-- how many unprocessed inputs we keep per player
	local queue_limit = 16

	-- how many inputs are executed per server tick ( protects from burst after lag spike )
	local steps_per_tick = 4

	-- client time is accepted only in this window around server time
	local time_back = 0.5
	local time_forward = 0.25

	-- how far from server shoot position the client position can be
	local origin_error_sqr = 128 * 128

	-- seq jump back bigger than this means client restarted its counter
	local reset_threshold = 256

	--- Queue is stored in the same table: items are input[ head ] ... input[ head + input[ 0 ] - 1 ]
	---@type table<Player, table>
	local players_input = setmetatable( { }, {
		__index = function( self, pl )
			local tbl = { [ 0 ] = 0, head = 1, last_seq = 0, last_time = 0 }

			rawset( self, pl, tbl )

			return tbl
		end
	} )

	gc.setTableRules( players_input, true )
	gc.setup( players_input, "Entity" )

	-- Client -> server, unreliable. Every packet repeats all inputs which are not acked yet,
	-- so a lost packet does not lose input. Sequence is contiguous: first_seq + i.
	net.Receive( "input", function( _, pl )
		local input = players_input[ pl ]

		local first_seq = net.ReadUInt( 32 )
		local count = net.ReadUInt( 5 )

		local last_seq = input.last_seq

		if first_seq + count - 1 < last_seq - reset_threshold then
			last_seq = first_seq - 1

			input.last_time = 0
		end

		local queue_count = input[ 0 ]

		for i = 0, count - 1 do
			local time = net.ReadDouble()
			local in_mask = net.ReadUInt( 16 )
			local weapon_index = net.ReadUInt( 13 )

			local px, py, pz = net.ReadDouble(), net.ReadDouble(), net.ReadDouble()
			local ap, ay, ar = net.ReadDouble(), net.ReadDouble(), net.ReadDouble()

			local cseq = first_seq + i

			-- history repeats old inputs, we take only new ones
			if cseq > last_seq then
				if cseq > last_seq + 1 and last_seq > 0 and developer:GetBool() then
					print( "[firing] input gap", pl, "last", last_seq, "got", cseq )
				end

				last_seq = cseq

				input[ input.head + queue_count ] = {
					cseq,
					time,
					bit_band( in_mask, in_allowed ),
					weapon_index,
					Vector( px, py, pz ),
					Angle( ap, ay, ar ),
				}

				queue_count = queue_count + 1

				if queue_count > queue_limit then
					input[ input.head ] = nil
					input.head = input.head + 1

					queue_count = queue_count - 1
				end
			end
		end

		input[ 0 ] = queue_count
		input.last_seq = last_seq

		-- always ack, even if nothing is new: client resends until it gets the ack
		net.Start( "input_ack", true )
		net.WriteUInt( last_seq, 32 )
		net.Send( pl )
	end )

	---@param pl Player
	---@param input table
	---@param step table
	---@param ct number
	local function runStep( pl, input, step, ct )
		-- shooter timeline: inside the window and never goes back
		local time = math_clamp( step[ 2 ], ct - time_back, ct + time_forward )

		if time < input.last_time then
			time = input.last_time
		end

		input.last_time = time

		local in_mask = step[ 3 ]
		local wep = Entity( step[ 4 ] )

		---@cast wep ash_weapon_base
		if pl:Alive() and wep:IsValid() and wep.IsAshWeapon and wep == Player_GetActiveWeapon( pl ) then

			-- angle is taken from the client as is, position only if it is close to the server one
			local position = step[ 5 ]
			local shoot_pos = Player_GetShootPos( pl )

			if position:DistToSqr( shoot_pos ) > origin_error_sqr then
				position = shoot_pos
			end

			firing.sharedFiring( pl, wep, in_mask, position, step[ 6 ], time, step[ 1 ] )
		else
			-- can not shoot, but button states must follow the client
			if developer:GetBool() then
				print( "[firing] input skipped", pl, "seq", step[ 1 ], "alive", pl:Alive(), "weapon", wep, "active", Player_GetActiveWeapon( pl ) )
			end

			firing.updateButtons( pl, in_mask )
		end
	end

	hook.Add( "Tick", "ash.firing.InputRun", function()
		local ct = CurTime()

		for _, pl in ash_player.iterator( true, true ) do
			local input = players_input[ pl ]

			local steps = 0

			while input[ 0 ] > 0 and steps < steps_per_tick do
				local head = input.head
				local step = input[ head ]

				-- сначала обновляем очередь, чтобы ошибка в runStep её не ломала
				input[ head ] = nil
				input.head = head + 1
				input[ 0 ] = input[ 0 ] - 1

				steps = steps + 1

				if step then
					local ok, err = pcall( runStep, pl, input, step, ct )

					if not ok then
						ErrorNoHalt( "[firing] runStep error: ", err, "\n" )
					end
				end
			end

			if input[ 0 ] == 0 then
				input.head = 1
			end
		end
	end )
end

return firing
