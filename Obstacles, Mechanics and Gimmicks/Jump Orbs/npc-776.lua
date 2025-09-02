local npcManager = require("npcManager")
local AI = require("jumpOrbs")

local orb = {}
local npcID = NPC_ID

local orbSettings = table.join({
	id = npcID,
        bounceHeight = -14,
        bounceEffectColour = Color.fromHexRGB(0xF82820),
        shineColour = Color.fromHexRGB(0xF82820),
},AI.sharedSettings)

npcManager.setNpcSettings(orbSettings)
AI.register(npcID)

return orb