local npcManager = require("npcManager")
local ai = require("fallingSpikes")

local fallingSpike = {}
local npcID = NPC_ID

local fallingSpikeSettings = table.join({
	id = npcID,
	isHorizontal = true,
}, ai.sharedSettings)

npcManager.setNpcSettings(fallingSpikeSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

ai.register(npcID)

return fallingSpike