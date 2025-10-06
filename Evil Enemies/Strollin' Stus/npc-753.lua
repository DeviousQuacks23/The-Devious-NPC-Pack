local npcManager = require("npcManager")
local AI = require("strollinStus")

local strollinStu = {}
local npcID = NPC_ID

local deathEffect = (npcID + 1)
-- local stompEffect = (npcID)

local settings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 64,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32,
	height = 48,
	
	frames = 4,
	framestyle = 1,
	framespeed = 4,

	cliffturn = true,
	score = 2, 

	stunnedID = npcID + 1,

	stompEffect = stompEffect,
	deathEffect = deathEffect,

	-- Fire Stu Settings

	jumphurt = true,
   	speed = 1.5,
    	chargeSpeed = 5,
	ishot = true,
	durability = -1,
}

npcManager.registerHarmTypes(npcID,
	{
		-- HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		-- HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
)

AI.register(npcID, settings)

return strollinStu