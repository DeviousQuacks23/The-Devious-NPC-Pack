local npcManager = require("npcManager")
local AI = require("diggable")

local cork = {}
local npcID = NPC_ID

local corkSettings = table.join({
	id = npcID,

	slashable = false,
	explodable = false,
        effect = 755,
}, AI.sharedSettings)

npcManager.setNpcSettings(corkSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return cork