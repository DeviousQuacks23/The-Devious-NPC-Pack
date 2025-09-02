local npcManager = require("npcManager")
local splitter = require("npcs/ai/splitter")
local bigGoomba = {}

local splitSFX = Misc.resolveFile("colossalgoomba-die.ogg")

local npcID = NPC_ID

local hugeGoombaSettings = {
	id = npcID, 
	gfxheight = 512, 
	gfxwidth = 512, 
	width = 512, 
	height = 512,
	gfxoffsety=2,
	frames = 2, 
	framestyle = 0,
	framespeed = 128,
	jumphurt = 0, 
	nogravity = 0, 
	noblockcollision = 0,
	nofireball = 0,
	noiceball = 1,
	noyoshi = 1, 
	speed = 0.075,
	iswalker = true,
	health=40,
	splits=2,
	splitid=751,
	weight = 32
}

local harmTypes2 = {
	[HARM_TYPE_SWORD]=752, 
	[HARM_TYPE_PROJECTILE_USED]=10, 
	[HARM_TYPE_SPINJUMP]=10, 
	[HARM_TYPE_TAIL]=752, 
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