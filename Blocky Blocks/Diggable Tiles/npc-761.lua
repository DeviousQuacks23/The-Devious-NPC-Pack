local npcManager = require("npcManager")
local AI = require("diggable")

local cork = {}
local npcID = NPC_ID

local corkSettings = table.join({
	id = npcID,

	gfxheight = 96,
	gfxwidth = 96,
	width = 96,
	height = 96,

	slashable = false,
	explodable = false,
        effect = 757,
}, AI.sharedSettings)

npcManager.setNpcSettings(corkSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return cork