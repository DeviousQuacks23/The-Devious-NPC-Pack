local npcManager = require("npcManager")
local bro = require("extendedBros")

local hammerBro = {}
local npcID = NPC_ID

local deathEffectID = (npcID)
local throwID = (898)

local crossHairIMG = Graphics.loadImageResolved("eliteBroCrossHair.png")
local crossHairSFX = Misc.resolveSoundFile("eliteBroCrossHair.ogg")

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

		local dist = math.abs((distanceX + distanceY) / 2)
		if dist > 192 then return end

		local mod = RNG.random(0.4, 0.7)
		v.speedX = (mod/32)*distanceX

		local t = math.max(1,math.abs(distanceX/v.speedX))

		v.speedY = (distanceY/t - Defines.npc_grav*t*0.5)
	end),
}

npcManager.setNpcSettings(broSettings)
bro.setDefaultHarmTypes(npcID, deathEffectID)

bro.register(npcID)

function hammerBro.onInitAPI()
	npcManager.registerEvent(npcID, hammerBro, "onDrawNPC")
end

function hammerBro.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

    	local data = v.data._basegame

	if data.held then return end
	if data.throwingID ~= nil then
		local target = Player.getNearest(v.x + v.width / 2, v.y + v.height)
		local distanceX = (target.x+target.width*0.5)-(v.x + v.width*0.5)
		local distanceY = (target.y+target.height)-(v.y + v.height)
		local dist = math.abs((distanceX + distanceY) / 2)
		local scale = RNG.random(0.9, 1.1)

		if dist <= 192 then
	        	Graphics.drawBox{
		        	texture = crossHairIMG,
		        	x = (target.x + (target.width / 2)) + RNG.random(-8, 8),
		        	y = (target.y + (target.height / 2)) + RNG.random(-8, 8),
		        	width = crossHairIMG.width * scale,
		        	height = crossHairIMG.height * scale,
		        	sceneCoords = true,
		        	centered = true,
		        	priority = -5,
	        	}

			-- Crosshair SFX
	
			if not data.crossHairSFX then
				data.crossHairSFX = SFX.play(crossHairSFX)
			else
				if not data.crossHairSFX:isplaying() then SFX.play(crossHairSFX) end
			end
		end
	end
end

return hammerBro