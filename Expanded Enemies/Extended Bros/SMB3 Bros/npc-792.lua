local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (898)

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

	holdoffsetx = 18,
	holdoffsety = 22,
	throwoffsetx = 16,
	throwoffsety = 22,

	jumpspeed = 9,
	throwid = throwID,
	quake = true,
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro