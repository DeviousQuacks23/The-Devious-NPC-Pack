local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local whistle = require("npcs/ai/whistle")

local swoops = {}

local IDLE = 0
local SWOOP = 1

function swoops.register(npcID)
	npcManager.registerEvent(npcID, swoops, "onTickEndNPC")
end

local function animationHandling(v, data, config)
	if data.state == IDLE then
		v.animationFrame = math.floor(data.animTimer / config.idleFramespeed) % config.idleFrames
	elseif data.state == SWOOP then
		v.animationFrame = math.floor(data.animTimer / config.swoopFramespeed) % config.swoopFrames + config.idleFrames
	end

	data.animTimer = data.animTimer + 1
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = data.frame, frames = config.frames})
end

local function wakeUp(v, p, data, config)
	data.state = SWOOP
	data.animTimer = 0

	if config.swoopSFX then 
		SFX.play(config.swoopSFX)
	end

  	if (p.x + (p.width * 0.5)) < (v.x + (v.width * 0.5)) then
        	v.direction = -1
        else
                v.direction = 1
        end
        v.speedX = 0.01 * v.direction

	local n = (config.swoopTowardsPlayer and p) or v
                            
	if (p.y + (p.height * 0.5)) > (v.y + (v.height * 0.5)) then
       		v.speedY = config.swoopSpeedY
		data.swoopDist = (n.y + (n.height * 0.5)) - config.swoopYOffset
	else
		v.speedY = -config.swoopSpeedY
		data.swoopDist = (n.y + (n.height * 0.5)) + config.swoopYOffset
	end
end

function swoops.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.hitbox = Colliders.Box(v.x, v.y, config.detectSize.x, config.detectSize.y)
		data.state = IDLE
		data.swoopDist = 0
		data.animTimer = 0
		data.swooped = false
	end

	data.hitbox.x = v.x + (v.width * 0.5) - (data.hitbox.width * 0.5)
	data.hitbox.y = v.y + (v.height * 0.5) - (data.hitbox.height * 0.5)

	if v.heldIndex ~= 0 or v.forcedState > 0 then 
		animationHandling(v, data, config)
		return 
	end
	
	-- Bat thing

	if data.state == IDLE then
		for _,p in ipairs(Player.get()) do
			if p.section == v.section and p.deathTimer == 0 then
				if Colliders.collide(data.hitbox, p) then
					wakeUp(v, p, data, config)
				end
			end
		end

		if whistle.getActive() then
			wakeUp(v, npcutils.getNearestPlayer(v), data, config)
		end

		npcutils.applyLayerMovement(v)
	elseif data.state == SWOOP then
		if config.isHoming then
			v.speedX = config.swoopSpeedX * v.direction
		else
			v.speedX = (config.swoopSpeedX - math.clamp(math.abs(v.speedY), 0, config.swoopSpeedX)) * v.direction
		end

		if (v.speedY > 0 and (v.y + (v.height * 0.5)) > data.swoopDist) or (v.speedY < 0 and (v.y + (v.height * 0.5)) < data.swoopDist) then
			if not data.swooped then
				data.swooped = true
			end
		end

		if data.swooped then
			if config.isHoming then
            			local p = npcutils.getNearestPlayer(v)
				if (v.y + v.height * 0.5) > (p.y + p.height * 0.5) then
					v.speedY = v.speedY - config.homingAccel
				else
					v.speedY = v.speedY + config.homingAccel
				end

				v.speedY = math.clamp(v.speedY, -config.homingSpeed, config.homingSpeed)
			else
                		if v.speedY > 0 then
                        		v.speedY = math.max(0, v.speedY - config.deceleration)
                		elseif v.speedY < 0 then
                        		v.speedY = math.min(0, v.speedY + config.deceleration)
                		else
                        		v.speedY = 0
                		end
			end
		end
	end

	animationHandling(v, data, config)
end

return swoops