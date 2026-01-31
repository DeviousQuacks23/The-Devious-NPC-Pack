local npcManager = require("npcManager")
local AI = require("diggable")

local sand = {}
local npcID = NPC_ID

local sandSettings = table.join({
	id = npcID,

	npcblock = false, 
	npcblocktop = true, 
	playerblock = false, 

        effect = 760,
	effectSpeed = -2,
	renderPriority = -64,
}, AI.sharedSettings)

npcManager.setNpcSettings(sandSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return sand