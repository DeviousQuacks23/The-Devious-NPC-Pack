local npcManager = require("npcManager")
local AI = require("swoops")

local swoop = {}

local npcID = NPC_ID
local deathEffectID = npcID

local swoopSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 3,
	framestyle = 1,

	-- The more obsure settings

	luahandlesspeed = true, 
	nowaterphysics = true,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= false, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

	-- Custom properties

	detectSize = vector(400, 800),
	swoopSFX = Misc.resolveSoundFile("swooperflap"),

	swoopSpeedX = 1.5,
	swoopSpeedY = 2.5,
	swoopYOffset = 130,
	swoopTowardsPlayer = true,

	isHoming = true,
	homingAccel = 0.15,
	homingSpeed = 3,

	deceleration = 0.025,

	idleFrames = 1,
	idleFramespeed = 8,
	swoopFrames = 2,
	swoopFramespeed = 6,
}

npcManager.setNpcSettings(swoopSettings)
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
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = {id = deathEffectID, speedX = 0, speedY = 0},
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

AI.register(npcID)

return swoop