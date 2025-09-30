local npcManager = require("npcManager")
local AI = require("blarggs")

local blargg = {}
local npcID = NPC_ID

local blarggSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 192,
	gfxheight = 96,
	width = 58,
	height = 60,
	gfxoffsetx = 3,
	gfxoffsety = 32,

	frames = 2,
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

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = true, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = true,
	terminalvelocity = -1,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

	-- Custom properties

	spawnOffset = 36,
	detectSize = vector(600, 400),
	peekTime = 89,

	peekIMG = Graphics.loadImageResolved("npc-"..npcID.."-peek.png"),
	peekFrames = 2,
	peekFramespeed = 16,
	peekPriority = -60,
	peekSFXDelay = 16,

	peekRiseHeight = 52,
	peekRiseTime = 30,
	peekRiseAmplifier = 1.75,
	peekFallTime = 70,
	peekFallSpeed = 2,

	leapSpeed = vector(1, 4.2),
	leapSFX = 61,
	leapGravityMod = 0.4,
	leapTerminalVelocity = 8,
	leapDespawnOffset = 48,

	startScale = 0,
	scaleSpeed = 0.1,
	shrinkSpeed = 1,
}

npcManager.setNpcSettings(blarggSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return blargg