local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local wizzerds = {}
-- Sprites by Teeks, tweaked by me

wizzerds.sharedSettings = {
	gfxwidth = 52,
	gfxheight = 48,
	width = 40,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 5,

	frames = 5,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = true,

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, 

	nofireball = false,
	noiceball = true,
	noyoshi= true, 

	score = 0, 
	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

        terminalvelocity = -1,
	staticdirection = true, 

        -- Custom Settings:

	-- HP 
	health = 3,
	disappearEffect = 294,
	disappearSound = 91,
	finalScore = 5,

	-- Animation
	headFrames = 4,
	mouthFrames = 1,

	-- Movement
	chaseSpeed = 0.15,
	maxSpeed = 3,
	sineSpeed = 1.5,
	sineStrength = 0.75,
	chaseRadius = 112,

	-- Mouth
	openMouthChance = 0.075,
	mouthOpenShootChance = 0.25,
	mouthOpenSpeed = 0.5,
	mouthOpenLength = 6,
	mouthOpenLengthShooting = 16,
	closedOffset = 3,

	-- Shooting
	fireID = 699,
	fireSpeedX = 3,
	fireSFX = Misc.resolveSoundFile("sound/character/samus_shoot"),

	-- Hands
	handIMG = nil,
	handOffsetX = 36,
	handOffsetY = 28,
	handFrames = 2,
	handFrameSpeed = 16,
	handRoamDist = 12,
	handRoamInterval = 16,
	handRoamMinSpeed = 0.25,
	handRoamMaxSpeed = 2,

	-- Clones
	wizzerdClones = true,
	cloneSpawnChance = 0.0075,
	minClones = 1,
	maxClones = 4,

	-- Lunging

	canLunge = true,
	lungeChance = 0.01,
	preLungeSFX = 35,
	preLungeDuration = 80,
	deceleration = 0.05,
	lungeSpeed = 8,
	lungeSFX = Misc.resolveSoundFile("sound/character/ub_lunge.wav"),
	lungeDuration = 140,
}

wizzerds.idMap = {}

function wizzerds.register(npcID)
	npcManager.registerEvent(npcID, wizzerds, "onTickEndNPC")
	npcManager.registerEvent(npcID, wizzerds, "onDrawNPC")

	wizzerds.idMap[npcID] = true
end

function wizzerds.onInitAPI()
    	registerEvent(wizzerds, "onNPCHarm")
    	registerEvent(wizzerds, "onPostNPCKill")
end

local function spawnQuadPoofs(v)
	for i = 1, 4 do
		local e = Effect.spawn(10, v.x + v.width * 0.5, v.y + v.height * 0.5)
		e.speedX = ({-2, -2, 2, 2})[i]
		e.speedY = ({-3, 3, -3, 3})[i]
                e.x = e.x - e.width * 0.5
		e.y = e.y - e.height * 0.5
	end
end

local function isOnScreen(v)
    	for i,c in ipairs(Camera.get()) do
		if v.x >= c.x - v.width and v.x < c.x + c.width + v.width and v.y >= c.y - v.height and v.y < c.y + c.height + v.height then return true end
    	end

    	return false
end

local function killAllClones(data)
	if data.clones == nil then return end

        for k,n in ipairs(data.clones) do
		if n.isValid then 
			n:kill(3)
			
			if isOnScreen(n) then
				spawnQuadPoofs(n)
				SFX.play(41)
			end
		end
	end
end

