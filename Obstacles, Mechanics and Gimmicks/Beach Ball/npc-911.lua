local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local beachBall = {}
local npcID = NPC_ID

local beachBallSettings = {
	id = npcID,

	-- Main stuff

	gfxwidth = 64,
	gfxheight = 64,
	width = 40,
	height = 64,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 1,
	framestyle = 0,
	framespeed = 8,

	-- The more obsure settings

	luahandlesspeed = true, 
	nowaterphysics = true,

	npcblock = false, 
	npcblocktop = true, 
	playerblock = false, 
	playerblocktop = true, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 
	staticdirection = true,

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,
	score = 0,
	weight = 2,

	-- Custom properties

	rotSpeed = 3,
	minFxSpeed = 3,

	bounceLimit = 1,
	bounceLossMod = 0.7,

	pushAccel = 0.05,
	slopeAccel = 0.025,
	decel = 0.025,
	turnAroundSpeed = 0.5,

	maxSpeed = 4,
	maxSpeedWater = 2.5,

	maxFloatSpeed = 1,
	floatAccel = 0.35,
}

npcManager.setNpcSettings(beachBallSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_LAVA, }, {[HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}, });
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

function beachBall.onInitAPI()
	npcManager.registerEvent(npcID, beachBall, "onTickEndNPC")
	npcManager.registerEvent(npcID, beachBall, "onDrawNPC")

	-- This is here so that stuff like beach koopas and outmaways will kick the ball
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
			if p.standingNPC == v then
				return math.sign(p.x + p.width/2 - v.x - v.width/2)
			end
		end
	end

	return false
end

function beachBall.onTickEndNPC(v)
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
		SFX.play(3)

                local e = Effect.spawn(75, v.x + v.width * 0.5, v.y + v.height)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
	end

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then 
		if v.isProjectile then npcutils.applyStationary(v) end
		return 
	end

	-- Physics

	if v.collidesBlockBottom and data.oldSpeedY then
        	if data.oldSpeedY > config.bounceLimit then
        		v.speedY = -data.oldSpeedY * config.bounceLossMod
		end
	end

	data.oldSpeedY = v.speedY

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
		v.speedX = -(v.speedX * config.turnAroundSpeed)
	end

	v.speedX = math.clamp(v.speedX, -config.maxSpeed, config.maxSpeed)
	v:mem(0x120, FIELD_BOOL, false)

	-- Water physics

        if v.underwater then
        	v.speedY = v.speedY - config.floatAccel

		v.speedX = math.clamp(v.speedX, -config.maxSpeedWater, config.maxSpeedWater)
		v.speedY = math.clamp(v.speedY, -config.maxFloatSpeed, config.maxFloatSpeed)

                if v.speedX > 0 then
                        v.speedX = math.max(0, v.speedX - config.decel)
                elseif v.speedX < 0 then
                        v.speedX = math.min(0, v.speedX + config.decel)
                else
                        v.speedX = 0
                end
	end

	-- VFX

	if math.abs(v.speedX) >= config.minFxSpeed and v.collidesBlockBottom then
		if RNG.randomInt(1, 3) == 1 then
                        local e = Effect.spawn(74, v.x + v.width * 0.5, v.y + v.height)
                        e.x = e.x - e.width * 0.5
			e.x = e.x + ((v.width * 0.5) * math.sign(v.speedX))
                        e.y = e.y - e.height * 0.5
		end
	end
end

function beachBall.onDrawNPC(v)
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

return beachBall