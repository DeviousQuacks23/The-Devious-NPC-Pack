local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local pokeys = require("pokeys")

local pokey = {}
local npcID = NPC_ID

local bodyDeathEffect = (npcID)
local headDeathEffect = (npcID - 1)

local pokeySettings = {
	id = npcID,
	
	gfxwidth = 48,
	gfxheight = 36,

	gfxoffsetx = 0,
	gfxoffsety = 2,
	
	width = 32,
	height = 32,
	
	frames = 2,
	framestyle = 1,
	framespeed = 8,

	nohurt = false,
	nogravity = false,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	notcointransformable = false,
	ignorethrownnpcs = false,
	staticdirection = true,
	luahandlesspeed = true,

	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	-- SMB2 settings (lol)

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	grabside = false,
	grabtop = false,

	-- Custom settings

	bodyDeathEffect = bodyDeathEffect,
	headDeathEffect = headDeathEffect,

	spawnedNPC = 0,

	headNormalFrames = 1,
	headFrameDelay = 8,

	bodyNormalFrames = 1,
	bodyFrameDelay = 8,

	turnDuration = 0,

	wavyMovement = true,
	consistentSpeed = false,

	waveSpeed = 8,
	waveIntensity = 3,

	rotate = true,
}

npcManager.setNpcSettings(pokeySettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

pokeys.registerBody(npcID)

return pokey