function wizzerds.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.animTimer = 0
		data.mouthFrame = 0
		data.handFrame = 0

		data.mouthOffset = 0
		data.mouthOccupied = false
		data.mouthGoal = 0

		data.isShooting = false
		data.sineTimer = 0
		data.chaseDir = 1
		data.lungeTimer = 0
		data.range = Colliders:Circle()

		data.hp = config.health
		data.immunity = 0

		data.handOffsetGoals = {}
		data.handOffsets = {}
		data.handFrames = {}

		data.parent = data.parent or nil
		data.clones = {}

		for i = 1,8 do
			data.handOffsetGoals[i] = RNG.random(-config.handRoamDist, config.handRoamDist)
			data.handOffsets[i] = 0
		end

		for i = 1,4 do
			data.handFrames[i] = 0
		end
	end

	data.range.x = v.x + v.width * 0.5
	data.range.y = v.y + v.height * 0.5
	data.range.radius = config.chaseRadius

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		if v.isProjectile then
			npcutils.applyStationary(v)
		end
		return
	end

	data.immunity = math.max(data.immunity - 1, 0)

	-- Hand animation

	for i = 1,8 do
		if data.animTimer % config.handRoamInterval == 0 then
			data.handOffsetGoals[i] = RNG.random(-config.handRoamDist, config.handRoamDist)
		end

    		if data.handOffsets[i] > data.handOffsetGoals[i] then
        		data.handOffsets[i] = math.max(data.handOffsetGoals[i], data.handOffsets[i] - RNG.random(config.handRoamMinSpeed, config.handRoamMaxSpeed))
    		elseif data.handOffsets[i] < data.handOffsetGoals[i] then
        		data.handOffsets[i] = math.min(data.handOffsetGoals[i], data.handOffsets[i] + RNG.random(config.handRoamMinSpeed, config.handRoamMaxSpeed))
    		else
        		data.handOffsets[i] = data.handOffsetGoals[i]
    		end
	end

	-- Mouth stuff

	if data.mouthOccupied then
		data.mouthOffset = math.min(data.mouthOffset + config.mouthOpenSpeed, data.mouthGoal)

		if data.mouthOffset >= data.mouthGoal then 
			data.mouthOccupied = false 
			data.mouthGoal = 0

			if data.isShooting then
				data.isShooting = false

				local fire = NPC.spawn(config.fireID, v.x + v.width * 0.5, v.y + v.height * 0.5)
        			fire.x = fire.x - fire.width * 0.5
				fire.y = fire.y - fire.height * 0.5
				fire.speedX = config.fireSpeedX * v.direction
				fire.layerName = "Spawned NPCs"
				fire.friendly = v.friendly
				spawnQuadPoofs(fire)

				if config.fireSFX then
					SFX.play(config.fireSFX)
				end
			end
		end
	else
		data.mouthOffset = math.max(data.mouthOffset - config.mouthOpenSpeed, 0)

		if data.mouthOffset <= 0 then
			if RNG.random(0, 1) <= config.openMouthChance then
				data.mouthOccupied = true

				if (RNG.random(0, 1) <= config.mouthOpenShootChance) and not data.parent then
					data.mouthGoal = config.mouthOpenLengthShooting
					data.isShooting = true
				else
					data.mouthGoal = config.mouthOpenLength
				end
			end
		end
	end

	-- Clones

	if config.wizzerdClones and not data.parent and #data.clones <= 0 then
		if RNG.random(0, 1) <= config.cloneSpawnChance then
			for i = 1,RNG.random(config.minClones, config.maxClones) do
				local n = NPC.spawn(v.id, v.x + v.width * 0.5, v.y + v.height * 0.5)
        			n.x = n.x - n.width * 0.5
				n.y = n.y - n.height * 0.5
				n.speedX = RNG.random(-6, 6)
				n.speedY = RNG.random(-6, 6)
				n.layerName = "Spawned NPCs"
				n.dontMove = v.dontMove
				n.friendly = v.friendly

				if isOnScreen(n) then
					spawnQuadPoofs(n)
					SFX.play(41)
				end

				n.data.parent = v
				table.insert(data.clones, n)
			end
		end
	end

        for k,n in ipairs(data.clones) do
		if n.isValid then 
            		v.despawnTimer = math.max(v.despawnTimer, n.despawnTimer)
            		n.despawnTimer = v.despawnTimer
		else
			table.remove(data.clones, k)
		end
	end

	-- Movement

    	local p = npcutils.getNearestPlayer(v)
    	local d = -vector(v.x + (v.width * 0.5) - p.x + (p.width * 0.5), v.y + (v.height * 0.5) - p.y + (p.height * 0.5)):normalize() * config.chaseSpeed

	data.chaseDir = 1

	if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
		if Colliders.collide(data.range, p) and Misc.canCollideWith(v, p) then
			v.despawnTimer = 180
			data.chaseDir = -1
		end
	end

	if data.lungeTimer <= 0 then
    		v.speedX = v.speedX + (d.x * data.chaseDir)
    		v.speedY = v.speedY + (d.y * data.chaseDir)

    		v.speedX = math.clamp(v.speedX, -config.maxSpeed, config.maxSpeed)
    		v.speedY = math.clamp(v.speedY, -config.maxSpeed, config.maxSpeed)

		-- Sine movement

		data.w = data.w or (config.sineSpeed * math.pi / 65)
		data.sineTimer = data.sineTimer + 1

		v.y = v.y + (20 * config.sineStrength) * -data.w * math.cos(data.w * data.sineTimer)
		v.x = v.x + (10 * config.sineStrength) * -data.w * math.sin(data.w * data.sineTimer)
	end

	npcutils.faceNearestPlayer(v)

	-- Lunging

	if data.lungeTimer >= 1 then
		data.lungeTimer = data.lungeTimer + 1

		if data.lungeTimer >= config.preLungeDuration then
			if data.lungeTimer == config.preLungeDuration then
				data.pos = vector((Player.getNearest(v.x + v.width/2, v.y + v.height).x + Player.getNearest(v.x + v.width/2, v.y + v.height).width * 0.5) - (v.x + v.width * 0.5),
				(Player.getNearest(v.x + v.width/2, v.y + v.height).y + Player.getNearest(v.x + v.width/2, v.y + v.height).height * 0.5) - (v.y + v.height * 0.5)):normalize()
				v.speedX = data.pos.x * config.lungeSpeed
				v.speedY = data.pos.y * config.lungeSpeed

        			Effect.spawn(71, v.x + v.width * 0.5, v.y + v.height * 0.5)

				if config.lungeSFX then
					SFX.play(config.lungeSFX)
				end
			end

			if isOnScreen(v) then
				if RNG.random(0, 1) <= 0.75 then
        				local e = Effect.spawn(74, v.x + RNG.randomInt(0, v.width), v.y + RNG.randomInt(0, v.height))
        				e.x = e.x - e.width * 0.5
        				e.y = e.y - e.height * 0.5
					e.speedX = -v.speedX * 0.5
					e.speedY = -v.speedY
				end

				if data.lungeTimer % (config.lungeSpeed * 2) == 0 then
					spawnQuadPoofs(v)
				end
			end
			
			if data.lungeTimer >= config.lungeDuration then
				data.lungeTimer = 0
			end
		else
                	if v.speedX > 0 then
                        	v.speedX = math.max(0, v.speedX - config.deceleration)
                	elseif v.speedX < 0 then
                        	v.speedX = math.min(0, v.speedX + config.deceleration)
                	else
                        	v.speedX = 0
                	end
                	if v.speedY > 0 then
                        	v.speedY = math.max(0, v.speedY - config.deceleration)
                	elseif v.speedY < 0 then
                        	v.speedY = math.min(0, v.speedY + config.deceleration)
                	else
                        	v.speedY = 0
                	end

	        	if data.lungeTimer % 4 > 0 and data.lungeTimer % 4 < 3 then
		    		v.x = v.x + 2
	        	else
		    		v.x = v.x - 2
	        	end

	        	if data.lungeTimer % 8 > 0 and data.lungeTimer % 8 < 5 then
		    		v.y = v.y + 1
	        	else
		    		v.y = v.y - 1
	        	end
		end
	else
		if config.canLunge and RNG.random(0, 1) <= config.lungeChance and not data.parent then
			spawnQuadPoofs(v)
			data.lungeTimer = 1
		
			if config.preLungeSFX then
				SFX.play(config.preLungeSFX)
			end
		end
	end

	-- Animation

	data.animTimer = data.animTimer + 1

	v.animationFrame = math.floor(data.animTimer / config.framespeed) % config.headFrames
	v.animationFrame = npcutils.getFrameByFramestyle(v)

	data.mouthFrame = math.floor(data.animTimer / config.framespeed) % config.mouthFrames + config.headFrames
	data.mouthFrame = npcutils.getFrameByFramestyle(v, {frame = data.mouthFrame})

	for i = 1,4 do
		if data.animTimer % config.handFrameSpeed == 0 then
			data.handFrames[i] = RNG.randomInt(0, (config.handFrames - 1))
		end

		data.handFrames[i] = npcutils.getFrameByFramestyle(v, {frame = data.handFrames[i], frames = config.handFrames})
	end
