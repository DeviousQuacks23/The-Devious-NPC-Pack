local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (897)

local broSettings = {
	id = npcID,

	gfxheight = 64,
	gfxwidth = 48,
	height = 64,
	width = 48,

	gfxoffsety = 2,

	frames = 4,
	framestyle = 1,
	framespeed = 8,

	score = 5,
	weight = 2,

	-- Custom properties

	holdoffsetx = 14,
	holdoffsety = 18,
	throwoffsetx = 14,

	walkframes = 50,
	jumpframes = 350,
	jumptimerange = 0,
	jumpspeed = 9,

	throwid = throwID,

	waitframeslow = 20,
	waitframeshigh = 20,
	holdframes = 20,
	initialtimerrange = 0,
	npcheldfirerate = 2,

	brospeed = 1,
	quake = true,
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro