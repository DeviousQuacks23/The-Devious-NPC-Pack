--[[

	Originally written by Emral, for the Conquest

]]

-- NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local easing = require("ext/easing")

-- Fancy trails
local afterimages
pcall(function() afterimages = require("afterimages") end)

-- Create the library table
local angrySun = {}

-- Applies NPC settings
angrySun.sharedSettings = ({
	gfxheight = 64,
	gfxwidth = 64,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 16,
	frames = 8,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	staticdirection = true,
	luahandlesspeed = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	ignorethrownnpcs = false,
	durability = -1,

	-- Custom settings

	angryFrames = 4,
	angryWhileSpinning = true,

	disableBuiltInAnimation = false,

	spawnSparkles = false,
	afterimageTrails = true,
	afterimageColour = Color.orange,

	horizontalDistance = 48,
	verticalDistance = 32,
	invertedMovement = false,

	accelerationRate = 1,
	movementSpeed = 1,
	loopLaps = 3,
	swoopDistance = 0.75,
	swoopDelay = 140,
	stallDelay = 0,

	projectileNPC = 706,

	preSwoopSFX = Misc.resolveFile("angry-sun.ogg"),
	swoopSFX = Misc.resolveFile("angry-sun-swoop.ogg"),

	killNPCs = true,
	moonFunction = nil,
})

-- Register events
function angrySun.register(npcID, registerHarmTypes, effectID)
	npcManager.registerEvent(npcID, angrySun, "onTickEndNPC")
	if registerHarmTypes then
		npcManager.registerHarmTypes(npcID,
			{
				HARM_TYPE_NPC,
				HARM_TYPE_PROJECTILE_USED,
				HARM_TYPE_HELD,
			}, 
			{
				[HARM_TYPE_NPC]=effectID,
				[HARM_TYPE_PROJECTILE_USED]=effectID,
				[HARM_TYPE_HELD]=effectID,
			}
		);
	end
end

