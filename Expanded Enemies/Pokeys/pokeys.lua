--[[
	Originally written by MrDoubleA, for Super Mario and The Rainbow Stars
	Modified by DeviousQuacks23, with permission
]]--

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local pokeys = {}

pokeys.managerIDList = {}
pokeys.managerIDMap = {}

pokeys.bodyIDList = {}
pokeys.bodyIDMap = {}

function pokeys.registerManager(npcID)
	npcManager.registerEvent(npcID, pokeys, "onTickNPC", "onTickManager")
	npcManager.registerEvent(npcID, pokeys, "onDrawNPC", "onDrawManager")

    	table.insert(pokeys.managerIDList,npcID)
   	pokeys.managerIDMap[npcID] = true
end

local function updateBodyFrame(v)
    	local config = NPC.config[v.id]
    	local data = v.data

    	if data.turnTimer > 0 then
        	data.animationFrame = config.headNormalFrames + config.bodyNormalFrames

        	if not data.isHead then
            		data.animationFrame = data.animationFrame + 1
        	end
    	elseif data.isHead then
        	data.animationFrame = math.floor(data.animationTimer/config.headFrameDelay) % config.headNormalFrames
    	else
        	data.animationFrame = (math.floor(data.animationTimer/config.bodyFrameDelay) % config.bodyNormalFrames) + config.headNormalFrames
    	end

   	data.animationFrame = npcutils.getFrameByFramestyle(v,{frame = data.animationFrame})
    	v.animationFrame = data.animationFrame
end

local function initialiseBody(v)
    	local config = NPC.config[v.id]
    	local data = v.data

    	data.offset = 0
    	data.offsetSpeed = 0
    	data.offsetGoal = 0

    	data.waveTimer = -(data.bodyIndex or 0)*8
    	data.rotation = 0

    	data.animationFrame = 0
    	data.animationTimer = 0

    	data.oldDirection = v.direction
    	data.turnTimer = 0

    	data.isGrabbed = false

    	updateBodyFrame(v)

    	data.initialised = true
end

local function initialiseManager(v)
    	local settings = v.data._settings
    	local config = NPC.config[v.id]
    	local data = v.data

    	local bodyConfig = NPC.config[config.bodyID]

    	data.bodyNPCs = {}
    	data.activeBodyCount = 0

    	data.crumbleTimer = 0
	data.timer = 0

    	for i = 1,settings.segmentCount do -- Build the pokey
        	local offset = -(i - 1)*config.segmentGap
        	local n = NPC.spawn(config.bodyID,v.x + v.width*0.5,v.y + v.height - bodyConfig.height*0.5 + offset,v.section,false,true)

        	n.data.managerNPC = v
        	n.data.bodyIndex = i

        	n.data.isHead = (i == settings.segmentCount)

        	initialiseBody(n)
        
        	n.data.offset = offset
        	n.direction = v.direction

        	table.insert(data.bodyNPCs,n)
        	data.activeBodyCount = data.activeBodyCount + 1
    	end

    	data.headAlive = true
    	data.initialised = true
end

