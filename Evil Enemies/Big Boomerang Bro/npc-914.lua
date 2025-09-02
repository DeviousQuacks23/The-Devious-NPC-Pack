local npcManager = require("npcManager")
local bro = require("npcs/AI/bro")

local bigBoomerangBros = {}
local npcID = NPC_ID
local broSettings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 48,
	height = 64,
	width = 48,
	gfxoffsety = 2,
	frames = 2,
	framestyle = 1,
	speed = 1,
	score = 5,
	holdoffsetx = 20,
	holdoffsety = 20,
	throwoffsetx = 20,
	throwoffsety = 20,
	walkframes = 100,
	jumpframes = 180,
	jumptimerange = 60,
	jumpspeed = 8.3,
	throwspeedx = 3.4,
	throwspeedy = -8,
	initialtimer = 100,
	waitframeslow = 80,
	waitframeshigh = 120,
	holdframes = 30,
	throwid = 615,
	quake = true,
	quakeintensity = 15,
	stunframes = 130,
	weight = 2,
	followplayer = true
}
npcManager.setNpcSettings(broSettings)

bro.setDefaultHarmTypes(npcID, 914)
bro.register(npcID)

return bigBoomerangBros