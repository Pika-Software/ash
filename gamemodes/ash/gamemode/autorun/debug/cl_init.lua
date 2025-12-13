---@class ash.debug
local debug = include( "./shared.lua" )

---@type ash.debug.overlay
local overlay = include( "./overlay.lua" )
debug.overlay = overlay

net.Receive( "overlay", function()
    local name = net.ReadString()
    if name == "box" then
        overlay.box(
            net.ReadBool(),
            Vector(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            Angle(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            Vector(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            Vector(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadBool(),
            net.ReadFloat()
        )
    elseif name == "cross" then
        overlay.cross(
            Vector(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            net.ReadFloat(),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadBool(),
            net.ReadFloat()
        )
    elseif name == "line" then
        overlay.line(
            Vector(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            Vector(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadBool(),
            net.ReadFloat()
        )
    elseif name == "text" then
        overlay.text(
            net.ReadString(),
            Vector(
                net.ReadDouble(),
                net.ReadDouble(),
                net.ReadDouble()
            ),
            net.ReadFloat(),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadUInt( 8 ),
            net.ReadBool(),
            net.ReadFloat()
        )
    end
end )

return debug
