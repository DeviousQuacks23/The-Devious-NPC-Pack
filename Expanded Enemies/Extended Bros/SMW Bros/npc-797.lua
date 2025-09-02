local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (900)

local broSettings = {
	id = npcID,

	gfxheight = 48,
	gfxwidth = 32,
	height = 48,
	width = 32,

	gfxoffsety = 2,

	frames = 4,
	framestyle = 1,
	framespeed = 8,

	score = 5,

	-- Custom properties

	holdoffsetx = 14,
	holdoffsety = 18,
	throwoffsetx = 14,

	animjumpframes = 1,
	animholdframes = 1,

	movewhenshooting = false,

	waitframeshigh = 70,
	holdframes = 20,
	npcheldfirerate = 4,

	brospeed = 1,
	throwid = throwID,
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro