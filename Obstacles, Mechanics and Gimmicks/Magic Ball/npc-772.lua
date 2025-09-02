local npcManager = require("npcManager")
local AI = require("magicBall_ai")

local ball = {}
local npcID = NPC_ID

local ballSettings = table.join({
	id = npcID,

	gfxwidth = 36,
	gfxheight = 36,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 4,
	framestyle = 1,
	framespeed = 4, 
},AI.sharedSettings)

npcManager.setNpcSettings(ballSettings)
AI.register(npcID)

return ball