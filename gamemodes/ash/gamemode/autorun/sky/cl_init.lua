do
	return
end

---@class ash.sky
local ash_sky = {}

local top_color = Vector( 0, 0, 0 )
local bottom_color = Vector( 0, 0, 0 )

function ash_sky.getTopColor()
	return top_color
end

---@param color Color
function ash_sky.setTopColor( color )
	top_color[ 1 ] = color.r / 255
	top_color[ 2 ] = color.g / 255
	top_color[ 3 ] = color.b / 255
end

function ash_sky.getBottomColor()
	return bottom_color
end

function ash_sky.setBottomColor( color )
	bottom_color = color
end

local dusk_color = Vector( 0, 0, 0 )
local dusk_scale = 0
local dusk_intensity = 0

function ash_sky.getDuskColor()
	return dusk_color
end

function ash_sky.setDuskColor( color )
	dusk_color = color
end

function ash_sky.getDuskScale()
	return dusk_scale
end

function ash_sky.setDuskScale( scale )
	dusk_scale = scale
end

function ash_sky.getDuskIntensity()
	return dusk_intensity
end

function ash_sky.setDuskIntensity( intensity )
	dusk_intensity = intensity
end

local fade_bias = 0
local hdr_scale = 0

function ash_sky.getFadeBias()
	return fade_bias
end

function ash_sky.setFadeBias( bias )
	fade_bias = bias
end

function ash_sky.getHDRScale()
	return hdr_scale
end

function ash_sky.setHDRScale( scale )
	hdr_scale = scale
end

local sun_normal = Vector( 0, 0, 0 )
local sun_color = Vector( 0, 0, 0 )
local sun_size = 0

function ash_sky.getSunNormal()
	return sun_normal
end

function ash_sky.setSunNormal( normal )
	sun_normal = normal
end

function ash_sky.getSunColor()
	return sun_color
end

function ash_sky.setSunColor( color )
	sun_color = color
end

function ash_sky.getSunSize()
	return sun_size
end

function ash_sky.setSunSize( size )
	sun_size = size
end

local star_layers = 3
local star_texture = "skybox/clouds"

local star_fade = 0
local star_scale = 0
local star_position = 0

function ash_sky.getStarLayers()
	return star_layers
end

function ash_sky.setStarLayers( layers )
	star_layers = layers
end

function ash_sky.getStarTexture()
	return star_texture
end

function ash_sky.setStarTexture( texture )
	star_texture = texture
end

function ash_sky.getStarFade()
	return star_fade
end

function ash_sky.setStarFade( fade )
	star_fade = fade
end

function ash_sky.getStarScale()
	return star_scale
end

function ash_sky.setStarScale( scale )
	star_scale = scale
end

function ash_sky.getStarPosition()
	return star_position
end

function ash_sky.setStarPosition( position )
	star_position = position
end

-- Defaults
ash_sky.setTopColor( Color( 100, 160, 255 ) )

local Material_SetTexture = Material.SetTexture
local Material_SetVector = Material.SetVector
local Material_SetFloat = Material.SetFloat
local Material_SetInt = Material.SetInt

matproxy.Add( {
	name = "SkyPaint",
	init = function( self, material, values )
	end,
	bind = function( self, material, entity )
		Material_SetVector( material, "$TOPCOLOR", top_color )
		Material_SetVector( material, "$BOTTOMCOLOR", bottom_color )

		Material_SetVector( material, "$DUSKCOLOR", dusk_color )

		Material_SetFloat( material, "$DUSKSCALE", dusk_scale )
		Material_SetFloat( material, "$DUSKINTENSITY", dusk_intensity )

		Material_SetFloat( material, "$FADEBIAS", fade_bias )
		Material_SetFloat( material, "$HDRSCALE", hdr_scale )

		Material_SetVector( material, "$SUNNORMAL", sun_normal )
		Material_SetVector( material, "$SUNCOLOR", sun_color )

		Material_SetFloat( material, "$SUNSIZE", sun_size )

		if star_layers == 0 then
			Material_SetInt( material, "$STARLAYERS", 0 )
			return
		end

		Material_SetInt( material, "$STARLAYERS", star_layers )

		Material_SetFloat( material, "$STARSCALE", star_scale )
		Material_SetFloat( material, "$STARFADE", star_fade )
		Material_SetFloat( material, "$STARPOS", star_position )

		---@diagnostic disable-next-line: param-type-mismatch
		Material_SetTexture( material, "$STARTEXTURE", star_texture )
	end
} )

-- hook.Add( "ash.entity.Created", "SkyPaint", function( entity )
-- 	if entity:GetClass() == "env_sky" then
-- 		entity:SetMaterial( "SkyPaint" )
-- 	end
-- end )

return ash_sky
