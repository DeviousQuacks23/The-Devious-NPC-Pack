local npcManager = require("npcManager")
local AI = require("landBloopers")

local landBlooper = {}

local npcID = NPC_ID
local inkShotID = (npcID - 3)

local stompEffectID = (npcID - 1)
local deathEffectID = (npcID - 1)

landBlooper.config = npcManager.setNpcSettings{
	id = npcID,
	gfxheight = 64,
	gfxwidth = 64,
	width = 30,
	height = 32,
	gfxoffsetx=0,
	gfxoffsety=16,
	frames = 5,
	framespeed=8,
	framestyle = 1,
	jumphurt = 0,
	nogravity = -1,
	nowaterphysics=true,
	noblockcollision = -1,
	nofireball=0,
	noiceball=1,
	noyoshi=0,
	cliffturn=-1,
	score=3,

	spitframes = 1,
	movetime = 65,
	spittime = 20,
	walkspeed = 1.5,
	turnchance = 20,
	inkshot = inkShotID,
	shotspeed = 5,
}

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = {id=stompEffectID, speedX=0, speedY=0},
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

AI.register(npcID, AI.TYPE.LEFTWALL)

return landBlooper