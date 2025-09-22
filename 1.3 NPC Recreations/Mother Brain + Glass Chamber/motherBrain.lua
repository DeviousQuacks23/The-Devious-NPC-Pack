local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local averageSmbxBoss = {}
averageSmbxBoss.idMap = {}

function averageSmbxBoss.register(npcID)
	npcManager.registerEvent(npcID, averageSmbxBoss, "onTickEndNPC")
	npcManager.registerEvent(npcID, averageSmbxBoss, "onDrawNPC")
	averageSmbxBoss.idMap[npcID] = true
end

function averageSmbxBoss.onInitAPI()
	registerEvent(averageSmbxBoss, "onNPCHarm")
	registerEvent(averageSmbxBoss, "onPostNPCKill")
end

local function animateIt(v, data, config)
	if data.painTimer > 0 and data.painTimer < config.flashTime then
		v.animationFrame = math.floor(data.animTimer / config.painFramespeed) % config.painFrames + config.idleFrames
	else
		v.animationFrame = math.floor(data.animTimer / config.idleFramespeed) % config.idleFrames
	end

	data.animTimer = data.animTimer + 1
	v.animationFrame = npcutils.getFrameByFramestyle(v, {frame = data.frame, frames = config.frames})
end

function averageSmbxBoss.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		if data.block and data.block.isValid then data.block:delete() end
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.hp = 0
		data.painTimer = 0
		data.shake = vector(0, 0)
		data.animTimer = 0
		data.held = false

		-- Spawn custom collision (so that NPCs can hit it)

		data.block = Block.spawn(config.solidBlockID, v.x, v.y)
		data.block.width = v.width * config.collisionOffset
		data.block.height = v.height * config.collisionOffset
	end

	-- Solid block stuff

	local newBlockX = v.x + v.width * 0.5 - data.block.width * 0.5
	local newBlockY = v.y + v.height * 0.5 - data.block.height * 0.5

	data.block.extraSpeedX = (newBlockX - data.block.x)
	data.block.extraSpeedY = (newBlockY - data.block.y)
	data.block:translate(data.block.extraSpeedX, data.block.extraSpeedY)

	-- Some more stuff

	if v.despawnTimer > 1 then v.despawnTimer = 100 end
        if v.isProjectile then v.isProjectile = false end

	if v.heldIndex > 0 then 
		data.held = true 
	else
		if data.held then v:kill(3) end
	end

	-- The actual AI

	local B, C = 0, 0
	if data.painTimer >= 1 then
                B = 1 - (data.painTimer / config.shakeTime)
                C = B * 0.5
                B = B * 15
                C = C * 15

                data.shake.x = RNG.random() * B - RNG.random() * C
                data.shake.y = RNG.random() * B - RNG.random() * C

		data.painTimer = data.painTimer + 1
		if data.painTimer >= config.shakeTime then data.painTimer = 0 end
	else
		data.shake = vector(0, 0)
	end

	npcutils.applyLayerMovement(v)
	animateIt(v, data, config)
end

function averageSmbxBoss.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data
	local config = NPC.config[v.id]

	if data.painTimer >= 1 then
		npcutils.drawNPC(v, {xOffset = (data.shake.x * config.shakeIntensity), yOffset = (data.shake.y * config.shakeIntensity)})
		npcutils.hideNPC(v)
	end
end

function averageSmbxBoss.onNPCHarm(eventObj, v, reason, culprit)
	if not averageSmbxBoss.idMap[v.id] then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	eventObj.cancelled = true
	if v:mem(0x156, FIELD_WORD) > 0 then return end
	
	if reason == HARM_TYPE_NPC or reason == HARM_TYPE_SWORD then
		if not (type(culprit) == "NPC" and culprit.id == 13) then
			if (type(culprit) == "NPC" and culprit.id == 171) then
				v:mem(0x156, FIELD_WORD, config.hammerImmune)
			else
				v:mem(0x156, FIELD_WORD, config.immune)
			end

			data.hp = data.hp + 1

			if data.hp >= config.health then
				v:kill(3)
			else
				data.painTimer = 1
				if config.hurtSFX then SFX.play(config.hurtSFX) end
			end
		end
	end
end

function averageSmbxBoss.onPostNPCKill(v, reason)
	if not averageSmbxBoss.idMap[v.id] then return end
	
	local config = NPC.config[v.id]

	if v.data.block and v.data.block.isValid then v.data.block:delete() end
	if reason == HARM_TYPE_NPC or reason == HARM_TYPE_SWORD then
		if config.deathSFX then SFX.play(config.deathSFX) end
		if config.explodeSFX then SFX.play(config.explodeSFX) end
	end
end

return averageSmbxBoss