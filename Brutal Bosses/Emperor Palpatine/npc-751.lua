local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local palpatine = {}
local npcID = NPC_ID

local palpatineSettings = {
	id = npcID,

	gfxwidth = 132,
	gfxheight = 120,
	width = 64,
	height = 64,
	gfxoffsetx = 0,
	gfxoffsety = 8,

	frames = 5,
	framestyle = 0,
	framespeed = 8, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = false,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	isstationary = true,

	-- Custom Properties

	health = 12,

	shieldWidth = 306,
	shieldHeight = 250,

	shieldOffset = 32,

	chairWidth = 170,
	chairHeight = 154,

	lightWidth = 124,
	lightHeight = 26,

	lightOffset = 32,

	poleWidth = 22,
	poleHeight = 512,
}

npcManager.setNpcSettings(palpatineSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA
	},
	{
	}
);

function palpatine.onInitAPI()
	npcManager.registerEvent(npcID, palpatine, "onTickEndNPC")
	npcManager.registerEvent(npcID, palpatine, "onDrawNPC")
	registerEvent(palpatine, "onPostNPCKill")
	registerEvent(palpatine, "onNPCHarm")
	registerEvent(palpatine, "onTick")
end

local playSound = false
local idleSoundObj

function palpatine.onTick()
    	if playSound then
        	-- Create the looping sound effect for all of the NPC's
        	if idleSoundObj == nil then
			idleSoundObj = SFX.play{sound = Misc.resolveSoundFile("Emperor SFX/energyfield_active_loop"),loops = 0}
        	end
   	 elseif idleSoundObj ~= nil then -- If the sound is still playing but there's no NPC's, stop it
        	idleSoundObj:stop()
        	idleSoundObj = nil
    	end
    
    	-- Clear playSound for the next tick
    	playSound = false
end

local effectVariants = {1,2,3,4,5,6,7,8}

