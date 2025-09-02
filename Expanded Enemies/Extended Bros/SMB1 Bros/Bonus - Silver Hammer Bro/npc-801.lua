local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (901)

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

	holdoffsetx = 4,
	holdoffsety = 14,
	throwoffsetx = 4,

	walkframes = 50,
	jumpframes = 250,
	jumptimerange = 0,
	jumpspeed = 9,

	throwid = throwID,

	brospeed = 1,
	movewhenjumping = true,

	onThrowFunction = (function(bro, ham, data, config)
		ham.speedX = RNG.random(3, 10) * data.facingDirection
	        ham.speedY = RNG.random(-3, -8)	
	end),
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro