local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local chompRocks = {}
chompRocks.idMap = {}

function chompRocks.register(npcID)
	npcManager.registerEvent(npcID, chompRocks, "onTickEndNPC")
	npcManager.registerEvent(npcID, chompRocks, "onDrawNPC")
	chompRocks.idMap[npcID] = true

	-- This is here so that stuff like beach koopas and outmaways will kick the rock
	NPC.VEGETABLE_MAP[npcID] = true
end

-- Taken directly from basegame spike AI
local function getSlopeSteepness(v)
	local greatestSteepness = 0

	for _,b in Block.iterateIntersecting(v.x,v.y + v.height,v.x + v.width,v.y + v.height + 0.2) do
		if not b.isHidden and not b:mem(0x5A,FIELD_BOOL) then
			local config = Block.config[b.id]

			if config ~= nil and config.floorslope ~= 0 and not config.passthrough and config.npcfilter == 0 then
				local steepness = b.height/b.width

				if steepness > math.abs(greatestSteepness) then
					greatestSteepness = steepness*config.floorslope
				end
			end
		end
	end

	return greatestSteepness
end

local function getPlayerPushing(v)
	for _,p in ipairs(Player.get()) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
			if Colliders.collide(p, Colliders.Box(v.x + 2, v.y - 2, v.width, v.height)) and p.keys.left then
				return -1
			elseif Colliders.collide(p, Colliders.Box(v.x - 2, v.y - 2, v.width, v.height)) and p.keys.right then
				return 1
			end
		end
	end

	return false
end

function chompRocks.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.rotation = 0
	end

	data.rotation = data.rotation + (v.speedX * config.rotSpeed)
	if not v.collidesBlockBottom then data.sfxTimer = (data.sfxTimer or 0) + 1 end

	if data.sfxTimer and data.sfxTimer >= 12 and v.collidesBlockBottom then
		data.sfxTimer = 0
		SFX.play(37)
	end

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then 
		if v.isProjectile then npcutils.applyStationary(v) end
		return 
	end

	-- Physics

	if getPlayerPushing(v) then
		v.speedX = v.speedX + (config.pushAccel * getPlayerPushing(v))
	elseif getSlopeSteepness(v) ~= 0 then
		v.speedX = v.speedX + (getSlopeSteepness(v) * config.slopeAccel)
	else
		if v.collidesBlockBottom then
                	if v.speedX > 0 then
                        	v.speedX = math.max(0, v.speedX - config.decel)
                	elseif v.speedX < 0 then
                        	v.speedX = math.min(0, v.speedX + config.decel)
                	else
                        	v.speedX = 0
                	end
		end
	end

	if v.collidesBlockLeft or v.collidesBlockRight then
		if getPlayerPushing(v) then
			v.speedX = 0
		else
			v.speedX = -(v.speedX * config.turnAroundSpeed)
		end
	end

	v.speedX = math.clamp(v.speedX, -config.maxSpeed, config.maxSpeed)
	v:mem(0x120, FIELD_BOOL, false)

	-- VFX

	if math.abs(v.speedX) >= config.minFxSpeed and v.collidesBlockBottom then
		if config.rollSfx then
			SFX.play(config.rollSfx, 1, 1, config.rollSfxDelay)
		end
		if RNG.randomInt(1, 3) == 1 then
                        local e = Effect.spawn(74, v.x + v.width * 0.5, v.y + v.height)
                        e.x = e.x - e.width * 0.5
			e.x = e.x + ((v.width * 0.5) * math.sign(v.speedX))
                        e.y = e.y - e.height * 0.5
		end
	end

	-- Wreck stuff

	for _, b in ipairs(Block.getIntersecting(v.x + v.speedX, v.y, v.x + v.width + v.speedX, v.y + v.height)) do
		if not b.isHidden and not b.layerObj.isHidden and b.layerName ~= "Destroyed Blocks" and b:mem(0x5A, FIELD_WORD) ~= -1 and Block.MEGA_SMASH_MAP[b.id] and v.speedX ~= 0 then 
			b:remove(true)
			SFX.play(3)
		end
	end

	for _, n in ipairs(NPC.getIntersecting(v.x + v.speedX, v.y, v.x + v.width + v.speedX, v.y + v.height)) do
		if n.id ~= v.id and n.idx ~= v.idx and n.isValid and not n.isHidden and not n.friendly and n.despawnTimer > 0 and v.speedX ~= 0 and NPC.HITTABLE_MAP[n.id] then 
			n:harm(3)
			if n.killFlag == 0 then
				v.speedX = -v.speedX
			end
		end
	end

	-- Push other rocks

	for _, n in ipairs(NPC.getIntersecting(v.x + v.speedX, v.y, v.x + v.width + v.speedX, v.y + v.height)) do
		if chompRocks.idMap[n.id] and n.idx ~= v.idx and n.isValid and not n.isHidden and not n.friendly and n.despawnTimer > 0 and v.speedX ~= 0 then 
			SFX.play(Misc.resolveSoundFile("bowlingball"), 1, 1, 6)
			n.speedX = v.speedX
			v.speedX = 0
		end
	end
end

function chompRocks.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

    	local config = NPC.config[v.id]
    	local data = v.data

    	local texture = Graphics.sprites.npc[v.id].img

    	if data.sprite == nil or data.sprite.texture ~= texture then
        	data.sprite = Sprite{texture = texture, frames = npcutils.getTotalFramesByFramestyle(v), pivot = Sprite.align.CENTRE}
    	end

	local lowPriorityStates = table.map{1, 3, 4}
    	local priority = (lowPriorityStates[v:mem(0x138, FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

    	data.sprite.x = v.x + v.width*0.5 + config.gfxoffsetx
    	data.sprite.y = v.y + v.height - config.gfxheight*0.5+ config.gfxoffsety
    	data.sprite.rotation = data.rotation or 0

    	data.sprite:draw{frame = v.animationFrame + 1, priority = priority, sceneCoords = true}

	-- Colliders.getHitbox(v):draw()
    	npcutils.hideNPC(v)
end

return chompRocks