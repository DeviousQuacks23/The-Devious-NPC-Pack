local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")

local rubbinDuck = {}
local npcID = NPC_ID

local rubbinDuckSettings = {
	id = npcID,

	gfxwidth = 64,
	gfxheight = 64,
	width = 48,
	height = 48,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = true,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = true,
	nogravity = true,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = false,
	noiceball = false,
	noyoshi= true,  

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = true,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	staticdirection = true, 

	-- Custom Properties

	wateraccel = -0.075,
	speedcapY = 1,
	maxSpeed = 2.5,
	accel = 0.025,
	chaseDist = 64,
	bounceLimit = 1,
	bounceLossMod = 0.7,

	fistImg = Graphics.loadImageResolved("npc-"..npcID.."-fist.png"),
	screenImg = Graphics.loadImageResolved("npc-"..npcID.."-hit.png"),

	punchSFX = Misc.resolveFile("sn_duckShoot.wav"),
	hitSFX = Misc.resolveFile("sn_jewelGoon_hit.wav"),
	hitBGSFX = Misc.resolveFile("sn_explosion4.wav"),
}

npcManager.setNpcSettings(rubbinDuckSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

function rubbinDuck.onInitAPI()
	npcManager.registerEvent(npcID, rubbinDuck, "onTickEndNPC")
	npcManager.registerEvent(npcID, rubbinDuck, "onDrawNPC")
	registerEvent(rubbinDuck, "onTick")
end

local IDLE = 0
local PUNCH = 1
local hitPlayers = {}

function rubbinDuck.onTick()
	for i,p in ipairs(Player.get()) do
		if hitPlayers[p.idx] then
			p.keys.left = KEYS_UP
			p.keys.right = KEYS_UP
			p.keys.jump = KEYS_UP
			p.keys.altJump = KEYS_UP
			p:mem(0x3C,FIELD_BOOL, true)

			p.speedX = -16 * p.direction
			p:mem(0x138, FIELD_FLOAT, p.speedX)
			p.speedX = 0

			if lunatime.tick() % 2 == 0 then
                        	local e = Effect.spawn(10, p.x + p.width * 0.5, p.y + p.height * 0.5) 
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
			end

			if p:isUnderwater() then
				p.speedY = p.speedY-(Defines.player_grav/10)
			else
				if p.speedY >= Defines.player_grav then
					p.speedY = -Defines.player_grav + 0.01
				end
			end

			if p.forcedState ~= 0 or p.deathTimer ~= 0 then
				hitPlayers[p.idx] = nil

				return
			end

			if p:mem(0x148, FIELD_WORD) == 2 or p:mem(0x14C, FIELD_WORD) == 2 then
				SFX.play(37)
				SFX.play(43)
				p:harm()

				Defines.earthquake = math.max(Defines.earthquake, 8)
	        		for j = 1, RNG.randomInt(16, 24) do
                        		local e = Effect.spawn(74, p.centerX, p.centerY)
                        		e.x = e.x - e.width * 0.5
                        		e.y = e.y - e.height * 0.5
		        		e.speedX = RNG.random(-12, 12)
		        		e.speedY = RNG.random(-20, 20)
	        		end  

				hitPlayers[p.idx] = nil
			end
		end
	end
end

function rubbinDuck.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.wasInWater = false
		data.state = IDLE
		data.lerp = 0
		data.timer = 0
		data.screenOpa = 0
		data.delay = 0
		data.hasPunched = false
	end

	if v.despawnTimer >= 10 then
		v.despawnTimer = math.max(100, v.despawnTimer)
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Moving around

	if v.underwater then
		v.speedY = v.speedY + config.wateraccel * Defines.npc_grav
			
		-- caps to its speed so its physics dont get all wacky
		if v.speedY < -config.speedcapY then
			v.speedY = -config.speedcapY
		end
			
		if v.speedY > config.speedcapY then
			v.speedY = config.speedcapY
		end

	        local p = npcutils.getNearestPlayer(v)	
	        local dist = (p.x + p.centreX) - (v.x + v.centreX)
	
	        if math.abs(dist) > config.chaseDist then
			v.speedX = math.clamp(v.speedX + (config.accel * v.direction), -config.maxSpeed, config.maxSpeed)
			npcutils.faceNearestPlayer(v)
		else
			if p.y < v.bottom then
                		if v.speedX > 0 then
                    			v.speedX = math.max(0,v.speedX - 0.15)
                		elseif v.speedX < 0 then
                    			v.speedX = math.min(0,v.speedX + 0.15)
                		end
			end
		end

		if not data.wasInWater then data.wasInWater = true end
	else
		if data.wasInWater then
			data.wasInWater = false
			if v.speedY < config.wateraccel then
				v.speedY = config.wateraccel
			end
		else
			v.speedY = v.speedY + Defines.npc_grav
		end

		if v.collidesBlockBottom and data.oldSpeedY then
        		if data.oldSpeedY > config.bounceLimit then
        			v.speedY = -data.oldSpeedY * config.bounceLossMod
			end
		end

		data.oldSpeedY = v.speedY

            	if v.collidesBlockBottom then
                	if v.speedX > 0 then
                    		v.speedX = math.max(0,v.speedX - 0.25)
                	elseif v.speedX < 0 then
                    		v.speedX = math.min(0,v.speedX + 0.25)
                	end
		
			if v.speedX == 0 then
				npcutils.faceNearestPlayer(v)
			end
            	else
                	if v.speedX > 0 then
                    		v.speedX = math.max(0,v.speedX - 0.025)
                	elseif v.speedX < 0 then
                   		v.speedX = math.min(0,v.speedX + 0.025)
                	end
            	end
	end

	v:mem(0x120, FIELD_BOOL, false)
	if v.collidesBlockLeft or v.collidesBlockRight then
		v.speedX = 0
	end

	-- Punching

	data.delay = math.max(data.delay - 1, 0)
	data.screenOpa = math.max(data.screenOpa - 0.025, 0)
	
	local hitboxPunch = {
      		[-1] = {v.centreX - 128, v.centreX},
                [1] = {v.centreX, v.centreX + 128},
        }

	if data.state == IDLE then
        	for k,p in ipairs(Player.getIntersecting((hitboxPunch[v.direction][1]), v.y, (hitboxPunch[v.direction][2]), v.bottom)) do
			if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and data.delay <= 0 then
				data.state = PUNCH

				if config.punchSFX then
					data.sound = SFX.play(config.punchSFX)
				end
			end
		end
	elseif data.state == PUNCH then
		v.speedX = 0

		if not data.hasPunched and data.lerp >= 1 then 
			data.hasPunched = true 

			for k,p in ipairs(Player.getIntersecting((hitboxPunch[v.direction][1]), v.y + 8, (hitboxPunch[v.direction][2]), v.bottom - 8)) do
				if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not hitPlayers[p.idx] then
					p.keys.run = KEYS_UP
					p.keys.altRun = KEYS_UP
					p:mem(0x154,FIELD_WORD, 0)
					p:mem(0x11C,FIELD_WORD, 0)
					p.direction = -v.direction
					hitPlayers[p.idx] = true

					data.screenOpa = 1
					Defines.earthquake = math.max(Defines.earthquake, 16)
	        			for j = 1, RNG.randomInt(16, 24) do
                        			local e = Effect.spawn(74, p.centerX, p.centerY)
                        			e.x = e.x - e.width * 0.5
                        			e.y = e.y - e.height * 0.5
		        			e.speedX = RNG.random(-12, 12)
		        			e.speedY = RNG.random(-20, 20)
	        			end  

					if config.hitSFX then
						if data.sound and data.sound.isValid and data.sound:isPlaying() then data.sound:Stop() end
						data.sound = SFX.play(config.hitSFX)
					end

					if config.hitBGSFX then
						SFX.play(config.hitBGSFX)
					end
				end
			end
		end	

		if data.hasPunched then data.timer = data.timer + 1 end	
		if data.timer >= 60 then
			data.lerp = math.max(data.lerp - 0.025, 0)
			
			if data.lerp <= 0 then
				data.state = IDLE
				data.timer = 0
				data.hasPunched = false
				data.delay = 150
			end
		else
			data.lerp = math.min(data.lerp + 0.15, 1)
		end
	end
end

function rubbinDuck.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data
	local config = NPC.config[v.id]

	-- The punch screen
	if config.screenImg and data.screenOpa and data.screenOpa > 0 then
		Graphics.drawBox{
                	texture = config.screenImg,
                	x = 0,
                	y = 0,
			color = Color.white .. (data.screenOpa or 0),
                	priority = -99,
                }
	end

	-- The realistic fist

	if not config.fistImg then return end

    	if data.sprite == nil or data.sprite.texture ~= config.fistImg then
        	data.sprite = Sprite{texture = config.fistImg, frames = 1, pivot = vector((v.direction + 1), 0.5)}
    	end

	local lowPriorityStates = table.map{1, 3, 4}
    	local priority = (lowPriorityStates[v:mem(0x138, FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

    	data.sprite.x = v.x + v.width*0.5 + config.gfxoffsetx
    	data.sprite.y = v.y + v.height - config.gfxheight*0.5+ config.gfxoffsety
	data.sprite.scale.x = easing.inQuart((data.lerp or 0), 0, v.direction, 1)

    	data.sprite:draw{frame = 1, priority = priority-0.01, sceneCoords = true}
end

return rubbinDuck