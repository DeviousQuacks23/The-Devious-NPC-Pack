local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local effectconfig = require("game/effectconfig")

-- A large majority of code was taken from Boss Bass.
-- Some help from MegaDood

local cheepChomp = {}
local npcID = NPC_ID

local cheepChompSettings = {
	id = npcID,

	gfxwidth = 124,
	gfxheight = 124,
	width = 96,
	height = 96,
	gfxoffsetx = 0,
	gfxoffsety = 14,

	frames = 8,
	framestyle = 1,
	framespeed = 4, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = true,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, 

	nofireball = false,
	noiceball = true,
	noyoshi = true, 

	score = 6, 

	jumphurt = true, 
	spinjumpsafe = false,
	
	staticdirection = true,

	weight = 3,

	-- Custom Properties
	
	health = 3,

        coins = 3,
	coinID = 10,

        hitboxRadius = 50,
        detectionRadius = 110,

	chaseSpeed = 1.5,
	preEatSpeed = -2,
	preEatAcceleration = 0.15,

	openSpeed = 6,
	openAcceleration = 0.35,
	openDuration = 90,
	closedSpeed = 0.5,
	closedDeceleration = 0.45,
	closedDuration = 60,

	wingFrames = 2,
	wingFramespeed = 6,

	rotateSprite = true,

	preEatSFX = 35,
	eatSFX = Misc.resolveFile("cheep_chomp.ogg"),
	snapShutSFX = 3,
}

npcManager.setNpcSettings(cheepChompSettings)

