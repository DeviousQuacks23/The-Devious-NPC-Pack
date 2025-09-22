local npcManager = require("npcManager")
local AI = require("skullRafts")

local skullRaft = {}
local npcID = NPC_ID

local skullRaftSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 20,
	gfxoffsetx = 0,
	gfxoffsety = 12,

	frames = 2,
	framestyle = 0,
	framespeed = 4,

	-- The more obsure settings

	luahandlesspeed = true, 
	nowaterphysics = true,

	npcblock = true, 
	npcblocktop = false, 
	playerblock = true, 
	playerblocktop = true, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = true,
	nowalldeath = false, 
	staticdirection = true,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

	-- Custom properties

	raftSpeed = 3,

	steppedOffset = 2,
	detectOffset = 16,
	floatMod = 1.05,
}

npcManager.setNpcSettings(skullRaftSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_OFFSCREEN}, {});

AI.register(npcID)

return skullRaft