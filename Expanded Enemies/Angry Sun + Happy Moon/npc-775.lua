local npcManager = require("npcManager")
local AI = require("angrySun_ai")

local angrySunNPC = {}
local npcID = NPC_ID

local angrySunNPCSettings = table.join({
	id = npcID,

	ishot = true,
}, AI.sharedSettings)

npcManager.setNpcSettings(angrySunNPCSettings)

AI.register(npcID, true, npcID)

return angrySunNPC