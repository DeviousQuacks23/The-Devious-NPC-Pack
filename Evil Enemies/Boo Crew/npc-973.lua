local npcManager = require("npcManager")
local AI = require("fadingBoo")

local fadingBoo = {}
local npcID = NPC_ID

local fadingBooSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 6,
	framestyle = 1,
	framespeed = 8,

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

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 2, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = true,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

	-- Custom properties

	floatSpeed = 1,
	turnAroundTime = 190,
	sineTimeMod = 0.04,
	sineAmplitude = 0.9,

	minSwoopTime = 30,
	maxSwoopTime = 120,
	swoopChance = 2,
	minSwoopDist = 140,
	preSwoopTime = 30,

	swoopSpeed = 1.85,
	swoopDistY = 48,

	inactiveOpacity = 0.6,
	fadeSpeed = 0.05,
	booVariants = 3,
}

npcManager.setNpcSettings(fadingBooSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return fadingBoo