function pokeys.onTickManager(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
        	if data.initialised then
            		for _,n in ipairs(data.bodyNPCs) do
                		if n.isValid then
                    			n:kill(HARM_TYPE_VANISH)
                		end
            		end

		    	data.initialised = false
        	end
        
		return
	end

    	local config = NPC.config[v.id]

	if not data.initialised then
        	initialiseManager(v)
	end

    	local minY = math.huge
    	local offset = 0

    	local validNPCForcedStates = table.map{0,1,3,4} -- 0x138 values that are valid and don't kick the NPC out of the stack

    	data.activeBodyCount = 0
    	data.headAlive = false

    	for k,n in ipairs(data.bodyNPCs) do
        	if n.isValid then
            		n.data.offsetGoal = offset

            		data.headAlive = data.headAlive or n.data.isHead

            		data.activeBodyCount = data.activeBodyCount + 1
            		n.data.bodyIndex = data.activeBodyCount

            		offset = offset - config.segmentGap
            		minY = math.min(minY,n.y)

            		v.despawnTimer = math.max(v.despawnTimer,n.despawnTimer)
            		n.despawnTimer = v.despawnTimer
        	end

		if not n.isValid or n.isGenerator or n.isHidden or n.despawnTimer <= 0 
		or not validNPCForcedStates[n:mem(0x138,FIELD_WORD)] 
		or n:mem(0x12C, FIELD_WORD) > 0 or n.isProjectile
		or n.id == 263 and n.ai1 > 0                       
		then
	    		table.remove(data.bodyNPCs,k) -- Remove from stack
	    		n.data.isGrabbed = true
	    		n.data.managerNPC = nil
        	end
    	end

    	if data.activeBodyCount <= 0 then
        	v:kill(HARM_TYPE_VANISH)
        	return
    	end

    	local newHeight = (v.y + v.height) - minY

    	v.y = v.y + v.height - newHeight
    	v.height = newHeight

    	if data.headAlive then
        	v.speedX = config.speed*v.direction -- Pokey movement

		if config.chaseInterval > 0 then
	    		data.timer = data.timer + 1
	    		if data.timer % config.chaseInterval == 0 then npcutils.faceNearestPlayer(v) end
		end
    	else
		if config.toppleIfHeadless then
            		data.crumbleTimer = data.crumbleTimer + 1

            		v.speedX = 0
            		v:mem(0x18,FIELD_FLOAT,0)

            		v.spawnId = 0

            		if data.crumbleTimer >= config.toppleTime then
                		-- Kill topmost NPC
                		for i = #data.bodyNPCs,1,-1 do
                    			local n = data.bodyNPCs[i]

                    			if n.isValid then
                        			n:kill(HARM_TYPE_NPC)
                        			break
                    			end
                		end

                		data.crumbleTimer = 0
            		end
		else
	    		data.headAlive = true
	    		for i = #data.bodyNPCs,1,-1 do
                		local n = data.bodyNPCs[i]
                		if n.isValid then
                    			n.data.isHead = true
                    			break
               			end
            		end
		end
    	end
end

function pokeys.onDrawManager(v)
    	if v.despawnTimer <= 0 then
        	return
    	end

    	local data = v.data

    	if not data.initialised then
        	initialiseManager(v)
    	end

    	--Colliders.getHitbox(v):draw()
end

function pokeys.registerBody(npcID)
	npcManager.registerEvent(npcID, pokeys, "onTickNPC", "onTickBody")
	npcManager.registerEvent(npcID, pokeys, "onDrawNPC", "onDrawBody")

    	table.insert(pokeys.bodyIDList,npcID)
    	pokeys.bodyIDMap[npcID] = true
end

function pokeys.onTickBody(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
    	local config = NPC.config[v.id]
		
	local manager = data.managerNPC
	
	if v.despawnTimer <= 0 then
		data.initialised = false
		return
	end

	-- Projectile stuff

	if v.isProjectile then 
		v.collisionGroup = "pokeySegments"
		Misc.groupsCollide["pokeySegments"][""] = false -- Disable collision

		-- Since we disabled collision, we'll have to re-add projectile logic
            	for _,n in ipairs(NPC.getIntersecting(v.x + 8, v.y + 8, v.x + v.width - 8, v.y + v.height - 8)) do
            		if n.idx ~= v.idx and not n.isHidden and not n.friendly and not v.friendly and NPC.HITTABLE_MAP[n.id] then
                    		n:harm(3)
		    		v:harm(4)
            		end
	    	end
	end

	-- Animation, rotation and stuff

    	if manager and manager.isValid and manager.data.headAlive then
        	data.waveTimer = data.waveTimer + 1

        	if config.rotate then 
			if (data.bodyIndex % 2 == 0) then -- Even number
	    			data.rotation = math.sin((data.waveTimer / 24) * math.pi) * 12
			else
	    			data.rotation = -math.sin((data.waveTimer / 24) * math.pi) * 12
			end
		end

        	data.animationTimer = data.animationTimer + 1

        	-- Turning
        	if data.oldDirection ~= v.direction then
            		data.oldDirection = v.direction
            		data.turnTimer = config.turnDuration
        	elseif data.turnTimer > 0 then
            		data.turnTimer = data.turnTimer - 1
        	end
	else
		data.rotation = 0
	end

    	updateBodyFrame(v)

	-- Init the body

	if not data.initialised then
		initialiseBody(v)
	end

	-- Manager stuff

    	if manager == nil or not manager.isValid then
		if not data.isGrabbed then
			v:kill(HARM_TYPE_NPC)
		end
		return
    	end

	-- The REAL Pokey code

    	-- Update offset from body
    	data.offsetSpeed = data.offsetSpeed + Defines.npc_grav
    	data.offset = data.offset + data.offsetSpeed

    	if data.offset >= data.offsetGoal then
        	data.offset = data.offsetGoal
        	data.offsetSpeed = 0
    	end

    	-- Move into position
    	v.speedX = manager.speedX
    	v.speedY = manager.speedY + data.offsetSpeed

    	if config.wavyMovement then 
		if config.consistentSpeed then
	    		v.x = manager.x + (manager.width - v.width)*0.5 + (data.bodyIndex > 1 and (math.sin((data.waveTimer+(manager.data.activeBodyCount - data.bodyIndex + 1))/config.waveSpeed)*config.waveIntensity) or 0) - (v.speedX) -- Apply wave offset
		else
    	    		v.x = manager.x + (manager.width - v.width)*0.5 + (math.sin((data.waveTimer+(manager.data.activeBodyCount - data.bodyIndex + 1))/config.waveSpeed)*config.waveIntensity) - (v.speedX) -- Apply wave offset
		end
    	else
    		v.x = manager.x + (manager.width - v.width)*0.5 - v.speedX
    	end

    	v.y = manager.y + manager.height - v.height + data.offset - v.speedY
    	v.direction = manager.direction
end

-- Priority stuffs

local overheadHoldingCharacters = table.map({CHARACTER_PEACH, CHARACTER_TOAD, CHARACTER_MEGAMAN, CHARACTER_KLONOA, CHARACTER_NINJABOMBERMAN, CHARACTER_ROSALINA, CHARACTER_ULTIMATERINKA})

local function isHeldOverhead(v)
	return overheadHoldingCharacters[v.heldPlayer.character]
end

local function getRenderPriority(v)
	local p = -45
	if v.forcedState == NPCFORCEDSTATE_BLOCK_RISE or v.forcedState == NPCFORCEDSTATE_BLOCK_FALL or v.forcedState == NPCFORCEDSTATE_WARP then
		p = -75
	elseif v.heldIndex > 0 then
		if isHeldOverhead(v) then
			p = -24
		else
			p = -30
		end
	elseif NPC.config[v.id].foreground then
		p = -15
	end
	return p
end

function pokeys.onDrawBody(v)
	if v.despawnTimer <= 0 then
        	return
    	end

    	local config = NPC.config[v.id]
    	local data = v.data

    	if not data.initialised then
        	initialiseBody(v)
    	end

    	if data.sprite == nil then
        	data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img,frames = npcutils.getTotalFramesByFramestyle(v),pivot = vector(0.5,0.5)}
    	end

    	data.sprite.x = v.x + v.width*0.5 + config.gfxoffsetx
    	data.sprite.y = v.y + v.height - config.gfxheight*(1 - data.sprite.pivot.y) + config.gfxoffsety
    	data.sprite.rotation = data.rotation*v.direction

	-- Priority
	
	local pri
	if data.managerNPC and data.managerNPC.isValid then
		pri = getRenderPriority(data.managerNPC)
	elseif v and v.isValid then
		pri = getRenderPriority(v)
	else
		pri = -45
	end

	-- Time to render

    	data.sprite:draw{frame = data.animationFrame+1,priority = pri,sceneCoords = true}
    	npcutils.hideNPC(v)

    	--Colliders.getHitbox(v):draw()
end

local deathEffectHarmTypes = table.map{HARM_TYPE_JUMP, HARM_TYPE_FROMBELOW, HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_HELD, HARM_TYPE_TAIL}

function pokeys.onPostNPCKill(v,reason)
    	if pokeys.bodyIDMap[v.id] and deathEffectHarmTypes[reason] then

        	local config = NPC.config[v.id]
        	local effectID = (v.data.isHead and config.headDeathEffect) or config.bodyDeathEffect

        	local effectConfig = Effect.config[effectID][1]

        	Effect.spawn(effectID,v.x + v.width*0.5 - effectConfig.width*(effectConfig.xAlign - 0.5),v.y + v.height*0.5 - effectConfig.height*(effectConfig.yAlign - 0.5))

		-- Spawn NPC (for snow pokeys)

		if v.data.isHead and reason == HARM_TYPE_JUMP and config.spawnedNPC > 0 then
            		local n = NPC.spawn(config.spawnedNPC, v.x + v.width * 0.5,v.y + v.height * 0.5, v.section)
            		n.x = n.x - n.width * 0.5
            		n.y = n.y - n.height * 0.5
	    		n.speedX = 0
	    		n.layerName = "Spawned NPCs"
		end
    	end
end

function pokeys.onInitAPI()
    	registerEvent(pokeys,"onPostNPCKill")
end

return pokeys