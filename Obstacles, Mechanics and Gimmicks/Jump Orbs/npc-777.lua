local npcManager = require("npcManager")
local AI = require("jumpOrbs")

local orb = {}
local npcID = NPC_ID

local orbSettings = table.join({
	id = npcID,
        bounceHeight = -8,
        bounceEffectColour = Color.fromHexRGB(0xE04890),
        shineColour = Color.fromHexRGB(0xE04890),
},AI.sharedSettings)

npcManager.setNpcSettings(orbSettings)
AI.register(npcID)

return orb