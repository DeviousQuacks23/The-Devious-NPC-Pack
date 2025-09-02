local npc = {}
local id = NPC_ID

local settings = {
	id = id,
	
	frames = 4,
	framespeed = 16,
	
	jumphurt = true,
	nohurt = true,
	
	npcblock = true,
	npcblocktop = false,
	playerblock = true,
	playerblocktop = true,
	noblockcollision = false,
	
	grabside = false,
	grabtop = true,
	
	noiceball = true,
	noyoshi= false,
	nofireball = true,

	nowalldeath = true,

	harmlessgrab = true,
	hitbounceheight = 5,
	bounceheight = 5,
        weight = 3,
	speed = 3.5,
	luahandlesspeed = true,
	useclearpipe = true
}

function npc.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end
	
	if v.speedX == 0 then
		v.animationFrame = 0
	end
end

function npc.onNPCHarm(e, v, reason, culprit)
	if reason == HARM_TYPE_LAVA or reason == HARM_TYPE_OFFSCREEN then return end

	if culprit ~= nil and culprit.isValid and culprit.id == NPC_ID then
		e.cancelled = true

		culprit.noblockcollision = true
		culprit.friendly = true
		culprit.isProjectile = false
		culprit.speedY = math.min(culprit.speedY, -NPC.config[culprit.id].hitbounceheight)
	end
end

function npc.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	if v.despawnTimer <= 0 then return end
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

	local config = NPC.config[v.id]
	local data = v.data._basegame

        if not v.underwater and data.dolowgravity and v.isProjectile then
        	v.speedY = v.speedY - 0.05
        end
	
	if v.speedX ~= 0 then
		data.lastDirection = data.lastDirection or v.direction

		if v.collidesBlockBottom then
			v.speedY = -NPC.config[v.id].bounceheight
			data.dolowgravity = true
		end

		if v.direction ~= data.lastDirection then
			v.speedX = v.direction * math.min(math.abs(v.speedX), NPC.config[v.id].speed)
		end

		data.lastDirection = v.direction
	end

	if v.speedX == 0 and v.speedY == 0 then
		v.isProjectile = false
	end

	if v.isProjectile and not config.harmlessthrown then
		-- We only want the rock to harm the player in the projectile state.
		-- You'd think just having it be solid would prevent this, but it can, somewhat randomnly, still happen.
		-- This just manually implements harming the player (in such a way that players on top of the rock should be safe).

		local x1 = v.x + 2
		local y1 = v.y + math.max(2,v.speedY)
		local x2 = v.x + v.width - 2
		local y2 = v.y + v.height - 2

		for _,p in ipairs(Player.getIntersecting(x1,y1,x2,y2)) do
			if p.idx ~= v:mem(0x130,FIELD_WORD) and p.idx ~= v.heldIndex then
				p:harm()
			end
		end
	end
end

function npc.onInitAPI()
	local nm = require 'npcManager'
	
	nm.setNpcSettings(settings)
	nm.registerHarmTypes(NPC_ID, {HARM_TYPE_LAVA, HARM_TYPE_SWORD, {
		[HARM_TYPE_SWORD] = 10,
		[HARM_TYPE_LAVA] = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
	}})
	nm.registerEvent(NPC_ID, npc, 'onDrawNPC')
	nm.registerEvent(NPC_ID, npc, 'onTickEndNPC')
	registerEvent(npc, "onNPCHarm")
end

return npc