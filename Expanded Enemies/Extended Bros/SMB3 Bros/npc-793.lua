local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (390)
local throwIDHeld = (13)

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

	throwid = throwID,
	throwidheld = throwIDHeld,

	throwoffsetx = -8,
	throwoffsety = -12,

	animholdframes = 1,
	animshootframes = 1,

	jumpframes = 65,
	jumptimerange = 20,
	jumpspeed = 6,
	secondjumpspeed = 4,
	secondjumpchance = 0.5,

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