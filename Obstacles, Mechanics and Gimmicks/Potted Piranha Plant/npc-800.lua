local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local spline = require("spline")
local easing = require("ext/easing")

local pottedPiranhaPlant = {}

local npcID = NPC_ID
local deathEffectID = npcID

local pottedPiranhaPlantSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 6,
	framestyle = 0,
	framespeed = 12, 

	luahandlesspeed = true, 
	nowaterphysics = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= true, 

	score = 3, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = false,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = true,
	grabtop = false,
	isstationary = true,

	-- Custom properties

        visionlength = 200,
        visionwidth = 80,

	potFrames = 1,
	potFramespeed = 8,
	mouthSleepFrames = 1,
	mouthActiveFrames = 2,
	mouthLungeFrames = 1,
	mouthRetractFrames = 1,

	mouthOffsetY = 32,
	mouthWidth = 32,
	mouthHeight = 32,

	lungeSpeed = 0.2,
	retractSpeed = 0.15,
	targetOffset = 8,

	killOneAtATime = true,
	stallTime = 15,

	lungeSound = Misc.resolveSoundFile("pottedLunge"),
	biteSound = Misc.resolveSoundFile("pottedBite"),

	stemWidth = 2,
	outlineWidth = 4,
	stemIntensity = 10,
	stemColour = Color.fromHexRGB(0x68B020),
	outlineColour = Color.fromHexRGB(0x282828),

	doCulling = true,

	-- Rapid fire settings. Have fun.
	-- lungeSpeed = 1,
	-- retractSpeed = 1,
	-- killOneAtATime = false,
	-- stallTime = 0,
}

npcManager.setNpcSettings(pottedPiranhaPlantSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SWORD]           = 10,
	}
);

function pottedPiranhaPlant.onInitAPI()
	npcManager.registerEvent(npcID, pottedPiranhaPlant, "onTickNPC")
	npcManager.registerEvent(npcID, pottedPiranhaPlant, "onDrawNPC")
end

local function retractBack(v, data, config)
	data.lerp = math.max(data.lerp - config.retractSpeed, 0)
	data.mouthLocation.x = easing.inCirc(data.lerp, data.startLocation.x, data.targetLocation.x - data.startLocation.x, 1)
	data.mouthLocation.y = easing.inCirc(data.lerp, data.startLocation.y, data.targetLocation.y - data.startLocation.y, 1)
	data.rotation = easing.inCirc(data.lerp, 0, data.goalRotation, 1)
	if data.stallTimer ~= 0 then data.stallTimer = 0 end
end

local function init(v, data, config)
	if not data.initialized then
		data.initialized = true

		data.animTimer = 0
		data.lunging = false
		data.lerp = 0
		data.mouthFrame = 0
		data.rotation = 0
		data.goalRotation = 0
		data.startLocation = vector(v.x + (v.width * 0.5), (v.y - config.mouthOffsetY))
		data.mouthLocation = data.startLocation
		data.lastMouthLocation = nil
		data.speed = vector(0, 0)
		data.targetLocation = vector(0, 0)
		data.stallTimer = 0

                if data.visionCollider == nil then
                	data.visionCollider = {
                        	[-1] = Colliders.Tri(0, 0, {0, 0}, {-config.visionlength, -config.visionwidth}, {-config.visionlength, config.visionwidth}),
                        	[1] = Colliders.Tri(0, 0, {0, 0}, {config.visionlength, -config.visionwidth}, {config.visionlength, config.visionwidth}),
                	}
                end
	end
end

-- Based off code from DRACalgar Law's Fire Koopa Clown Tank
local function seekTargets(v, data, config)
    	local potentialTargetList = {}

        for _,w in ipairs(Colliders.getColliding{a = data.visionCollider[v.direction], atype = Colliders.NPC, b = NPC.HITTABLE}) do
            	if w.idx ~= v.idx and not w.isGenerator and w.isValid and not w.isHidden and w.despawnTimer > 0 and not w.friendly and (not NPC.config[w.id].nohurt or w.id == npcID) and Misc.canCollideWith(v, w) then
			table.insert(potentialTargetList, w)
		end
        end

    	local closestTarget = nil
    	local closestDistance = math.huge

    	for _, target in ipairs(potentialTargetList) do
        	local distance = math.sqrt(((target.x + target.width / 2) - (v.x + v.width / 2 * v.direction))^2 + ((target.y + target.height / 2) - (v.y + v.height / 2))^2)
        	if distance < closestDistance then
            		closestDistance = distance
            		closestTarget = target
        	end
    	end

    	return closestTarget
