local npcManager = require("npcManager")
local ai = require("movingPlatforms")

local movingPlatform = {}
local npcID = NPC_ID

local movingPlatformSettings = {
	id = npcID,
	
	gfxwidth = 96,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,

	npcblock = false,
	npcblocktop = true,
	playerblock = false,
	playerblocktop = true,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	notcointransformable = true,
	ignorethrownnpcs = true,
	staticdirection = true,
	luahandlesspeed = true,
        terminalvelocity = -1,
}

npcManager.setNpcSettings(movingPlatformSettings)
npcManager.registerHarmTypes(npcID,{},nil)

ai.register(npcID)

return movingPlatform