local npcManager = require("npcManager")
local AI = require("motherBrain")

local overusedBoss = {}

local npcID = NPC_ID
local deathEffectID = npcID

local overusedBossSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 96,
	gfxheight = 106,
	width = 96,
	height = 106,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 2,
	framestyle = 1,
	framespeed = 8,

	-- The more obsure settings

	luahandlesspeed = true, 
	nowaterphysics = true,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = true, 
	playerblocktop = true, 

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	jumphurt = true, 
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

	health = 10,
	score = 9,

	idleFrames = 1,
	idleFramespeed = 8,
	painFrames = 1,
	painFramespeed = 8,

	flashTime = 15,
	shakeTime = 45,
	shakeIntensity = 1,

	hammerImmune = 60,
	immune = 20,

	hurtSFX = 68,
	deathSFX = 69,
	explodeSFX = 70,

	solidBlockID = 1006,
	collisionOffset = 0.95,
}

npcManager.setNpcSettings(overusedBossSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_NPC] = deathEffectID,
	}
);

AI.register(npcID)

return overusedBoss