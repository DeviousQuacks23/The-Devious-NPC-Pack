local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Based off code by Emral

local fallingSpike = {}

fallingSpike.sharedSettings = {
	gfxoffsetx = 0,
	gfxoffsety = 0, 

	width = 32, 
    	height = 32,
    	gfxwidth = 32,
    	gfxheight = 32,

    	frames = 1,
    	framestyle = 1,

    	noiceball = true,
    	noyoshi = true,
	luahandlesspeed = true,
	notcointransformable = true,
	ignorethrownnpcs = true,
        terminalvelocity = -1,  
	noblockcollision = true,
    	nowaterphysics = true,
    	jumphurt = true,
    	spinjumpsafe = true,
    	nogravity = true,
	staticdirection = true,

	-- Custom:

	isHorizontal = false,

	checkInterval = 16,
	detectSize = 96,
	fallSFX = Misc.resolveFile("fallingSpike.ogg"),

	shakeTime = 64,
	fallAccel = Defines.npc_grav,
	maxFallSpeed = 8,
}

function fallingSpike.register(id)
    	npcManager.registerEvent(id, fallingSpike, "onTickEndNPC")
    	npcManager.registerEvent(id, fallingSpike, "onDrawNPC")
end

local function customGravity(data, speed, maxSpeed, gravity)
	if data.direction == 1 then
		return math.min(maxSpeed, speed + gravity)
	elseif data.direction == -1 then	
		return math.max(-maxSpeed, speed - gravity)
	end
end

function fallingSpike.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data
        local config = NPC.config[v.id]

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true

    		data.timer = 0
		data.offset = 0
		data.direction = v.direction
	end

	if v.isProjectile then v.isProjectile = false end
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

        npcutils.applyLayerMovement(v)
	local speed = (config.isHorizontal and "speedX") or "speedY"

	if data.timer <= 0 then
            	local p = npcutils.getNearestPlayer(v)
            	local distX = (p.x + p.width * 0.5) - (v.x + v.width * 0.5)
            	local distY = (p.y + p.height * 0.5) - (v.y + v.height * 0.5)
		local dist = (config.isHorizontal and distY) or distX
		
        	if lunatime.tick() % config.checkInterval == 0 then
			if math.abs(dist) <= config.detectSize then data.timer = 1 end
		end
	else
		data.timer = data.timer + 1
		if data.timer > config.shakeTime then
			v[speed] = customGravity(data, v[speed], config.maxFallSpeed, config.fallAccel)
			data.offset = 0
		else
	        	if data.timer % 4 > 0 and data.timer % 4 < 3 then
		    		data.offset = data.offset + 2
	        	else
		    		data.offset = data.offset - 2
	        	end

			if data.timer == config.shakeTime then
				if config.fallSFX then SFX.play(config.fallSFX) end
			end
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames,
		direction = data.direction
	});
end

function fallingSpike.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data
        local config = NPC.config[v.id]

    	if not data.offset or data.offset == 0 then return end

	if config.isHorizontal then
		npcutils.drawNPC(v, {yOffset = data.offset})
	else
		npcutils.drawNPC(v, {xOffset = data.offset})
	end

	npcutils.hideNPC(v)
end

return fallingSpike