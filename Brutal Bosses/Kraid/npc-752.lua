local npcManager = require("npcManager")

local rockProjectile = {}
local npcID = NPC_ID

local rockProjectileSettings = {
	id = npcID,
	gfxheight = 28,
	gfxwidth = 28,
	height = 28,
	width = 28,
	frames = 1,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noshieldfireeffect = true,
	framestyle = 0,
	jumphurt = 1,
	noblockcollision = 1,
	nofireball = true,
        noyoshi = 1,
	noiceball = 1,
	score = 0
}

npcManager.setNpcSettings(rockProjectileSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_OFFSCREEN,
	},
	{
	}
);

return rockProjectile