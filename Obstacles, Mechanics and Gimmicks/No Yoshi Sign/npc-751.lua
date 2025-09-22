local npcManager = require("npcManager")
local AI = require("noMountSigns")

local noMountSign = {}
local npcID = NPC_ID

local noMountSignSettings = {
	id = npcID,

	gfxwidth = 64,
	gfxheight = 160,
	width = 16,
	height = 160,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 3,
	framestyle = 0,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = false,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	weight = 2,
	isstationary = true,
	staticdirection = true, 

	-- Custom Properties

	preventMount = MOUNT_YOSHI,
	signFrames = 1,
	noEntrySFX = Misc.resolveSoundFile("smwwrong.ogg"),
	shakeTime = 50,
	bumpSpeed = 5,
	addHitboxWidth = 16,
}

npcManager.setNpcSettings(noMountSignSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_LAVA, HARM_TYPE_OFFSCREEN, }, {[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack=0, yoffset=1, yoffsetBack=1.5}, })

AI.register(npcID)

return noMountSign