local blockManager = require("blockManager")
local AI = require("shrinkBlocks")

local shrinkBlock = {}
local blockID = BLOCK_ID

local shrinkBlockSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 
	
	shrinkSpeed = 0.375,
	minimumSize = 16,

	shrinkSFX = Misc.resolveSoundFile("shrinkBlockStart"),
	vanishSFX = Misc.resolveSoundFile("shrinkBlockVanish"),
}

blockManager.setBlockSettings(shrinkBlockSettings)
AI.register(blockID)

return shrinkBlock