local deathEffectID = (npcID)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
	},
	{
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

local CHASE = 0
local PREEAT = 1
local OPENMOUTH = 2
local CLOSED = 3

function cheepChomp.onInitAPI()
	npcManager.registerEvent(npcID, cheepChomp, "onTickEndNPC")
	npcManager.registerEvent(npcID, cheepChomp, "onDrawNPC")
	registerEvent(cheepChomp, "onPostNPCKill") 
	registerEvent(cheepChomp, "onNPCHarm") 

	Cheats.register("jaws",{
		isCheat = true,
		activateSFX = 34,
		aliases = {"swimforyourlife","cheepchompchaos"},
		onActivate = (function() 
			for i,p in ipairs(Player.get()) do
				local c = Camera.get()[p.idx]
				if c == nil then
					c = camera
				end

	                        NPC.spawn(npcID, c.x, p.y)
				NPC.spawn(npcID, c.x + c.width, p.y)
	                        NPC.spawn(npcID, c.x, p.y - 128)
				NPC.spawn(npcID, c.x + c.width, p.y - 128)
	                        NPC.spawn(npcID, c.x, p.y + 128)
				NPC.spawn(npcID, c.x + c.width, p.y + 128)
                        end
			return true
		end)
	})
end

function cheepChomp.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.timer = 0
		data.animTimer = 0
		data.wingAnimationTimer = 0

		data.health = cfg.health
                data.hasBeenUnderwater = false
                data.state = CHASE
		data.openMouth = false

		data.hitbox = Colliders:Circle()
		data.range = Colliders:Circle()

		data.rotation = 0
		data.speed = 0

		data.eatTimer = 0
		data.eatenPlayer = 0
		data.eatenx = 0
		data.eateny = 0
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

	data.hitbox.x = v.x+v.width*0.5
	data.hitbox.y = v.y+v.height*0.5
	data.hitbox.radius = cfg.hitboxRadius

	data.range.x = v.x+v.width*0.5
	data.range.y = v.y+v.height*0.5
	data.range.radius = cfg.detectionRadius

        if v.underwater then -- If the NPC is underwater then...
                data.hasBeenUnderwater = true

        	local speed = vector(data.speed * v.direction, 0):rotate(data.rotation)
        	v.speedX = speed.x
        	v.speedY = speed.y

                if data.state == CHASE then
			data.openMouth = false

			local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
			data.vector = vector(p.x-v.x+(p.width-v.width)*0.5, p.y-v.y+(p.height-v.height)*0.5):normalize()
			data.rotation = math.deg(math.atan2(data.vector.y * v.direction, data.vector.x * v.direction))

			data.speed = cfg.chaseSpeed
			npcutils.faceNearestPlayer(v)

                        for k,p in ipairs(Player.get()) do
                                if Colliders.collide(data.range,p) and Misc.canCollideWith(v, p) and p:mem(0x36, FIELD_BOOL) then
                                        data.state = PREEAT
					data.speed = cfg.preEatSpeed
					if cfg.preEatSFX then 
						SFX.play(cfg.preEatSFX) 
					end
                                end
                        end
                elseif data.state == PREEAT then
			data.openMouth = false
			data.speed = math.min(0, data.speed + cfg.preEatAcceleration)

                        if data.speed >= 0 then
                                data.state = OPENMOUTH
                                data.timer = 0
				if cfg.eatSFX then 
					SFX.play(cfg.eatSFX) 
				end
                        end
                elseif data.state == OPENMOUTH then
			data.openMouth = true

			data.speed = math.min(cfg.openSpeed, data.speed + cfg.openAcceleration)

	                if data.eatenPlayer == 0 then
		                if Level.winState() == 0 then
			                for k,p in ipairs(Player.get()) do
				                if Colliders.collide(data.hitbox,p) and Misc.canCollideWith(v, p) then
					                if p.forcedState == 0 and not p.inClearPipe and not p.inLaunchBarrel and not p:isInvincible() and p.hasStarman == false and p.isMega == false and p.deathTimer == 0 then
                                                                data.state = CLOSED
								data.timer = 0

						                data.eatenPlayer = p.idx
						                data.eatenx = p.x
						                data.eateny = p.y
							        SFX.play(55)
						                if p.holdingNPC and p.holdingNPC.isValid then
							                p.holdingNPC.heldIndex = 0
						                end
					                end
				                end
			                end
		                end
	                end

                        if data.timer >= cfg.openDuration then
                                data.state = CLOSED
                                data.timer = 0
				if cfg.snapShutSFX then 
					SFX.play(cfg.snapShutSFX) 
				end
                        end
                elseif data.state == CLOSED then
			data.openMouth = false

			data.speed = math.max(cfg.closedSpeed, data.speed - cfg.closedDeceleration)

                        if data.timer >= cfg.closedDuration then
                                data.state = CHASE
                        end
                end
        else
		data.state = CLOSED
                v.speedY = v.speedY + Defines.npc_grav -- Emulate gravity, since nogravity is enabled.
                if data.hasBeenUnderwater then
                        v.speedX = 2 * v.direction
                else
                        v.speedX = 0
                end
        end

	-- Don't despawn

	if v.data._settings.doNotDespawn then
                v.despawnTimer = 180
        end

	-- Kill eaten players

	if data.eatenPlayer > 0 then
		local p = Player(data.eatenPlayer)
		p.forcedState = FORCEDSTATE_BOSSBASS
		p.frame = -50 * p.direction
		p:mem(0x140, FIELD_WORD, 2)
		p.x = data.eatenx
		p.y = data.eateny

		data.eatTimer = data.eatTimer + 1

		if data.eatTimer >= 65 then
			Player(data.eatenPlayer):kill()
			for k,w in ipairs(Effect.get({3, 5, 129, 130, 134, 149, 150, 151, 152, 153, 154, 155, 156, 159, 161})) do
				w.timer = 0
				w.animationFrame = -1000
			end
			data.eatenPlayer = 0
			data.eatTimer = 0
		end
	end

	-- Destroy everything

        for k,p in ipairs(Player.get()) do
                if Colliders.collide(data.hitbox,p) and Misc.canCollideWith(v, p) then
                        p:harm()
                end
        end

        for k,n in ipairs(NPC.getIntersecting(v.x - 32, v.y - 32, v.x + v.width + 32, v.y + v.height + 32)) do
                if Colliders.collide(data.hitbox,n) and Misc.canCollideWith(v, n) then
                        if n.idx ~= v.idx and n.id ~= v.id and (not n.isProjectile) and (not n.isHidden) and (not n.friendly) and NPC.HITTABLE_MAP[n.id] then
                                n:mem(0x122,FIELD_WORD, 3)
                        end
                end
        end

	for k,w in ipairs(Block.getIntersecting(v.x - 32, v.y - 32, v.x + v.width + 32, v.y + v.height + 32)) do
                if Colliders.collide(data.hitbox,w) and Misc.canCollideWith(v, w) then
                    	if not w.isHidden and not w.layerObj.isHidden and w.layerName ~= "Destroyed Blocks" and w:mem(0x5A, FIELD_WORD) ~= -1 then 
				if Block.MEGA_SMASH_MAP[w.id] or Block.MEGA_HIT_MAP[w.id] then 
			        	w:remove(true)
                                	SFX.play(3)
				end
			end
                end
        end

	-- Animation

    	local frameCount = cfg.frames / cfg.wingFrames

    	v.animationFrame = math.floor(data.animTimer / cfg.framespeed) % frameCount + (math.floor(data.wingAnimationTimer / cfg.wingFramespeed) % cfg.wingFrames) * frameCount

	data.wingAnimationTimer = data.wingAnimationTimer + 1
	data.animTimer = math.clamp(data.animTimer, 1, (cfg.framespeed * frameCount) - 2)

	if data.openMouth then
		data.animTimer = data.animTimer + 1
	else
		data.animTimer = data.animTimer - 1
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = cfg.frames
	});
