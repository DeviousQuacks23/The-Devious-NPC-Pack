local npcManager = require("npcManager")
local ai = require("muralEnemies")

local muralGoomba = {}
local npcID = NPC_ID

local muralGoombaSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 48,
	width = 32,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 2,
	framestyle = 0,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= true, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	weight = 2,

	-- Custom Properties

	health = 1,
}

npcManager.setNpcSettings(muralGoombaSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
	},
	{
	}
);

ai.register(npcID)

return muralGoomba