local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local baBang = {}

-- Sprites by Wet-Dry Guy

local npcID = NPC_ID
local deathEffectID = npcID

local baBangSettings = {
	id = npcID,

	gfxwidth = 24,
	gfxheight = 48,
	width = 24,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 8,
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

	nofireball = true,
	noiceball = false,
	noyoshi= true, 

	score = 2, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	-- Custom Properties

	jumpRadius = 80,
	detectRadius = 160,

	wanderSpeed = 0.6,
	detectJump = -4,
	chaseAccel = 0.25,
	chaseMaxSpeed = 4,
	jumpHeightMod = 0.55,
	friendlyWhenJumping = true,

	explosionID = 3,
	quake = 6,

	igniteSFX = 42,
	fuseSFX = 16,
	fuseSFXDelay = 6,
	fuseVolume = 0.5,
	jumpSFX = 24,

	flashFramespeed = 2,
	flashFrames = 2,
}

npcManager.setNpcSettings(baBangSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
);

function baBang.onInitAPI()
	npcManager.registerEvent(npcID, baBang, "onTickEndNPC")
end

local IDLE = 0
local ACTIVE = 1
local JUMP = 2

function baBang.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true

		data.range = Colliders:Circle()
		data.radius = 0
		data.state = IDLE
		data.animTimer = 0
		data.flashAnimTimer = 0
		data.direction = 0
		data.timer = 0
	end

	data.range.x = v.x + v.width * 0.5
	data.range.y = v.y + v.height * 0.5
	data.range.radius = data.radius

	if data.state == ACTIVE then
		data.radius = config.jumpRadius
	else
		data.radius = config.detectRadius
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		v.animationFrame = ((v.direction == 1 and config.frames) or 0)
		return
	end
	
	-- Main AI

	data.timer = data.timer + 1

	if data.state == IDLE then
		v.speedX = config.wanderSpeed * v.direction

        	for _,p in ipairs(Player.get()) do
                	if Colliders.collide(data.range, p) and Misc.canCollideWith(v, p) and not v.friendly then
				if config.igniteSFX then SFX.play(config.igniteSFX) end
				data.state = ACTIVE
				data.timer = 0

				v.speedX = 0
				v.speedY = config.detectJump
			end
		end
	elseif data.state == ACTIVE then
		if config.fuseSFX then
                	if data.timer % config.fuseSFXDelay == 0 then
				SFX.play(config.fuseSFX, config.fuseVolume) 
			end
		end

		local p = npcutils.getNearestPlayer(v)
		data.animTimer = data.animTimer + 1

		if v.collidesBlockBottom then
		        if data.timer % (math.abs(v.speedX) * 3) == 0 then
		                local e = Effect.spawn(74, 0, 0)
		                e.y = v.y + v.height - e.height * 0.5

                                if v.direction == -1 then
		                        e.x = v.x + RNG.random(-v.width / 10, v.width / 10)
                                else
		                        e.x = v.x + RNG.random(-v.width / 10, v.width / 10) + v.width - 8
                                end
                        end

			if p.x + p.width / 2 < v.x + v.width / 2 then
				v.speedX = v.speedX - config.chaseAccel
				data.direction = -1
			else
				v.speedX = v.speedX + config.chaseAccel
				data.direction = 1
			end
		end

		v.speedX = math.clamp(v.speedX, -config.chaseMaxSpeed, config.chaseMaxSpeed)

        	for _,p in ipairs(Player.get()) do
                	if data.timer > 1 and v.collidesBlockBottom and Colliders.collide(data.range, p) and Misc.canCollideWith(v, p) and not v.friendly then
				if config.jumpSFX then SFX.play(config.jumpSFX) end
				data.state = JUMP

				-- Fall towards the nearest player
				-- Code taken from cold soup's Ramone Koopa, which is based off of code from MDA's cutscenePal.lua

				local target = p
				local distanceX = (target.x+target.width*0.5)-(v.x + v.width*0.5)
				local distanceY = (target.y+target.height)-(v.y + v.height)

				v.speedX = (config.jumpHeightMod/32)*distanceX
				local t = math.max(1,math.abs(distanceX/v.speedX))
				v.speedY = (distanceY/t - Defines.npc_grav*t*0.5)
			end
		end
	elseif data.state == JUMP then
		if config.fuseSFX then
                	if data.timer % config.fuseSFXDelay == 0 then
				SFX.play(config.fuseSFX, config.fuseVolume) 
			end
		end

		if config.friendlyWhenJumping then v.friendly = true end

        	if v.collidesBlockBottom or v.collidesBlockRight or v.collidesBlockUp or v.collidesBlockLeft then
	       		v:mem(0x122,FIELD_WORD, HARM_TYPE_OFFSCREEN)
	        	Explosion.spawn(v.x + 0.5 * v.width, v.y + 0.5 * v.height, config.explosionID)
			Defines.earthquake = math.max(Defines.earthquake, config.quake)

                        local e = Effect.spawn(75, v.x + v.width * 0.5, v.y + v.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
        	end
	end

	-- Animation

    	local frameCount = config.frames / config.flashFrames
    	v.animationFrame = math.floor(data.animTimer / config.framespeed) % frameCount + (math.floor(data.flashAnimTimer / config.flashFramespeed) % config.flashFrames) * frameCount
	data.animTimer = data.animTimer + 1

	if data.state ~= IDLE then
		data.flashAnimTimer = data.flashAnimTimer + 1
	else
		data.flashAnimTimer = 0
	end

	if data.state ~= ACTIVE then data.direction = v.direction end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames,
		direction = data.direction
	});
end

return baBang