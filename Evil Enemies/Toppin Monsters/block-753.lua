local blockManager = require("blockManager")

local alarmBlock = {}
local blockID = BLOCK_ID

local alarmBlockSettings = {
	id = blockID,
	frames = 1,
	framespeed = 8, 
}

local config = blockManager.setBlockSettings(alarmBlockSettings)

return alarmBlock