local npcManager = require("npcManager")
local AI = require("jumpOrbs")

local orb = {}
local npcID = NPC_ID

local orbSettings = table.join({
	id = npcID,
        bounceHeight = 20,
        bounceEffectColour = Color.fromHexRGB(0x585858),
        shineColour = Color.fromHexRGB(0x585858),
},AI.sharedSettings)

npcManager.setNpcSettings(orbSettings)
AI.register(npcID)

return orb