local npcManager = require("npcManager")

local hammer = {}
local npcID = NPC_ID

local hammerSettings = {
	id = npcID,

	gfxheight = 32,
	gfxwidth = 32,

	height = 32,
	width = 32,

	frames = 4,
	framespeed = 6,
	framestyle = 1,

	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,

	jumphurt = 1,
	noblockcollision = 1,
    	noyoshi = 1,
	noiceball = 1,
}

npcManager.setNpcSettings(hammerSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_OFFSCREEN}, {});

return hammer