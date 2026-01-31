local npcManager = require("npcManager")
local AI = require("diggable")

local cloud = {}
local npcID = NPC_ID

local cloudSettings = table.join({
	id = npcID,

	npcblock = false, 
	npcblocktop = true, 
	playerblock = false, 

	slashable = false,
	explodable = false,

        effect = 759,
	renderPriority = -64,
}, AI.sharedSettings)

npcManager.setNpcSettings(cloudSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return cloud