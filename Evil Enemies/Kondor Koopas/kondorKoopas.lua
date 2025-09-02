local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local kondorKoopa = {}

kondorKoopa.sharedSettings = {
	gfxwidth = 48,
	gfxheight = 48,
	width = 32,
	height = 16,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 2,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= false, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

        -- Custom Settings

	speed = 1.4,
	turnOnCliffs = true,

	detectionJumpHeight = -4,
        visionLength = 180,
        visionWidth = 80,

	acceleration = 0.1,
	decelleeration = 0.2, -- Devious sucks at spelling
	maxSprintSpeed = 8,
	sprintDuration = 3,

	lowGravity = false,
	lowGravityAccelerationRate = 0.075,

	mimicJumps = false,
	jumpHeight = -6,
	jumpRadius = 180
}

function kondorKoopa.register(npcID)
	npcManager.registerEvent(npcID, kondorKoopa, "onTickEndNPC")
end

local NORMAL = 0
local ALERT = 1
local RUN = 2

local function solidFilter(v,solid)
    local solidType = type(solid)

    if solidType == "Block" then
        local solidConfig = Block.config[solid.id]

        if solid.isHidden or solid:mem(0x5A,FIELD_BOOL) then
            return false
        end

        if solidConfig.passthrough then
            return false
        end

        -- NPC filter
        if solidConfig.npcfilter < 0 or solidConfig.npcfilter == v.id then
            return false
        end

        return true
    elseif solidType == "NPC" then
        local solidConfig = NPC.config[solid.id]

        if solid.despawnTimer <= 0 or solid.isGenerator or solid.friendly or solid:mem(0x12C,FIELD_WORD) > 0 then
            return
        end

        if solidConfig.npcblock or solidConfig.playerblocktop then -- why do NPC's also use playerblocktop
            return true
        end

        return false
    end
end

local function shouldCliffturn(v,data,config)
    -- Making good cliffturning is surprisingly difficult
    if not v.collidesBlockBottom then
        return false
    end

    local width = v.width * 0.8
    local height = 24

    local x
    local y = v.y + v.height + 2

    if v.direction == DIR_LEFT then
        x = v.x + v.width*0.75 - width
    else
        x = v.x + v.width*0.25
    end


    --Colliders.Box(x,y,width,height):Draw(Color.purple.. 0.5)


    for _,block in Block.iterateIntersecting(x,y,x + width,y + height + 128) do
        if solidFilter(v,block) then
            local extraHeight = 0
            if Block.SLOPE_LR_FLOOR_MAP[block.id] or Block.SLOPE_RL_FLOOR_MAP[block.id] then
                extraHeight = (block.height / block.width) * 16
            end

            if (y + height + extraHeight) > block.y then
                --Colliders.getHitbox(block):Draw()
                return false
            end
        end
    end

    for _,npc in NPC.iterateIntersecting(x,y,x + width,y + height) do
        if solidFilter(v,npc) then
            return false
        end
    end

    return true
end

function kondorKoopa.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.state = NORMAL
		data.speed = 0
                data.timer = 0
		data.hasReachedMachSpeed = false
                data.animTimer = 0
		data.range = Colliders:Circle()
                data.visionCollider = {
                        [-1] = Colliders.Tri(0, 0, {0, 0}, {-config.visionLength, -config.visionWidth},{-config.visionLength, config.visionWidth}),
                        [1] = Colliders.Tri(0, 0, {0, 0}, {config.visionLength, -config.visionWidth},{config.visionLength, config.visionWidth}),
                }
	end

        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height

	data.range.x = v.x+v.width*0.5
	data.range.y = v.y+v.height*0.5
	data.range.radius = config.jumpRadius

	if v.heldIndex ~= 0 
	or v.isProjectile  
	or v.forcedState > 0
	then
		return
	end
    
        data.animTimer = data.animTimer + 1

        if config.turnOnCliffs and shouldCliffturn(v,data,config) then v.direction = -v.direction end
	if config.lowGravity and v.speedY ~= 0 and not v.underwater then v.speedY = v.speedY - config.lowGravityAccelerationRate end

        if data.state == NORMAL then
                v.speedX = config.speed * v.direction
                v.animationFrame = math.floor(data.animTimer / config.framespeed) % config.frames
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
                                data.state = ALERT
				if v.collidesBlockBottom then
					SFX.play(1)
					v.speedY = config.detectionJumpHeight
				end
                        end
                end
        elseif data.state == ALERT then
		v.speedX = 0
		v.animationFrame = (config.frames - 1)
		if v.collidesBlockBottom then data.state = RUN end
        elseif data.state == RUN then
                v.speedX = data.speed * v.direction
                v.animationFrame = math.floor((data.animTimer / (config.framespeed * 4)) * data.speed) % config.frames
                if v.collidesBlockBottom then
		        if (data.animTimer % 6) == 0 then SFX.play(Misc.resolveSoundFile("sound/extended/chuck-stomp.ogg"), 0.4) end
		        if (data.animTimer % 2) == 0 then
		                local e = Effect.spawn(74,0,0)
		                e.y = v.y+v.height-e.height * 0.5
                                if v.direction == -1 then
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)
                                else
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                                end
                        end
                end
		if math.abs(data.speed) >= config.maxSprintSpeed then data.hasReachedMachSpeed = true end	
		if data.hasReachedMachSpeed then data.timer = data.timer + 1 end	
		if data.timer >= lunatime.toTicks(config.sprintDuration) then
                	if data.speed > 0 then
                        	data.speed = data.speed - config.decelleeration
               		else
                        	data.speed = 0
                	end
			if data.speed == 0 then
				data.state = NORMAL
				data.timer = 0
				data.hasReachedMachSpeed = false
				npcutils.faceNearestPlayer(v)
			end
		else
			if data.speed < config.maxSprintSpeed then data.speed = data.speed + config.acceleration end
		end
		if config.mimicJumps then
			for k,p in ipairs(Player.get()) do
				if Colliders.collide(data.range,p) and Misc.canCollideWith(v, p) then
					if v.collidesBlockBottom and (p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED) and not p:mem(0x36, FIELD_BOOL) and p.speedY < 0 then -- taken from Deltom's Hoppycat
						SFX.play(1)
						v.speedY = config.jumpHeight
					end
				end
			end
		end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

return kondorKoopa