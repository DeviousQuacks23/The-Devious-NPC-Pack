local npcManager = require("npcManager")
local AI = require("chompRocks")

local chompRock = {}
local npcID = NPC_ID

local chompRockSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 64,
	gfxheight = 64,
	width = 48,
	height = 64,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 1,
	framestyle = 0,
	framespeed = 8,

	-- The more obsure settings

	luahandlesspeed = true, 
	nowaterphysics = false,

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
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 
	staticdirection = true,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,
	score = 0,
	weight = 3,

	-- Custom properties

	rotSpeed = 3,
	minFxSpeed = 3,
	rollSfx = "chomp-rock.ogg",
	rollSfxDelay = 16,

	pushAccel = 0.1,
	slopeAccel = 0.05,
	decel = 0.025,
	turnAroundSpeed = 0.5,
	maxSpeed = 8,
}

npcManager.setNpcSettings(chompRockSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_LAVA, }, {[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}, });
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

AI.register(npcID)

return chompRock