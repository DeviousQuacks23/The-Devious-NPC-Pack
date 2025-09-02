local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Sprites by Smuglutena
-- Dedicated to the OG Broozer NPC, by KateBulka

local broozer = {}
local npcID = NPC_ID

local deathEffectID = 773

local broozerSettings = {
	id = npcID,

	gfxwidth = 88,
	gfxheight = 64,
	width = 40,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 17,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,

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
	noyoshi = true, 

	score = 0, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	grabside = false,
	grabtop = false,
	weight = 2,

	-- Custom Properties:

	health = 3,

	detectRadius = 150,
	chaseRadius = 320,

	idleFrames = 1,
	idleFramespeed = 8,
	idleTime = 50,

	walkFrames = 4,
	walkFramespeed = 12,
	walkSpeed = 1,
	walkTime = 100,

	detectJump = -4,
	chaseFrames = 8,
	chaseFramespeed = 3,
	chaseAccel = 0.1,
	chaseMaxSpeed = 4,
	chaseSoundDelay = 12,
	blockBreakSpeedMod = 0.05,

	breakableBlocks = {2, 4, 5, 60, 88, 89, 90, 115, 186, 188, 192, 193, 224, 225, 226, 293, 526, 668, 682, 683, 694, 457, 280, 1375, 1374},

	hurtFrames = 4,
	hurtTime = 70,
	jumpHurtSpeed = 3,
	finalScore = 4,
}

npcManager.setNpcSettings(broozerSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_LAVA,
		HARM_TYPE_OFFSCREEN
	},
	{
		[HARM_TYPE_JUMP]            = {id = deathEffectID, speedX = 0, speedY = 0},
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
	}
);

function broozer.onInitAPI()
	npcManager.registerEvent(npcID, broozer, "onTickEndNPC")
	registerEvent(broozer, "onNPCHarm")
end

local IDLE = 0
local WALK = 1
local CHASE = 2
local HURT = 3

-- Taken from MDA's Mildes
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

