
MODULE.Networks = {
    "overlay"
}

MODULE.ClientFiles = {
    "overlay.lua",
    "shared.lua"
}

---@class ash.debug
local debug = include( "./shared.lua" )

---@class ash.debug.overlay
local overlay = {}

---@diagnostic disable-next-line: duplicate-set-field
function overlay.box( filled, origin, angles, mins, maxs, r, g, b, write_depth, lifetime )
    net.Start( "overlay", true )
    net.WriteString( "box" )

    net.WriteBool( filled )

    net.WriteDouble( origin[ 1 ] )
    net.WriteDouble( origin[ 2 ] )
    net.WriteDouble( origin[ 3 ] )

    if angles == nil then
        angles = angle_zero
    end

    net.WriteDouble( angles[ 1 ] )
    net.WriteDouble( angles[ 2 ] )
    net.WriteDouble( angles[ 3 ] )

    net.WriteDouble( mins[ 1 ] )
    net.WriteDouble( mins[ 2 ] )
    net.WriteDouble( mins[ 3 ] )

    net.WriteDouble( maxs[ 1 ] )
    net.WriteDouble( maxs[ 2 ] )
    net.WriteDouble( maxs[ 3 ] )

    net.WriteUInt( r, 8 )
    net.WriteUInt( g, 8 )
    net.WriteUInt( b, 8 )

    net.WriteBool( write_depth )
    net.WriteFloat( lifetime )

    net.Broadcast()
end

---@diagnostic disable-next-line: duplicate-set-field
function overlay.cross( origin, size, r, g, b, write_depth, lifetime )
    net.Start( "overlay", true )
    net.WriteString( "cross" )

    net.WriteDouble( origin[ 1 ] )
    net.WriteDouble( origin[ 2 ] )
    net.WriteDouble( origin[ 3 ] )

    net.WriteFloat( size )

    net.WriteUInt( r, 8 )
    net.WriteUInt( g, 8 )
    net.WriteUInt( b, 8 )

    net.WriteBool( write_depth )
    net.WriteFloat( lifetime )

    net.Broadcast()
end

---@diagnostic disable-next-line: duplicate-set-field
function overlay.line( start_position, end_position, r, g, b, write_depth, lifetime )
    net.Start( "overlay", true )
    net.WriteString( "line" )

    net.WriteDouble( start_position[ 1 ] )
    net.WriteDouble( start_position[ 2 ] )
    net.WriteDouble( start_position[ 3 ] )

    net.WriteDouble( end_position[ 1 ] )
    net.WriteDouble( end_position[ 2 ] )
    net.WriteDouble( end_position[ 3 ] )

    net.WriteUInt( r, 8 )
    net.WriteUInt( g, 8 )
    net.WriteUInt( b, 8 )

    net.WriteBool( write_depth )
    net.WriteFloat( lifetime )

    net.Broadcast()
end

---@diagnostic disable-next-line: duplicate-set-field
function overlay.text( str, origin, size, r, g, b, write_depth, lifetime )
    net.Start( "overlay", true )
    net.WriteString( "text" )

    net.WriteString( str )

    net.WriteDouble( origin[ 1 ] )
    net.WriteDouble( origin[ 2 ] )
    net.WriteDouble( origin[ 3 ] )

    net.WriteFloat( size )

    net.WriteUInt( r, 8 )
    net.WriteUInt( g, 8 )
    net.WriteUInt( b, 8 )

    net.WriteBool( write_depth )
    net.WriteFloat( lifetime )

    net.Broadcast()
end

debug.overlay = overlay

return debug