function palpatine.onPostNPCKill(v,reason)
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_LAVA or reason == HARM_TYPE_OFFSCREEN then return end

        local config = NPC.config[v.id]

	SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_dies"))

        Effect.spawn(751, v.x + v.width * 0.5,v.y + v.height * 0.5)

    	for _,variant in ipairs(effectVariants) do
        	local e = Effect.spawn(756, v.x + v.width * 0.5,v.y + v.height * 0.5, variant)
	end

        Effect.spawn(758, v.x+(v.width/2)+config.gfxoffsetx,v.y+v.height + config.lightOffset)
        Effect.spawn(759, v.x+(v.width/2)+config.gfxoffsetx,v.y+v.height + config.lightOffset + 8 + (config.poleHeight / 2))

        local e = Effect.spawn(272, v.x + v.width * 0.5,v.y + v.height * 0.5)
	e.xScale = 2
	e.yScale = 2
	SFX.play(43)

	Misc.score(10000)
        local e = Effect.spawn(760, v.x + v.width * 0.5,v.y)
        e.x = e.x - e.width * 0.5

	for j = 1, RNG.randomInt(12, 24) do
                local e = Effect.spawn(10, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
		e.speedX = RNG.random(-8, 8)
		e.speedY = RNG.random(-8, 8)
	end  

	if v.legacyBoss then
		local ball = NPC.spawn(354, v.x, v.y, v.section)
		ball.x = ball.x + ((v.width - ball.width) / 2)
		ball.y = ball.y + ((v.height - ball.height) / 2)
		ball.speedY = -6
		ball.despawnTimer = 100
	end
end

local NORMAL = 0
local LAUGH = 1
local CHAIR = 2
local HURT = 3
local STUN = 4

function palpatine.onTickEndNPC(v)
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
		data.shield = true
		data.immunity = 0
		data.cooldown = 0
		data.range = Colliders:Circle()
		data.hp = config.health
		data.timer = 0
		data.shocks = 0
		data.chairDir = 1
		data.chairFrame = 0
		data.render = true
		data.shieldTimer = 0
		data.lightFrame = 0
	end

	data.range.x = v.x + v.width * 0.5
	data.range.y = v.y + v.height * 0.5 - 40
	data.range.radius = 100

	if v.heldIndex ~= 0  or v.forcedState > 0 then return end
        if v.isProjectile then v.isProjectile = false end
        v.despawnTimer = 180
	
	-- Main AI

	data.immunity = math.max(data.immunity - 1, 0)
	data.cooldown = math.max(data.cooldown - 1, 0)
	data.timer = data.timer + 1
	data.shieldTimer = data.shieldTimer + 1

	--Text.print(data.hp,0,0)

	if data.shield then
		if (v.x + v.width > camera.x and v.x < camera.x + camera.width and v.y + v.height > camera.y and v.y < camera.y + camera.height) then
			playSound = true
		end
		if data.cooldown <= 0 then
        		for k,n in ipairs(NPC.getIntersecting(v.x - 256, v.y - 256, v.x + v.width + 256, v.y + v.height + 256)) do
                		if Colliders.collide(data.range,n) and Misc.canCollideWith(v, n) then
					if n.id ~= v.id and not n.isHidden and not n.friendly then
						n:harm(3)
						if n.x + (n.width * 0.5) == v.x + (v.width * 0.5) then
							n.speedX = RNG.irandomEntry({-6, 6})
						else
							n.speedX = math.sign((n.x + (n.width / 2)) - (v.x + (v.width / 2))) * 4
						end
						n.speedY = -5
						SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_electric_zap_0"..RNG.randomInt(1, 3)..""))
						Defines.earthquake = 4
						data.shocks = data.shocks + 1
						data.cooldown = 20
						local vector = vector(n.x-v.x+(n.width-v.width)*0.5, n.y-v.y+(n.height-v.height)*0.5):normalize()
						local e = Effect.spawn(761, v.x + v.width * 0.5,v.y + v.height * 0.5)
						e.angle = math.deg(math.atan2(vector.y, vector.x)) + 90
                        		end
                		end
        		end
        		for k,p in ipairs(Player.get()) do
                		if Colliders.collide(data.range,p) and Misc.canCollideWith(v, p) then
					if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
						local distance = vector((p.x + p.width*0.5) - (v.x + v.width*0.5),(p.y + p.height*0.5) - (v.y + v.height*0.5))
			        		p.speedX = (distance.x / v.width ) * 8
			        		p.speedY = (distance.y / v.height) * 4
						SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_electric_zap_0"..RNG.randomInt(1, 3)..""))
						Defines.earthquake = 4
						data.shocks = data.shocks + 1
						data.cooldown = 20
						local vector = vector(p.x-v.x+(p.width-v.width)*0.5, p.y-v.y+(p.height-v.height)*0.5):normalize()
						local e = Effect.spawn(761, v.x + v.width * 0.5,v.y + v.height * 0.5)
						e.angle = math.deg(math.atan2(vector.y, vector.x)) + 90
					end
				end
			end
		end
		if data.shocks >= 5 then
			SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_caugh_0"..RNG.randomInt(1, 2).."")) 
			data.shocks = 0
			data.state = HURT
			data.timer = 0 
		end
	end

        if RNG.randomInt(1, (config.health * 0.5)) == (data.hp + 1) then
                local e = Effect.spawn(753, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
	end
        if RNG.randomInt(1, config.health) == (data.hp + 1) then
                local e = Effect.spawn(754, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
	end
        if RNG.randomInt(1, (config.health * 0.75)) == (data.hp + 1) then
                local e = Effect.spawn(755, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
	end

	if data.state == NORMAL then
		data.render = true
		data.shield = true
		data.chairFrame = 0
		data.lightFrame = math.floor(data.shieldTimer / 256) % 4 + 1
		v.animationFrame = 0
		if data.timer >= 400 then
			data.state = LAUGH
			data.timer = 0 
		end
	elseif data.state == LAUGH then
		data.render = true
		data.chairFrame = 0
		data.lightFrame = math.floor(data.shieldTimer / 256) % 4 + 1
		if data.timer == 10 then 
			SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_electric_zap_0"..RNG.randomInt(1, 3).."")) 
			for j = 1, RNG.randomInt(2, 6) do Effect.spawn(757, v.x + v.width * 0.5,v.y + v.height * 0.5) end
		end
		if data.timer >= 20 then
			if data.timer == 20 then SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_laugh_0"..RNG.randomInt(1, 2).."")) end
			v.animationFrame = 1
			if data.timer >= 180 then
				SFX.play(Misc.resolveSoundFile("Emperor SFX/chair_spin"))
				data.state = CHAIR
				data.timer = 0 
			end
		else
			v.animationFrame = 0
		end
	elseif data.state == CHAIR then
		data.render = false
		data.shield = false
		data.chairFrame = math.floor(data.timer / 6) % 4 + 2
		data.lightFrame = math.floor(data.shieldTimer / 256) % 4 + 1
		if data.chairDir == 1 then
			v.y = v.y - 1
			if v.y <= v.spawnY - 192 then
				data.chairDir = -data.chairDir
			end
		elseif data.chairDir == -1 then
			v.y = v.y + 1
			if v.y >= v.spawnY then
				data.chairDir = -data.chairDir
			end
		end
		if data.timer >= 170 then
			data.state = NORMAL
			data.timer = 0 
		end
	elseif data.state == HURT then
		data.lightFrame = 0
		data.chairFrame = 0
		data.render = true
		data.shield = false
		if data.immunity <= 0 then
			v.animationFrame = 3
		else
			if data.hp <= 3 then
				v.animationFrame = 4
			else
				v.animationFrame = 2
			end
		end
		if data.timer >= 500 then
			data.state = NORMAL
			data.timer = 0 
		end
	elseif data.state == STUN then
		data.lightFrame = 0
		data.chairFrame = 1
		v.animationFrame = 4
		data.shield = false
		data.render = true
	end
end

function palpatine.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img
	local lowPriorityStates = table.map{1,3,4}
        local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45
	
	if data.render then
		Graphics.drawBox{
			texture = img,
			x = v.x+(v.width/2)+config.gfxoffsetx,
			y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
			width = config.gfxwidth,
			height = config.gfxheight,
			sourceY = v.animationFrame * config.gfxheight,
			sourceHeight = config.gfxheight,
                	sourceWidth = config.gfxwidth,
			sceneCoords = true,
			centered = true,
			priority = priority,
		}
	end

	npcutils.hideNPC(v)

	if data.shield then
		local shieldImg = Graphics.loadImageResolved("npc-"..v.id.."-shield.png")
		Graphics.drawBox{
			texture = shieldImg,
			x = v.x+(v.width/2),
			y = v.y - config.shieldOffset,
			width = config.shieldWidth,
			height = config.shieldHeight,
			sourceY = math.floor(data.shieldTimer / 6) % 4 * config.shieldHeight,
			sourceHeight = config.shieldHeight,
			sceneCoords = true,
			centered = true,
			priority = priority - 1,
		}
	end

	-- Draw the chair

	local chairImg = Graphics.loadImageResolved("npc-"..v.id.."-chair.png")
	Graphics.drawBox{
		texture = chairImg,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.chairWidth,
		height = config.chairHeight,
		sourceY = data.chairFrame * config.chairHeight,
		sourceHeight = config.chairHeight,
		sceneCoords = true,
		centered = true,
		priority = priority - 2,
	}

	local lightImg = Graphics.loadImageResolved("npc-"..v.id.."-lights.png")
	Graphics.drawBox{
		texture = lightImg,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height + config.lightOffset,
		width = config.lightWidth,
		height = config.lightHeight,
		sourceY = data.lightFrame * config.lightHeight,
		sourceHeight = config.lightHeight,
		sceneCoords = true,
		centered = true,
		priority = priority - 1,
	}

	local poleImg = Graphics.loadImageResolved("npc-"..v.id.."-pole.png")
	Graphics.drawBox{
		texture = poleImg,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height + config.lightOffset + 8 + (config.poleHeight / 2),
		width = config.poleWidth,
		height = config.poleHeight,
		sceneCoords = true,
		centered = true,
		priority = -85,
	}
end

function palpatine.onNPCHarm(eventObj,v,reason,culprit)
	if v.id ~= npcID then return end

        local data = v.data
	local settings = v.data._settings
	
        if reason ~= HARM_TYPE_LAVA then eventObj.cancelled = true end

	if data.immunity <= 0 then
		data.immunity = 30
		if data.hp > 0 then data.hp = data.hp - 1 end
		SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_hit_0"..RNG.randomInt(1, 3)..""))
		if data.hp <= 0 then
			if data.state ~= STUN then
				data.state = STUN
				Defines.earthquake = 4
				SFX.play(Misc.resolveSoundFile("Emperor SFX/emperor_stunned"))
				Effect.spawn(752, v.x + v.width * 0.5,v.y + v.height * 0.5)
				if settings.stunnedEvent ~= "" then triggerEvent(settings.stunnedEvent) end
	        		for j = 1, RNG.randomInt(16, 32) do
                        		local e = Effect.spawn(80, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        		e.x = e.x - e.width * 0.5
                        		e.y = e.y - e.height * 0.5
		        		e.speedX = RNG.random(-8, 8)
		        		e.speedY = RNG.random(-8, 8)
	        		end  
			end
		end
	end

	if reason == HARM_TYPE_JUMP then
		if culprit.__type == "Player" then
			culprit.speedX = math.sign((culprit.x + (culprit.width / 2)) - (v.x + (v.width / 2))) * 7.5
		end
	elseif reason == HARM_TYPE_NPC then
		if type(culprit) == "NPC" then
                        local e = Effect.spawn(75, culprit.x + culprit.width * 0.5,culprit.y + culprit.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
			culprit.speedX = math.sign((culprit.x + (culprit.width / 2)) - (v.x + (v.width / 2))) * 4
			culprit.speedY = -5
			culprit:harm(3)
		end
	end
end

return palpatine