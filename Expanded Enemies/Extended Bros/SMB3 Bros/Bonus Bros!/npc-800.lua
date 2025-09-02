local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (898)

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

	throwid = throwID,
	volley = 3,
	npcheldfirerate = 9,

	onThrowFunction = (function(bro, ham, data, config)
		local v = ham

		if data.held then 
			v.speedX = RNG.random(1, 5) * v.direction
	        	v.speedY = RNG.random(-5, -10)	

			return 
		end

		-- Fall towards the nearest player
		-- Code taken from cold soup's Ramone Koopa, which is based off of code from MDA's cutscenePal.lua
		local target = Player.getNearest(v.x + v.width / 2, v.y + v.height)
		local distanceX = (target.x+target.width*0.5)-(v.x + v.width*0.5)
		local distanceY = (target.y+target.height)-(v.y + v.height)

		v.speedX = (0.4/32)*distanceX

		local t = math.max(1,math.abs(distanceX/v.speedX))

		v.speedY = (distanceY/t - Defines.npc_grav*t*0.5)
	end),
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

return hammerBro