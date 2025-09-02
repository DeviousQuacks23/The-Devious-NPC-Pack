local npcManager = require("npcManager")
local AI = require("jumpOrbs")

local orb = {}
local npcID = NPC_ID

local orbSettings = table.join({
	id = npcID,
},AI.sharedSettings)

npcManager.setNpcSettings(orbSettings)
AI.register(npcID)

return orb