local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (899)

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

	holdoffsetx = 10,
	throwoffsetx = 10,

	holdframes = 50,
	npcheldfirerate = 4,

	throwid = throwID,
	syncheldspeed = false,

	holdSFX = ("sniperBro-load.ogg"),
	throwSFX = ("sniperBro-shoot.ogg"),

	onThrowFunction = (function(bro, ham, data, config)
		local v = ham

		if data.held then
			v.speedX = 12 * v.direction
	        	v.speedY = 0	

			v.data.isHeldHammer = true

			return
		end

		-- Sniper Bro logic
		local p = Player.getNearest(v.x + v.width / 2, v.y + v.height)
	        data.pos = vector((p.x + p.width * 0.5) - (v.x + v.width * 0.5), (p.y + p.height * 0.5) - (v.y + v.height * 0.5)):normalize()

	        v.speedX = data.pos.x * 12
	        v.speedY = data.pos.y * 12
	end),
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro