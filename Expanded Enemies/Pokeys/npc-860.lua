local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local pokeys = require("pokeys")

local pokey = {}
local npcID = NPC_ID

local bodyID = (npcID + 1)

local pokeySettings = {
	id = npcID,

	-- Do not touch unless you know what you are doing
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 128,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi = true,
	nowaterphysics = false,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	notcointransformable = true,
	ignorethrownnpcs = true,
	staticdirection = false,
	luahandlesspeed = true,

	grabside = false,
	grabtop = false,

	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	score = 0,

	-- Custom settings

	bodyID = bodyID,
	segmentGap = 32,

	toppleIfHeadless = true,
	toppleTime = 8,

	speed = 0.3,
	chaseInterval = 80,

	cliffturn = true,
}

npcManager.setNpcSettings(pokeySettings)
npcManager.registerHarmTypes(npcID,{},{})

pokeys.registerManager(npcID)

return pokey