end

local function respawnRoutine(t)
	Routine.waitFrames(t.timer)
	local spawn = false
	local s = Section.getActiveIndices()
	for k,sec in ipairs(s) do
		if sec == t.section then
			spawn = true
			break
		end
	end
	if spawn then
		local closestCam = nil
		for k,c in ipairs(Camera.get()) do
			if closestCam == nil or (c.x + 0.5 * c.width - t.x < closestCam.x + 0.5 * closestCam.width - t.x) then
				closestCam = c
			end
		end
		if closestCam ~= nil then
			local mult = 1
			if closestCam.x + 0.5 * closestCam.width > t.x then
				mult = -1
			end

			if closestCam.y + closestCam.height < t.y or closestCam.y > t.y then
				y = closestCam.y - 96
			end
			
			local n = NPC.spawn(t.npcID, closestCam.x + 0.5 * closestCam.width + (0.5 * closestCam.width + NPC.config[t.npcID].width) * mult, t.y, t.section, t.respawns, true)
			n.data._settings.timer = t.timer
			n.data._settings.respawn = true
                        n.data._settings.doNotDespawn = t.dontDespawn
			n.friendly = t.friendly
			n.dontMove = t.dontMove
			n.layerName = t.layerName
			n.attachedLayerName = t.attachedLayerName
			n.activateEventName = t.activateEventName
			n.deathEventName = t.deathEventName
			n.talkEventName = t.talkEventName
			n.noMoreObjInLayer = t.noMoreObjInLayer
			n.msg = t.msg
		end
	end
end

function cheepChomp.onNPCHarm(e, v, r, c)
	if v.id ~= npcID then return end

	local data = v.data

	if type(c) == "NPC" and c.id == 13 and data.health > 1 then
		e.cancelled = true
		data.health = data.health - 1
		SFX.play(9)
		if c ~= nil then Effect.spawn(75, c.x, c.y) end
	end
end

