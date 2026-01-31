local npcManager = require("npcManager")
local AI = require("diggable")

local cork = {}
local npcID = NPC_ID

local corkSettings = table.join({
	id = npcID,

	gfxheight = 128,
	gfxwidth = 128,
	width = 128,
	height = 128,

	slashable = false,
	explodable = false,
        effect = 758,
}, AI.sharedSettings)

npcManager.setNpcSettings(corkSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return cork