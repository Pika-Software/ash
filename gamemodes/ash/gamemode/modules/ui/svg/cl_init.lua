--[[--------------------------------------------------------------------------
	tinysvg — a pure-Lua SVG reader + renderer for Garry's Mod.

	Parses SVG documents and renders them as true vector graphics, so icons
	and images can be drawn at ANY size without losing resolution.

	USAGE
		local doc = tinysvg.Parse(svgText)              -- from a string
		local doc = tinysvg.Load("materials/hq/icon.svg") -- from a file ("GAME" mount)

		-- In a HUD / panel Paint hook:
		doc:Draw(x, y, w, h)        -- recommended: cached render-target, auto re-rasters per size bucket
		doc:Render(x, y, w, h)      -- immediate vector draw (sharpest, costlier per frame)
		local mat = doc:GetMaterial(256, 256)  -- raw IMaterial (premultiplied alpha — draw via doc:Draw
		                                       -- or tinysvg.DrawMaterial for correct blending)

		opts table (all optional) for Draw/Render/GetMaterial:
			supersample = 2          -- raster antialiasing factor (1..4)
			tint        = Color(...) -- multiplies all paints (white icons -> any color)
			alpha       = 1          -- opacity multiplier, applied at DRAW time (cheap:
			                         -- animating it does NOT re-rasterize). The ambient
			                         -- VGUI panel:SetAlpha is also folded in, so an icon
			                         -- fades together with its parent panel for free.
			exact       = false      -- Draw(): rasterize at exact size instead of size buckets
		Parse/Load opts:
			currentColor = Color(...) -- value used for SVG 'currentColor'

	SUPPORTED
		<svg> (viewBox, width/height, preserveAspectRatio), <g>, <defs>, <use>,
		<path> (M L H V C S Q T A Z, all relative/absolute forms),
		<rect> (incl. rounded), <circle>, <ellipse>, <line>, <polyline>, <polygon>,
		transform (matrix/translate/scale/rotate/skewX/skewY),
		fill (incl. fill-rule nonzero/evenodd), stroke (width, linecap, linejoin,
		miterlimit, dasharray, dashoffset), opacity / fill-opacity / stroke-opacity,
		<linearGradient>/<radialGradient> (stops, href chains, objectBoundingBox +
		userSpaceOnUse, gradientTransform, focal points; spreadMethod renders as pad),
		colors (#hex 3/4/6/8, rgb(), rgba(), hsl(), all CSS named colors,
		currentColor), units (px pt pc mm cm in em ex %),
		<style> blocks + class/id/type CSS selectors, inline style="...".

	NOT SUPPORTED (skipped with a doc.warnings entry)
		<text>, <image>, <pattern>, masks/filters/clip paths, animation/scripting,
		non-pad spreadMethod (falls back to pad), group opacity is approximated
		(multiplied into children instead of compositing a layer).

	NOTES
		* Group opacity approximation only differs visually where siblings overlap.
		* Non-uniform scale distorts stroke widths slightly (average scale is used).
		* doc:Render() uses stencils; safe in HUD hooks, VGUI Paint and 3D2D.
		* Rasterized materials are premultiplied-alpha; doc:Draw handles blending.
------------------------------------------------------------------------------]]

---@class ash.ui.svg
local tinysvg = {}
tinysvg.Version = "1.0.0"
tinysvg.TessTolerance = 0.25	-- device-pixel curve flattening tolerance

-- Render-readiness gate (see the PostRender hook lower down). Declared up here so
-- both Parse (which registers each doc) and Draw (which reads the flag) capture
-- these as upvalues. allDocs uses weak keys so dead docs are collected.
local rasterReady = false
local allDocs = setmetatable({}, { __mode = "k" })
tinysvg.PrintWarnings = false	-- print parse warnings to console

local abs, ceil, floor, max, min = math.abs, math.ceil, math.floor, math.max, math.min
local sqrt, sin, cos, tan, acos, rad = math.sqrt, math.sin, math.cos, math.tan, math.acos, math.rad
local frexp, ldexp = math.frexp, math.ldexp
local atan2 = math.atan2
local pi = math.pi
local strfind, strsub, strgsub, strmatch, strgmatch = string.find, string.sub, string.gsub, string.match, string.gmatch
local strlower, strchar = string.lower, string.char
local tinsert = table.insert

local KAPPA = 0.5522847498307934 -- cubic approximation factor for quarter circles

--------------------------------------------------------------------------------
-- Small utilities
--------------------------------------------------------------------------------

local function trim(s)
	return strmatch(s, "^%s*(.-)%s*$") or ""
end

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function lerp(t, a, b)
	return a + (b - a) * t
end

local function isFinite(n)
	return n == n and n ~= math.huge and n ~= -math.huge
end

-- Accepts Color objects or {r,g,b,a} / {1,2,3,4} tables; returns r,g,b,a numbers.
local function colorBits(c, dr, dg, db, da)
	if not c then return dr, dg, db, da end
	local r = c.r or c[1] or dr
	local g = c.g or c[2] or dg
	local b = c.b or c[3] or db
	local a = c.a or c[4] or da
	return r, g, b, a
end

--------------------------------------------------------------------------------
-- 2D affine matrix { a, b, c, d, e, f }:  x' = a*x + c*y + e ; y' = b*x + d*y + f
--------------------------------------------------------------------------------

local function matIdentity()
	return { 1, 0, 0, 1, 0, 0 }
end

-- m2 is applied to the point first, then m1 (standard CTM composition).
local function matMul(m1, m2)
	return {
		m1[1] * m2[1] + m1[3] * m2[2],
		m1[2] * m2[1] + m1[4] * m2[2],
		m1[1] * m2[3] + m1[3] * m2[4],
		m1[2] * m2[3] + m1[4] * m2[4],
		m1[1] * m2[5] + m1[3] * m2[6] + m1[5],
		m1[2] * m2[5] + m1[4] * m2[6] + m1[6],
	}
end

local function matApply(m, x, y)
	return m[1] * x + m[3] * y + m[5], m[2] * x + m[4] * y + m[6]
end

local function matInverse(m)
	local det = m[1] * m[4] - m[2] * m[3]
	if abs(det) < 1e-12 then return nil end
	local id = 1 / det
	local a, b, c, d = m[4] * id, -m[2] * id, -m[3] * id, m[1] * id
	return { a, b, c, d, -(a * m[5] + c * m[6]), -(b * m[5] + d * m[6]) }
end

-- Average absolute scale factor; used for stroke widths and tessellation density.
local function matScale(m)
	local sx = sqrt(m[1] * m[1] + m[2] * m[2])
	local sy = sqrt(m[3] * m[3] + m[4] * m[4])
	return (sx + sy) * 0.5
end

local function matTranslate(tx, ty)
	return { 1, 0, 0, 1, tx, ty }
end

local function matScaleM(sx, sy)
	return { sx, 0, 0, sy, 0, 0 }
end

--------------------------------------------------------------------------------
-- Number / list / length parsing
--------------------------------------------------------------------------------

