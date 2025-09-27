--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local fireBar = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fireBarSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 1,
	framestyle = 0,
	framespeed = 4,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nogliding=true,
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	
	ignorethrownnpcs = true,
	linkshieldable = false,

	-- lightradius=32,
	-- lightbrightness=1,
	-- lightcolor=Color.orange,
	-- lightflicker = true,

	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	-- ishot=true,
	-- durability=-1,
}

--Applies NPC settings
npcManager.setNpcSettings(fireBarSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

--Gotta return the library table!
return fireBar