local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (390)
local throwIDHeld = (13)

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

	throwid = throwID,
	throwidheld = throwIDHeld,

	throwoffsetx = -18,
	throwoffsety = -16,

	animholdframes = 1,
	animshootframes = 1,

	jumpspeed = 9,
	quake = true,

	movewhenshooting = false,
	doheldharm = false,
	drawheldnpc = false,

	volley = 2,
	volleyframes = 40,

	waitframeslow = 135,
	waitframeshigh = 180,
	holdframes = 40,

	throwspeedx = 4.5,
	throwspeedy = 4,
	throwSFX = 18,

	-- Make fire bros shoot fireballs upwards when held
	onThrowFunction = (function(bro, ham, data, config)
        	if bro:mem(0x12C,FIELD_WORD) > 0 then
        		local p = Player(bro:mem(0x12C,FIELD_WORD))
			
			if p.keys.up then
				ham.speedY = -6
			end
		end
	end),
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro