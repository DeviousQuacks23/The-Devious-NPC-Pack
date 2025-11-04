local npcManager = require("npcManager")
local ai = require("flipperGates")

local flipperGate = {}
local npcID = NPC_ID

local flipperGateSettings = table.join({
	id = npcID,

	gfxwidth = 40,
	gfxheight = 128,
	width = 32,
	height = 128,
}, ai.sharedSettings)

npcManager.setNpcSettings(flipperGateSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

ai.register(npcID)

return flipperGate