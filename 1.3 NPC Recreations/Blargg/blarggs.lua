local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")

-- Sprites by Mister Mike

local blarggs = {}

local IDLE = 0
local PEEK = 1
local LEAP = 2

function blarggs.register(npcID)
	npcManager.registerEvent(npcID, blarggs, "onTickNPC")
    	npcManager.registerEvent(npcID, blarggs, "onDrawNPC")
end

function blarggs.onTickNPC(v)
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
		data.timer = 0
		data.scale = config.startScale
		data.canRender = false
		data.peekY = 0

		v.y = v.y + v.height + config.spawnOffset
	end

	data.hitbox.x = v.x + (v.width * 0.5) - (data.hitbox.width * 0.5)
	data.hitbox.y = v.y + (v.height * 0.5) - (data.hitbox.height * 0.5)

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then return end

	npcutils.applyLayerMovement(v)
	data.timer = data.timer + 1

	if data.state == IDLE then
		for _,p in ipairs(Player.get()) do
			if p.section == v.section and p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
				if Colliders.collide(data.hitbox, p) then
  					if (p.x + (p.width * 0.5)) < (v.x + (v.width * 0.5)) then
        					v.direction = -1
        				else
                				v.direction = 1
        				end

					data.state = PEEK
					data.canRender = true
					data.timer = 0
				end
			end
		end
	elseif data.state == PEEK then
		if data.timer <= config.peekRiseTime then
			data.peekY = easing.outBack(data.timer / config.peekRiseTime, 0, -config.peekRiseHeight, 1, config.peekRiseAmplifier)
		elseif data.timer >= config.peekFallTime then
			data.peekY = data.peekY + config.peekFallSpeed
		end

		if config.peekSFXDelay > 0 then
			if (data.timer > config.peekRiseTime) and (data.timer <= config.peekFallTime) then
				if data.timer % config.peekSFXDelay == 0 then 
					SFX.play(72) 
				end
			end
		end

		if data.timer >= (config.peekTime - (1 / config.scaleSpeed)) then
			data.scale = math.min(1, data.scale + config.scaleSpeed)
		end

		if data.timer >= config.peekTime then
			data.state = LEAP
			data.canRender = false
			data.timer = 0

			v.speedX = config.leapSpeed.x * v.direction
			v.speedY = -config.leapSpeed.y

			if config.leapSFX then 
				SFX.play(config.leapSFX)
			end
		end
	elseif data.state == LEAP then
		v.speedY = math.min(config.leapTerminalVelocity, v.speedY + (Defines.npc_grav * config.leapGravityMod))

		if v.y > (v.spawnY + v.height + config.leapDespawnOffset) then
			data.scale = math.max(0, data.scale - config.shrinkSpeed)
			if data.scale <= 0 then
				v:mem(0x124,FIELD_BOOL, false)
				v.despawnTimer = 0
			end
		end
	end
end

function blarggs.onDrawNPC(v)
    	if v.despawnTimer <= 0 or v.isHidden then return end
	if not v.data.initialized then return end

    	local config = NPC.config[v.id]
    	local data = v.data

	-- Peek sprite

    	if data.sprite == nil then
        	data.sprite = Sprite{texture = config.peekIMG, frames = config.peekFrames, pivot = Sprite.align.TOP}
    	end

    	data.sprite.x = v.x + v.width * 0.5 + ((config.peekIMG.width * 0.5) * v.direction)
    	data.sprite.y = v.y + data.peekY
	
	if data.canRender then
    		data.sprite:draw{frame = (math.floor(data.timer / config.peekFramespeed) % config.peekFrames) + 1, priority = config.peekPriority, sceneCoords = true}
	end

	-- Custom rendered Blarggs (for scale)

	if data.scale >= 1 then return end

	local img = Graphics.sprites.npc[v.id].img
	local lowPriorityStates = table.map{1,3,4}
        local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	if data.scale > 0 then
	        Graphics.drawBox{
		        texture = img,
		        x = v.x+(v.width/2)+config.gfxoffsetx,
		        y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		        width = config.gfxwidth * data.scale,
		        height = config.gfxheight * data.scale,
		        sourceY = v.animationFrame * config.gfxheight,
		        sourceHeight = config.gfxheight,
                        sourceWidth = config.gfxwidth,
		        sceneCoords = true,
		        centered = true,
		        priority = priority,
	        }
	end

	npcutils.hideNPC(v)
end

return blarggs