local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local textplus = require("textplus")

local textBlock = {}
local blockID = BLOCK_ID

local textBlockSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 

	passthrough = true
}

blockManager.setBlockSettings(textBlockSettings)

function textBlock.onInitAPI()
	blockManager.registerEvent(blockID, textBlock, "onCameraDrawBlock")
end

function textBlock.onCameraDrawBlock(v, camIdx)
    	if not blockutils.visible(Camera(camIdx),v.x,v.y,v.width,v.height) or not blockutils.hiddenFilter(v) then return end
	
	local data = v.data
	local settings = v.data._settings

	if settings.theActualText == "" then return end

	local tpFont
	if settings.fontSetting ~= "" then
		tpFont = textplus.loadFont(settings.fontSetting)
	end

    	textplus.print{
        	x = v.x + (v.width * 0.5),
        	y = v.y + (v.height * 0.5),
        	text = settings.theActualText,
		maxWidth = settings.maximumWide,
		pivot = vector(settings.pivotation.x, settings.pivotation.y),
		sceneCoords = true,
		priority = settings.renderPrio,
		color = settings.colorfulTexting * settings.colorfulOpacity,
		smooth = false,
		font = tpFont,
		xscale = (settings.textingSize.x * 2),
		yscale = (settings.textingSize.y * 2)
    	}

	if settings.iWantOutlines then
    		textplus.print{
        		x = v.x + (v.width * 0.5) - (2 * settings.outlineSize),
        		y = v.y + (v.height * 0.5) - (2 * settings.outlineSize),
        		text = settings.theActualText,
			maxWidth = settings.maximumWide,
			pivot = vector(settings.pivotation.x, settings.pivotation.y),
			sceneCoords = true,
			priority = settings.renderPrio - 1,
			color = settings.colorOutline * settings.opacityOutline,
			smooth = false,
			font = tpFont,
			xscale = (settings.textingSize.x * 2),
			yscale = (settings.textingSize.y * 2)
    		}
    		textplus.print{
        		x = v.x + (v.width * 0.5) + (2 * settings.outlineSize),
        		y = v.y + (v.height * 0.5) - (2 * settings.outlineSize),
        		text = settings.theActualText,
			maxWidth = settings.maximumWide,
			pivot = vector(settings.pivotation.x, settings.pivotation.y),
			sceneCoords = true,
			priority = settings.renderPrio - 1,
			color = settings.colorOutline * settings.opacityOutline,
			smooth = false,
			font = tpFont,
			xscale = (settings.textingSize.x * 2),
			yscale = (settings.textingSize.y * 2)
    		}
    		textplus.print{
        		x = v.x + (v.width * 0.5) - (2 * settings.outlineSize),
        		y = v.y + (v.height * 0.5) + (2 * settings.outlineSize),
        		text = settings.theActualText,
			maxWidth = settings.maximumWide,
			pivot = vector(settings.pivotation.x, settings.pivotation.y),
			sceneCoords = true,
			priority = settings.renderPrio - 1,
			color = settings.colorOutline * settings.opacityOutline,
			smooth = false,
			font = tpFont,
			xscale = (settings.textingSize.x * 2),
			yscale = (settings.textingSize.y * 2)
    		}
    		textplus.print{
        		x = v.x + (v.width * 0.5) + (2 * settings.outlineSize),
        		y = v.y + (v.height * 0.5) + (2 * settings.outlineSize),
        		text = settings.theActualText,
			maxWidth = settings.maximumWide,
			pivot = vector(settings.pivotation.x, settings.pivotation.y),
			sceneCoords = true,
			priority = settings.renderPrio - 0.1,
			color = settings.colorOutline * settings.opacityOutline,
			smooth = false,
			font = tpFont,
			xscale = (settings.textingSize.x * 2),
			yscale = (settings.textingSize.y * 2)
    		}
	end

	if settings.iWantShadows then
    		textplus.print{
        		x = v.x + (v.width * 0.5) + (2 * settings.shadowDist.x),
        		y = v.y + (v.height * 0.5) + (2 * settings.shadowDist.y),
        		text = settings.theActualText,
			maxWidth = settings.maximumWide,
			pivot = vector(settings.pivotation.x, settings.pivotation.y),
			sceneCoords = true,
			priority = settings.renderPrio - 0.2,
			color = settings.colorShadow * settings.opacityShadow,
			smooth = false,
			font = tpFont,
			xscale = (settings.textingSize.x * 2),
			yscale = (settings.textingSize.y * 2)
    		}
	end
end

return textBlock