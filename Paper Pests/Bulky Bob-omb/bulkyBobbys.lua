local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bulkyBobOmb = {}

bulkyBobOmb.sharedSettings = {
	gfxwidth = 112,
	gfxheight = 96,
	width = 64,
	height = 72,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 12,
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
	noiceball = true,
	noyoshi= true, 

	score = 4, 

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

	weight = 3,

        -- Custom Settings

	wanderSpeed = 0.8,
	chaseSpeed = 1.5,
	turnDelay = 50,

	smokeDelay = 16,

	kaboomDelay = 260,
	fuseTime = 60,

	explosionEffect = 773,
	earthquake = 6,
	useBulkyExplosion = false,

	igniteSound = Misc.resolveFile("kabomb-ignite.ogg"),
	smokeSound = Misc.resolveFile("kabomb-fuse.ogg"),
	explosionSFX = Misc.resolveFile("bulkyExplosion.ogg"),
}

function bulkyBobOmb.register(npcID)
	npcManager.registerEvent(npcID, bulkyBobOmb, "onTickEndNPC")
end

local NORMAL = 0
local CHASE = 1
local KABOOM = 2

local bulkyBobbyExplosion = Explosion.register(96, nil, nil, true, false)
local BobUlkExplosion = Explosion.register(192, nil, nil, true, false)

function bulkyBobOmb.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.sound = nil
                data.state = NORMAL
                data.timer = 0
		data.animTimer = 0
                data.visionCollider = {
                        [-1] = Colliders.Tri(0,0,{0,0},{-150,-50},{-150,50}),
                        [1] = Colliders.Tri(0,0,{0,0},{150,-50},{150,50}),
                }
	end

        data.visionCollider[v.direction].x = v.x + 0.5 * v.width
        data.visionCollider[v.direction].y = v.y + 0.5 * v.height

	if v.heldIndex ~= 0 
	or v.isProjectile  
	or v.forcedState > 0
	then
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4
		return
	end

	data.animTimer = data.animTimer + 1

        if data.state == NORMAL then
		v.speedX = config.wanderSpeed * v.direction
                v.animationFrame = math.floor(data.animTimer / 8) % 4
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
		                data.sound = SFX.play(config.igniteSound)
                                data.state = CHASE
                                v.speedX = 0
                                v.speedY = -5
                        end
                end
        elseif data.state == CHASE then
		data.timer = data.timer + 1
                v.animationFrame = math.floor(data.animTimer / 4) % 4 + 4
                if not data.sound:isplaying() then SFX.play(config.smokeSound) end
		if data.timer % config.turnDelay == 0 then npcutils.faceNearestPlayer(v) end
		if data.timer % config.smokeDelay == 0 then 
			local e = Effect.spawn(131, v.x, v.y)
			if v.direction == -1 then e.x = e.x + v.width else e.x = e.x - e.width end
			e.y = e.y - e.height
		end
                if v.collidesBlockBottom then
			v.speedX = config.chaseSpeed * v.direction
		        if (data.timer % RNG.randomInt(8, 16)) == 0 then
		                local e = Effect.spawn(74,0,0)
		                e.y = v.y+v.height-e.height * 0.5
                                if v.direction == -1 then
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)
                                else
		                        e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                                end
                        end
                end	
		if data.timer >= config.kaboomDelay then
			data.state = KABOOM
			data.timer = 0
		end
        elseif data.state == KABOOM then
		v.speedX = 0
		data.timer = data.timer + 1
		npcutils.faceNearestPlayer(v)
                v.animationFrame = math.floor(data.animTimer / 4) % 4 + 8
                if not data.sound:isplaying() then SFX.play(config.smokeSound) end
                if data.timer%4 > 0 and data.timer%4 < 3 then
                        v.x = v.x - 2
                else
                        v.x = v.x + 2
                end
		if data.timer >= config.fuseTime then
			v:kill(9)
			Defines.earthquake = config.earthquake
			SFX.play(config.explosionSFX)
                        Effect.spawn(config.explosionEffect, v.x + v.width * 0.5,v.y + v.height * 0.5)
			if config.useBulkyExplosion then
                		Explosion.create(v.x + v.width*0.5, v.y + v.height*0.5 - 12, BobUlkExplosion, nil, false)
			else
                		Explosion.create(v.x + v.width*0.5, v.y + v.height*0.5 - 12, bulkyBobbyExplosion, nil, false)
			end
	        	for j = 1, RNG.randomInt(24, 64) do
                        	local e = Effect.spawn(131, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
		        	e.speedX = RNG.random(-12, 12)
		        	e.speedY = RNG.random(-20, 20)
	        	end  
		end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

return bulkyBobOmb