end

function wizzerds.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	-- Colliders.getHitbox(v):draw()

	local img = Graphics.sprites.npc[v.id].img
	local lowPriorityStates = table.map{1,3,4}
        local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	local frame = {v.animationFrame, data.mouthFrame}
	local pivots = {vector(0.5, 1), vector(0.5, 0)}
	local prioffsets = {0.01, 0}
	local dir = {-1, 1}
	
	for j = 1,2 do
		data.sprite = {}

    		if data.sprite[j] == nil then
        		data.sprite[j] = Sprite{texture = img, frames = npcutils.getTotalFramesByFramestyle(v), pivot = pivots[j]}
    		end

    		data.sprite[j].x = v.x + (v.width / 2) + config.gfxoffsetx 
    		data.sprite[j].y = v.y + (v.height / 2) + (-config.closedOffset * dir[j]) + (data.mouthOffset * dir[j]) + config.gfxoffsety

    		data.sprite[j]:draw{frame = frame[j] + 1, priority = priority + prioffsets[j], sceneCoords = true}
	end

	local handOffsetsX = {-config.handOffsetX, -config.handOffsetX, config.handOffsetX, config.handOffsetX}
	local handOffsetsY = {-config.handOffsetY, config.handOffsetY, config.handOffsetY, -config.handOffsetY}

	if config.handIMG then
		for j = 1,4 do
			data.sprite2 = {}

    			if data.sprite2[j] == nil then
        			data.sprite2[j] = Sprite{texture = config.handIMG, frames = npcutils.getTotalFramesByFramestyle(v, {frames = config.handFrames}), pivot = vector(0.5, 0.5)}
    			end

    			data.sprite2[j].x = v.x + (v.width / 2) + handOffsetsX[j] + data.handOffsets[j] + config.gfxoffsetx 
    			data.sprite2[j].y = v.y + (v.height / 2) + handOffsetsY[j] + data.handOffsets[j+4] + config.gfxoffsety

    			data.sprite2[j]:draw{frame = data.handFrames[j] + 1, priority = (priority - 0.01), sceneCoords = true}

			-- Text.print(data.handFrames[j], (24 * v.idx), (16 * j - 1))
		end
	end

	npcutils.hideNPC(v)
