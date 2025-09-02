local npcManager = require("npcManager")

local panser = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id=npcID,
	width=16,
	height=16,
	gfxheight=16,
	gfxwidth=16,
	
	framestyle=0,
	framespeed=8,
	frames=4,
	
	noblockcollision = true,
	
	ignorethrownnpcs = true,
	linkshieldable = true,
	nogravity = true,
	spinjumpsafe = false,
	
	npcblock=false,
	
	lightradius=64,
	lightcolor=Color.orange,
	lightbrightness=1,
	jumphurt=true,
	
	nofireball=true,
	noiceball = true,
        noyoshi = 1,

	ishot = true,
	durability = 2,
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_OFFSCREEN,
	},
	{
	}
);

return panser
