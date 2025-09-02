local npcManager = require("npcManager")
local AI = require("corks")

local cork = {}
local npcID = NPC_ID

local size = 64
local corkEffect = 756

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