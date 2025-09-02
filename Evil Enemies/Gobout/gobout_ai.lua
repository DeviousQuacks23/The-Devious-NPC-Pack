local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local gobout = {}

gobout.sharedSettings = {
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 4,
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

	speed = 1.5,
        turnInterval = 60,
        deceleration = 0.025,
        spitInterval = 50,  
        postSpitInterval = 100,  
        npcIsProjectile = false,
        npcSpeedX = 4,
        npcSpeedY = -2,
        openMouthDuration = 20,
}

function gobout.register(npcID)
	npcManager.registerEvent(npcID, gobout, "onTickEndNPC")
end

local CHASE = 0
local SPIT = 1

function gobout.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.state = CHASE
                data.timer = 0
                data.turnTimer = 0
                data.animTimer2 = 0
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
		return
	end
    
        data.turnTimer = data.turnTimer + 1
        data.animTimer = data.animTimer + 1
        data.animTimer2 = data.animTimer2 - 1

        if data.state == CHASE then
                v.speedX = config.speed * v.direction
                v.animationFrame = math.floor(data.animTimer / 6) % 4
                if data.turnTimer % config.turnInterval == 0 then npcutils.faceNearestPlayer(v) end
                for k,p in ipairs(Player.get()) do
                        if Colliders.collide(data.visionCollider[v.direction], p) then
                                data.state = SPIT
                        end
                end
        elseif data.state == SPIT then
                if v.speedX > 0 then
                        v.speedX = math.max(0, v.speedX - config.deceleration)
                elseif v.speedX < 0 then
                        v.speedX = math.min(0, v.speedX + config.deceleration)
                else
                        v.speedX = 0
                end
                if v.speedX == 0 then
                        data.timer = data.timer + 1
                        npcutils.faceNearestPlayer(v)
                	if data.animTimer2 >= 0 then
                        	v.animationFrame = 2
                	else
                        	v.animationFrame = 0
                	end
                        if data.timer == config.spitInterval then
				local n = NPC.spawn((v.ai1 > 0 and v.ai1) or 282, v.x + (32 * v.direction), v.y, v.section)
                                n.isProjectile = config.npcIsProjectile
				n.direction = v.direction
				n.speedX = config.npcSpeedX * n.direction
                                n.speedY = config.npcSpeedY
				n.friendly = v.friendly
				n.layerName = "Spawned NPCs"
	  	                if NPC.config[n.id].iscoin then n.ai1 = 1 end
                        	local e = Effect.spawn(10, v.x + v.width * v.direction, v.y + v.height * 0.5) 
                                e.y = e.y - e.height * 0.5
                        	e.speedX = 2 * v.direction
				data.animTimer2 = config.openMouthDuration
				SFX.play("goboutSpit.ogg")
                        end
                        if data.timer >= config.postSpitInterval then
                                data.state = CHASE
                                data.timer = 0
				data.animTimer = 0
                        end
                else
                        v.animationFrame = math.floor(data.animTimer / 4) % 4
                	if v.collidesBlockBottom then
		        	if (lunatime.tick() % 4) == 0 then SFX.play(10) end
		        	if (lunatime.tick() % RNG.randomInt(1, 3)) == 0 then
					local e = Effect.spawn(74,0,0)
                			if v.direction == -1 then
						e.x = v.x+RNG.random(-v.width/10,v.width/10)
               			        else
						e.x = v.x+RNG.random(-v.width/10,v.width/10)+config.width-8
                			end
					e.y = v.y+v.height-e.height * 0.5
                        	end
                	end
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
end

return gobout