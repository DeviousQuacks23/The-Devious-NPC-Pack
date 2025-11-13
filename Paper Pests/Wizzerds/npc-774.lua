local npcManager = require("npcManager")
local AI = require("wizzerds")

local wizzerd = {}
local npcID = NPC_ID

local wizzerdSettings = table.join({
	id = npcID,
	handIMG = Graphics.loadImageResolved("npc-"..npcID.."-hands.png"),
}, AI.sharedSettings)

npcManager.setNpcSettings(wizzerdSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

AI.register(npcID)

return wizzerd