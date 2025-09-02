local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (615)

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

	holdoffsetx = 16,
	holdoffsety = 26,
	throwoffsetx = 16,
	throwoffsety = 0,
	waitframeslow = 120,
	waitframeshigh = 180,
	throwspeedx = 0,
	throwspeedy = 0,
	throwid = throwID,
	drawnpcinfront = false,
	syncheldspeed = false,
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro