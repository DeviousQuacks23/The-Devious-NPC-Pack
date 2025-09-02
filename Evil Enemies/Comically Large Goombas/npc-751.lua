local npcManager = require("npcManager")
local splitter = require("npcs/ai/splitter")
local bigGoomba = {}

local splitSFX = Misc.resolveFile("gigagoomba-die.ogg")

local npcID = NPC_ID

local hugeGoombaSettings = {
	id = npcID, 
	gfxheight = 256, 
	gfxwidth = 256, 
	width = 256, 
	height = 256,
	gfxoffsety=2,
	frames = 2, 
	framestyle = 0,
	framespeed = 64,
	jumphurt = 0, 
	nogravity = 0, 
	noblockcollision = 0,
	nofireball = 0,
	noiceball = 1,
	noyoshi = 1, 
	speed = 0.15,
	iswalker = true,
	health=20,
	splits=2,
	splitid=467,
	weight = 16
}

local harmTypes2 = {
	[HARM_TYPE_SWORD]=751, 
	[HARM_TYPE_PROJECTILE_USED]=10, 
	[HARM_TYPE_SPINJUMP]=10, 
	[HARM_TYPE_TAIL]=751, 
	[HARM_TYPE_JUMP]=10, 
	[HARM_TYPE_FROMBELOW]=10, 
	[HARM_TYPE_HELD]=10, 
	[HARM_TYPE_NPC]=10, 
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmTypes2), harmTypes2)

npcManager.setNpcSettings(hugeGoombaSettings)

splitter.register(npcID, splitSFX)

return bigGoomba