function broozer.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.hp = (config.health - 1)
		data.range = Colliders:Circle()
		data.radius = 0
		data.state = IDLE
		data.timer = 0
		data.hasTurned = false
		data.direction = 0
	end

	data.range.x = v.x + v.width * 0.5
	data.range.y = v.y + v.height * 0.5
	data.range.radius = data.radius

	if data.state == CHASE then
		data.radius = config.chaseRadius
	else
		data.radius = config.detectRadius
	end

	if v.heldIndex ~= 0 or v.isProjectile or v.forcedState > 0 then
		v.animationFrame = ((v.direction == 1 and config.frames) or 0)
		data.initialized = false
		return
	end

	data.timer = data.timer + 1
	
	if data.state == IDLE or data.state == WALK then
        	for _, p in ipairs(Player.get()) do
                	if Colliders.collide(data.range, p) and Misc.canCollideWith(v, p) then
				data.state = CHASE
				data.timer = 0
				v.speedY = config.detectJump
			end
		end
	end

	if data.state == IDLE then
		v.animationFrame = math.floor(data.timer / config.idleFramespeed) % config.idleFrames

		if data.timer >= config.idleTime then
			if data.hasTurned then v.direction = -v.direction end
			data.state = WALK
			data.timer = 0
		end
	elseif data.state == WALK then
		v.animationFrame = math.floor(data.timer / config.walkFramespeed) % config.walkFrames + config.idleFrames
		v.speedX = config.walkSpeed * v.direction

		if (data.timer >= config.walkTime) or shouldCliffturn(v, data, config) then
			v.speedX = 0
			data.hasTurned = true
			data.state = IDLE
			data.timer = 0
		end
	elseif data.state == CHASE then
		v.animationFrame = math.floor(data.timer / config.chaseFramespeed) % config.chaseFrames + (config.idleFrames + config.walkFrames)
		if data.timer % config.chaseSoundDelay == 0 then 
			SFX.play(3, 0.5) 
		end

		local p = npcutils.getNearestPlayer(v)

		if p.x + p.width / 2 < v.x + v.width / 2 then
			v.speedX = v.speedX - config.chaseAccel
			data.direction = -1
		else
			v.speedX = v.speedX + config.chaseAccel
			data.direction = 1
		end
		v.speedX = math.clamp(v.speedX, -config.chaseMaxSpeed, config.chaseMaxSpeed)

                if not Colliders.collide(data.range, p) and v.collidesBlockBottom then
			v.direction = data.direction
			data.hasTurned = false
			data.state = IDLE
			data.timer = 0
		end

		for _, b in ipairs(Block.getIntersecting(v.x + v.speedX, v.y, v.x + v.width + v.speedX, v.y + v.height)) do
			if not b.isHidden and not b.layerObj.isHidden and b.layerName ~= "Destroyed Blocks" and b:mem(0x5A, FIELD_WORD) ~= -1 and (Block.MEGA_SMASH_MAP[b.id] or config.breakableBlocks[b.id]) and v.speedX ~= 0 then 
				b:remove(true)
				SFX.play(3)
				v.speedX = v.speedX * config.blockBreakSpeedMod
			end
		end

		for _, n in ipairs(NPC.getIntersecting(v.x + v.speedX, v.y, v.x + v.width + v.speedX, v.y + v.height)) do
			if n.id ~= v.id and n.isValid and not n.isHidden and not n.friendly and n.despawnTimer > 0 and n.heldIndex == 0 and not n.isProjectile and v.speedX ~= 0 
			and (NPC.SHELL_MAP[n.id] or NPC.VEGETABLE_MAP[n.id] or NPC.config[n.id].grabside) then 
           			n.direction = v.direction
            			n.speedX = v.direction * Defines.projectilespeedx
            			if not NPC.SHELL_MAP[n.id] then n.speedY = RNG.random(-4, -6) end
				n.isProjectile = true
				if n.id == 45 then n.ai1 = 1 end

        			local e = Effect.spawn(75, n.x + n.width * 0.5, n.y + n.height * 0.5)
        			e.x = e.x - e.width * 0.5
        			e.y = e.y - e.height * 0.5
				SFX.play(9)
			end
		end

                if v.collidesBlockBottom and v.speedX ~= 0 then
		        if data.timer % 2 == 0 then
		                local e = Effect.spawn(74, 0, 0)
		                e.y = v.y + v.height - e.height * 0.5
                                if v.direction == -1 then
		                        e.x = v.x + RNG.random(-v.width / 10, v.width / 10)
                                else
		                        e.x = v.x + RNG.random(-v.width / 10, v.width / 10) + config.width - 8
                                end
                        end
                end
	elseif data.state == HURT then
		local frames = (config.idleFrames + config.walkFrames + config.chaseFrames)
		v.animationFrame = math.lerp(frames, frames + config.hurtFrames, data.timer / config.hurtTime)

		if data.timer >= config.hurtTime then
			v.speedX = 0
			data.state = IDLE
			data.timer = 0
		end
	end

	if data.state ~= CHASE then data.direction = v.direction end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames,
		direction = data.direction
	});
end

function broozer.onNPCHarm(e, v, r, c)
	if v.id ~= npcID then return end

	local data = v.data
        local config = NPC.config[v.id]

	-- from MegaDood
	local culpritIsPlayer = (c and c.__type == "Player") 
	local culpritIsNPC    = (c and c.__type == "NPC")
	
	if r == HARM_TYPE_JUMP then
		if data.hp > 0 then
			SFX.play(2)
			SFX.play(39)

			v.speedX = 0
			v.direction = data.direction
			data.state = HURT
			data.timer = 0
			
			e.cancelled = true
		end

		if data.state == HURT then
			SFX.play(2)
			e.cancelled = true
		end

		if culpritIsPlayer then
			c.speedX = math.sign((c.x + (c.width / 2)) - (v.x + (v.width / 2))) * config.jumpHurtSpeed
		end
		
		data.hp = data.hp - 1
	elseif r == HARM_TYPE_FROMBELOW then
		v.speedY = -6
		SFX.play(9)
		e.cancelled = true
	elseif r == HARM_TYPE_NPC then
		if culpritIsNPC and c.id == 13 and data.hp > 0 then
			data.hp = data.hp - 0.5
			SFX.play(9)
			e.cancelled = true
		end
	end

	if not e.cancelled then
		v.direction = data.direction
		if r ~= HARM_TYPE_LAVA and r ~= HARM_TYPE_OFFSCREEN then
			Misc.givePoints(config.finalScore, vector(v.x + (v.width / 2), v.y), true)
		end
	end
end

return broozer