-- Parses "1, 2.5 -3e2 .5" style lists into an array of numbers.
local function parseNumberList(s)
	local out = {}
	if not s then return out end
	for tok in strgmatch(s, "[^%s,]+") do
		-- split glued numbers like "5-3" or "1.5.3" conservatively via tonumber first
		local n = tonumber(tok)
		if n then
			out[#out + 1] = n
		else
			-- fall back to scanning the token for embedded numbers
			local i = 1
			while i <= #tok do
				local s1, e1 = strfind(tok, "^[+-]?%d+%.?%d*", i)
				if not s1 then s1, e1 = strfind(tok, "^[+-]?%.%d+", i) end
				if not s1 then break end
				local s2, e2 = strfind(tok, "^[eE][+-]?%d+", e1 + 1)
				if s2 then e1 = e2 end
				out[#out + 1] = tonumber(strsub(tok, s1, e1))
				i = e1 + 1
			end
		end
	end
	return out
end

local UNIT_SCALE = {
	px = 1, pt = 96 / 72, pc = 16,
	mm = 96 / 25.4, cm = 96 / 2.54, ["in"] = 96,
}

-- fontSize for em/ex (defaults 16). Percentages are handled by parseLengthPct.
local function parseLength(s, _ref, fontSize)
	if type(s) == "number" then return s end
	if not s then return nil end
	s = trim(s)
	local num = tonumber(strmatch(s, "^[+-]?[%d%.eE+-]+"))
	if not num then return nil end
	local unit = strlower(strmatch(s, "(%a+)%s*$") or "")
	if unit == "" then return num end
	if UNIT_SCALE[unit] then return num * UNIT_SCALE[unit] end
	if unit == "em" then return num * (fontSize or 16) end
	if unit == "ex" then return num * (fontSize or 16) * 0.5 end
	return num
end

local function parseLengthPct(s, ref, fontSize)
	if type(s) == "number" then return s end
	if not s then return nil end
	s = trim(s)
	if strsub(s, -1) == "%" then
		local num = tonumber(strsub(s, 1, -2))
		if not num then return nil end
		return num / 100 * (ref or 100)
	end
	return parseLength(s, ref, fontSize)
end

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

local NAMED_COLORS = {
	aliceblue = 0xF0F8FF, antiquewhite = 0xFAEBD7, aqua = 0x00FFFF, aquamarine = 0x7FFFD4,
	azure = 0xF0FFFF, beige = 0xF5F5DC, bisque = 0xFFE4C4, black = 0x000000,
	blanchedalmond = 0xFFEBCD, blue = 0x0000FF, blueviolet = 0x8A2BE2, brown = 0xA52A2A,
	burlywood = 0xDEB887, cadetblue = 0x5F9EA0, chartreuse = 0x7FFF00, chocolate = 0xD2691E,
	coral = 0xFF7F50, cornflowerblue = 0x6495ED, cornsilk = 0xFFF8DC, crimson = 0xDC143C,
	cyan = 0x00FFFF, darkblue = 0x00008B, darkcyan = 0x008B8B, darkgoldenrod = 0xB8860B,
	darkgray = 0xA9A9A9, darkgreen = 0x006400, darkgrey = 0xA9A9A9, darkkhaki = 0xBDB76B,
	darkmagenta = 0x8B008B, darkolivegreen = 0x556B2F, darkorange = 0xFF8C00, darkorchid = 0x9932CC,
	darkred = 0x8B0000, darksalmon = 0xE9967A, darkseagreen = 0x8FBC8F, darkslateblue = 0x483D8B,
	darkslategray = 0x2F4F4F, darkslategrey = 0x2F4F4F, darkturquoise = 0x00CED1, darkviolet = 0x9400D3,
	deeppink = 0xFF1493, deepskyblue = 0x00BFFF, dimgray = 0x696969, dimgrey = 0x696969,
	dodgerblue = 0x1E90FF, firebrick = 0xB22222, floralwhite = 0xFFFAF0, forestgreen = 0x228B22,
	fuchsia = 0xFF00FF, gainsboro = 0xDCDCDC, ghostwhite = 0xF8F8FF, gold = 0xFFD700,
	goldenrod = 0xDAA520, gray = 0x808080, green = 0x008000, greenyellow = 0xADFF2F,
	grey = 0x808080, honeydew = 0xF0FFF0, hotpink = 0xFF69B4, indianred = 0xCD5C5C,
	indigo = 0x4B0082, ivory = 0xFFFFF0, khaki = 0xF0E68C, lavender = 0xE6E6FA,
	lavenderblush = 0xFFF0F5, lawngreen = 0x7CFC00, lemonchiffon = 0xFFFACD, lightblue = 0xADD8E6,
	lightcoral = 0xF08080, lightcyan = 0xE0FFFF, lightgoldenrodyellow = 0xFAFAD2, lightgray = 0xD3D3D3,
	lightgreen = 0x90EE90, lightgrey = 0xD3D3D3, lightpink = 0xFFB6C1, lightsalmon = 0xFFA07A,
	lightseagreen = 0x20B2AA, lightskyblue = 0x87CEFA, lightslategray = 0x778899, lightslategrey = 0x778899,
	lightsteelblue = 0xB0C4DE, lightyellow = 0xFFFFE0, lime = 0x00FF00, limegreen = 0x32CD32,
	linen = 0xFAF0E6, magenta = 0xFF00FF, maroon = 0x800000, mediumaquamarine = 0x66CDAA,
	mediumblue = 0x0000CD, mediumorchid = 0xBA55D3, mediumpurple = 0x9370DB, mediumseagreen = 0x3CB371,
	mediumslateblue = 0x7B68EE, mediumspringgreen = 0x00FA9A, mediumturquoise = 0x48D1CC, mediumvioletred = 0xC71585,
	midnightblue = 0x191970, mintcream = 0xF5FFFA, mistyrose = 0xFFE4E1, moccasin = 0xFFE4B5,
	navajowhite = 0xFFDEAD, navy = 0x000080, oldlace = 0xFDF5E6, olive = 0x808000,
	olivedrab = 0x6B8E23, orange = 0xFFA500, orangered = 0xFF4500, orchid = 0xDA70D6,
	palegoldenrod = 0xEEE8AA, palegreen = 0x98FB98, paleturquoise = 0xAFEEEE, palevioletred = 0xDB7093,
	papayawhip = 0xFFEFD5, peachpuff = 0xFFDAB9, peru = 0xCD853F, pink = 0xFFC0CB,
	plum = 0xDDA0DD, powderblue = 0xB0E0E6, purple = 0x800080, rebeccapurple = 0x663399,
	red = 0xFF0000, rosybrown = 0xBC8F8F, royalblue = 0x4169E1, saddlebrown = 0x8B4513,
	salmon = 0xFA8072, sandybrown = 0xF4A460, seagreen = 0x2E8B57, seashell = 0xFFF5EE,
	sienna = 0xA0522D, silver = 0xC0C0C0, skyblue = 0x87CEEB, slateblue = 0x6A5ACD,
	slategray = 0x708090, slategrey = 0x708090, snow = 0xFFFAFA, springgreen = 0x00FF7F,
	steelblue = 0x4682B4, tan = 0xD2B48C, teal = 0x008080, thistle = 0xD8BFD8,
	tomato = 0xFF6347, turquoise = 0x40E0D0, violet = 0xEE82EE, wheat = 0xF5DEB3,
	white = 0xFFFFFF, whitesmoke = 0xF5F5F5, yellow = 0xFFFF00, yellowgreen = 0x9ACD32,
}

local function hslToRgb(h, s, l)
	h = (h % 360) / 360
	local function f(n)
		local k = (n + h * 12) % 12
		local a = s * min(l, 1 - l)
		return l - a * max(-1, min(k - 3, 9 - k, 1))
	end
	return f(0) * 255, f(8) * 255, f(4) * 255
end

-- Returns {r,g,b,a} (0-255), the string "none", or nil if unparseable.
local function parseColor(s)
	if not s then return nil end
	s = strlower(trim(s))
	if s == "" then return nil end
	if s == "none" then return "none" end
	if s == "transparent" then return { 0, 0, 0, 0 } end

	if strsub(s, 1, 1) == "#" then
		local hex = strsub(s, 2)
		local n = #hex
		if not strmatch(hex, "^%x+$") then return nil end
		if n == 3 or n == 4 then
			local r = tonumber(strsub(hex, 1, 1), 16)
			local g = tonumber(strsub(hex, 2, 2), 16)
			local b = tonumber(strsub(hex, 3, 3), 16)
			local a = n == 4 and tonumber(strsub(hex, 4, 4), 16) * 17 or 255
			return { r * 17, g * 17, b * 17, a }
		elseif n == 6 or n == 8 then
			local r = tonumber(strsub(hex, 1, 2), 16)
			local g = tonumber(strsub(hex, 3, 4), 16)
			local b = tonumber(strsub(hex, 5, 6), 16)
			local a = n == 8 and tonumber(strsub(hex, 7, 8), 16) or 255
			return { r, g, b, a }
		end
		return nil
	end

	local fn, args = strmatch(s, "^(%a+)%s*%(([^)]*)%)$")
	if fn then
		local function comp(v)
			v = trim(v)
			if strsub(v, -1) == "%" then
				return (tonumber(strsub(v, 1, -2)) or 0) * 2.55
			end
			return tonumber(v) or 0
		end
		local parts = {}
		for p in strgmatch(args, "[^,%s/]+") do parts[#parts + 1] = p end
		if fn == "rgb" or fn == "rgba" then
			local r, g, b = comp(parts[1] or "0"), comp(parts[2] or "0"), comp(parts[3] or "0")
			local a = 255
			if parts[4] then
				local av = trim(parts[4])
				if strsub(av, -1) == "%" then a = (tonumber(strsub(av, 1, -2)) or 100) * 2.55
				else a = (tonumber(av) or 1) * 255 end
			end
			return { clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255), clamp(a, 0, 255) }
		elseif fn == "hsl" or fn == "hsla" then
			local h = tonumber(parts[1]) or 0
			local sat = (tonumber(strmatch(parts[2] or "0", "[%d%.]+")) or 0) / 100
			local lig = (tonumber(strmatch(parts[3] or "0", "[%d%.]+")) or 0) / 100
			local a = 255
			if parts[4] then
				local av = trim(parts[4])
				if strsub(av, -1) == "%" then a = (tonumber(strsub(av, 1, -2)) or 100) * 2.55
				else a = (tonumber(av) or 1) * 255 end
			end
			local r, g, b = hslToRgb(h, sat, lig)
			return { clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255), clamp(a, 0, 255) }
		end
		return nil
	end

	local hexv = NAMED_COLORS[s]
	if hexv then
		return { floor(hexv / 65536) % 256, floor(hexv / 256) % 256, hexv % 256, 255 }
	end
	return nil
end

--------------------------------------------------------------------------------
-- Minimal XML parser -> { tag, attrs, children, text } tree
--------------------------------------------------------------------------------

local function utf8Char(code)
	if code < 0x80 then return strchar(code) end
	if code < 0x800 then
		return strchar(0xC0 + floor(code / 0x40), 0x80 + code % 0x40)
	end
	if code < 0x10000 then
		return strchar(0xE0 + floor(code / 0x1000), 0x80 + floor(code / 0x40) % 0x40, 0x80 + code % 0x40)
	end
	return "?"
end

local XML_ENTITIES = { amp = "&", lt = "<", gt = ">", quot = "\"", apos = "'" }

local function decodeEntities(s)
	if not strfind(s, "&", 1, true) then return s end
	return (strgsub(s, "&(#?x?%w+);", function(e)
		if XML_ENTITIES[e] then return XML_ENTITIES[e] end
		local dec = strmatch(e, "^#(%d+)$")
		if dec then return utf8Char(tonumber(dec)) end
		local hex = strmatch(e, "^#x(%x+)$")
		if hex then return utf8Char(tonumber(hex, 16)) end
		return "&" .. e .. ";"
	end))
end

-- Finds the real end of a tag, respecting quoted attribute values.
local function findTagEnd(s, i)
	local quote = nil
	local n = #s
	while i <= n do
		local ch = strsub(s, i, i)
		if quote then
			if ch == quote then quote = nil end
		elseif ch == "\"" or ch == "'" then
			quote = ch
		elseif ch == ">" then
			return i
		end
		i = i + 1
	end
	return nil
end

local function parseAttrs(s)
	local attrs = {}
	local i = 1
	while true do
		local ks, ke, name = strfind(s, "([%w_:%-%.]+)%s*=%s*", i)
		if not ks then break end
		local q = strsub(s, ke + 1, ke + 1)
		if q == "\"" or q == "'" then
			local ve = strfind(s, q, ke + 2, true)
			if not ve then break end
			attrs[name] = decodeEntities(strsub(s, ke + 2, ve - 1))
			i = ve + 1
		else
			local vs, ve, val = strfind(s, "^(%S+)", ke + 1)
			if not vs then break end
			attrs[name] = decodeEntities(val)
			i = ve + 1
		end
	end
	return attrs
end

local function xmlParse(s)
	local root = { tag = "#root", attrs = {}, children = {} }
	local stack = { root }
	local top = root
	local i = 1
	local n = #s

	while i <= n do
		local lt = strfind(s, "<", i, true)
		if not lt then
			break
		end
		if lt > i then
			local text = strsub(s, i, lt - 1)
			if strfind(text, "%S") then
				tinsert(top.children, { tag = "#text", text = decodeEntities(text), attrs = {}, children = {} })
			end
		end

		if strsub(s, lt, lt + 3) == "<!--" then
			local ce = strfind(s, "-->", lt + 4, true)
			i = ce and (ce + 3) or (n + 1)
		elseif strsub(s, lt, lt + 8) == "<![CDATA[" then
			local ce = strfind(s, "]]>", lt + 9, true)
			local text = strsub(s, lt + 9, ce and (ce - 1) or n)
			tinsert(top.children, { tag = "#text", text = text, attrs = {}, children = {} })
			i = ce and (ce + 3) or (n + 1)
		elseif strsub(s, lt, lt + 1) == "<!" then
			-- DOCTYPE etc. — may contain an [internal subset]
			local depth = 0
			local j = lt + 2
			while j <= n do
				local ch = strsub(s, j, j)
				if ch == "[" then depth = depth + 1
				elseif ch == "]" then depth = depth - 1
				elseif ch == ">" and depth <= 0 then break end
				j = j + 1
			end
			i = j + 1
		elseif strsub(s, lt, lt + 1) == "<?" then
			local ce = strfind(s, "?>", lt + 2, true)
			i = ce and (ce + 2) or (n + 1)
		elseif strsub(s, lt, lt + 1) == "</" then
			local gt = strfind(s, ">", lt + 2, true)
			local name = trim(strsub(s, lt + 2, gt and (gt - 1) or n))
			name = strlower(strgsub(name, "^[%w_%-%.]+:", ""))
			-- pop to matching open tag (tolerates mismatches)
			for d = #stack, 2, -1 do
				if stack[d].tag == name then
					for _ = #stack, d, -1 do table.remove(stack) end
					break
				end
			end
			top = stack[#stack]
			i = gt and (gt + 1) or (n + 1)
		else
			local gt = findTagEnd(s, lt + 1)
			if not gt then break end
			local inner = strsub(s, lt + 1, gt - 1)
			local selfClose = strsub(inner, -1) == "/"
			if selfClose then inner = strsub(inner, 1, -2) end
			local name = strmatch(inner, "^([%w_:%-%.]+)")
			if name then
				local node = {
					-- tags are lowercased (SVG camelCase like linearGradient) so all
					-- lookup tables can be lowercase; attribute names keep their case
					tag = strlower(strgsub(name, "^[%w_%-%.]+:", "")),
					attrs = parseAttrs(strsub(inner, #name + 1)),
					children = {},
				}
				tinsert(top.children, node)
				if not selfClose then
					tinsert(stack, node)
					top = node
				end
			end
			i = gt + 1
		end
	end

	return root
end

-- Gets an attribute, also checking the xlink: namespaced variant.
local function getAttr(node, name)
	return node.attrs[name] or node.attrs["xlink:" .. name]
end

local function nodeText(node)
	local out = {}
	for _, c in ipairs(node.children) do
		if c.tag == "#text" then out[#out + 1] = c.text end
	end
	return table.concat(out)
end

--------------------------------------------------------------------------------
-- Minimal CSS (type / .class / #id selectors from <style> blocks)
--------------------------------------------------------------------------------

local function parseCssProps(body)
	local props = {}
	for k, v in strgmatch(body, "([%w%-]+)%s*:%s*([^;]+)") do
		props[strlower(trim(k))] = trim(v)
	end
	return props
end

local function parseCss(cssText, index)
	cssText = strgsub(cssText, "/%*.-%*/", "")
	local order = index._order or 0
	for sels, body in strgmatch(cssText, "([^{}]+)%{([^}]*)%}") do
		local props = parseCssProps(body)
		for sel in strgmatch(sels, "[^,]+") do
			sel = trim(sel)
			local rule = nil
			if sel == "*" then
				rule = { spec = 0, props = props }
				tinsert(index.star, rule)
			elseif strmatch(sel, "^%.[%w_%-]+$") then
				rule = { spec = 10, props = props }
				local key = strsub(sel, 2)
				index.byClass[key] = index.byClass[key] or {}
				tinsert(index.byClass[key], rule)
			elseif strmatch(sel, "^#[%w_%-]+$") then
				rule = { spec = 100, props = props }
				local key = strsub(sel, 2)
				index.byId[key] = index.byId[key] or {}
				tinsert(index.byId[key], rule)
			elseif strmatch(sel, "^[%w_%-]+$") then
				rule = { spec = 1, props = props }
				local key = strlower(sel)
				index.byTag[key] = index.byTag[key] or {}
				tinsert(index.byTag[key], rule)
			end
			if rule then
				order = order + 1
				rule.order = order
			end
		end
	end
	index._order = order
end

-- Merged property map for a node: presentation attrs < CSS rules < inline style.
local PRESENTATION_PROPS = {
	["fill"] = true, ["fill-opacity"] = true, ["fill-rule"] = true,
	["stroke"] = true, ["stroke-width"] = true, ["stroke-opacity"] = true,
	["stroke-linecap"] = true, ["stroke-linejoin"] = true, ["stroke-miterlimit"] = true,
	["stroke-dasharray"] = true, ["stroke-dashoffset"] = true,
	["opacity"] = true, ["color"] = true, ["display"] = true, ["visibility"] = true,
	["stop-color"] = true, ["stop-opacity"] = true,
}

local function resolveProps(node, css)
	local props = {}
	for k, v in pairs(node.attrs) do
		local lk = strlower(k)
		if PRESENTATION_PROPS[lk] then props[lk] = v end
	end

	local matches = {}
	local function collect(list)
		if list then
			for _, r in ipairs(list) do tinsert(matches, r) end
		end
	end
	collect(css.star)
	collect(css.byTag[strlower(node.tag)])
	local classAttr = node.attrs.class
	if classAttr then
		for cls in strgmatch(classAttr, "[^%s]+") do
			collect(css.byClass[cls])
		end
	end
	if node.attrs.id then collect(css.byId[node.attrs.id]) end
	table.sort(matches, function(a, b)
		if a.spec ~= b.spec then return a.spec < b.spec end
		return a.order < b.order
	end)
	for _, r in ipairs(matches) do
		for k, v in pairs(r.props) do props[k] = v end
	end

	local style = node.attrs.style
	if style then
		for k, v in pairs(parseCssProps(style)) do props[k] = v end
	end
	return props
end

--------------------------------------------------------------------------------
-- Transform parsing
--------------------------------------------------------------------------------

local function parseTransform(s)
	local m = matIdentity()
	if not s then return m end
	for fn, args in strgmatch(s, "([%w]+)%s*%(([^)]*)%)") do
		local a = parseNumberList(args)
		local t = nil
		fn = strlower(fn)
		if fn == "matrix" and #a >= 6 then
			t = { a[1], a[2], a[3], a[4], a[5], a[6] }
		elseif fn == "translate" then
			t = matTranslate(a[1] or 0, a[2] or 0)
		elseif fn == "scale" then
			t = matScaleM(a[1] or 1, a[2] or a[1] or 1)
		elseif fn == "rotate" then
			local ang = rad(a[1] or 0)
			local c, sn = cos(ang), sin(ang)
			t = { c, sn, -sn, c, 0, 0 }
			if a[2] or a[3] then
				local cx, cy = a[2] or 0, a[3] or 0
				t = matMul(matMul(matTranslate(cx, cy), t), matTranslate(-cx, -cy))
			end
		elseif fn == "skewx" then
			t = { 1, 0, tan(rad(a[1] or 0)), 1, 0, 0 }
		elseif fn == "skewy" then
			t = { 1, tan(rad(a[1] or 0)), 0, 1, 0, 0 }
		end
		if t then m = matMul(m, t) end
	end
	return m
end

--------------------------------------------------------------------------------
-- Path data parser. Output: list of subpaths
--   subpath = { x = startX, y = startY, closed = bool, segs = { seg, ... } }
--   seg = { "L", x, y }  or  { "C", c1x, c1y, c2x, c2y, x, y }
-- Quadratics and arcs are converted to cubics; everything is absolute.
--------------------------------------------------------------------------------

local function readNumber(d, i)
	i = strfind(d, "[^%s,]", i) or (#d + 1)
	local s1, e1 = strfind(d, "^[+-]?%d+%.?%d*", i)
	if not s1 then
		s1, e1 = strfind(d, "^[+-]?%.%d+", i)
	end
	if not s1 then return nil, i end
	local s2, e2 = strfind(d, "^[eE][+-]?%d+", e1 + 1)
	if s2 then e1 = e2 end
	return tonumber(strsub(d, s1, e1)), e1 + 1
end

-- Arc flags are single chars and may be glued to the next number ("a1 1 0 0150,50").
local function readFlag(d, i)
	i = strfind(d, "[^%s,]", i) or (#d + 1)
	local ch = strsub(d, i, i)
	if ch == "0" then return 0, i + 1 end
	if ch == "1" then return 1, i + 1 end
	return nil, i
end

local function vecAngle(ux, uy, vx, vy)
	local d = ux * vx + uy * vy
	local l = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
	if l < 1e-12 then return 0 end
	local a = acos(clamp(d / l, -1, 1))
	if ux * vy - uy * vx < 0 then a = -a end
	return a
end

local function arcToCubics(segs, x1, y1, rx, ry, rotDeg, largeArc, sweep, x2, y2)
	if rx == 0 or ry == 0 then
		tinsert(segs, { "L", x2, y2 })
		return
	end
	rx, ry = abs(rx), abs(ry)
	local phi = rad(rotDeg % 360)
	local cosp, sinp = cos(phi), sin(phi)
	local dx2, dy2 = (x1 - x2) / 2, (y1 - y2) / 2
	local x1p = cosp * dx2 + sinp * dy2
	local y1p = -sinp * dx2 + cosp * dy2
	if x1p == 0 and y1p == 0 then return end

	local l = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
	if l > 1 then
		local sc = sqrt(l)
		rx, ry = rx * sc, ry * sc
	end
	local rx2, ry2 = rx * rx, ry * ry
	local num = rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p
	local den = rx2 * y1p * y1p + ry2 * x1p * x1p
	local co = den > 0 and sqrt(max(0, num / den)) or 0
	if largeArc == sweep then co = -co end
	local cxp = co * rx * y1p / ry
	local cyp = -co * ry * x1p / rx
	local cx = cosp * cxp - sinp * cyp + (x1 + x2) / 2
	local cy = sinp * cxp + cosp * cyp + (y1 + y2) / 2

	local ux, uy = (x1p - cxp) / rx, (y1p - cyp) / ry
	local vx, vy = (-x1p - cxp) / rx, (-y1p - cyp) / ry
	local theta = vecAngle(1, 0, ux, uy)
	local dtheta = vecAngle(ux, uy, vx, vy)
	if sweep == 0 and dtheta > 0 then dtheta = dtheta - 2 * pi end
	if sweep == 1 and dtheta < 0 then dtheta = dtheta + 2 * pi end

	local nsegs = max(1, ceil(abs(dtheta) / (pi / 2 + 0.001)))
	local delta = dtheta / nsegs
	local kfac = 4 / 3 * tan(delta / 4)
	local px, py = x1, y1

	for seg = 1, nsegs do
		local t2 = theta + delta
		local sinT1, cosT1 = sin(theta), cos(theta)
		local sinT2, cosT2 = sin(t2), cos(t2)
		local c1x = px + kfac * (-rx * cosp * sinT1 - ry * sinp * cosT1)
		local c1y = py + kfac * (-rx * sinp * sinT1 + ry * cosp * cosT1)
		local ex = cx + rx * cosp * cosT2 - ry * sinp * sinT2
		local ey = cy + rx * sinp * cosT2 + ry * cosp * sinT2
		local c2x = ex - kfac * (-rx * cosp * sinT2 - ry * sinp * cosT2)
		local c2y = ey - kfac * (-rx * sinp * sinT2 + ry * cosp * cosT2)
		if seg == nsegs then ex, ey = x2, y2 end
		tinsert(segs, { "C", c1x, c1y, c2x, c2y, ex, ey })
		px, py, theta = ex, ey, t2
	end
end

local function parsePath(d)
	local subpaths = {}
	local cur = nil
	local cx, cy = 0, 0
	local sx, sy = 0, 0
	local lastC2x, lastC2y = nil, nil -- last cubic control (for S)
	local lastQx, lastQy = nil, nil   -- last quadratic control (for T)
	local lastCmd = nil
	local i = 1
	local n = #d

	local function open(x, y)
		cur = { x = x, y = y, closed = false, segs = {} }
		tinsert(subpaths, cur)
		sx, sy = x, y
	end

	local function ensureOpen()
		if not cur then open(cx, cy) end
	end

	while i <= n do
		local ws = strfind(d, "[^%s,]", i)
		if not ws then break end
		i = ws
		local cmd = strmatch(strsub(d, i, i), "[MmLlHhVvCcSsQqTtAaZz]")
		if cmd then
			i = i + 1
		else
			-- implicit repeat of the previous command
			cmd = lastCmd
			if not cmd or cmd == "Z" or cmd == "z" then break end
			if cmd == "M" then cmd = "L" elseif cmd == "m" then cmd = "l" end
		end

		local rel = cmd >= "a" and cmd <= "z"
		local CMD = strlower(cmd)

		if CMD == "z" then
			if cur then
				cur.closed = true
			end
			cx, cy = sx, sy
			cur = nil
			lastC2x, lastQx = nil, nil
		elseif CMD == "m" then
			local x, y
			x, i = readNumber(d, i)
			y, i = readNumber(d, i)
			if not x or not y then break end
			if rel then x, y = cx + x, cy + y end
			cx, cy = x, y
			open(x, y)
			lastC2x, lastQx = nil, nil
		elseif CMD == "l" then
			local x, y
			x, i = readNumber(d, i)
			y, i = readNumber(d, i)
			if not x or not y then break end
			if rel then x, y = cx + x, cy + y end
			ensureOpen()
			tinsert(cur.segs, { "L", x, y })
			cx, cy = x, y
			lastC2x, lastQx = nil, nil
		elseif CMD == "h" or CMD == "v" then
			local v
			v, i = readNumber(d, i)
			if not v then break end
			local x, y
			if CMD == "h" then
				x = rel and (cx + v) or v
				y = cy
			else
				x = cx
				y = rel and (cy + v) or v
			end
			ensureOpen()
			tinsert(cur.segs, { "L", x, y })
			cx, cy = x, y
			lastC2x, lastQx = nil, nil
		elseif CMD == "c" or CMD == "s" then
			local x1, y1, x2, y2, x, y
			if CMD == "c" then
				x1, i = readNumber(d, i); y1, i = readNumber(d, i)
			else
				if lastC2x then
					x1, y1 = 2 * cx - lastC2x, 2 * cy - lastC2y
				else
					x1, y1 = cx, cy
				end
			end
			x2, i = readNumber(d, i); y2, i = readNumber(d, i)
			x, i = readNumber(d, i); y, i = readNumber(d, i)
			if not x or not y or not x2 or not y2 or not x1 or not y1 then break end
			if rel then
				if CMD == "c" then x1, y1 = cx + x1, cy + y1 end
				x2, y2 = cx + x2, cy + y2
				x, y = cx + x, cy + y
			end
			ensureOpen()
			tinsert(cur.segs, { "C", x1, y1, x2, y2, x, y })
			lastC2x, lastC2y = x2, y2
			lastQx = nil
			cx, cy = x, y
		elseif CMD == "q" or CMD == "t" then
			local qx, qy, x, y
			if CMD == "q" then
				qx, i = readNumber(d, i); qy, i = readNumber(d, i)
			else
				if lastQx then
					qx, qy = 2 * cx - lastQx, 2 * cy - lastQy
				else
					qx, qy = cx, cy
				end
			end
			x, i = readNumber(d, i); y, i = readNumber(d, i)
			if not x or not y or not qx or not qy then break end
			if rel then
				if CMD == "q" then qx, qy = cx + qx, cy + qy end
				x, y = cx + x, cy + y
			end
			ensureOpen()
			-- elevate quadratic to cubic
			local c1x, c1y = cx + 2 / 3 * (qx - cx), cy + 2 / 3 * (qy - cy)
			local c2x, c2y = x + 2 / 3 * (qx - x), y + 2 / 3 * (qy - y)
			tinsert(cur.segs, { "C", c1x, c1y, c2x, c2y, x, y })
			lastQx, lastQy = qx, qy
			lastC2x = nil
			cx, cy = x, y
		elseif CMD == "a" then
			local rx, ry, rot, laf, swf, x, y
			rx, i = readNumber(d, i); ry, i = readNumber(d, i)
			rot, i = readNumber(d, i)
			laf, i = readFlag(d, i); swf, i = readFlag(d, i)
			x, i = readNumber(d, i); y, i = readNumber(d, i)
			if not rx or not ry or not rot or not laf or not swf or not x or not y then break end
			if rel then x, y = cx + x, cy + y end
			ensureOpen()
			arcToCubics(cur.segs, cx, cy, rx, ry, rot, laf, swf, x, y)
			cx, cy = x, y
			lastC2x, lastQx = nil, nil
		end

		lastCmd = cmd
	end

	-- drop empty subpaths
	local out = {}
	for _, sp in ipairs(subpaths) do
		if #sp.segs > 0 then out[#out + 1] = sp end
	end
	return out
end

--------------------------------------------------------------------------------
-- Basic shapes -> subpaths
--------------------------------------------------------------------------------

local function cubicSeg(c1x, c1y, c2x, c2y, x, y)
	return { "C", c1x, c1y, c2x, c2y, x, y }
end

local function ellipseSubpath(cx, cy, rx, ry)
	local kx, ky = rx * KAPPA, ry * KAPPA
	return {
		x = cx + rx, y = cy, closed = true,
		segs = {
			cubicSeg(cx + rx, cy + ky, cx + kx, cy + ry, cx, cy + ry),
			cubicSeg(cx - kx, cy + ry, cx - rx, cy + ky, cx - rx, cy),
			cubicSeg(cx - rx, cy - ky, cx - kx, cy - ry, cx, cy - ry),
			cubicSeg(cx + kx, cy - ry, cx + rx, cy - ky, cx + rx, cy),
		},
	}
end

local function rectSubpath(x, y, w, h, rx, ry)
	if w <= 0 or h <= 0 then return nil end
	rx = rx or 0
	ry = ry or 0
	rx = clamp(rx, 0, w / 2)
	ry = clamp(ry, 0, h / 2)
	if rx <= 0 or ry <= 0 then
		return {
			x = x, y = y, closed = true,
			segs = {
				{ "L", x + w, y }, { "L", x + w, y + h }, { "L", x, y + h }, { "L", x, y },
			},
		}
	end
	local kx, ky = rx * (1 - KAPPA), ry * (1 - KAPPA)
	return {
		x = x + rx, y = y, closed = true,
		segs = {
			{ "L", x + w - rx, y },
			cubicSeg(x + w - kx, y, x + w, y + ky, x + w, y + ry),
			{ "L", x + w, y + h - ry },
			cubicSeg(x + w, y + h - ky, x + w - kx, y + h, x + w - rx, y + h),
			{ "L", x + rx, y + h },
			cubicSeg(x + kx, y + h, x, y + h - ky, x, y + h - ry),
			{ "L", x, y + ry },
			cubicSeg(x, y + ky, x + kx, y, x + rx, y),
		},
	}
end

local function polySubpath(pointsAttr, closed)
	local nums = parseNumberList(pointsAttr)
	if #nums < 4 then return nil end
	local sp = { x = nums[1], y = nums[2], closed = closed, segs = {} }
	for k = 3, #nums - 1, 2 do
		tinsert(sp.segs, { "L", nums[k], nums[k + 1] })
	end
	return sp
end

--------------------------------------------------------------------------------
-- Flattening: subpaths (+matrix) -> device-space polylines { x1,y1,x2,y2,... }
--------------------------------------------------------------------------------

local function flattenCubic(out, x0, y0, x1, y1, x2, y2, x3, y3, tol, depth)
	local dx, dy = x3 - x0, y3 - y0
	local chord2 = dx * dx + dy * dy
	if chord2 < 1e-9 then
		-- degenerate chord: split if the control net is large (loops back on itself)
		local s1 = (x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)
		local s2 = (x2 - x0) * (x2 - x0) + (y2 - y0) * (y2 - y0)
		if depth >= 10 or max(s1, s2) <= tol * tol then
			out[#out + 1] = x3; out[#out + 1] = y3
			return
		end
	else
		local d1 = abs((x1 - x0) * dy - (y1 - y0) * dx)
		local d2 = abs((x2 - x0) * dy - (y2 - y0) * dx)
		if depth >= 10 or (d1 + d2) * (d1 + d2) <= tol * chord2 then
			out[#out + 1] = x3; out[#out + 1] = y3
			return
		end
	end

	local x01, y01 = (x0 + x1) / 2, (y0 + y1) / 2
	local x12, y12 = (x1 + x2) / 2, (y1 + y2) / 2
	local x23, y23 = (x2 + x3) / 2, (y2 + y3) / 2
	local xa, ya = (x01 + x12) / 2, (y01 + y12) / 2
	local xb, yb = (x12 + x23) / 2, (y12 + y23) / 2
	local xm, ym = (xa + xb) / 2, (ya + yb) / 2
	flattenCubic(out, x0, y0, x01, y01, xa, ya, xm, ym, tol, depth + 1)
	flattenCubic(out, xm, ym, xb, yb, x23, y23, x3, y3, tol, depth + 1)
end

-- Returns { points = flatArray, closed = bool } per subpath, transformed by m.
local function flattenSubpaths(subpaths, m, tol)
	tol = tol or tinysvg.TessTolerance
	local out = {}
	for _, sp in ipairs(subpaths) do
		local pts = {}
		local px, py = matApply(m, sp.x, sp.y)
		pts[1], pts[2] = px, py
		local cxp, cyp = sp.x, sp.y
		for _, seg in ipairs(sp.segs) do
			if seg[1] == "L" then
				local dxp, dyp = matApply(m, seg[2], seg[3])
				pts[#pts + 1] = dxp; pts[#pts + 1] = dyp
				cxp, cyp = seg[2], seg[3]
			else
				local lx, ly = matApply(m, cxp, cyp)
				local c1x, c1y = matApply(m, seg[2], seg[3])
				local c2x, c2y = matApply(m, seg[4], seg[5])
				local ex, ey = matApply(m, seg[6], seg[7])
				flattenCubic(pts, lx, ly, c1x, c1y, c2x, c2y, ex, ey, tol, 0)
				cxp, cyp = seg[6], seg[7]
			end
		end
		-- strip consecutive duplicates
		local clean = { pts[1], pts[2] }
		for k = 3, #pts - 1, 2 do
			local lastX, lastY = clean[#clean - 1], clean[#clean]
			if abs(pts[k] - lastX) > 1e-6 or abs(pts[k + 1] - lastY) > 1e-6 then
				clean[#clean + 1] = pts[k]
				clean[#clean + 1] = pts[k + 1]
			end
		end
		-- drop the closing duplicate of a closed loop
		if sp.closed and #clean >= 4 then
			if abs(clean[1] - clean[#clean - 1]) < 1e-6 and abs(clean[2] - clean[#clean]) < 1e-6 then
				clean[#clean] = nil
				clean[#clean] = nil
			end
		end
		if #clean >= 4 then
			tinsert(out, { points = clean, closed = sp.closed and true or false })
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- Stroke tessellation: device polylines -> triangle soup { x1,y1,x2,y2,x3,y3 }
--------------------------------------------------------------------------------

local function emitTri(tris, x1, y1, x2, y2, x3, y3)
	local k = #tris
	tris[k + 1] = x1; tris[k + 2] = y1
	tris[k + 3] = x2; tris[k + 4] = y2
	tris[k + 5] = x3; tris[k + 6] = y3
end

local function emitArcFan(tris, cx, cy, x0, y0, x1, y1, r)
	local a0 = atan2(y0 - cy, x0 - cx)
	local a1 = atan2(y1 - cy, x1 - cx)
	local delta = a1 - a0
	while delta > pi do delta = delta - 2 * pi end
	while delta < -pi do delta = delta + 2 * pi end
	local steps = max(1, ceil(abs(delta) / 0.35))
	local px, py = x0, y0
	for s = 1, steps do
		local a = a0 + delta * (s / steps)
		local nx, ny = cx + cos(a) * r, cy + sin(a) * r
		emitTri(tris, cx, cy, px, py, nx, ny)
		px, py = nx, ny
	end
end

-- Half-circle (or any >90°) fans are direction-ambiguous; route via an explicit
-- midpoint so the bulge lands on the intended side.
local function emitArcFanVia(tris, cx, cy, x0, y0, mx, my, x1, y1, r)
	emitArcFan(tris, cx, cy, x0, y0, mx, my, r)
	emitArcFan(tris, cx, cy, mx, my, x1, y1, r)
end

local function emitCircle(tris, cx, cy, r)
	local steps = max(6, ceil(pi / 0.35))
	local px, py = cx + r, cy
	for s = 1, steps do
		local a = (2 * pi) * (s / steps)
		local nx, ny = cx + cos(a) * r, cy + sin(a) * r
		emitTri(tris, cx, cy, px, py, nx, ny)
		px, py = nx, ny
	end
end

-- Splits a flat polyline by an SVG dash pattern (lengths already device-scaled).
local function dashPolyline(pts, closed, pattern, offset)
	local lens = {}
	local total = 0
	for _, v in ipairs(pattern) do
		if v < 0 then return nil end
		total = total + v
		lens[#lens + 1] = v
	end
	if total <= 1e-9 then return nil end
	if #lens % 2 == 1 then
		for k = 1, #lens do lens[#lens + 1] = lens[k] end
		total = total * 2
	end

	-- pattern cursor after applying dashoffset
	local phase = (offset or 0) % total
	if phase < 0 then phase = phase + total end
	local di = 1
	local on = true
	local remain = lens[1]
	while phase > 0 do
		if phase >= remain then
			phase = phase - remain
			di = di % #lens + 1
			on = not on
			remain = lens[di]
		else
			remain = remain - phase
			phase = 0
		end
	end

	local src = pts
	if closed then
		src = {}
		for k = 1, #pts do src[k] = pts[k] end
		src[#src + 1] = pts[1]
		src[#src + 1] = pts[2]
	end

	local out = {}
	local curRun = nil
	if on then curRun = { src[1], src[2] } end

	local n = #src / 2
	for k = 1, n - 1 do
		local x0, y0 = src[k * 2 - 1], src[k * 2]
		local x1, y1 = src[k * 2 + 1], src[k * 2 + 2]
		local segLen = sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
		local t = 0
		while segLen - t > 1e-9 do
			local step = min(remain, segLen - t)
			t = t + step
			remain = remain - step
			local ix, iy = lerp(t / segLen, x0, x1), lerp(t / segLen, y0, y1)
			if remain <= 1e-9 then
				-- pattern segment boundary
				if on then
					curRun[#curRun + 1] = ix
					curRun[#curRun + 1] = iy
					if #curRun >= 4 then tinsert(out, curRun) end
					curRun = nil
				else
					curRun = { ix, iy }
				end
				on = not on
				di = di % #lens + 1
				remain = lens[di]
			elseif t >= segLen and on then
				-- segment ends inside an "on" run: carry the vertex
				curRun[#curRun + 1] = x1
				curRun[#curRun + 1] = y1
			end
		end
	end
	if curRun and #curRun >= 4 then tinsert(out, curRun) end
	return out
end

-- polys: list of { points, closed }; returns triangle soup.
local function strokeTessellate(polys, width, cap, join, miterLimit, dashPattern, dashOffset)
	local h = max(width, 0.01) * 0.5
	local tris = {}
	cap = cap or "butt"
	join = join or "miter"
	miterLimit = miterLimit or 4

	local lines = {}
	for _, poly in ipairs(polys) do
		if dashPattern then
			local runs = dashPolyline(poly.points, poly.closed, dashPattern, dashOffset)
			if runs then
				for _, run in ipairs(runs) do
					tinsert(lines, { points = run, closed = false })
				end
			else
				tinsert(lines, poly)
			end
		else
			tinsert(lines, poly)
		end
	end

	for _, line in ipairs(lines) do
		local pts = line.points
		local n = #pts / 2
		if n == 1 then
			if cap == "round" then
				emitCircle(tris, pts[1], pts[2], h)
			elseif cap == "square" then
				local x, y = pts[1], pts[2]
				emitTri(tris, x - h, y - h, x + h, y - h, x + h, y + h)
				emitTri(tris, x - h, y - h, x + h, y + h, x - h, y + h)
			end
		elseif n >= 2 then
			-- build segment list (skip zero-length)
			local segs = {}
			local count = line.closed and n or (n - 1)
			for k = 1, count do
				local k2 = k % n + 1
				local x0, y0 = pts[k * 2 - 1], pts[k * 2]
				local x1, y1 = pts[k2 * 2 - 1], pts[k2 * 2]
				local dx, dy = x1 - x0, y1 - y0
				local len = sqrt(dx * dx + dy * dy)
				if len > 1e-9 then
					tinsert(segs, {
						x0 = x0, y0 = y0, x1 = x1, y1 = y1,
						dx = dx / len, dy = dy / len,
						nx = -dy / len, ny = dx / len,
					})
				end
			end

			local m = #segs
			if m > 0 then
				-- quads
				for k = 1, m do
					local s = segs[k]
					local ax, ay = s.x0 + s.nx * h, s.y0 + s.ny * h
					local bx, by = s.x1 + s.nx * h, s.y1 + s.ny * h
					local cx2, cy2 = s.x1 - s.nx * h, s.y1 - s.ny * h
					local dx2, dy2 = s.x0 - s.nx * h, s.y0 - s.ny * h
					emitTri(tris, ax, ay, bx, by, cx2, cy2)
					emitTri(tris, ax, ay, cx2, cy2, dx2, dy2)
				end

				-- joins
				local jcount = line.closed and m or (m - 1)
				for k = 1, jcount do
					local a = segs[k]
					local b = segs[k % m + 1]
					local px, py = a.x1, a.y1
					local cross = a.dx * b.dy - a.dy * b.dx
					local dot = a.dx * b.dx + a.dy * b.dy
					if abs(cross) > 1e-9 or dot < 0 then
						local sgn = cross >= 0 and -1 or 1
						local e0x, e0y = px + a.nx * h * sgn, py + a.ny * h * sgn
						local e1x, e1y = px + b.nx * h * sgn, py + b.ny * h * sgn
						if dot < -0.999999 then
							-- 180° reversal: bulge forward along the incoming direction, like a cap
							emitArcFanVia(tris, px, py, e0x, e0y, px + a.dx * h, py + a.dy * h, e1x, e1y, h)
						elseif join == "round" then
							emitArcFan(tris, px, py, e0x, e0y, e1x, e1y, h)
						elseif join == "bevel" then
							emitTri(tris, px, py, e0x, e0y, e1x, e1y)
						else -- miter
							local mx, my = a.nx * sgn + b.nx * sgn, a.ny * sgn + b.ny * sgn
							local mlen = sqrt(mx * mx + my * my)
							if mlen > 1e-9 then
								mx, my = mx / mlen, my / mlen
								local cosHalf = mx * (a.nx * sgn) + my * (a.ny * sgn)
								if cosHalf > 1e-6 and (1 / cosHalf) <= miterLimit then
									local tipx, tipy = px + mx * h / cosHalf, py + my * h / cosHalf
									emitTri(tris, px, py, e0x, e0y, tipx, tipy)
									emitTri(tris, px, py, tipx, tipy, e1x, e1y)
								else
									emitTri(tris, px, py, e0x, e0y, e1x, e1y)
								end
							end
						end
					end
				end

				-- caps
				if not line.closed then
					local s0 = segs[1]
					local s1 = segs[m]
					if cap == "round" then
						emitArcFanVia(tris, s0.x0, s0.y0,
							s0.x0 + s0.nx * h, s0.y0 + s0.ny * h,
							s0.x0 - s0.dx * h, s0.y0 - s0.dy * h,
							s0.x0 - s0.nx * h, s0.y0 - s0.ny * h, h)
						emitArcFanVia(tris, s1.x1, s1.y1,
							s1.x1 - s1.nx * h, s1.y1 - s1.ny * h,
							s1.x1 + s1.dx * h, s1.y1 + s1.dy * h,
							s1.x1 + s1.nx * h, s1.y1 + s1.ny * h, h)
					elseif cap == "square" then
						local ex, ey = -s0.dx * h, -s0.dy * h
						emitTri(tris, s0.x0 + s0.nx * h, s0.y0 + s0.ny * h, s0.x0 + s0.nx * h + ex, s0.y0 + s0.ny * h + ey, s0.x0 - s0.nx * h + ex, s0.y0 - s0.ny * h + ey)
						emitTri(tris, s0.x0 + s0.nx * h, s0.y0 + s0.ny * h, s0.x0 - s0.nx * h + ex, s0.y0 - s0.ny * h + ey, s0.x0 - s0.nx * h, s0.y0 - s0.ny * h)
						ex, ey = s1.dx * h, s1.dy * h
						emitTri(tris, s1.x1 + s1.nx * h, s1.y1 + s1.ny * h, s1.x1 + s1.nx * h + ex, s1.y1 + s1.ny * h + ey, s1.x1 - s1.nx * h + ex, s1.y1 - s1.ny * h + ey)
						emitTri(tris, s1.x1 + s1.nx * h, s1.y1 + s1.ny * h, s1.x1 - s1.nx * h + ex, s1.y1 - s1.ny * h + ey, s1.x1 - s1.nx * h, s1.y1 - s1.ny * h)
					end
				end
			end
		end
	end

	return tris
end

--------------------------------------------------------------------------------
-- Gradient resolution
--------------------------------------------------------------------------------

local function resolveGradient(doc, id, depth)
	depth = depth or 0
	if depth > 4 then return nil end
	local cached = doc.gradients[id]
	if cached ~= nil then return cached or nil end

	local node = doc.idmap[id]
	if not node or (node.tag ~= "lineargradient" and node.tag ~= "radialgradient") then
		doc.gradients[id] = false
		return nil
	end

	-- collect the href chain
	local chain = {}
	local seen = {}
	local cur = node
	while cur and not seen[cur] and #chain < 5 do
		seen[cur] = true
		tinsert(chain, cur)
		local href = getAttr(cur, "href")
		local refId = href and strmatch(href, "^#(.+)$")
		cur = refId and doc.idmap[refId] or nil
		if cur and cur.tag ~= "lineargradient" and cur.tag ~= "radialgradient" then cur = nil end
	end

	local function chainAttr(name)
		for _, cn in ipairs(chain) do
			if cn.attrs[name] ~= nil then return cn.attrs[name] end
		end
		return nil
	end

	-- stops come from the first node in the chain that has any
	local stops = {}
	for _, cn in ipairs(chain) do
		local found = false
		for _, child in ipairs(cn.children) do
			if child.tag == "stop" then
				found = true
				local props = resolveProps(child, doc.css)
				local off = child.attrs.offset or "0"
				if strsub(trim(off), -1) == "%" then
					off = (tonumber(strsub(trim(off), 1, -2)) or 0) / 100
				else
					off = tonumber(off) or 0
				end
				off = clamp(off, 0, 1)
				local col = parseColor(props["stop-color"] or "#000")
				if col == "none" or not col then col = { 0, 0, 0, 255 } end
				if strlower(props["stop-color"] or "") == "currentcolor" then
					col = { doc.currentColor[1], doc.currentColor[2], doc.currentColor[3], doc.currentColor[4] }
				end
				local sop = tonumber(props["stop-opacity"]) or 1
				tinsert(stops, { off = off, r = col[1], g = col[2], b = col[3], a = col[4] * clamp(sop, 0, 1) })
			end
		end
		if found then break end
	end
	if #stops == 0 then
		doc.gradients[id] = false
		return nil
	end
	-- enforce non-decreasing offsets
	for k = 2, #stops do
		if stops[k].off < stops[k - 1].off then stops[k].off = stops[k - 1].off end
	end

	local grad = {
		id = id,
		type = node.tag == "lineargradient" and "linear" or "radial",
		stops = stops,
		units = strlower(chainAttr("gradientUnits") or "objectboundingbox"),
		transform = parseTransform(chainAttr("gradientTransform")),
		spread = strlower(chainAttr("spreadMethod") or "pad"),
	}

	local obb = grad.units ~= "userspaceonuse"
	local vw = doc.viewBox and doc.viewBox[3] or 100
	local vh = doc.viewBox and doc.viewBox[4] or 100
	local refX = obb and 1 or vw
	local refY = obb and 1 or vh
	local refD = obb and 1 or sqrt((vw * vw + vh * vh) / 2)

	if grad.type == "linear" then
		grad.x1 = parseLengthPct(chainAttr("x1") or "0%", refX) or 0
		grad.y1 = parseLengthPct(chainAttr("y1") or "0%", refY) or 0
		grad.x2 = parseLengthPct(chainAttr("x2") or "100%", refX) or refX
		grad.y2 = parseLengthPct(chainAttr("y2") or "0%", refY) or 0
	else
		grad.cx = parseLengthPct(chainAttr("cx") or "50%", refX) or refX / 2
		grad.cy = parseLengthPct(chainAttr("cy") or "50%", refY) or refY / 2
		grad.r = parseLengthPct(chainAttr("r") or "50%", refD) or refD / 2
		grad.fx = parseLengthPct(chainAttr("fx"), refX) or grad.cx
		grad.fy = parseLengthPct(chainAttr("fy"), refY) or grad.cy
	end

	doc.gradients[id] = grad
	if grad.spread ~= "pad" then
		tinsert(doc.warnings, "gradient '" .. id .. "': spreadMethod '" .. grad.spread .. "' rendered as pad")
	end
	return grad
end

local function sampleGradient(stops, t)
	local first, last = stops[1], stops[#stops]
	if t <= first.off then return first.r, first.g, first.b, first.a end
	if t >= last.off then return last.r, last.g, last.b, last.a end
	for k = 2, #stops do
		local s1, s0 = stops[k], stops[k - 1]
		if t <= s1.off then
			local span = s1.off - s0.off
			local f = span > 1e-9 and (t - s0.off) / span or 0
			return lerp(f, s0.r, s1.r), lerp(f, s0.g, s1.g), lerp(f, s0.b, s1.b), lerp(f, s0.a, s1.a)
		end
	end
	return last.r, last.g, last.b, last.a
end

--------------------------------------------------------------------------------
-- Document build: XML tree -> flat display list of fill/stroke primitives
--------------------------------------------------------------------------------

local STYLE_DEFAULTS = {
	fill = { col = { 0, 0, 0, 255 } },
	fillOpacity = 1,
	rule = "nonzero",
	stroke = "none",
	strokeOpacity = 1,
	strokeWidth = 1,
	cap = "butt",
	join = "miter",
	miterlimit = 4,
	dash = false,
	dashoffset = 0,
}

local function copyStyle(st)
	local out = {}
	for k, v in pairs(st) do out[k] = v end
	return out
end

local function parsePaint(value, style, doc)
	if not value then return nil end
	value = trim(value)
	local lower = strlower(value)
	if lower == "none" then return "none" end
	if lower == "currentcolor" then
		local c = style.color or doc.currentColor
		return { col = { c[1], c[2], c[3], c[4] } }
	end
	local url = strmatch(value, "^url%s*%(%s*['\"]?#([^'\")%s]+)['\"]?%s*%)")
	if url then
		return { grad = url }
	end
	local col = parseColor(value)
	if col == "none" then return "none" end
	if col then return { col = col } end
	return nil
end

local function applyProps(style, props, doc)
	local v

	v = props["color"]
	if v then
		local c = parseColor(v)
		if c and c ~= "none" then style.color = c end
	end

	v = props["fill"]
	if v then
		local p = parsePaint(v, style, doc)
		if p then style.fill = p end
	end
	v = props["fill-opacity"]
	if v then style.fillOpacity = clamp(tonumber(v) or 1, 0, 1) end
	v = props["fill-rule"]
	if v then
		v = strlower(trim(v))
		if v == "evenodd" or v == "nonzero" then style.rule = v end
	end

	v = props["stroke"]
	if v then
		local p = parsePaint(v, style, doc)
		if p then style.stroke = p end
	end
	v = props["stroke-opacity"]
	if v then style.strokeOpacity = clamp(tonumber(v) or 1, 0, 1) end
	v = props["stroke-width"]
	if v then
		local w = parseLengthPct(v, doc.strokePctRef)
		if w then style.strokeWidth = max(w, 0) end
	end
	v = props["stroke-linecap"]
	if v then
		v = strlower(trim(v))
		if v == "butt" or v == "round" or v == "square" then style.cap = v end
	end
	v = props["stroke-linejoin"]
	if v then
		v = strlower(trim(v))
		if v == "miter" or v == "round" or v == "bevel" then style.join = v end
	end
	v = props["stroke-miterlimit"]
	if v then style.miterlimit = max(tonumber(v) or 4, 1) end
	v = props["stroke-dasharray"]
	if v then
		v = strlower(trim(v))
		if v == "none" then
			style.dash = false
		else
			local nums = {}
			for _, s in ipairs(parseNumberList(v)) do nums[#nums + 1] = s end
			local any = false
			for _, s in ipairs(nums) do
				if s > 0 then any = true end
				if s < 0 then any = false break end
			end
			style.dash = (any and #nums > 0) and nums or false
		end
	end
	v = props["stroke-dashoffset"]
	if v then style.dashoffset = parseLengthPct(v, doc.strokePctRef) or 0 end
end

local SHAPE_TAGS = {
	path = true, rect = true, circle = true, ellipse = true,
	line = true, polyline = true, polygon = true,
}

local SKIP_TAGS = {
	defs = true, title = true, desc = true, metadata = true, style = true,
	lineargradient = true, radialgradient = true, pattern = true, marker = true,
	clippath = true, mask = true, filter = true, symbol = true, script = true,
	["#text"] = true,
}

local UNSUPPORTED_WARN = {
	text = "text elements", image = "embedded images",
	foreignobject = "foreignObject",
}

local function shapeToSubpaths(node, doc)
	local tag = node.tag
	local at = node.attrs
	if tag == "path" then
		if not at.d then return nil end
		return parsePath(at.d)
	elseif tag == "rect" then
		local x = parseLengthPct(at.x or 0, doc.vbW) or 0
		local y = parseLengthPct(at.y or 0, doc.vbH) or 0
		local w = parseLengthPct(at.width or 0, doc.vbW) or 0
		local h = parseLengthPct(at.height or 0, doc.vbH) or 0
		local rx = at.rx and parseLengthPct(at.rx, doc.vbW) or nil
		local ry = at.ry and parseLengthPct(at.ry, doc.vbH) or nil
		if rx and rx < 0 then rx = nil end
		if ry and ry < 0 then ry = nil end
		rx = rx or ry
		ry = ry or rx
		local sp = rectSubpath(x, y, w, h, rx or 0, ry or 0)
		return sp and { sp } or nil
	elseif tag == "circle" then
		local cx = parseLengthPct(at.cx or 0, doc.vbW) or 0
		local cy = parseLengthPct(at.cy or 0, doc.vbH) or 0
		local r = parseLengthPct(at.r or 0, doc.strokePctRef) or 0
		if r <= 0 then return nil end
		return { ellipseSubpath(cx, cy, r, r) }
	elseif tag == "ellipse" then
		local cx = parseLengthPct(at.cx or 0, doc.vbW) or 0
		local cy = parseLengthPct(at.cy or 0, doc.vbH) or 0
		local rx = parseLengthPct(at.rx or 0, doc.vbW) or 0
		local ry = parseLengthPct(at.ry or 0, doc.vbH) or 0
		if rx <= 0 or ry <= 0 then return nil end
		return { ellipseSubpath(cx, cy, rx, ry) }
	elseif tag == "line" then
		local x1 = parseLengthPct(at.x1 or 0, doc.vbW) or 0
		local y1 = parseLengthPct(at.y1 or 0, doc.vbH) or 0
		local x2 = parseLengthPct(at.x2 or 0, doc.vbW) or 0
		local y2 = parseLengthPct(at.y2 or 0, doc.vbH) or 0
		return { { x = x1, y = y1, closed = false, segs = { { "L", x2, y2 } } } }
	elseif tag == "polyline" or tag == "polygon" then
		local sp = polySubpath(at.points, tag == "polygon")
		return sp and { sp } or nil
	end
	return nil
end

-- user-space bbox of subpaths (control-point hull — fine for gradients/cover)
local function subpathsBBox(subpaths)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	local function pt(x, y)
		if x < minX then minX = x end
		if y < minY then minY = y end
		if x > maxX then maxX = x end
		if y > maxY then maxY = y end
	end
	for _, sp in ipairs(subpaths) do
		pt(sp.x, sp.y)
		for _, seg in ipairs(sp.segs) do
			if seg[1] == "L" then
				pt(seg[2], seg[3])
			else
				pt(seg[2], seg[3]); pt(seg[4], seg[5]); pt(seg[6], seg[7])
			end
		end
	end
	if minX > maxX then return { 0, 0, 0, 0 } end
	return { minX, minY, maxX - minX, maxY - minY }
end

local function buildWalk(doc, node, ctm, style, opacity, useDepth)
	local tag = node.tag

	if SKIP_TAGS[tag] then return end
	if UNSUPPORTED_WARN[tag] then
		if not doc._warned[tag] then
			doc._warned[tag] = true
			tinsert(doc.warnings, "unsupported: " .. UNSUPPORTED_WARN[tag])
		end
		return
	end

	local props = resolveProps(node, doc.css)
	if strlower(props["display"] or "") == "none" then return end
	if strlower(props["visibility"] or "") == "hidden" then return end

	style = copyStyle(style)
	applyProps(style, props, doc)

	local nodeOpacity = clamp(tonumber(props["opacity"]) or 1, 0, 1)
	opacity = opacity * nodeOpacity
	if opacity <= 0 then return end

	if node.attrs.transform then
		ctm = matMul(ctm, parseTransform(node.attrs.transform))
	end

	if tag == "g" or tag == "a" or tag == "switch" then
		for _, child in ipairs(node.children) do
			buildWalk(doc, child, ctm, style, opacity, useDepth)
		end
		return
	end

	if tag == "svg" then
		-- nested <svg>: simple x/y translation (root svg never reaches here)
		local x = parseLengthPct(node.attrs.x or 0, doc.vbW) or 0
		local y = parseLengthPct(node.attrs.y or 0, doc.vbH) or 0
		if x ~= 0 or y ~= 0 then ctm = matMul(ctm, matTranslate(x, y)) end
		for _, child in ipairs(node.children) do
			buildWalk(doc, child, ctm, style, opacity, useDepth)
		end
		return
	end

	if tag == "use" then
		if useDepth >= 8 then return end
		local href = getAttr(node, "href")
		local refId = href and strmatch(href, "^#(.+)$")
		local target = refId and doc.idmap[refId]
		if not target then return end
		local x = parseLengthPct(node.attrs.x or 0, doc.vbW) or 0
		local y = parseLengthPct(node.attrs.y or 0, doc.vbH) or 0
		local m2 = (x ~= 0 or y ~= 0) and matMul(ctm, matTranslate(x, y)) or ctm
		if target.tag == "symbol" or target.tag == "svg" then
			for _, child in ipairs(target.children) do
				buildWalk(doc, child, m2, style, opacity, useDepth + 1)
			end
		else
			buildWalk(doc, target, m2, style, opacity, useDepth + 1)
		end
		return
	end

	if SHAPE_TAGS[tag] then
		node._subpaths = node._subpaths or shapeToSubpaths(node, doc)
		local sub = node._subpaths
		if not sub or #sub == 0 then return end
		local ubbox = subpathsBBox(sub)

		local fillable = tag ~= "line" -- lines have no area
		if fillable and style.fill ~= "none" and style.fill and style.fillOpacity > 0 then
			tinsert(doc.prims, {
				kind = "fill",
				sub = sub,
				ctm = ctm,
				paint = style.fill,
				opacity = opacity * style.fillOpacity,
				rule = style.rule,
				ubbox = ubbox,
			})
		end
		if style.stroke ~= "none" and style.stroke and style.strokeOpacity > 0 and style.strokeWidth > 0 then
			tinsert(doc.prims, {
				kind = "stroke",
				sub = sub,
				ctm = ctm,
				paint = style.stroke,
				opacity = opacity * style.strokeOpacity,
				width = style.strokeWidth,
				cap = style.cap,
				join = style.join,
				miterlimit = style.miterlimit,
				dash = style.dash or nil,
				dashoffset = style.dashoffset,
				ubbox = ubbox,
			})
		end
		return
	end

	-- unknown container-ish tag: walk children (tolerant)
	for _, child in ipairs(node.children) do
		buildWalk(doc, child, ctm, style, opacity, useDepth)
	end
end

local function indexTree(doc, node)
	if node.attrs and node.attrs.id and not doc.idmap[node.attrs.id] then
		doc.idmap[node.attrs.id] = node
	end
	if node.tag == "style" then
		parseCss(nodeText(node), doc.css)
	end
	for _, child in ipairs(node.children) do
		indexTree(doc, child)
	end
end

local function parsePreserveAspectRatio(s)
	local par = { align = "xmidymid", meet = true }
	if not s then return par end
	s = strlower(trim(s))
	local align = strmatch(s, "^(x%w+)") or strmatch(s, "^(none)")
	if align then par.align = align end
	if strfind(s, "slice", 1, true) then par.meet = false end
	return par
end

--------------------------------------------------------------------------------
-- Document object
--------------------------------------------------------------------------------

local Document = {}
Document.__index = Document

local loadCache = {}

function tinysvg.Parse(svgText, opts)
	if type(svgText) ~= "string" or #svgText == 0 then
		return nil, "empty input"
	end
	opts = opts or {}

	local ok, docOrErr = pcall(function()
		local rootNode = xmlParse(svgText)
		local svgNode = nil
		for _, c in ipairs(rootNode.children) do
			if c.tag == "svg" then svgNode = c break end
		end
		if not svgNode then error("no <svg> element found", 0) end

		local doc = setmetatable({
			prims = {},
			idmap = {},
			gradients = {},
			css = { star = {}, byTag = {}, byClass = {}, byId = {} },
			warnings = {},
			_warned = {},
			_matCache = {},
			_lutCache = {},
			_flatCache = {},
			_flatCount = 0,
		}, Document)

		local cr, cg, cb, ca = colorBits(opts.currentColor, 0, 0, 0, 255)
		doc.currentColor = { cr, cg, cb, ca }

		indexTree(doc, svgNode)

		-- viewport
		local vb = parseNumberList(svgNode.attrs.viewBox)
		local attrW = parseLength(svgNode.attrs.width)
		local attrH = parseLength(svgNode.attrs.height)
		if svgNode.attrs.width and strfind(svgNode.attrs.width, "%%") then attrW = nil end
		if svgNode.attrs.height and strfind(svgNode.attrs.height, "%%") then attrH = nil end

		if #vb >= 4 and vb[3] > 0 and vb[4] > 0 then
			doc.viewBox = { vb[1], vb[2], vb[3], vb[4] }
		elseif attrW and attrH and attrW > 0 and attrH > 0 then
			doc.viewBox = { 0, 0, attrW, attrH }
		end
		doc.width = attrW or (doc.viewBox and doc.viewBox[3])
		doc.height = attrH or (doc.viewBox and doc.viewBox[4])
		doc.vbW = doc.viewBox and doc.viewBox[3] or doc.width or 100
		doc.vbH = doc.viewBox and doc.viewBox[4] or doc.height or 100
		doc.strokePctRef = sqrt((doc.vbW * doc.vbW + doc.vbH * doc.vbH) / 2)
		doc.par = parsePreserveAspectRatio(svgNode.attrs.preserveAspectRatio)

		-- root transform (SVG2) applies inside the viewport
		local rootCtm = matIdentity()
		if svgNode.attrs.transform then
			rootCtm = parseTransform(svgNode.attrs.transform)
		end

		local style = copyStyle(STYLE_DEFAULTS)
		style.color = doc.currentColor

		for _, child in ipairs(svgNode.children) do
			buildWalk(doc, child, rootCtm, style, 1, 0)
		end

		-- no declared size: derive the viewBox from content bounds
		if not doc.viewBox then
			local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
			for _, prim in ipairs(doc.prims) do
				local b = prim.ubbox
				local corners = {
					b[1], b[2], b[1] + b[3], b[2], b[1], b[2] + b[4], b[1] + b[3], b[2] + b[4],
				}
				for k = 1, 8, 2 do
					local x, y = matApply(prim.ctm, corners[k], corners[k + 1])
					local pad = prim.kind == "stroke" and prim.width or 0
					minX = min(minX, x - pad); maxX = max(maxX, x + pad)
					minY = min(minY, y - pad); maxY = max(maxY, y + pad)
				end
			end
			if minX > maxX then minX, minY, maxX, maxY = 0, 0, 1, 1 end
			doc.viewBox = { minX, minY, max(maxX - minX, 1e-6), max(maxY - minY, 1e-6) }
			doc.width = doc.width or doc.viewBox[3]
			doc.height = doc.height or doc.viewBox[4]
			doc.vbW, doc.vbH = doc.viewBox[3], doc.viewBox[4]
		end
		doc.width = doc.width or doc.viewBox[3]
		doc.height = doc.height or doc.viewBox[4]

		doc.crc = util and util.CRC and util.CRC(svgText .. "|" .. cr .. "," .. cg .. "," .. cb .. "," .. ca) or tostring(#svgText)
		allDocs[doc] = true   -- register for the render-readiness cache flush
		return doc
	end)

	if not ok then
		return nil, tostring(docOrErr)
	end
	if tinysvg.PrintWarnings and #docOrErr.warnings > 0 and print then
		for _, w in ipairs(docOrErr.warnings) do
			print("[tinysvg] warning: " .. w)
		end
	end
	return docOrErr
end

-- Loads + caches by path. mount defaults to "GAME"; re-reads when file.Time changes.
function tinysvg.Load(path, mount, opts)
	mount = mount or "GAME"
	local key = mount .. "|" .. path
	local mtime = file.Time(path, mount) or 0
	local cached = loadCache[key]
	if cached and cached.mtime == mtime then
		return cached.doc, cached.err
	end
	local txt = file.Read(path, mount)
	local doc, err
	if not txt then
		doc, err = nil, "tinysvg: cannot read '" .. path .. "' (" .. mount .. ")"
	else
		doc, err = tinysvg.Parse(txt, opts)
	end
	loadCache[key] = { doc = doc, err = err, mtime = mtime }
	return doc, err
end

function tinysvg.ClearCache()
	loadCache = {}
end

function Document:GetSize()
	return self.width or 64, self.height or 64
end

-- viewBox -> target rect matrix honoring preserveAspectRatio
local function viewportMatrix(doc, x, y, w, h)
	local vb = doc.viewBox
	local sx, sy = w / vb[3], h / vb[4]
	local ox, oy = 0, 0
	if doc.par.align ~= "none" then
		local s = doc.par.meet and min(sx, sy) or max(sx, sy)
		sx, sy = s, s
		local exW = w - vb[3] * s
		local exH = h - vb[4] * s
		local ax = strfind(doc.par.align, "xmid", 1, true) and 0.5 or (strfind(doc.par.align, "xmax", 1, true) and 1 or 0)
		local ay = strfind(doc.par.align, "ymid", 1, true) and 0.5 or (strfind(doc.par.align, "ymax", 1, true) and 1 or 0)
		ox, oy = exW * ax, exH * ay
	end
	return matMul(matMul(matTranslate(x + ox, y + oy), matScaleM(sx, sy)), matTranslate(-vb[1], -vb[2]))
end

--------------------------------------------------------------------------------
-- Renderer (stencil-based; everything drawn through the surface library)
--------------------------------------------------------------------------------

local MAX_POLY_VERTS = 60

-- True while rasterizing into one of our render targets; alpha writes must stay
-- force-enabled there (surface drawing does not write RT alpha by default).
local inRasterPass = false

-- Render-to-texture is unreliable during the first frames after a map join: an
-- RT can rasterize BLANK and then get cached forever (until autorefresh rebuilds
-- the docs), which is why icons were invisible on a fresh join but appeared after
-- a code reload. `rasterReady` gates the cached-RT fast path: until the render
-- system has run a few real frames, Document:Draw falls back to the immediate
-- vector Render() (no RT, always correct) and caches nothing blank.
--
-- It must flip true via a hook that ALWAYS fires — NOT PostDrawHUD, which never
-- runs while a fullscreen menu/lobby suppresses the HUD. PostRender fires once per
-- rendered frame unconditionally; we wait a few frames so RT writes are safe, then
-- (rasterReady / allDocs are declared near the top so Parse and Draw capture them
-- as upvalues; the logic below only flips the flag and flushes caches.)
--
-- WHY a simple frame counter is not enough: render-to-texture is blank not just
-- for the first few frames, but for the whole menu/loading phase BEFORE the player
-- spawns into the world — and those frames tick PostRender too. A blank raster
-- produced then gets cached and sticks. So readiness is tied to the player being
-- fully in-game (InitPostEntity), and we additionally FLUSH every doc's material
-- cache a moment after spawn so anything rasterized blank during loading is
-- dropped and re-rasterized in a live render context.
local function flushAllRasters(reason)
	local n = 0
	for d in pairs(allDocs) do d._matCache = {}; n = n + 1 end
	if tinysvg.DebugReady then
		print(("[tinysvg] flushed %d doc raster cache(s) (%s)"):format(n, reason or "?"))
	end
end

-- Public: force every cached raster to be regenerated on next draw. Call this when
-- you KNOW the render context just became valid (e.g. a menu/lobby opening after a
-- fresh map join) if icons ever come up blank.
function tinysvg.InvalidateAll()
	flushAllRasters("InvalidateAll")
end

-- Schedule the post-(re)load settle flushes. Render-to-texture is unreliable for
-- a short while after a map join (and the first draw after a code autorefresh), and
-- a raster produced then sticks blank. We can't cheaply detect a bad raster, so we
-- simply DROP all cached rasters at a few real-time points once things have settled
-- — by REAL TIME, not frame count (frame counts elapse during loading, before the
-- render context is live, which is the trap an earlier version fell into). Each
-- flush makes the next draw re-rasterize; the later ones are guaranteed past the
-- unsettled window, so icons end up correct without any caller cooperation.
local function scheduleSettleFlushes()
	if not timer then return end
	rasterReady = true
	for _, delay in ipairs({ 0.25, 0.75, 1.5, 3.0 }) do
		timer.Simple(delay, function() flushAllRasters("settle@" .. delay .. "s") end)
	end
end

if hook and hook.Add then
	-- Fresh map join.
	hook.Add("InitPostEntity", "tinysvg_raster_ready", scheduleSettleFlushes)
end
-- Also run on file (re)load — covers autorefresh and the case where InitPostEntity
-- already fired before this file loaded (e.g. lua_reload / first gamemode mount).
scheduleSettleFlushes()

-- Diagnostic: `tinysvg_status` in the client console reports the readiness gate.
if concommand and concommand.Add then
	concommand.Add("tinysvg_status", function()
		local ndocs = 0
		for _ in pairs(allDocs) do ndocs = ndocs + 1 end
		print(("[tinysvg] rasterReady=%s  liveDocs=%d"):format(tostring(rasterReady), ndocs))
	end)
	-- Force a re-raster on demand (type `tinysvg_flush` if icons are ever blank).
	concommand.Add("tinysvg_flush", function() tinysvg.InvalidateAll() end)
end

-- Recycled fan-polygon vertex tables: surface.DrawPoly consumes the table during
-- the call, so one persistent array is reused for every fan. Vertex tables live in
-- a side pool (capped at MAX_POLY_VERTS + 1 entries ever) so shrinking the array
-- for a smaller fan doesn't throw them to the GC.
local fanPoly = {}
local fanPolyPool = {}
local fanPolyLen = 0

local function fanPolySetLen(n)
	for k = fanPolyLen + 1, n do
		local v = fanPolyPool[k]
		if not v then
			v = { x = 0, y = 0 }
			fanPolyPool[k] = v
		end
		fanPoly[k] = v
	end
	for k = fanPolyLen, n + 1, -1 do
		fanPoly[k] = nil
	end
	fanPolyLen = n
end

local function drawFanStencil(pts)
	local n = floor(#pts / 2)
	if n < 3 then return end
	local ax, ay = pts[1], pts[2]
	local i = 2
	while i <= n - 1 do
		local j = min(i + MAX_POLY_VERTS - 2, n - 1)
		fanPolySetLen(j - i + 3)
		local apex = fanPoly[1]
		apex.x, apex.y = ax, ay
		local k = 2
		for v = i, j + 1 do
			local vert = fanPoly[k]
			vert.x = pts[v * 2 - 1]
			vert.y = pts[v * 2]
			k = k + 1
		end
		surface.DrawPoly(fanPoly)
		i = j + 1
	end
end

local triPoly = { { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 } }
local function drawTrisStencil(tris)
	for k = 1, #tris, 6 do
		triPoly[1].x, triPoly[1].y = tris[k], tris[k + 1]
		triPoly[2].x, triPoly[2].y = tris[k + 2], tris[k + 3]
		triPoly[3].x, triPoly[3].y = tris[k + 4], tris[k + 5]
		surface.DrawPoly(triPoly)
	end
end

-- Static geometry callbacks for stencilMark (fill = fan per subpath, stroke = tris).
local function drawPolysStencil(polys)
	for k = 1, #polys do
		drawFanStencil(polys[k].points)
	end
end

local function bboxOfFlat(arrays)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for _, arr in ipairs(arrays) do
		local pts = arr.points or arr
		for k = 1, #pts - 1, 2 do
			local x, y = pts[k], pts[k + 1]
			if x < minX then minX = x end
			if x > maxX then maxX = x end
			if y < minY then minY = y end
			if y > maxY then maxY = y end
		end
	end
	if minX > maxX then return nil end
	return minX - 2, minY - 2, maxX + 2, maxY + 2
end

-- Stencil phase 1: mark coverage. drawGeom(geom) is called twice (once per cull
-- mode). It is passed as a statically-defined function + argument — NOT a fresh
-- closure per primitive — so the render path allocates nothing here.
local function stencilMark(mode, drawGeom, geom)
	render.SetStencilEnable(true)
	render.SetStencilWriteMask(255)
	render.SetStencilTestMask(255)
	render.SetStencilReferenceValue(0)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

	draw.NoTexture()
	-- alpha must NOT be 0: the engine skips surface geometry entirely when the
	-- draw color is fully transparent, which would leave the stencil unmarked.
	-- Color writes are masked off below; even unmasked, alpha 1 is a ~0.4% tint.
	surface.SetDrawColor(0, 0, 0, 1)
	render.OverrideColorWriteEnable(true, false)
	render.OverrideAlphaWriteEnable(true, false)

	if mode == "evenodd" then
		render.SetStencilPassOperation(STENCILOPERATION_INVERT)
		render.CullMode(MATERIAL_CULLMODE_CCW)
		drawGeom(geom)
		render.CullMode(MATERIAL_CULLMODE_CW)
		drawGeom(geom)
	elseif mode == "nonzero" then
		render.SetStencilPassOperation(STENCILOPERATION_INCR)
		render.CullMode(MATERIAL_CULLMODE_CCW)
		drawGeom(geom)
		render.SetStencilPassOperation(STENCILOPERATION_DECR)
		render.CullMode(MATERIAL_CULLMODE_CW)
		drawGeom(geom)
	else -- "union" (strokes): saturating increment regardless of winding
		render.SetStencilPassOperation(STENCILOPERATION_INCRSAT)
		render.CullMode(MATERIAL_CULLMODE_CCW)
		drawGeom(geom)
		render.CullMode(MATERIAL_CULLMODE_CW)
		drawGeom(geom)
	end

	render.CullMode(MATERIAL_CULLMODE_CCW)
	render.OverrideColorWriteEnable(false, false)
	if inRasterPass then
		render.OverrideAlphaWriteEnable(true, true)
	else
		render.OverrideAlphaWriteEnable(false, false)
	end

	-- phase 2 setup: paint where stencil != 0, zeroing it as we go (self-cleaning)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)
	render.SetStencilPassOperation(STENCILOPERATION_ZERO)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
end

local function stencilEnd()
	render.SetStencilEnable(false)
end

--------------------------------------------------------------------------------
-- Gradient LUT materials (256x1 strip sampled by u)
--------------------------------------------------------------------------------

local function sanitizeName(s)
	return strlower(strgsub(tostring(s), "[^%w]", "_"))
end

local function getGradientLUT(doc, grad)
	local cached = doc._lutCache[grad.id]
	if cached then return cached end

	local name = "tinysvg_lut_" .. sanitizeName(doc.crc) .. "_" .. sanitizeName(grad.id)
	local tex = GetRenderTargetEx(name, 256, 1,
		RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE,
		4 + 8 + 256 + 512, -- CLAMPS | CLAMPT | NOMIP | NOLOD
		0, IMAGE_FORMAT_BGRA8888)

	render.PushRenderTarget(tex)
	render.Clear(0, 0, 0, 0, false, false)
	render.OverrideAlphaWriteEnable(true, true)
	render.OverrideBlend(true, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
	cam.Start2D()
	draw.NoTexture()
	for px = 0, 255 do
		local r, g, b, a = sampleGradient(grad.stops, px / 255)
		-- fully transparent texels are skipped by the engine; the Clear above
		-- already left them at (0,0,0,0), which is the correct value
		if a > 0 then
			surface.SetDrawColor(r, g, b, a)
			surface.DrawRect(px, 0, 1, 1)
		end
	end
	cam.End2D()
	render.OverrideBlend(false)
	render.OverrideAlphaWriteEnable(false, false)
	render.PopRenderTarget()

	local mat = CreateMaterial(name .. "_mat", "UnlitGeneric", {
		["$basetexture"] = tex:GetName(),
		["$translucent"] = 1,
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
	})
	doc._lutCache[grad.id] = mat
	return mat
end

-- Pre-creates LUTs so no RT pushes happen inside the stencil/raster sequence.
local function ensurePaintResources(doc)
	for _, prim in ipairs(doc.prims) do
		if prim.paint and prim.paint.grad then
			local grad = resolveGradient(doc, prim.paint.grad)
			if grad then getGradientLUT(doc, grad) end
		end
	end
end

--------------------------------------------------------------------------------
-- Paint cover pass
--------------------------------------------------------------------------------

local coverQuad = { { x = 0, y = 0, u = 0, v = 0.5 }, { x = 0, y = 0, u = 0, v = 0.5 }, { x = 0, y = 0, u = 0, v = 0.5 }, { x = 0, y = 0, u = 0, v = 0.5 } }

local function setQuad(i, x, y, u)
	coverQuad[i].x = x
	coverQuad[i].y = y
	coverQuad[i].u = u
end

-- Gradient device matrix: deviceM ∘ (bbox map for objectBoundingBox) ∘ gradientTransform
local function gradientDeviceMatrix(grad, deviceM, ubbox)
	local m = deviceM
	if grad.units ~= "userspaceonuse" then
		local bw = ubbox[3] > 1e-9 and ubbox[3] or 1e-9
		local bh = ubbox[4] > 1e-9 and ubbox[4] or 1e-9
		m = matMul(m, { bw, 0, 0, bh, ubbox[1], ubbox[2] })
	end
	return matMul(m, grad.transform)
end

local function coverSolid(col, opacity, tint, x0, y0, x1, y1)
	local tr, tg, tb, ta = colorBits(tint, 255, 255, 255, 255)
	draw.NoTexture()
	surface.SetDrawColor(
		col[1] * tr / 255,
		col[2] * tg / 255,
		col[3] * tb / 255,
		col[4] * opacity * ta / 255)
	setQuad(1, x0, y0, 0)
	setQuad(2, x1, y0, 0)
	setQuad(3, x1, y1, 0)
	setQuad(4, x0, y1, 0)
	surface.DrawPoly(coverQuad)
end

local function coverLinear(doc, grad, deviceM, ubbox, opacity, tint, x0, y0, x1, y1)
	local G = gradientDeviceMatrix(grad, deviceM, ubbox)
	local invG = matInverse(G)
	if not invG then
		local lr, lg, lb, la = sampleGradient(grad.stops, 1)
		coverSolid({ lr, lg, lb, la }, opacity, tint, x0, y0, x1, y1)
		return
	end
	local gdx, gdy = grad.x2 - grad.x1, grad.y2 - grad.y1
	local glen2 = gdx * gdx + gdy * gdy
	if glen2 < 1e-12 then
		local lr, lg, lb, la = sampleGradient(grad.stops, 1)
		coverSolid({ lr, lg, lb, la }, opacity, tint, x0, y0, x1, y1)
		return
	end

	local function uAt(px, py)
		local qx, qy = matApply(invG, px, py)
		return ((qx - grad.x1) * gdx + (qy - grad.y1) * gdy) / glen2
	end

	local mat = getGradientLUT(doc, grad)
	surface.SetMaterial(mat)
	local tr, tg, tb, ta = colorBits(tint, 255, 255, 255, 255)
	surface.SetDrawColor(tr, tg, tb, 255 * opacity * ta / 255)
	setQuad(1, x0, y0, uAt(x0, y0))
	setQuad(2, x1, y0, uAt(x1, y0))
	setQuad(3, x1, y1, uAt(x1, y1))
	setQuad(4, x0, y1, uAt(x0, y1))
	surface.DrawPoly(coverQuad)
end

local RADIAL_SEGS = 48

local function coverRadial(doc, grad, deviceM, ubbox, opacity, tint, x0, y0, x1, y1)
	local G = gradientDeviceMatrix(grad, deviceM, ubbox)
	if grad.r <= 1e-9 then
		local lr, lg, lb, la = sampleGradient(grad.stops, 1)
		coverSolid({ lr, lg, lb, la }, opacity, tint, x0, y0, x1, y1)
		return
	end

	local mat = getGradientLUT(doc, grad)
	surface.SetMaterial(mat)
	local tr, tg, tb, ta = colorBits(tint, 255, 255, 255, 255)
	surface.SetDrawColor(tr, tg, tb, 255 * opacity * ta / 255)

	-- ring radii at each stop offset (plus 0 and 1)
	local ts = { 0 }
	for _, s in ipairs(grad.stops) do
		if s.off > ts[#ts] + 1e-6 and s.off < 1 then tinsert(ts, s.off) end
	end
	if ts[#ts] < 1 then tinsert(ts, 1) end

	-- SVG radial: circle family from (fx,fy,r=0) at t=0 to (cx,cy,r) at t=1
	local function ringPoint(t, k)
		local a = (2 * pi) * (k / RADIAL_SEGS)
		local rcx = lerp(t, grad.fx, grad.cx)
		local rcy = lerp(t, grad.fy, grad.cy)
		local rr = t * grad.r
		return matApply(G, rcx + cos(a) * rr, rcy + sin(a) * rr)
	end

	-- center disk (t = 0 .. ts[2])
	local t1 = ts[2] or 1
	local fxd, fyd = matApply(G, grad.fx, grad.fy)
	for k = 0, RADIAL_SEGS - 1 do
		local ax, ay = ringPoint(t1, k)
		local bx, by = ringPoint(t1, k + 1)
		setQuad(1, fxd, fyd, 0)
		setQuad(2, fxd, fyd, 0)
		setQuad(3, bx, by, t1)
		setQuad(4, ax, ay, t1)
		surface.DrawPoly(coverQuad)
	end

	-- annuli between consecutive ring radii
	for ri = 2, #ts - 1 do
		local ta1, tb1 = ts[ri], ts[ri + 1]
		for k = 0, RADIAL_SEGS - 1 do
			local iax, iay = ringPoint(ta1, k)
			local ibx, iby = ringPoint(ta1, k + 1)
			local oax, oay = ringPoint(tb1, k)
			local obx, oby = ringPoint(tb1, k + 1)
			setQuad(1, oax, oay, tb1)
			setQuad(2, obx, oby, tb1)
			setQuad(3, ibx, iby, ta1)
			setQuad(4, iax, iay, ta1)
			surface.DrawPoly(coverQuad)
		end
	end

	-- outer pad: full-bbox quad drawn last; the self-zeroing stencil means it only
	-- touches pixels the rings didn't already paint.
	setQuad(1, x0, y0, 1)
	setQuad(2, x1, y0, 1)
	setQuad(3, x1, y1, 1)
	setQuad(4, x0, y1, 1)
	surface.DrawPoly(coverQuad)
end

local function coverPaint(doc, prim, deviceM, tintOpts, x0, y0, x1, y1)
	local paint = prim.paint
	local opacity = prim.opacity * (tintOpts.alpha or 1)
	if paint.col then
		coverSolid(paint.col, opacity, tintOpts.tint, x0, y0, x1, y1)
	elseif paint.grad then
		local grad = resolveGradient(doc, paint.grad)
		if not grad then return end
		if grad.type == "linear" then
			coverLinear(doc, grad, deviceM, prim.ubbox, opacity, tintOpts.tint, x0, y0, x1, y1)
		else
			coverRadial(doc, grad, deviceM, prim.ubbox, opacity, tintOpts.tint, x0, y0, x1, y1)
		end
	end
end

--------------------------------------------------------------------------------
-- Per-primitive flattening cache + render
--------------------------------------------------------------------------------

-- The per-prim cache is a small array scanned by comparing the device matrix
-- quantized per component (~3 decimals for the linear part, 2 for translation) —
-- no key string is formatted per prim per frame. A prim rarely accumulates more
-- than a couple of distinct device matrices before the global 256-entry flush.
local function getFlat(doc, prim, deviceM)
	local cache = doc._flatCache[prim]
	if not cache then
		cache = {}
		doc._flatCache[prim] = cache
	end
	local qa = floor(deviceM[1] * 1000 + 0.5)
	local qb = floor(deviceM[2] * 1000 + 0.5)
	local qc = floor(deviceM[3] * 1000 + 0.5)
	local qd = floor(deviceM[4] * 1000 + 0.5)
	local qe = floor(deviceM[5] * 100 + 0.5)
	local qf = floor(deviceM[6] * 100 + 0.5)
	for k = 1, #cache do
		local entry = cache[k]
		if entry.qa == qa and entry.qb == qb and entry.qc == qc
			and entry.qd == qd and entry.qe == qe and entry.qf == qf then
			return entry
		end
	end

	if doc._flatCount > 256 then
		doc._flatCache = {}
		doc._flatCount = 0
		cache = {}
		doc._flatCache[prim] = cache
	end

	local entry = {
		qa = qa, qb = qb, qc = qc, qd = qd, qe = qe, qf = qf,
		polys = flattenSubpaths(prim.sub, deviceM, tinysvg.TessTolerance),
	}
	if prim.kind == "stroke" then
		local scale = matScale(deviceM)
		local wdev = max(prim.width * scale, 0.1)
		local dash = nil
		if prim.dash then
			dash = {}
			for _, v in ipairs(prim.dash) do dash[#dash + 1] = v * scale end
		end
		entry.tris = strokeTessellate(entry.polys, wdev, prim.cap, prim.join, prim.miterlimit, dash, (prim.dashoffset or 0) * scale)
		entry.bbox = { bboxOfFlat({ entry.tris }) }
	else
		entry.bbox = { bboxOfFlat(entry.polys) }
	end
	cache[#cache + 1] = entry
	doc._flatCount = doc._flatCount + 1
	return entry
end

local function renderPrim(doc, prim, viewM, tintOpts)
	local deviceM = matMul(viewM, prim.ctm)
	local flat = getFlat(doc, prim, deviceM)
	local bx0, by0, bx1, by1 = flat.bbox[1], flat.bbox[2], flat.bbox[3], flat.bbox[4]
	if not bx0 then return end

	if prim.kind == "fill" then
		if #flat.polys == 0 then return end
		stencilMark(prim.rule, drawPolysStencil, flat.polys)
	else
		if not flat.tris or #flat.tris == 0 then return end
		stencilMark("union", drawTrisStencil, flat.tris)
	end

	coverPaint(doc, prim, deviceM, tintOpts, bx0, by0, bx1, by1)
	stencilEnd()
end

--[[
	Immediate-mode vector draw into the current 2D context (HUD, panel Paint, 3D2D).
	Sharp at any size; cost scales with shape count. For icons drawn every frame,
	prefer doc:Draw() which uses a cached render target.
]]
function Document:Render(x, y, w, h, opts)
	opts = opts or {}
	w = w or self.width or 64
	h = h or self.height or 64
	if w <= 0 or h <= 0 or #self.prims == 0 then return end

	ensurePaintResources(self)
	render.ClearStencil()

	local viewM = viewportMatrix(self, x, y, w, h)
	local tintOpts = { tint = opts.tint, alpha = opts.alpha or 1 }
	for _, prim in ipairs(self.prims) do
		renderPrim(self, prim, viewM, tintOpts)
	end
end

--------------------------------------------------------------------------------
-- Rasterization to a cached material
--------------------------------------------------------------------------------

-- NOTE: opts.alpha is deliberately NOT part of the cache key. Opacity is applied
-- cheaply at DRAW time (DrawMaterial modulates the draw colour), so an animating
-- alpha — e.g. a fade-out — reuses the one cached raster instead of re-rasterizing
-- the whole SVG to a new render target every frame (which lagged hard). Only the
-- tint colour (which changes the rasterized pixels) belongs in the key.
--
-- Cache keys are packed integers, not strings, so the per-frame cache hit
-- allocates nothing: _matCache[sizeKey][tintKey]. sizeKey packs (w, h,
-- supersample) — 12 + 12 + 2 bits; tintKey packs RGBA (or -1 for untinted).
local function tintKey(tint)
	if not tint then return -1 end
	local r, g, b, a = colorBits(tint, 255, 255, 255, 255)
	return ((floor(r) * 256 + floor(g)) * 256 + floor(b)) * 256 + floor(a)
end

--------------------------------------------------------------------------------
-- Pooled render targets
--------------------------------------------------------------------------------
-- Engine RTs are permanent once created, so minting a unique RT per
-- (doc, size, tint) grows GPU memory forever. Instead rasters render into a pool
-- of RTs keyed by pixel size. A slot belongs to the raster that last claimed it;
-- a slot not drawn for POOL_REUSE_AFTER seconds may be handed to a different one.
-- Every claim bumps slot.gen, so a doc cache entry whose slot was reassigned
-- (entry.gen ~= slot.gen) simply misses and re-rasterizes — no back-references
-- from the pool to documents, and nothing to release explicitly.
--
-- Caller consequence: do NOT hold the IMaterial from GetMaterial across frames.
-- Re-call GetMaterial each frame (a warm hit is two table lookups); that both
-- revalidates the slot and marks it live so it is not reassigned under you.

local rtPool = {}  -- [rw * 8192 + rh] = array of slots { tex, mat, gen, lastUse }
local POOL_REUSE_AFTER = 5 -- seconds unused before a slot may be reassigned

local function claimSlot(rw, rh)
	local pkey = rw * 8192 + rh
	local slots = rtPool[pkey]
	if not slots then
		slots = {}
		rtPool[pkey] = slots
	end

	local now = RealTime()
	local pick, pickAge = nil, POOL_REUSE_AFTER
	for k = 1, #slots do
		local s = slots[k]
		local age = now - s.lastUse
		if age > pickAge then
			pick, pickAge = s, age
		end
	end

	if not pick then
		local name = "tinysvg_pool_" .. rw .. "x" .. rh .. "_" .. (#slots + 1)
		local tex = GetRenderTargetEx(name, rw, rh,
			RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_SHARED,
			4 + 8 + 256 + 512, -- CLAMPS | CLAMPT | NOMIP | NOLOD
			0, IMAGE_FORMAT_BGRA8888)
		pick = {
			tex = tex,
			mat = CreateMaterial(name .. "_mat", "UnlitGeneric", {
				["$basetexture"] = tex:GetName(),
				["$translucent"] = 1,
				["$vertexcolor"] = 1,
				["$vertexalpha"] = 1,
			}),
			gen = 0,
			lastUse = 0,
		}
		slots[#slots + 1] = pick
	end

	pick.gen = pick.gen + 1
	pick.lastUse = now
	return pick
end

--[[
	Returns an IMaterial with the document rasterized at w x h (premultiplied
	alpha). Cached per (size, supersample, tint). Draw it with doc:Draw or
	tinysvg.DrawMaterial — plain surface.DrawTexturedRect will show dark fringes
	on antialiased edges because of the premultiplied alpha.

	The material is backed by a POOLED render target: re-call GetMaterial every
	frame you draw it (a warm hit is two table lookups) rather than holding the
	returned IMaterial — a raster that stops being requested may have its RT
	reassigned to another document after a few seconds.
]]
function Document:GetMaterial(w, h, opts)
	opts = opts or {}
	w = clamp(floor(w or self.width or 64), 1, 4096)
	h = clamp(floor(h or self.height or 64), 1, 4096)
	local ss = clamp(floor(opts.supersample or 2), 1, 4)

	local sk = (w * 4096 + h) * 4 + (ss - 1)
	local tk = tintKey(opts.tint)
	local bySize = self._matCache[sk]
	local entry = bySize and bySize[tk]
	if entry and entry.gen == entry.slot.gen then
		entry.slot.lastUse = RealTime()
		return entry.slot.mat
	end

	ensurePaintResources(self)

	-- Stencils are only reliable against the shared (screen) depth-stencil
	-- buffer, so the RT may not exceed the screen; shrink uniformly if needed.
	local maxW = min(4096, ScrW())
	local maxH = min(4096, ScrH())
	local fit = min(1, maxW / (w * ss), maxH / (h * ss))
	local rw = max(1, floor(w * ss * fit))
	local rh = max(1, floor(h * ss * fit))

	local slot = claimSlot(rw, rh)

	render.PushRenderTarget(slot.tex)
	render.Clear(0, 0, 0, 0, false, true) -- color + stencil; leave shared depth alone
	cam.Start2D()
	-- surface drawing does not write RT alpha unless forced
	render.OverrideAlphaWriteEnable(true, true)
	-- straight-alpha compositing for color, accumulate coverage in alpha
	render.OverrideBlend(true,
		BLEND_SRC_ALPHA, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD,
		BLEND_ONE, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD)
	inRasterPass = true
	self:Render(0, 0, rw, rh, opts)
	inRasterPass = false
	render.OverrideBlend(false)
	render.OverrideAlphaWriteEnable(false, false)
	cam.End2D()
	render.PopRenderTarget()

	if not bySize then
		bySize = {}
		self._matCache[sk] = bySize
	end
	bySize[tk] = { slot = slot, gen = slot.gen }
	return slot.mat
end

-- Draws a premultiplied-alpha material correctly (used by Document:Draw).
-- Folds in the ambient surface alpha multiplier (set by VGUI panel:SetAlpha and
-- DScrollPanel fades) so an icon fades together with its parent panel — without
-- this, OverrideBlend bypasses the panel alpha and the icon stays fully opaque
-- while everything around it fades. Cheap: it's still one textured quad, no
-- re-raster (opacity is no longer part of the material cache key).
function tinysvg.DrawMaterial(mat, x, y, w, h, alpha)
	alpha = (alpha or 1) * (surface.GetAlphaMultiplier and surface.GetAlphaMultiplier() or 1)
	if alpha <= 0 then return end
	surface.SetMaterial(mat)
	surface.SetDrawColor(255 * alpha, 255 * alpha, 255 * alpha, 255 * alpha)
	render.OverrideBlend(true, BLEND_ONE, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD)
	surface.DrawTexturedRect(x, y, w, h)
	render.OverrideBlend(false)
end

-- Size buckets are 2^k and 3*2^(k-1): 16, 24, 32, 48, 64, ... 1536, 2048.
-- Closed form (no table scan): split v into mantissa/exponent and snap the
-- mantissa up to the next of 0.5 / 0.75 / 1.
local function bucketFor(v)
	if v <= 16 then return 16 end
	if v >= 2048 then return 2048 end
	local m, e = frexp(v)
	if m == 0.5 then return v end -- exact power of two
	if m <= 0.75 then return ldexp(0.75, e) end
	return ldexp(1, e)
end

--[[
	Recommended draw call: rasterizes once per size bucket and reuses the cached
	material, so per-frame cost is one textured quad. Scaling stays crisp because
	the raster re-renders when the requested size outgrows its bucket.
]]
function Document:Draw(x, y, w, h, opts)
	opts = opts or {}
	w = max(floor(w or self.width or 64), 1)
	h = max(floor(h or self.height or 64), 1)

	-- During the first frames after a map join, RT rasterization can produce a
	-- blank texture that then sticks in the cache. Until the render system is
	-- proven live (rasterReady), draw via the immediate vector path — it's correct
	-- from frame 1 and caches nothing, so no blank raster is ever stored.
	if not rasterReady then
		self:Render(x, y, w, h, opts)
		return
	end

	local bw, bh = w, h
	if not opts.exact then
		bw, bh = bucketFor(w), bucketFor(h)
	end
	local mat = self:GetMaterial(bw, bh, opts)
	tinysvg.DrawMaterial(mat, x, y, w, h, opts.alpha)
end

--[[
	Force the raster for (w, h, opts) to exist NOW, in a self-contained render
	context, instead of waiting for the first Draw to build it lazily mid-paint.

	WHY THIS EXISTS — the fade problem this solves:
	  An icon's render target is built the first time it's drawn. If that first
	  draw lands in a panel that's being composited at partial alpha (a fade-in),
	  the engine can corrupt the RT write and a BLANK material gets cached and
	  sticks. Callers used to dodge this by parking the panel off-screen at full
	  alpha for a few frames so every icon rasterized cleanly before the fade —
	  fragile (it only warms icons that actually painted in those frames) and it
	  couples UI fade timing to this caching quirk.

	  Prewarm does the rasterization explicitly and up front. GetMaterial already
	  rasterizes inside its own PushRenderTarget/cam.Start2D block, so it does NOT
	  depend on the ambient paint state at all — calling it here, off the paint
	  path (e.g. on panel open or player spawn), produces a clean cached raster.
	  The subsequent fade just reuses it: opacity is applied at DRAW time and is
	  not part of the material cache key, so animating alpha never re-rasterizes.

	Bucketing matches Draw EXACTLY: pass the same (w, h, opts) you will pass to
	Draw and the warmed key is the one Draw looks up. Returns the IMaterial (or
	nil if not yet rasterReady — warm again after spawn, or just let Draw's
	vector fallback cover those early frames).
]]
function Document:Prewarm(w, h, opts)
	-- Before the render system is proven live, rasterizing would cache a blank.
	-- Skip — Draw falls back to the immediate vector path until then anyway, and
	-- the post-spawn settle flush (scheduleSettleFlushes) drops anything stale.
	if not rasterReady then return nil end
	opts = opts or {}
	w = max(floor(w or self.width or 64), 1)
	h = max(floor(h or self.height or 64), 1)
	local bw, bh = w, h
	if not opts.exact then
		bw, bh = bucketFor(w), bucketFor(h)
	end
	return self:GetMaterial(bw, bh, opts)
end

-- Batch helper: warm a list of docs at one size/opts in a single call. Each item
-- is a doc, or { doc = doc, w = , h = , opts = } to override per icon. Safe to
-- call every time a panel opens — already-cached rasters are a hash hit and cost
-- nothing. Returns the number actually rasterized this call (0 before rasterReady).
function tinysvg.Prewarm(items, w, h, opts)
	if not rasterReady or type(items) ~= "table" then return 0 end
	local n = 0
	for _, it in ipairs(items) do
		local doc = it.Draw and it or it.doc
		if doc and doc.Prewarm then
			if doc:Prewarm(it.w or w, it.h or h, it.opts or opts) then n = n + 1 end
		end
	end
	return n
end

-- Drops cached rasters/luts for this document (e.g. after screen mode changes).
function Document:Invalidate()
	self._matCache = {}
	self._lutCache = {}
	self._flatCache = {}
	self._flatCount = 0
end

--------------------------------------------------------------------------------
-- IconSet — a managed, parse-once cache of named inline SVG icons.
--------------------------------------------------------------------------------
--[[
	A thin convenience layer over Parse/Draw/Prewarm for the common UI case: "I
	have a fixed set of small inline-SVG glyphs I draw by name in panel Paints, and
	I want them to fade in cleanly without the first-paint raster going blank."

	It bundles the three things every caller was otherwise re-implementing:
	  1. Lazy parse + cache by key (parse on first use, reuse forever).
	  2. A UNIQUE doc.crc per icon. Raster RTs are pooled and not named by crc,
	     but gradient LUT textures still are ("tinysvg_lut_<crc>_<gradid>") and
	     those names are GLOBAL engine resources; two icons whose SVG happened to
	     hash to the same crc could clobber each other's gradient LUTs. Keying crc
	     to "<prefix>_<key>" guarantees distinct names across the whole set.
	  3. Batch Prewarm so a panel can rasterize its whole icon set up front (on
	     open / on spawn) instead of lazily mid-fade — which is what corrupts the
	     RT and caches a blank. See Document:Prewarm for the full rationale.

	Usage (sources is a { key = svgString } table):
	  local ICONS = tinysvg.NewIconSet("myui", SOURCES)
	  -- in a Paint hook:
	  ICONS:Draw("back", x, y, w, h, color, alpha)   -- alpha defaults to 1; the
	      -- parent panel's alpha is folded in automatically (fades with the panel)
	  -- on panel open (returns true once actually warmed; retry while false):
	  ICONS:Prewarm({ {"back", 32, goldColor}, {"check", 16, greenColor} })

	prefix MUST be unique per set (it namespaces the RT ids). sources is
	{ key = svgString }; unknown keys draw nothing.
]]
local IconSet = {}
IconSet.__index = IconSet

function tinysvg.NewIconSet(prefix, sources)
	return setmetatable({
		prefix = tostring(prefix or "iconset"),
		sources = sources or {},
		docs = {},          -- key -> parsed Document or false (parse failed)
	}, IconSet)
end

-- Add / replace sources after construction (e.g. merging a shared glyph set with
-- screen-specific ones). Drops any cached doc for a replaced key so it re-parses.
function IconSet:Add(sources)
	for k, v in pairs(sources or {}) do
		self.sources[k] = v
		self.docs[k] = nil
	end
	return self
end

-- Parsed doc for a key (parsed + crc-stamped on first call), or false if the key
-- is unknown / failed to parse / tinysvg is unavailable.
function IconSet:Doc(key)
	local src = self.sources[key]
	if not src then return false end
	local doc = self.docs[key]
	if doc == nil then
		doc = tinysvg.Parse(src) or false
		if doc then doc.crc = self.prefix .. "_" .. key end
		self.docs[key] = doc
	end
	return doc
end

-- Draw an icon by key. col tints it, alpha is the cheap draw-time opacity (the
-- ambient panel alpha is folded in by DrawMaterial, so an icon fades with its
-- parent). supersample defaults to 2. Unknown key = draws nothing.
function IconSet:Draw(key, x, y, w, h, col, alpha)
	local doc = self:Doc(key)
	if doc then doc:Draw(x, y, w, h, { tint = col, alpha = alpha, supersample = 2 }) end
end

-- Pre-rasterize a list of icons so the first paint / fade-in reuses warm RTs.
-- Each spec is { key, size, tint } (size is a single number — icons are square;
-- it's bucketed internally so it only needs to land in the right size bucket).
-- Already-warm combos are a cheap hash hit, so calling this on every panel-open
-- is fine. Returns true once the set is actually warmed (tinysvg was rasterReady),
-- false while still in the post-join settle window so the caller can retry.
function IconSet:Prewarm(specs)
	local items = {}
	for _, s in ipairs(specs or {}) do
		local doc = self:Doc(s[1])
		if doc then
			items[#items + 1] = { doc = doc, w = s[2], h = s[2], opts = { tint = s[3], supersample = 2 } }
		end
	end
	if #items == 0 then return true end          -- nothing warmable; don't retry
	return tinysvg.Prewarm(items) > 0            -- >0 only once rasterReady
end

-- Invalidate every cached doc's rasters (e.g. after a screen-mode change). Parsed
-- geometry is kept; only the size/tint render targets are dropped.
function IconSet:Invalidate()
	for _, doc in pairs(self.docs) do
		if doc then doc:Invalidate() end
	end
end

-- RT contents can be lost on screen mode changes; re-rasterize lazily.
if hook and hook.Add then
	hook.Add("OnScreenSizeChanged", "tinysvg_invalidate", function()
		for _, entry in pairs(loadCache) do
			if entry.doc then entry.doc:Invalidate() end
		end
	end)
end

--------------------------------------------------------------------------------
-- Internals exposed for the self-test harness (unstable API)
--------------------------------------------------------------------------------

tinysvg._internal = {
	xmlParse = xmlParse,
	parsePath = parsePath,
	parseTransform = parseTransform,
	parseColor = parseColor,
	parseNumberList = parseNumberList,
	parseLength = parseLength,
	parseLengthPct = parseLengthPct,
	flattenSubpaths = flattenSubpaths,
	strokeTessellate = strokeTessellate,
	dashPolyline = dashPolyline,
	resolveGradient = resolveGradient,
	sampleGradient = sampleGradient,
	matMul = matMul,
	matApply = matApply,
	matInverse = matInverse,
	matScale = matScale,
	subpathsBBox = subpathsBBox,
	isFinite = isFinite,
}

return tinysvg