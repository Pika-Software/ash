---@class flame_puppeteer : ENT
---@field RagdollEntity Entity
---@field GetPuppet fun( self: flame_puppeteer ): Entity
---@field SetPuppet fun( self: flame_puppeteer, puppet: Entity )
local ENT = ENT

ENT.Type = "anim"

function ENT:SetupDataTables()
    self:NetworkVar( "Entity", 0, "Puppet" )
end

-- function ENT:GenerateCapsuleMesh( width, height, hsegs, vsegs )
--     hsegs       = hsegs or 8
--     vsegs       = vsegs or 4

--     local r     = width * 0.5
--     local hcyl  = math.max( 0, height - width ) -- straight cylinder section height
--     local halfH = hcyl * 0.5

--     -- Build a grid of (hsegs+1) x rows vertices, then tessellate into triangles.
--     -- rows:  vsegs rows for top cap  +  2 rows for cylinder ring  +  vsegs rows for bottom cap
--     local verts = {} -- { {x,y,z}, ... }  (temp storage)
--     local tris  = {} -- flat Vector list returned to caller

--     local function addVert( x, y, z )
--         verts[ #verts + 1 ] = { x, y, z }
--     end

--     -- ── Top hemisphere ──────────────────────────────────────────────────────
--     -- phi goes from π/2 (pole) down to 0 (equator)
--     for row = 0, vsegs do
--         local phi = (math.pi * 0.5) * (1 - row / vsegs) -- π/2 → 0
--         local yr  = r * math.sin( phi )
--         local pr  = r * math.cos( phi )

--         for col = 0, hsegs do
--             local theta = (2 * math.pi) * col / hsegs
--             addVert( pr * math.cos( theta ), pr * math.sin( theta ), halfH + yr )
--         end
--     end

--     -- ── Bottom hemisphere ────────────────────────────────────────────────────
--     -- phi goes from 0 (equator) down to -π/2 (pole)
--     for row = 0, vsegs do
--         local phi = -(math.pi * 0.5) * (row / vsegs) -- 0 → -π/2
--         local yr  = r * math.sin( phi )
--         local pr  = r * math.cos( phi )

--         for col = 0, hsegs do
--             local theta = (2 * math.pi) * col / hsegs
--             addVert( pr * math.cos( theta ), pr * math.sin( theta ), halfH + yr )
--         end
--     end

--     -- ── Tessellate quads into triangles ──────────────────────────────────────
--     -- Total rows of vertices = (vsegs+1) top + (vsegs+1) bottom  = 2*(vsegs+1)
--     -- Each row has (hsegs+1) verts (col 0 == col hsegs, seam duplicated for UV simplicity)

--     local stride = hsegs + 1
--     local totalRows = 2 * (vsegs + 1) - 1 -- shared equator row counted once

--     -- Recompute: top block is rows 0..vsegs, bottom block is rows vsegs..2*vsegs
--     -- They share the equator row, so total unique rows = 2*vsegs + 1
--     -- Index into verts: row * stride + col  (1-based: +1)

--     local function vi( row, col )
--         return row * stride + (col % hsegs) + 1 -- 1-based
--     end

--     local function pushTri( a, b, c )
--         local va, vb, vc = verts[ a ], verts[ b ], verts[ c ]
--         tris[ #tris + 1 ] = Vector( va[ 1 ], va[ 2 ], va[ 3 ] )
--         tris[ #tris + 1 ] = Vector( vb[ 1 ], vb[ 2 ], vb[ 3 ] )
--         tris[ #tris + 1 ] = Vector( vc[ 1 ], vc[ 2 ], vc[ 3 ] )
--     end

--     local numRows = 2 * vsegs -- quad strip rows

--     for row = 0, numRows - 1 do
--         for col = 0, hsegs - 1 do
--             local tl = vi( row, col )
--             local tr = vi( row, col + 1 )
--             local bl = vi( row + 1, col )
--             local br = vi( row + 1, col + 1 )

--             -- two triangles per quad (CCW winding)
--             pushTri( tl, bl, tr )
--             pushTri( tr, bl, br )
--         end
--     end

--     return tris
-- end

function ENT:GenerateCapsuleMesh( width, height, hsegs, vsegs )
    hsegs      = hsegs or 8
    vsegs      = vsegs or 4

    local r    = width * 0.5
    local hcyl = math.max( 0, height - width )
    local botC = r
    local topC = r + hcyl

    local tris = {}

    local function pushTri( ax, ay, az, bx, by, bz, cx, cy, cz )
        tris[ #tris + 1 ] = Vector( ax, ay, az )
        tris[ #tris + 1 ] = Vector( bx, by, bz )
        tris[ #tris + 1 ] = Vector( cx, cy, cz )
    end

    -- returns x,y,z of a point on a ring
    local function pt( z, pr, col )
        local theta = (2 * math.pi) * col / hsegs
        return pr * math.cos( theta ), pr * math.sin( theta ), z
    end

    -- stitch two full rings as quads
    local function stitchRings( zA, prA, zB, prB )
        for c = 0, hsegs - 1 do
            local nc = (c + 1) % hsegs
            local ax, ay, az = pt( zA, prA, c )
            local bx, by, bz = pt( zA, prA, nc )
            local cx, cy, cz = pt( zB, prB, c )
            local dx, dy, dz = pt( zB, prB, nc )
            pushTri( ax, ay, az, cx, cy, cz, bx, by, bz )
            pushTri( bx, by, bz, cx, cy, cz, dx, dy, dz )
        end
    end

    -- stitch a pole point to a ring as a fan
    local function stitchPoleTop( poleZ, ringZ, ringPr )
        for c = 0, hsegs - 1 do
            local nc = (c + 1) % hsegs
            local ax, ay, az = pt( ringZ, ringPr, c )
            local bx, by, bz = pt( ringZ, ringPr, nc )
            pushTri( 0, 0, poleZ, ax, ay, az, bx, by, bz )
        end
    end

    local function stitchPoleBot( poleZ, ringZ, ringPr )
        for c = 0, hsegs - 1 do
            local nc = (c + 1) % hsegs
            local ax, ay, az = pt( ringZ, ringPr, c )
            local bx, by, bz = pt( ringZ, ringPr, nc )
            pushTri( 0, 0, poleZ, bx, by, bz, ax, ay, az )
        end
    end

    -- precompute hemisphere rings (phi 90°->0°, skip pole and equator)
    -- ring[1] = closest to pole, ring[vsegs-1] = closest to equator
    local topRings = {}     -- { z, pr }
    local botRings = {}
    for i = 1, vsegs - 1 do
        local phi = (math.pi * 0.5) * (1 - i / vsegs)
        topRings[ i ] = { topC + r * math.sin( phi ), r * math.cos( phi ) }

        local phi2 = -(math.pi * 0.5) * (i / vsegs)
        botRings[ i ] = { botC + r * math.sin( phi2 ), r * math.cos( phi2 ) }
    end

    -- top pole fan -> first ring
    stitchPoleTop( topC + r, topRings[ 1 ][ 1 ], topRings[ 1 ][ 2 ] )

    -- top hemisphere ring->ring
    for i = 1, vsegs - 2 do
        stitchRings( topRings[ i ][ 1 ], topRings[ i ][ 2 ], topRings[ i + 1 ][ 1 ], topRings[ i + 1 ][ 2 ] )
    end

    -- last top ring -> top equator
    stitchRings( topRings[ vsegs - 1 ][ 1 ], topRings[ vsegs - 1 ][ 2 ], topC, r )

    -- top equator -> bottom equator  (the cylinder)
    stitchRings( topC, r, botC, r )

    -- bottom equator -> first bottom ring
    stitchRings( botC, r, botRings[ 1 ][ 1 ], botRings[ 1 ][ 2 ] )

    -- bottom hemisphere ring->ring
    for i = 1, vsegs - 2 do
        stitchRings( botRings[ i ][ 1 ], botRings[ i ][ 2 ], botRings[ i + 1 ][ 1 ], botRings[ i + 1 ][ 2 ] )
    end

    -- last bottom ring -> bottom pole fan
    stitchPoleBot( botC - r, botRings[ vsegs - 1 ][ 1 ], botRings[ vsegs - 1 ][ 2 ] )

    return tris
end
