local npcManager = require("npcManager")
local AI = require("firebars")

local firebar = {}
local npcID = NPC_ID

local firebarSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 0,
	framespeed = 8,

	foreground = false,

	speed = 1,
	luahandlesspeed = true,
	nowaterphysics = true,
	staticdirection = true,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,

	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,
	nowalldeath = true,

	linkshieldable = false,
	noshieldfireeffect = false,
	grabside = false,
	grabtop = false,

	ignorethrownnpcs = true,
	nogliding = true,
	nopowblock = true,
	weight = 0,
}

npcManager.setNpcSettings(firebarSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return firebar