end

function pottedPiranhaPlant.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	init(v, data, config)

	-- Stuff that is changed every tick

	data.startLocation = vector(v.x + (v.width * 0.5), (v.y - config.mouthOffsetY))
        data.visionCollider[v.direction].x = v.x + (v.width * 0.5)
	data.visionCollider[v.direction].y = v.y + 0.5 * v.height

	if data.lastMouthLocation and data.stallTimer <= 0 then
		data.speed.x = data.mouthLocation.x - data.lastMouthLocation.x
		data.speed.y = data.mouthLocation.y - data.lastMouthLocation.y
	end

	data.lastMouthLocation = vector(data.mouthLocation.x, data.mouthLocation.y)
	data.animTimer = data.animTimer + 1

	if v.isProjectile or v.forcedState > 0 then retractBack(v, data, config) return end
	
	-- Actual stuff starts here

	if data.lunging then
		data.lerp = math.min(data.lerp + config.lungeSpeed, 1)
		data.mouthLocation.x = easing.inQuart(data.lerp, data.startLocation.x, data.targetLocation.x - data.startLocation.x, 1)
		data.mouthLocation.y = easing.inQuart(data.lerp, data.startLocation.y, data.targetLocation.y - data.startLocation.y, 1)
		data.rotation = easing.inQuart(data.lerp, 0, data.goalRotation, 1)

		if data.lerp >= 1 then
			if data.stallTimer == 0 then
				if config.biteSound then
					SFX.play(config.biteSound)
				end

				local e = Effect.spawn(132, data.mouthLocation.x, data.mouthLocation.y)
                        	e.x = e.x - e.width * 0.5
                       		e.y = e.y - e.height * 0.5

        			for k,n in ipairs(NPC.getIntersecting(data.mouthLocation.x, data.mouthLocation.y, data.mouthLocation.x + config.mouthWidth, data.mouthLocation.y + config.mouthHeight)) do
                        		if n.idx ~= v.idx and not n.isGenerator and n.isValid and not n.isHidden and n.despawnTimer > 0 and not n.friendly 
					and (not NPC.config[n.id].nohurt or n.id == npcID) and NPC.HITTABLE_MAP[n.id] and Misc.canCollideWith(v, n) then
                                		n:harm(3)
						if config.killOneAtATime then
							break
						end
					end
                        	end
			end

			data.stallTimer = data.stallTimer + 1

			if data.stallTimer >= config.stallTime then
				data.stallTimer = 0
				data.lunging = false
			end
		end
	else
		retractBack(v, data, config)
	end

	local w = seekTargets(v, data, config)

	if v.heldIndex ~= 0 then 
		if not data.lunging and data.lerp <= 0 then
			if w then
				data.targetLocation = vector((w.x + w.width * 0.5) + RNG.randomInt(-config.targetOffset, config.targetOffset), (w.y + w.height * 0.5) + RNG.randomInt(-config.targetOffset, config.targetOffset))

				data.vector = vector(w.x - v.x + (w.width - v.width) * 0.5, w.y - v.y + (w.height - v.height) * 0.5):normalize()
				data.goalRotation = math.deg(math.atan2(data.vector.y * v.direction, data.vector.x * v.direction)) + (90 * v.direction)

				data.lunging = true
	
				if config.lungeSound then
					SFX.play(config.lungeSound)
				end
            		end
        	end
	else
		if data.lunging then data.lunging = false end

		-- ZZZZZZZZZ...
		if data.animTimer % 60 == 0 then
			Effect.spawn(190, data.mouthLocation.x, data.mouthLocation.y + (config.mouthHeight * 0.5))
		end

		-- Make the pot bouncy
		if v.collidesBlockBottom and data.oldSpeedY then
        		if data.oldSpeedY > 1 then
        			v.speedY = -data.oldSpeedY * 0.5
			end
		end

		data.oldSpeedY = v.speedY
	end
end

