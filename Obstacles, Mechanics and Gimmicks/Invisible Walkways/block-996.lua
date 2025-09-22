local blockManager = require("blockManager")
local AI = require("invisWalkways")

local invisWalkway = {}
local blockID = BLOCK_ID

local invisWalkwaySettings = {
	id = blockID,

	frames = 1,
	framespeed = 8, 

	semisolid = true,
	floorslope = 0, 
	ceilingslope = 0,

	-- Exclusive stuff

	radius = 180,
	fadeSpeed = 0.05,
	distScale = 2,
}

blockManager.setBlockSettings(invisWalkwaySettings)
AI.register(blockID)

return invisWalkway