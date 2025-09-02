local npcManager = require("npcManager")
local ai = require("robirdo_ai")

local robobirdo = {}
local npcID = NPC_ID

local theSettings = table.join({
	id = npcID,
},ai.sharedSettings)

npcManager.setNpcSettings(theSettings)

ai.register(npcID)

return robobirdo