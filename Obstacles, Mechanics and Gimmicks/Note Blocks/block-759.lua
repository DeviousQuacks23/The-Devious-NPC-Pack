local blockManager = require("blockManager")

local noteBlock = {}
local blockID = BLOCK_ID

local noteBlockSettings = {
	id = blockID,

	frames = 4,
	framespeed = 8,
	bumpable = true,
}

blockManager.setBlockSettings(noteBlockSettings)

local AI = require("noteBlocks")
AI.register(blockID)

return noteBlock