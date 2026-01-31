local blockManager = require("blockManager")
local AI = require("flipswapPanels")

local flipswapPanel = {}
local blockID = BLOCK_ID

-- Convenience
local isInvert = false

local flipswapPanelSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 
	
	passthrough = isInvert,

	activateImg = Graphics.loadImageResolved("block-"..blockID.."b.png"),
}

blockManager.setBlockSettings(flipswapPanelSettings)
AI.register(blockID, isInvert)

return flipswapPanel