function cheepChomp.onPostNPCKill(v, r)
	if v.id == npcID then

		local data = v.data
                local cfg = NPC.config[v.id]

		if (cfg.coins > 0) and (cfg.coinID > 0) then
                	for i = 1, cfg.coins do
                        	local coin = NPC.spawn(cfg.coinID, v.x + v.width * 0.5, v.y + v.height * 0.5, v.section, false)
                        	coin.x = coin.x - coin.width * 0.5
                        	coin.y = coin.y - coin.height * 0.5
                        	coin.speedX = RNG.random(-1.5, 1.5)
                        	coin.speedY = RNG.random(-2, -8)
				coin.layerName = "Spawned NPCs"
	  	                if NPC.config[coin.id].iscoin then
		                        coin.ai1 = 1
                                end
                	end
		end

		if v.data._settings.respawn then
			Routine.run(respawnRoutine, {
				npcID = v.id,
				x = v.x + 0.5 * v.width,
				y = v.y + 0.5 * v.height,
				section = v.section,
				timer = v.data._settings.timer,
				respawns = v.spawnid ~= 0,
				friendly = v.friendly,
				dontMove = v.dontMove,
				layerName = v.layerName,
				attachedLayerName = v.attachedLayerName,
				activateEventName = v.activateEventName,
				deathEventName = v.deathEventName,
				talkEventName = v.talkEventName,
				noMoreObjInLayer = v.noMoreObjInLayer,
				msg = v.msg,
                                dontDespawn = (v.data._settings.doNotDespawn and true) or false
			})
		end

		if data.eatenPlayer > 0 then
			local p = Player(data.eatenPlayer)
			p.forcedState = 0
			data.eatenPlayer = 0
			p.speedX = 0
			p.speedY = 0
			SFX.play(38)
			if #Colliders.getColliding{
				a = p, b = Block.SOLID .. Block.PLAYERSOLID, btype = Colliders.BLOCK, collisionGroup = v.collisionGroup, filter = function(other)
					return (not other.isHidden) and (not other:mem(0x5A, FIELD_BOOL))
				end } > 0 then
					p:kill()
			end
		end
	end
end

--[[************************
Rotation code by MrDoubleA
**************************]]

local sprite

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function cheepChomp.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end
	if not config.rotateSprite then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

-- bonus!!!!!!

function effectconfig.onTick.TICK_CHEEPCHOMP(v)
	if v.timer <= (v.lifetime - 40) then
		v.rotation = 0

		if v.timer == (v.lifetime - 40) then
			v.speedX = 0
			v.speedY = 0

			Defines.earthquake = 10

			SFX.play(Misc.resolveSoundFile("bowlingball"))
			SFX.play(37, 0.5)

                        local e = Effect.spawn(249, v.x + v.width * 0.5,v.y + v.height * 0.5)
			e.xScale = 8
			e.yScale = 8
                        e.x = e.x - (e.width * e.xScale) * 0.5
                        e.y = e.y - (e.height * e.yScale) * 0.5
		end

		if v.timer <= (v.lifetime - 80) then
			v.gravity = 0.075
			v.maxSpeedY = 6
		else
			v.gravity = 0
		end
	end

	if v.timer > (v.lifetime - 45) then
		v.xScale = v.xScale + 0.085
		v.yScale = v.yScale + 0.085
	elseif v.timer > (v.lifetime - 50) then
		v.xScale = v.xScale - 0.1
		v.yScale = v.yScale - 0.1
	end

	if v.timer == (v.lifetime - 1) then
		SFX.play(36)
		SFX.play(43, 0.5)

		Defines.earthquake = 4

	        for j = 1, 16 do
                        local e = Effect.spawn(10, v.x, v.y)
		        e.speedX = RNG.random(-16, 16)
		        e.speedY = RNG.random(-24, 24)
	       	end  

	        for j = 1, 32 do
                        local e = Effect.spawn(74, v.x, v.y)
		        e.speedX = RNG.random(-8, 8)
		        e.speedY = RNG.random(-12, 12)
	        end  
	end
end

return cheepChomp