local npcManager = require("npcManager")

local squigglerSegment = {}
local npcID = NPC_ID

local squigglerSegmentSettings = {
	id = npcID,
	gfxwidth = 16,
	gfxheight = 16,
	width = 16,
	height = 16,
	frames = 1,
	framestyle = 1,
	framespeed = 8,
	nogravity = true,
	noblockcollision = true,
	luahandlesspeed = true,
	nofireball = false,
	noiceball = false,
	noyoshi = true,
	score = 0,
	jumphurt = false,
	spinjumpsafe = false,
}

npcManager.setNpcSettings(squigglerSegmentSettings)

local deathEffectID = npcID
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_VANISH,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = {id=deathEffectID, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

return squigglerSegment