local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local noMountSign = {}

function noMountSign.register(npcID)
	npcManager.registerEvent(npcID, noMountSign, "onTickEndNPC")
	npcManager.registerEvent(npcID, noMountSign, "onDrawNPC")
end

local function animationHandling(v, config, settings)
	v.animationFrame = (math.floor(lunatime.tick() / config.framespeed) % config.signFrames) + config.signFrames * (settings.signDir or 0)
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = v.data.frame, frames = config.frames})
end

function noMountSign.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.oldSpeedY = v.speedY
		data.offset = 0
		data.timer = 0
		data.shakeTimer = 0
	end

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then 
		animationHandling(v, config, settings)
		return 
	end

	data.timer = math.max(0, data.timer - 1)
	if data.timer > 0 then
		data.shakeTimer = data.shakeTimer + 1

	       	if data.shakeTimer % 8 > 0 and data.shakeTimer % 8 < 5 then
	       		data.offset = data.offset + 1
	        else
		    	data.offset = data.offset - 1
	        end
	else
		data.offset = 0
		data.shakeTimer = 0
	end

	if v.collidesBlockBottom then
        	if data.oldSpeedY > 1 then
        		v.speedY = -data.oldSpeedY * 0.5
                end
	end
	data.oldSpeedY = v.speedY

	local offset = settings.addY or 0

	for _,p in ipairs(Player.getIntersecting(v.x - config.addHitboxWidth, v.y - offset, v.x + v.width + config.addHitboxWidth, v.y + v.height)) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
			if p.mount == config.preventMount then
				p.speedX = math.sign((p.x + (p.width / 2)) - (v.x + (v.width / 2))) * config.bumpSpeed
				data.timer = config.shakeTime
				SFX.play(3)

				if config.noEntrySFX then 
					SFX.play(config.noEntrySFX)
				end
			end
		end
	end

	animationHandling(v, config, settings)
	npcutils.applyLayerMovement(v)
end

function noMountSign.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

    	npcutils.drawNPC(v, {xOffset = (v.data.offset or 0), priority = -75})
    	npcutils.hideNPC(v)
end

return noMountSign