-- Draw spline function
-- Taken from Emral's Momentum Teleporters
local function drawSplineCustom(spline, steps, halfwidth, priority, colour)
    	steps = steps or 50
    	local ps = {}
    	local idx = 1
    	local ds = 1/steps
    	local s = 0
    	local dir = spline.startTan
    	local pold = spline:evaluate(0)
    	local tx = {}
    	for i = 0,steps do
        	local p = spline:evaluate(s)
        	s = s+ds
        	local texCoord = 0.5
        	if i == 0 then
            		texCoord = 0
        	elseif i == steps then
            		texCoord = 1
        	end

        	local normal = vector(dir.x, dir.y):rotate(-90):normalize() * halfwidth
        
        	ps[idx] = p[1] + normal.x
        	ps[idx+1] = p[2] + normal.y
        	ps[idx+2] = p[1] - normal.x
        	ps[idx+3] = p[2] - normal.y
        	tx[idx] = texCoord
        	tx[idx+1] = 0
        	tx[idx+2] = texCoord
        	tx[idx+3] = 1

        	if i < steps then
            		dir = spline:evaluate(s+ds) - p
        	end
        
        	idx = idx+4
    	end
		
    	Graphics.glDraw{
        	vertexCoords = ps,
        	textureCoords = tx,
        	primitive = Graphics.GL_TRIANGLE_STRIP,
        	priority = priority,
        	sceneCoords = true,
        	color = colour
    	}
end

-- All these functions are taken from S.Koopa0's Gamboos
local function isOnScreen(v)
    	for i,c in ipairs(Camera.get()) do
		if v.x >= c.x - v.width and v.x < c.x + c.width + v.width and v.y >= c.y - v.height and v.y < c.y + c.height + v.height then return true end
    	end
    	return false
end

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

function pottedPiranhaPlant.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data
        local config = NPC.config[v.id]
	local img = Graphics.sprites.npc[v.id].img
        local priority = getRenderPriority(v)

	init(v, data, config)

	-- Animation

	v.animationFrame = math.floor(data.animTimer / config.potFramespeed) % config.potFrames
	v.animationFrame = npcutils.getFrameByFramestyle(v)

	if data.lunging then
		if data.stallTimer > 0 then
			data.mouthFrame = math.floor(data.animTimer / config.framespeed) % config.mouthRetractFrames + (config.potFrames + config.mouthSleepFrames + config.mouthActiveFrames + config.mouthLungeFrames)
		else
			data.mouthFrame = math.floor(data.animTimer / config.framespeed) % config.mouthLungeFrames + (config.potFrames + config.mouthSleepFrames + config.mouthActiveFrames)
		end
	else
		if data.lerp > 0 then
			data.mouthFrame = math.floor(data.animTimer / config.framespeed) % config.mouthRetractFrames + (config.potFrames + config.mouthSleepFrames + config.mouthActiveFrames + config.mouthLungeFrames)
		elseif v.heldIndex ~= 0 then
			data.mouthFrame = math.floor(data.animTimer / config.framespeed) % config.mouthActiveFrames + (config.potFrames + config.mouthSleepFrames)
		else
			data.mouthFrame = math.floor(data.animTimer / config.framespeed) % config.mouthSleepFrames + config.potFrames
		end
	end
	data.mouthFrame = npcutils.getFrameByFramestyle(v, {frame = data.mouthFrame})

	-- Culling

	if config.doCulling and not isOnScreen(v) then return end

	-- Draw the mouth

    	if data.sprite == nil then
        	data.sprite = Sprite{texture = img, frames = npcutils.getTotalFramesByFramestyle(v), pivot = Sprite.align.CENTRE}
    	end

    	data.sprite.x = (data.mouthLocation.x + config.gfxoffsetx)
    	data.sprite.y = (data.mouthLocation.y + config.gfxheight + config.gfxoffsety) - (data.lerp * config.mouthHeight)
	data.sprite.rotation = data.rotation

    	data.sprite:draw{frame = data.mouthFrame + 1, priority = priority + 0.01, sceneCoords = true}

	-- Draw the stem

	local spline = spline.segment{
		start = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height),
                stop = vector(data.mouthLocation.x, data.mouthLocation.y + math.lerp(config.mouthHeight, 0, data.lerp)),
                startTan = vector.zero2,
                stopTan = data.speed * config.stemIntensity,
        }

        drawSplineCustom(spline, nil, config.stemWidth, priority + 0.0075, config.stemColour)
        drawSplineCustom(spline, nil, config.outlineWidth, priority + 0.005, config.outlineColour)
end

return pottedPiranhaPlant