local npcManager = require("npcManager")
local AI = require("strollinStus")

local strollinStu = {}
local npcID = NPC_ID

local deathEffect = (npcID - 1)
local stompEffect = (npcID - 2)

local settings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 36,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32,
	height = 32,
	
	frames = 2,
	framestyle = 1,
	framespeed = 8,

	score = 2, 

        isStunned = true,
	recoverID = npcID - 1,

	nohurt = true,
	grabside = true,

	stompEffect = stompEffect,
	deathEffect = deathEffect,

	coinAmount = 5,
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
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)

AI.register(npcID, settings)

return strollinStu