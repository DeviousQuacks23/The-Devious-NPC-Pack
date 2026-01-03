local npcManager = require("npcManager")
local ai = require("bowserBlades")

local bowserBlade = {}
local npcID = NPC_ID

local bowserBladeSettings = table.join({
	id = npcID,
}, ai.sharedSettings)

npcManager.setNpcSettings(bowserBladeSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

ai.register(npcID)

return bowserBlade