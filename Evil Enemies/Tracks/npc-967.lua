local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local tracks = {}

local npcID = NPC_ID
local deathEffectID = npcID

local tracksSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 40,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 2,
	framestyle = 0,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = false,
	noiceball = false,
	noyoshi= true, 
	score = 0, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	-- Custom Properties

	radius = 256,
	stayStillSpeed = 0.5,
	fadeSpeed = 0.035,
	
	wanderSpeed = 0,
	speedUpInt = 0.15,
	maxFleeSpeed = 4.5,

	turnInterval = 24,

	hopOverStuff = true,
	hopDetectWidth = 128,
	hopSpeed = -6.7,

	minCoins = 5,
	maxCoins = 20,
	coinID = 10,
}

npcManager.setNpcSettings(tracksSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=deathEffectID,
		[HARM_TYPE_FROMBELOW]=deathEffectID,
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

function tracks.onInitAPI()
	npcManager.registerEvent(npcID, tracks, "onTickNPC")
        npcManager.registerEvent(npcID, tracks, "onDrawNPC")
	registerEvent(tracks, "onPostNPCKill")
end

function tracks.onPostNPCKill(v, r)
	if r == HARM_TYPE_LAVA or r == HARM_TYPE_OFFSCREEN then return end

	if v.id == npcID then
                local cfg = NPC.config[v.id]

		if (cfg.minCoins > 0) and (cfg.maxCoins > 0) and (cfg.coinID > 0) then
	        	for j = 1, RNG.randomInt(6, 16) do
                        	local e = Effect.spawn(80, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        	e.x = e.x - e.width * 0.5
                        	e.y = e.y - e.height * 0.5
		        	e.speedX = RNG.random(-4, 4)
		        	e.speedY = RNG.random(-4, 4)
	        	end  

                        SFX.play(59)

                	for i = 1, RNG.randomInt(cfg.minCoins, cfg.maxCoins) do
                        	local coin = NPC.spawn(cfg.coinID, v.x + v.width * 0.5, v.y + v.height * 0.5)
                        	coin.x = coin.x - coin.width * 0.5
                        	coin.y = coin.y - coin.height * 0.5
                        	coin.speedX = RNG.random(-6, 6)
                        	coin.speedY = RNG.random(-3, -12)
				coin.layerName = "Spawned NPCs"
				coin.friendly = v.friendly
				coin.noblockcollision = true

	  	                if NPC.config[coin.id].iscoin then
		                        coin.ai1 = 1
                                end
                	end
		end
	end
end

function tracks.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.opacity = 1
		data.detected = true
		data.canFlee = false
		data.detectTimer = 0
		data.range = Colliders:Circle()
		data.speed = config.wanderSpeed
	end

	data.range.x = v.x + v.width * 0.5
	data.range.y = v.y + v.height * 0.5
	data.range.radius = config.radius

	if v.heldIndex ~= 0
	or v.isProjectile  
	or v.forcedState > 0
	then
		data.opacity = math.min(1, data.opacity + config.fadeSpeed)
	     	return
	end

	-- Tracks

	v.speedX = data.speed * v.direction

        if data.oldSpeedY and data.oldSpeedY > 1 and v.collidesBlockBottom then
        	v.speedY = -data.oldSpeedY * 0.35
        end

	data.oldSpeedY = v.speedY
	local p = npcutils.getNearestPlayer(v)

	if data.canFlee then
		data.detected = false

		if p.forcedState == 0 and p.deathTimer == 0 then
			if math.abs(p.speedX) <= config.stayStillSpeed then
				data.detected = true
			end
		end
	else
		if p.forcedState == 0 and p.deathTimer == 0 then
                	if Colliders.collide(data.range, p) and Misc.canCollideWith(v, p) then
				data.canFlee = true

				SFX.play(Misc.resolveSoundFile("chuck-whistle"))
				v.speedY = -5	
			end
		end
	end

	if data.detected then
		data.opacity = math.min(1, data.opacity + config.fadeSpeed)
		data.speed = math.max(config.wanderSpeed, data.speed - config.speedUpInt)
		data.detectTimer = 0
	else
		data.opacity = math.max(0, data.opacity - config.fadeSpeed)

		if data.opacity <= 0 and data.canFlee then
			data.speed = math.min(config.maxFleeSpeed, data.speed + config.speedUpInt)
			data.detectTimer = data.detectTimer + 1

			if data.detectTimer % config.turnInterval == 0 or data.detectTimer == 1 then
				v.direction = -math.sign((p.x + (p.width / 2)) - (v.x + (v.width / 2)))
			end

               		if RNG.randomInt(1, 10) == 1 then
                        	local e = Effect.spawn(80, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                        	e.speedX = RNG.random(-2, 2)
                        	e.speedY = RNG.random(-2, 2)
                        	e.x = e.x - e.width *0.5
                        	e.y = e.y - e.height*0.5
                	end
		end
	end

        if v.collidesBlockBottom and config.hopOverStuff then
		local colBox = Colliders.Box()

            	colBox.width = config.hopDetectWidth
            	colBox.height = 2

		colBox.x = v.x + (v.width/2) - (colBox.width/2)
            	colBox.y = v.y + v.height - colBox.height
		-- colBox:Debug(true)
            
            	local npcs = Colliders.getColliding{a = colBox, btype = Colliders.NPC, filter = function(other) return (Colliders.FILTER_COL_NPC_DEF(other) and other:mem(0x136,FIELD_BOOL)) end}

            	for _,npc in ipairs(npcs) do
                	v.speedY = config.hopSpeed
            	end
        end

	if not v.dontMove and v.speedX ~= 0 and v.collidesBlockBottom then
		if lunatime.tick() % 2 == 0 then
                        local e = Effect.spawn(74, v.x + v.width * 0.5,v.y + v.height)
                        e.x = e.x - e.width * 0.5
			e.x = e.x + ((v.width/2) * v.direction)
                        e.y = e.y - e.height * 0.5
		end
	end
end

function tracks.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.opacity then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img

	local lowPriorityStates = table.map{1,3,4}
	local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,
		height = config.gfxheight,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
		sceneCoords = true,
		centered = true,
		color = math.lerp(Color.black, Color.white, data.opacity) .. data.opacity,
		priority = priority,
	}

	npcutils.hideNPC(v)
end

return tracks