MODULE.Networks = {
    "network.Table"
}

local setmetatable = setmetatable
local os_clock = os.clock
local istable = istable
local pairs = pairs
local type = type
local net = net

---@class ash.network
local network = {}

network.begin = net.Start
network.abort = net.Abort
network.await = net.Receive

if CLIENT then
    network.send = net.SendToServer
else
    network.send = net.Send
end

network.len = net.BytesWritten
network.left = net.BytesLeft

network.readBit = net.ReadBool
network.writeBit = net.WriteBool

network.writeUInt = net.WriteUInt
network.writeInt = net.WriteInt

network.writeFloat = net.WriteFloat
network.writeDouble = net.WriteDouble

network.readBytes = net.ReadData
network.writeBytes = net.WriteData

network.readString = net.ReadString
network.writeString = net.WriteString

---@type table<table | string, fun( object: any )>
local writers = {}

---@type table<table | string, fun( object: any )>
local readers = {}

function network.setupReader( metatable, reader )
    local type_name = type( metatable )

    readers[ type_name ] = reader
    readers[ metatable ] = reader
end

function network.setupWriter( metatable, writer )
    local type_name = type( metatable )

    writers[ type_name ] = writer
    writers[ metatable ] = writer
end

---@param name string
---@param streamer fun( object: any )
function network.stream( name, streamer )

end

---@type table<ash.network.Table, string>
local names = {}

---@type table<string, ash.network.Table>
local tables_by_name = {}

---@type integer
local table_count = 0

---@type ash.network.Table[]
local table_list = {}

---@type table<ash.network.Table.Node, ash.network.Table>
local tables_by_node = {}
gc.setTableRules( tables_by_node, true )

---@type table<ash.network.Table.Node, ash.network.Table.Node>
local node_children = {}
gc.setTableRules( node_children, true )

---@type table<ash.network.Table.Node, table<string, any>>
local node_values = {}
gc.setTableRules( node_values, true )

---@type table<ash.network.Table.Node, table<Player, table<string, number>>>
local node_send_times = {}

do

    local player_meta = {
        ---@param key string
        ---@return table<string, number>
        __index = function( self, key )
            ---@type table<string, number>
            local times = {}
            self[ key ] = times
            return times
        end,
        __mode = "k"
    }

    setmetatable( node_send_times, {
        ---@param pl Player
        __index = function( self, pl )
            ---@type table<Player, table<string, number>>
            local players = {}
            self[ pl ] = players
            setmetatable( players, player_meta )
            return players
        end,
        __mode = "k"
    } )

end

---@type table<ash.network.Table.Node, table<string, number>>
local node_change_times = {}
gc.setTableRules( node_change_times, true )


---@param node ash.network.Table.Node
---@param key string
local function sync_with_players( node, key, value )
    for _, pl in player.Iterator() do
        if not pl:IsBot() then
            print( "pl", pl )
        end
    end

    print( "sync", node, key, value )
end

---@class ash.network.Table.Node : dreamwork.Object
local Node = class.base( "network.Table.Node", true )

---@return string
---@protected
function Node:__tostring()
    return string.format( "ash.network.Table.Node: %p", self )
end

---@param parent ash.network.Table.Node | nil
---@protected
function Node:__init( parent )
    node_values[ self ] = {}
    node_send_times[ self ] = {}
    node_change_times[ self ] = {}
    node_children[ self ] = parent
    tables_by_node[ self ] = tables_by_node[ parent ]
end

---@param key string
---@return any
---@protected
function Node:__index( key )
    return node_values[ self ][ key ]
end

---@param key string
---@param value any
---@protected
function Node:__newindex( key, value )
    local values = node_values[ self ]
    if values[ key ] ~= value then
        values[ key ] = value
        node_change_times[ self ][ key ] = os_clock()
        sync_with_players( self, key, value )
    end
end

---@class ash.network.Table.NodeClass : ash.network.Table.Node
---@overload fun( parent: ash.network.Table.Node | nil ): ash.network.Table.Node
local NodeClass = class.create( Node )


---@class ash.network.Table : dreamwork.Object
---@field __class ash.network.TableClass
local Table = class.base( "network.Table", true )

---@protected
---@return string
function Table:__tostring()
    return string.format( "ash.network.Table: %p [%s]", self, names[ self ] )
end

---@param name string
---@protected
function Table:__init( name )
    names[ self ] = name
    tables_by_name[ name ] = self

    table_count = table_count + 1
    table_list[ table_count ] = self

    local node = NodeClass()
    node_children[ self ] = node
    tables_by_node[ node ] = self
end

---@param key string
---@return any value
---@protected
function Table:__index( key )
    return node_children[ self ][ key ]
end

---@param node ash.network.Table.Node
---@param key string
---@param value any
local function value_sync( node, key, value )
    if node[ key ] == value then return end

    if istable( value ) then
        local child = NodeClass( node )

        for k, v in pairs( value ) do
            value_sync( child, k, v )
        end

        node[ key ] = child
        return
    end

    node[ key ] = value
end

---@param key string
---@param value any
---@protected
function Table:__newindex( key, value )
    value_sync( node_children[ self ], key, value )
end

---@param pl Player
function Table:sync( pl )
    if pl:IsBot() then return end

    net.Start( "network.Table" )



    if pl == nil then
        net.Broadcast()
    else
        net.Send( pl )
    end
end

---@class ash.network.TableClass : ash.network.Table
---@field __base ash.network.Table
---@overload fun( name: string ): ash.network.Table
local TableClass = class.create( Table )
network.Table = TableClass

---@param name string
---@return ash.network.Table | nil
---@protected
function TableClass:__new( name )
    return tables_by_name[ name ]
end

local obj = TableClass( "network.Table" )

obj.key = "value"
obj.key = "value2"

obj.tabl = {
    a = {
        b = "value"
    }
}

obj.tabl.a.b = "value2"

print( obj.tabl.a.b )

if SERVER then

    ---@param pl Player
    hook.Add( "ash.player.Initialized", "InitialPayload", function( pl )
        -- for i = 1, table_count, 1 do
        --     table_list[ i ]:sync( pl )
        -- end
    end )

end

return network
