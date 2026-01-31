local blockManager = require("blockManager")
local AI = require("checkeredBlocks")

local checkeredBlock = {}
local blockID = BLOCK_ID

local checkeredBlockSettings = {
	id = blockID,
	frames = 1,
	framespeed = 8,
	width = 64,
	height = 64,
}

blockManager.setBlockSettings(checkeredBlockSettings)
AI.register(blockID)

return checkeredBlock