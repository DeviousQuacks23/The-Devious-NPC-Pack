local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (900)

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

	holdoffsetx = 16,
	holdoffsety = 22,
	throwoffsetx = 16,
	throwoffsety = 22,

	jumpframes = 350,
	jumpspeed = 9,

	animholdframes = 1,
	animshootframes = 1,

	movewhenshooting = false,
	throwid = throwID,

	waitframeshigh = 70,
	holdframes = 20,
	npcheldfirerate = 4,

	brospeed = 1,
	quake = true,
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro