local npcManager = require("npcManager")
local AI = require("diggable")

local cork = {}
local npcID = NPC_ID

local corkSettings = table.join({
	id = npcID,

	gfxheight = 64,
	gfxwidth = 64,
	width = 64,
	height = 64,

	slashable = false,
	explodable = false,
        effect = 756,
}, AI.sharedSettings)

npcManager.setNpcSettings(corkSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return cork