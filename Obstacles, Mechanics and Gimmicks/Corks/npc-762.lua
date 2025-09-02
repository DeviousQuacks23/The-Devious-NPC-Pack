local npcManager = require("npcManager")
local AI = require("corks")

local cork = {}
local npcID = NPC_ID

local size = 128
local corkEffect = 758

local corkSettings = table.join({
	id = npcID,
	gfxheight = size,
	gfxwidth = size,
	width = size,
	height = size,
        effect = corkEffect,
},AI.sharedSettings)

npcManager.setNpcSettings(corkSettings)
AI.register(npcID)

return cork