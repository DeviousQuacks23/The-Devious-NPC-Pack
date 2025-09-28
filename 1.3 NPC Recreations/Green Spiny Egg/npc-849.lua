local npcManager = require("npcManager")
local AI = require("greenSpinyEggs")

local greenSpinyEgg = {}
local npcID = NPC_ID

local deathEffectID = npcID

local greenSpinyEggSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32,
	height = 32,
	
	frames = 2,
	framestyle = 0,
	framespeed = 4,
	
	luahandlesspeed = true, 
	staticdirection = true,
	nowaterphysics = true,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 
	grabside = false,
	grabtop = false,

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 
	nofireball = false,
	noiceball = false,
	noyoshi= false, 

	score = 2, 
	jumphurt = true, 
	spinjumpsafe = true, 

	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 
	linkshieldable = false,
	noshieldfireeffect = false,

	-- Custom stuff

	maxSpeed = 4,
	accel = 0.04,
	bounceLimit = 1,
	bounceLossMod = 0.7,
}

npcManager.setNpcSettings(greenSpinyEggSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

AI.register(npcID)

return greenSpinyEgg