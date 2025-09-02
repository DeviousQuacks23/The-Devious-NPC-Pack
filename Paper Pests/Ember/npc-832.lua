local npcManager = require("npcManager")
local AI = require("ember")

local ember = {}
local npcID = NPC_ID

local emberSettings = {
	id = npcID,
	gfxheight = 52,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 6,
	framestyle = 1,
	framespeed = 8, 
	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false, 

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true, 
	spinjumpsafe = true, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,

	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.green,

	-- Custom properties

	shootTime = 75,
	fireballID = 833
}

npcManager.setNpcSettings(emberSettings)

local deathEffectID = (798)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
	}, 
	{
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_HELD]=deathEffectID,
	}
);

AI.register(npcID)

return ember