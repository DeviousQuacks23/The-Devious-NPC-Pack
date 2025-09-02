local npcManager = require("npcManager")
local ai = require("robirdo_ai")

local robobirdo = {}
local npcID = NPC_ID

local theSettings = table.join({
	id = npcID,
	projectiles = {760, 761},
	effect = 759,
	debris = 760,
},ai.sharedSettings)

npcManager.setNpcSettings(theSettings)

ai.register(npcID)

return robobirdo