end

local invalidHarmTypes = table.map{HARM_TYPE_LAVA, HARM_TYPE_OFFSCREEN}

function wizzerds.onNPCHarm(eventObj, v, reason, culprit)
	if not wizzerds.idMap[v.id] then return end

	local data = v.data
	local config = NPC.config[v.id]

	if table.contains(config.vulnerableharmtypes, reason) and not invalidHarmTypes[reason] and not data.parent then
		if data.immunity > 0 then
			eventObj.cancelled = true
			return
		end

		if data.hp > 1 then
			eventObj.cancelled = true
			killAllClones(data)
			data.hp = data.hp - 1
			data.immunity = 25
			SFX.play(9)
			Effect.spawn(75, v)
		end
	end
end

function wizzerds.onPostNPCKill(v, r)
	if not wizzerds.idMap[v.id] then return end

	local data = v.data
	local config = NPC.config[v.id]

	killAllClones(data)

	if invalidHarmTypes[reason] then return end

	if not data.parent then
		Misc.givePoints(config.finalScore, vector(v.x + (v.width / 2), v.y), true)
	end

	if not isOnScreen(v) then return end

	spawnQuadPoofs(v)
	Effect.spawn(config.disappearEffect, v.x + v.width*0.5, v.y + v.height*0.5)

	if config.disappearSound then
		SFX.play(config.disappearSound)
	end
end

return wizzerds