function angrySun.onTickEndNPC(v)
	-- Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	
	-- If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	-- Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    -- Grabbed
	or v:mem(0x136, FIELD_BOOL)        -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0    -- Contained within
	then
		data.initialized = false
		return
	end

	-- Initialize
	if not data.initialized then
		data.animTimer = 0
		data.timer = 0
		data.state = 0
		data.lerp = 0
		data.initialized = true
		data.lerpStartPos = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
		data.lerpGoalPos = vector(0, 0)
		data.lerpDuration = 100
		data.camIdx = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height).idx
		data.loopLaps = 0
		data.isStalling = false
	end

	local cam = Camera.get()[data.camIdx]
	if cam == nil then
		cam = camera
	end

	local camSpeed = vector.zero2

	if data.lastCamPos == nil then
		data.lastCamPos = vector(cam.x + 0.5 * cam.width, cam.y + 0.5 * cam.height)
	else
		camSpeed = vector(cam.x + 0.5 * cam.width - data.lastCamPos.x, cam.y + 0.5 * cam.height - data.lastCamPos.y)
		data.lastCamPos = vector(cam.x + 0.5 * cam.width, cam.y + 0.5 * cam.height)
	end

	if data.state == 0 then -- First spawned in
		data.lerpGoalPos = vector(cam.x + 0.5 * cam.width + 0.4 * cam.width * v.direction, cam.y + cam.height * 0.5 - 0.4 * cam.height)
		data.state = -1
	elseif data.state == -1 then -- Go to the corner of the screen
		data.lerpStartPos = data.lerpStartPos + camSpeed
		data.lerpGoalPos = data.lerpGoalPos + camSpeed
		data.lerp = data.lerp + 1
		v.x = data.lerpStartPos.x + (data.lerpGoalPos.x - data.lerpStartPos.x) * easing.inOutQuad(data.lerp * (0.01 * cfg.accelerationRate), 0, 1, 1) - 0.5 * v.width
		v.y = data.lerpStartPos.y + (data.lerpGoalPos.y - data.lerpStartPos.y) * easing.inOutQuad(data.lerp * (0.01 * cfg.accelerationRate), 0, 1, 1) - 0.5 * v.height

		if data.lerp >= (100 / cfg.accelerationRate) then
			data.lerp = 0
			data.state = 1
			v.direction = -v.direction
			data.timer = 0
		end
	elseif data.state == 1 then -- Rest in the corner of the screen
		v.x = v.x + camSpeed.x
		v.y = v.y + camSpeed.y
		if (v.x + 0.5 * v.width ~= cam.x + 0.5 * cam.width - 0.4 * cam.width * v.direction) then
			v.x = math.lerp(v.x + 0.5 * v.width, cam.x + 0.5 * cam.width - 0.4 * cam.width * v.direction, data.timer/140) - v.width * 0.5
		end
		if v.y + 0.5 * v.height ~= cam.y + cam.height * 0.5 - 0.4 * cam.height then
			v.y = math.lerp(v.y + 0.5 * v.height, cam.y + cam.height * 0.5 - 0.4 * cam.height, data.timer/140) - v.height * 0.5
		end
		data.timer = data.timer + 1
		if data.isStalling then
			data.lerpStartPos = data.lerpStartPos + camSpeed
			data.lerpGoalPos = data.lerpGoalPos + camSpeed
			if data.timer >= cfg.stallDelay then
				if cfg.swoopSFX then SFX.play(cfg.swoopSFX) end
				data.isStalling = false
				data.state = 3
				if cfg.projectileNPC and cfg.projectileNPC > 0 then -- Spawn projectiles, like in NewerSMBW
					SFX.play(18)
					local n = NPC.spawn(cfg.projectileNPC, v.x + v.width * 0.5, v.y + v.height * 0.5, v.section, false)
                       			n.x = n.x - n.width * 0.5
                        		n.y = n.y - n.height * 0.5
					n.speedX = 3.5 * v.direction
					n.speedY = 1.5
					n.friendly = v.friendly
					n.layerName = "Spawned NPCs"
					local n = NPC.spawn(cfg.projectileNPC, v.x + v.width * 0.5, v.y + v.height * 0.5, v.section, false)
                       			n.x = n.x - n.width * 0.5
                        		n.y = n.y - n.height * 0.5
					n.speedX = 4 * v.direction
					n.speedY = 3
					n.friendly = v.friendly
					n.layerName = "Spawned NPCs"
					local n = NPC.spawn(cfg.projectileNPC, v.x + v.width * 0.5, v.y + v.height * 0.5, v.section, false)
                       			n.x = n.x - n.width * 0.5
                        		n.y = n.y - n.height * 0.5
					n.speedX = 3.5 * v.direction
					n.speedY = 4.5
					n.friendly = v.friendly
					n.layerName = "Spawned NPCs"
				end
			end
		else
			if data.timer >= cfg.swoopDelay then
				data.timer = 0
				data.state = 2
				if cfg.preSwoopSFX then SFX.play(cfg.preSwoopSFX) end
				data.lerpStartPos = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
				data.lerpGoalPos = vector(cam.x + 0.5 * cam.width + 0.4 * cam.width * v.direction, cam.y + cam.height * cfg.swoopDistance)
			end
		end
	elseif data.state == 2 then -- Preparing to swoop down
		data.lerpStartPos = data.lerpStartPos + camSpeed
		data.lerpGoalPos = data.lerpGoalPos + camSpeed
		if (data.lerpStartPos.x ~= cam.x + 0.5 * cam.width - 0.4 * cam.width * v.direction) then
			data.lerpStartPos.x = math.lerp(data.lerpStartPos.x, cam.x + 0.5 * cam.width - 0.4 * cam.width * v.direction, data.timer/140)
		end
		if data.lerpStartPos.y ~= cam.y + cam.height * 0.5 - 0.4 * cam.height then
			v.y = math.lerp(data.lerpStartPos.y, cam.y + cam.height * 0.5 - 0.4 * cam.height, data.timer/140)
		end
		data.timer = data.timer + 1
		v.x = data.lerpStartPos.x + (cfg.horizontalDistance - math.cos(math.rad(data.timer * (6 * cfg.movementSpeed) * v.direction)) * cfg.horizontalDistance) * v.direction - 0.5 * v.width
		if cfg.invertedMovement then
			v.y = data.lerpStartPos.y + math.sin(math.rad(data.timer * (6 * cfg.movementSpeed))) * cfg.verticalDistance - 0.5 * v.height
		else
			v.y = data.lerpStartPos.y + -math.sin(math.rad(data.timer * (6 * cfg.movementSpeed))) * cfg.verticalDistance - 0.5 * v.height
		end
		if v.x + 0.5 * v.width == data.lerpStartPos.x then
			data.loopLaps = data.loopLaps + 1
			if data.loopLaps >= cfg.loopLaps then
				data.isStalling = true
				data.timer = 0
				data.loopLaps = 0
				data.state = 1
			end
		end
	elseif data.state == 3 then -- Swoop down
		if afterimages and cfg.afterimageTrails then afterimages.create(v, 24, cfg.afterimageColour, true, -49) end
		data.lerpStartPos = data.lerpStartPos + camSpeed
		data.lerpGoalPos = data.lerpGoalPos + camSpeed
		data.lerp = data.lerp + 0.75
		v.x = data.lerpStartPos.x + (data.lerpGoalPos.x - data.lerpStartPos.x) * easing.inOutQuad(data.lerp * 0.01, 0, 1, 1) - 0.5 * v.width
		if data.lerp <= 50 then
			v.y = data.lerpStartPos.y + (data.lerpGoalPos.y - data.lerpStartPos.y) * easing.outQuad(data.lerp * 0.02, 0, 1, 1) - 0.5 * v.height
			if data.lerp + 0.75 >= 50 then
				data.lerpStartPos.y = data.lerpGoalPos.y
				data.lerpGoalPos.y = cam.y + cam.height * 0.5 - 0.4 * cam.height
			end
		else
			v.y = data.lerpStartPos.y + (data.lerpGoalPos.y - data.lerpStartPos.y) * easing.inQuad((data.lerp-50) * 0.02, 0, 1, 1) - 0.5 * v.height
		end

		if data.lerp >= 100 then
			data.lerp = 0
			data.state = 1
			v.direction = -v.direction
			data.timer = 0
		end
	end

	if cfg.spawnSparkles then
                if RNG.randomInt(1, 15) == 1 then
                        local e = Effect.spawn(80, v.x + RNG.randomInt(0, v.width), v.y + RNG.randomInt(0, v.height))
                        e.speedX = RNG.random(-2, 2)
                        e.speedY = RNG.random(-2, 2)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
                end
	end

	if v.killFlag == 0 and cfg.killNPCs and not v.friendly then
		for k,v in ipairs(Colliders.getColliding{a = v, b = NPC.HITTABLE, btype = Colliders.NPC, filter = function(other)
			if other.isHidden or other.despawnTimer <= 0 or other.forcedState > 0 then
				return false
			end
			return true
		end}) do
			v:harm(3)
		end
	end

	if cfg.moonFunction ~= nil then
		for _,p in ipairs(Player.get()) do
			if p.forcedState == 0 and p.deathTimer == 0 and Colliders.collide(v, p) and Misc.canCollideWith(v, p) then
				cfg.moonFunction(v, p, data, cfg)
			end
		end
	end

	v.despawnTimer = 180

	-- Animation

	if cfg.disableBuiltInAnimation then return end

	data.animTimer = data.animTimer + 1

	local f = math.floor(data.animTimer/cfg.framespeed) % (cfg.frames - cfg.angryFrames)
	if (data.state == 2 and cfg.angryWhileSpinning) or data.state == 3 then
		f = (cfg.frames - cfg.angryFrames) + math.floor(data.animTimer/cfg.framespeed) % cfg.angryFrames
	end

	if cfg.framestyle > 0 and v.direction == 1 then
		f = f + cfg.frames
	end

	v.animationTimer = 2
	v.animationFrame = f
end

-- Gotta return the library table!
return angrySun