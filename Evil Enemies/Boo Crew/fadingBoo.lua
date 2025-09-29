local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local fadingBoos = {}

local FLOAT = 0
local PRESWOOP = 1
local SWOOP = 2

function fadingBoos.register(npcID)
	npcManager.registerEvent(npcID, fadingBoos, "onTickEndNPC")
    	npcManager.registerEvent(npcID, fadingBoos, "onDrawNPC")
end

local function animationHandling(v, data, config)
	local frames = (config.frames / config.booVariants)
	v.animationFrame = math.floor(data.animTimer / config.framespeed) % frames + (frames * data.variant)

	data.animTimer = data.animTimer + 1
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = data.frame, frames = config.frames})

	if data.state == FLOAT then
		data.opacity = math.max(config.inactiveOpacity, data.opacity - config.fadeSpeed)
	else
		data.opacity = math.min(1, data.opacity + config.fadeSpeed)
		data.swoopInt = RNG.randomInt(config.minSwoopTime, config.maxSwoopTime)
	end
end

local function init(v, data, config)
	data.initialized = true
	npcutils.hideNPC(v)

	data.timer = 0
	data.animTimer = 0

	data.swoopInt = RNG.randomInt(config.minSwoopTime, config.maxSwoopTime)
	data.variant = (RNG.randomInt(1, config.booVariants) - 1)
	data.sineDir = RNG.irandomEntry({-1, 1})

	data.state = FLOAT
	data.opacity = config.inactiveOpacity
	data.ogFriendly = v.friendly
	v.friendly = true

        data.diveStartPosition = nil
        data.divePlayerPosition = nil
end

function fadingBoos.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		init(v, data, config)
	end

	animationHandling(v, data, config)

	if v.isProjectile then v.isProjectile = false end
	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

    	local p = npcutils.getNearestPlayer(v)
        npcutils.applyLayerMovement(v)
	data.timer = data.timer + 1
	
	if data.state == FLOAT then
		v.speedX = config.floatSpeed * v.direction
		v.speedY = (math.sin(data.timer * config.sineTimeMod) * config.sineAmplitude) * data.sineDir

		if data.timer % config.turnAroundTime == 0 then
			v.direction = -v.direction
		end

		v.friendly = true
            	local distX = (p.x + p.width * 0.5) - (v.x + v.width * 0.5)

		if math.abs(distX) <= config.minSwoopDist and p.y >= v.y then
			if RNG.randomInt(1, config.swoopChance) == 1 then
				if data.timer % data.swoopInt == 0 then
					v.friendly = data.ogFriendly
					npcutils.faceNearestPlayer(v)
                			data.diveStartPosition, data.divePlayerPosition = vector(v.x + (v.width / 2), v.y + (v.height / 2)), vector(p.x + (p.width / 2), p.y + (p.height / 2))
					data.state = PRESWOOP
					data.timer = 0
				end
			end
		end
	elseif data.state == PRESWOOP then
		v.speedX, v.speedY = 0, 0

		if data.timer >= config.preSwoopTime then
			data.state = SWOOP
                   	data.timer = 0
		end
	elseif data.state == SWOOP then
                v.speedX = (data.diveStartPosition.x + ((data.divePlayerPosition.x - data.diveStartPosition.x)) - data.diveStartPosition.x) / 128
                v.speedY = math.cos((data.timer * (math.pi * config.swoopSpeed)) / 256) * ((data.divePlayerPosition.y - data.diveStartPosition.y) / config.swoopDistY)
    
                if v.y + (v.height / 2) < data.diveStartPosition.y and v.speedY < 0 then
			v.direction = RNG.irandomEntry({-1, 1})
			data.sineDir = RNG.irandomEntry({-1, 1})
                    	data.state = FLOAT
                   	data.timer = 0
                end
	end
end

function fadingBoos.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data
        local config = NPC.config[v.id]

	if not data.initialized then init(v, data, config) end
	if data.opacity >= 1 then return end

	npcutils.drawNPC(v, {opacity = data.opacity})
	npcutils.hideNPC(v)
end

return fadingBoos